---
title: "Transcript Message Actions and Cursor Mode"
owners: []
soft_links: [/ui-and-experience/transcript-and-history/message-selector-and-restore-flows.md, /ui-and-experience/shell-and-input/prompt-composer-and-queued-command-shell.md, /ui-and-experience/shell-and-input/terminal-runtime-and-fullscreen-interaction.md]
---

# Transcript Message Actions and Cursor Mode

In fullscreen sessions, Claude Code can temporarily swap the prompt for a transcript cursor. That cursor is not generic row selection. It only lands on actionable transcript items, keeps them visible while the transcript continues to stream, and offers message-level actions that reuse rewind and copy semantics instead of inventing a second editing model.

## Scope boundary

This leaf covers:

- when transcript cursor mode is available
- which transcript rows count as actionable targets
- how cursor navigation, expansion, and exit behave
- how copy and "copy primary tool input" behave
- how "edit last prompt" hands off into rewind semantics

It intentionally does not re-document prompt-history search, rewind confirmation details, or transcript-mode pager search beyond the points where those systems intersect with cursor mode.

## Entry is a prompt-to-transcript handoff

Equivalent behavior should preserve:

- cursor mode only existing in fullscreen transcript-capable environments, and being suppressible by feature gate or explicit disable setting
- the prompt binding using a dedicated "enter message actions" shortcut instead of overloading ordinary Up-arrow history
- modal overlays and prompt-history search blocking cursor entry so the prompt is not half-owned by two interaction models at once
- entering cursor mode targeting the latest navigable real user prompt, not merely the bottom-most rendered row
- the prompt widget disappearing while cursor mode is active, but the unsent draft text surviving the round-trip unchanged because draft state remains owned by the session rather than by the mounted input component

## Actionable rows are curated, not all visible rows

Cursor mode only works when transcript rows can support meaningful actions.

Equivalent behavior should preserve:

- user rows being actionable only when they are real authored prompts, not meta rows, compact summaries, synthetic interrupt rows, or XML-like command wrappers that never represented direct user intent
- assistant rows being actionable only when they contain substantive visible text or a tool call whose primary input can be extracted as a meaningful path, command, query, URL, or prompt
- grouped tool-use bundles and collapsed read/search bundles being actionable as aggregate transcript objects
- system rows staying mostly actionable, except for purely diagnostic or bookkeeping subtypes such as timing, saved-memory, away-summary, thinking-only, or aggregate stop-hook metrics rows
- attachment rows only being actionable for concrete user-facing artifacts such as queued commands, diagnostics, and hook failure cards
- zero-height or non-rendered rows being skipped even if their data shape would otherwise qualify
- queued-command attachments not counting as "previous/next user prompt" targets, because they resemble prompts visually but are not rewindable raw user messages

## Navigation is visibility-aware and transcript-aware

Equivalent behavior should preserve:

- a selected row always being highlighted and scrolled back into view after navigation or transcript growth
- `Up`/`Down` and `j`/`k` moving across the next visible actionable row
- `Shift+Up` and `Shift+Down` moving only between real user prompts
- top and bottom jump shortcuts selecting the first or last actionable row in the current transcript
- moving past the final actionable row exiting cursor mode and repinning the transcript to the bottom, rather than leaving the user stranded on a phantom selection below the fold
- selection identity tracking the chosen transcript item rather than a fragile screen position, so streaming appends do not silently retarget the cursor

## Actions share the transcript's real semantics

Equivalent behavior should preserve:

- `Enter` toggling expanded rendering for grouped tool-use rows, collapsed read/search rows, expandable attachment cards, and expandable system rows
- `Enter` on a user prompt invoking edit-or-rewind behavior instead of expansion
- `c` copying a type-aware textual representation of the selected row rather than its chrome
- user-message copy stripping leading system-reminder wrappers before placing text on the clipboard
- assistant tool-call copy falling back to the extracted primary input when there is no visible assistant prose to copy
- grouped tool-use and collapsed read/search copy returning the underlying tool-result text, not only the collapsed summary label
- queued-command attachment copy returning the queued prompt text so recovery previews and transcript copy stay aligned
- `p` copying only the primary input for supported tool calls, using human-meaningful labels such as path, command, query, URL, or prompt
- successful copy operations using the terminal clipboard path plus one short-lived "copied" notification that replaces prior copy toasts instead of stacking them

## Exit and rewind reuse existing recovery logic

Equivalent behavior should preserve:

- `Esc` being two-stage: collapse an expanded row first, then leave cursor mode on the next press
- `Ctrl+C` exiting cursor mode immediately so an expanded selection does not add extra keypresses before an interrupt can happen
- user-prompt edit first mapping the selected rendered row back to its raw source prompt, even when normalized transcript rows have derived identifiers
- only prompts that the rewind selector would accept being editable from cursor mode
- lossless cases, meaning no tracked file-history changes after the prompt and only synthetic later transcript content, restoring the prompt immediately after cancelling the current turn
- non-lossless cases opening the same rewind/message-selector confirmation surface with the selected prompt pretargeted, instead of trying to re-implement restore policy inline
- restore-from-cursor reusing the same prompt repopulation helpers as rewind, so pasted image attachments and other prompt-local state come back with the text

## Failure modes

- **selector pollution**: synthetic transcript rows become editable or copyable as if they were authored prompts
- **copy drift**: the cursor copies collapsed labels or wrapper markup instead of the underlying user-visible content
- **selection drift**: streaming transcript growth causes the cursor to jump to a different row or disappear off-screen
- **exit dead-end**: escaping an expanded selection takes too many presses and interferes with normal interrupt behavior

## Test Design

In the observed source, transcript and history behavior is verified through projection regressions, artifact-backed integration tests, and history-navigation end-to-end scenarios.

Equivalent coverage should prove:

- projection, filtering, search, selection, and restore behavior preserve the transcript contracts and cursor semantics documented here
- session artifacts, previews, exports, and restore paths compose correctly with real message stores and persisted history state
- users can navigate, resume, export, and restore history through the real product surface without replay duplication or state loss
