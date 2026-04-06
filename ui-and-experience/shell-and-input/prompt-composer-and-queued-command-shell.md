---
title: "Prompt Composer and Queued Command Shell"
owners: []
soft_links: [/runtime-orchestration/automation/prompt-suggestion-and-speculation.md, /runtime-orchestration/tasks/foregrounded-worker-steering.md, /runtime-orchestration/turn-flow/turn-attachments-and-sidechannels.md, /runtime-orchestration/state/app-state-and-input-routing.md, /product-surface/command-dispatch-and-composition.md, /ui-and-experience/shell-and-input/vim-mode-and-modal-editing.md, /ui-and-experience/background-and-teamwork/companion-surface.md]
---

# Prompt Composer and Queued Command Shell

Claude Code's interactive prompt bar is not a thin text field. It is a shared shell that coordinates text composition, bash-mode entry, pasted artifacts, autocomplete, history, footer navigation, prompt suggestions, worker steering, and queued command recovery against one live session.

## Scope boundary

This leaf covers:

- the interactive prompt shell rendered around the main text input
- how the input buffer, cursor, mode, and overlays arbitrate ownership
- how queued commands can be previewed, recovered into the buffer, or submitted later
- how autocomplete, history, paste handling, stash, and footer navigation reuse the same shell
- how direct submit and queued submit converge into one execution path

It intentionally does not re-document:

- speculative next-prompt generation internals already captured in [prompt-suggestion-and-speculation.md](../runtime-orchestration/automation/prompt-suggestion-and-speculation.md)
- worker transcript steering semantics already captured in [foregrounded-worker-steering.md](../runtime-orchestration/tasks/foregrounded-worker-steering.md)
- post-submit attachment injection and mid-turn queue draining already captured in [turn-attachments-and-sidechannels.md](../runtime-orchestration/turn-flow/turn-attachments-and-sidechannels.md)

## One shell, multiple modes

Equivalent behavior should preserve:

- one prompt shell supporting at least ordinary prompt entry, bash entry, delayed permission-recovery entry, and task-notification preview modes
- prompt mode being the normal editable path and bash mode being inferred from a leading mode marker rather than a wholly separate widget
- local dialog-style command surfaces that intentionally leave the prompt visible still being treated as modal for key-routing purposes, so their navigation keys do not leak into the underlying input
- worker foregrounding changing who receives submissions and which permission mode is shown, without replacing the shell component itself
- special-mode escape behavior at cursor position zero collapsing back to ordinary prompt mode rather than leaving the shell stranded in a half-edited command prefix

## Buffer ownership and cursor contract

Equivalent behavior should preserve:

- the prompt maintaining an explicit cursor offset instead of relying on append-only editing
- externally injected text, such as speech-to-text or other programmatic input replacement, moving the cursor to the end unless the caller explicitly sets a cursor position
- external insertion paths being able to add text at the current cursor rather than replacing the whole buffer
- click-to-position support mapping terminal coordinates back into wrapped text offsets when alternate-screen mouse tracking is available
- fullscreen rendering capping the visible input viewport while still keeping cursor-relative scrolling correct

## Placeholder and empty-state behavior

Equivalent behavior should preserve:

- placeholder text only appearing when the editable input is actually empty
- teammate view replacing the normal placeholder with a teammate-directed hint
- queued editable commands surfacing a temporary "press up to recover" style hint only for the first few times a user encounters the feature
- first-run example commands appearing only before the user has meaningfully used the shell, and being suppressed in proactive-style modes where the runtime already drives the interaction
- leader-only prompt suggestions overriding the default placeholder only when they are actually renderable in the shell

## Typeahead and completion surfaces

The shell hosts multiple completion systems that are related but not interchangeable.

Equivalent behavior should preserve:

- dropdown suggestions for slash commands, files, directories, shell completions, agent direct-message targets, resume targets, and Slack channels all sharing one visible suggestion surface
- mid-input slash command completion using inline ghost text when the cursor is in the middle of a prompt, instead of forcing the full dropdown
- command-argument hints rendering separately from suggestion rows so command syntax help can persist even when there is no selected row
- fullscreen layouts portaling suggestion rows into an overlay layer instead of consuming footer space, while non-fullscreen layouts render them inline above the footer
- suggestion selection being preserved by stable item identity when the suggestion list refreshes, rather than always snapping back to the first row
- Tab and right-arrow accepting the currently displayed suggestion only when a higher-priority overlay or conflicting suggestion system is not active
- file and directory completions understanding quoted paths, `@`-prefixed file references, and suffix rules such as trailing slash for directories versus trailing space for completed files
- direct-message and Slack-channel completions replacing only the active trigger token rather than the whole input buffer

## History navigation and search

Claude Code has two history systems because "previous entry" and "search the transcript of prior prompts" are different jobs.

Equivalent behavior should preserve:

- arrow-key history being stateful, mode-aware, and draft-preserving
- the first upward history step capturing the current draft, cursor state, draft-local hidden-content state, and active mode so downward traversal can restore that draft exactly
- bash-mode history traversal staying filtered to bash entries for the duration of that traversal instead of mixing with ordinary prompts mid-stream
- history entries being read in chunks and cached so rapid repeated arrow presses do not force one disk read per keystroke
- a search hint appearing only after the user has meaningfully navigated history, then dismissing once actual search starts
- incremental history search using its own query string, original-buffer snapshot, async reverse reader, and accept/cancel/execute handlers
- search mode borrowing footer space for its query field and suppressing conflicting footer hints such as Vim insert state
- search accept restoring the clean underlying value and mode rather than leaving the raw decorated history display in the buffer
- empty-query search restoring the original draft and pasted contents instead of committing a partial search state

## Paste, attachments, and collapsed artifacts

Equivalent behavior should preserve:

- image pastes turning into inline reference chips while the binary content is stored separately
- image storage being updated immediately enough for UI references to resolve, while heavier persistence work can continue in the background
- a lazy post-image space rule so typing directly after an inserted image chip naturally separates the chip from the next token
- removing an image chip from the buffer pruning the now-unreferenced image payload from the draft-local hidden-content state
- pasted text normalizing line endings, tabs, and escape sequences before further processing
- large or tall pasted text collapsing into a referenced pasted-text artifact instead of expanding the input until it destabilizes terminal layout
- extremely large input values being truncated once per newly loaded input value into a compact placeholder plus separately stored hidden content
- IDE-driven file mentions being inserted at the cursor with spacing and optional line references rather than being appended blindly

## Undo, stash, and external editor

Equivalent behavior should preserve:

- a debounced undo buffer storing text, cursor offset, and draft-local hidden-content state together
- stash acting as a full prompt snapshot, not only plain text, so image or collapsed-text references survive stash and unstash
- stashing non-empty input clearing the live buffer, while invoking stash on an empty buffer restores the previously stashed prompt
- external-editor editing expanding collapsed pasted-text references before opening the editor, then replacing the live buffer only if the edited content actually changed
- external-editor failure surfacing a notification without corrupting the current in-shell draft

## Unified queued-command shell

The prompt shell is also the recovery UI for the unified command queue.

Equivalent behavior should preserve:

- queued commands living in the shared session queue rather than inside one prompt instance's transient UI state
- prompt surfaces reading immutable queue snapshots so redraws happen only when queue contents actually change
- queue priorities preserving an interruption class, a normal between-turn class, and a deferred class
- editability and visibility being separate questions: some system-originated queued items remain visible as preview but are intentionally not pullable back into the editable buffer
- only user-editable queued commands being recoverable through Up or Escape
- queue preview rows rendering below the prompt in normal layouts, but disappearing while a worker transcript is foregrounded
- idle-style notifications being hidden from the preview entirely
- task-notification preview rows being capped to a small visible count and collapsed into an overflow summary message when too many accumulate
- queued bash commands previewing as bash input rather than as plain freeform text

## Recovering queued commands into the buffer

Equivalent behavior should preserve:

- Up on the first line preferring queued editable commands over ordinary history traversal
- Escape, when not consumed by a stronger overlay or request-cancel path, also being able to pull queued editable commands into the live buffer
- pulling queued commands back into the buffer concatenating their editable text in queue order ahead of the current draft rather than replacing the draft outright
- pasted image payloads attached to recovered queued commands being restored into the draft-local hidden-content state so the inline image references still resolve
- non-editable queued commands remaining in the queue after editable commands are popped for editing
- recovering queued commands always normalizing the shell back to prompt mode so the user re-edits concrete content instead of hidden queue metadata

## Submission routing and busy-state behavior

Equivalent behavior should preserve:

- direct submit and queued submit converging into one common execution loop, with direct user input first being normalized into the same queued-command shape
- prompt submission refusing empty text unless images are attached
- before any queueing or direct execution, pasted-text references being expanded so queued work preserves the content that existed at submit time
- immediate local terminal dialogs for specific slash commands being allowed to open while the session is already busy, instead of always queueing behind the active turn
- ordinary prompt and bash submissions queueing when another query or comparable external loading path is active
- busy-state queueing preserving raw pasted contents, pre-expansion text, and slash-routing metadata across that async boundary
- when the in-flight tool is explicitly interruptible, a new submission being able to abort the current turn before queueing the follow-up
- once execution begins, only the first command in a batched execution pass receiving turn-level attachments such as IDE selection and draft-local image resizing, while later commands in the same pass intentionally skip attachment duplication
- local slash commands that produce no transcript messages still clearing temporary UI state and releasing the query guard cleanly

## Footer, overlays, and focus arbitration

Equivalent behavior should preserve:

- one footer area multiplexing status line, history search field, mode hints, notification pills, and navigation affordances
- history-search UI taking over the left-side footer slot instead of opening a separate detached screen
- Vim insert hints appearing only when Vim mode is active and history search is not already using that space
- help, suggestions, quick-open, history picker, bridge dialog, model picker, fast-mode picker, thinking toggle, background-task detail, and other modal surfaces all being able to temporarily own prompt focus
- footer-item selection disabling normal text-input focus so arrow keys and Enter route to footer navigation instead of editing text
- printable characters typed while a footer pill is selected dropping the selection and entering text into the prompt, so footer focus never traps typing
- footer navigation order being derived from which pills are currently visible rather than a fixed static menu
- bridge, teams, tasks, tmux, and companion pills each opening their own action while still using one common footer-selection state machine

## Failure modes

- **overlay leakage**: a modal dialog leaves the prompt technically mounted but still receives arrow or escape keys underneath the dialog
- **draft loss**: history navigation or search fails to restore the user's original draft, cursor position, or draft-local hidden-content state
- **queue corruption**: pulling queued commands into the buffer discards attached images or mixes editable and non-editable commands incorrectly
- **completion rivalry**: placeholder suggestions, ghost text, dropdown suggestions, and footer navigation all compete for the same keystroke without a stable priority order
- **layout thrash**: large pastes or unstable suggestion widths force repeated terminal reflow and repaint churn
- **busy-submit duplication**: direct submit and queued submit diverge, so images, references, or slash-command handling behave differently depending on whether the session was busy
