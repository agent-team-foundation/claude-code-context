---
title: "Message Selector and Restore Flows"
owners: []
soft_links: [/runtime-orchestration/sessions/file-checkpointing-and-rewind.md, /runtime-orchestration/turn-flow/queued-command-projection-and-replay.md, /ui-and-experience/shell-and-input/prompt-history-persistence-and-paste-store.md]
---

# Message Selector and Restore Flows

Claude Code's rewind UI is more than a list of past prompts. It filters for genuinely user-authored restore points, previews whether code can be rewound, offers conversation-only versus code versus summarize variants, and reuses the same semantics for fast-path undo after a cancelled turn.

## Scope boundary

This leaf covers:

- which messages are eligible restore points
- how the picker and confirm screen behave
- when restore skips confirmation and when it cannot
- what conversation, code, and summarize restore actually reset
- how cancel-time auto-restore reuses the same meaning filters

It intentionally does not re-document the internals of file-history snapshot storage or compact-model summarization beyond the user-visible restore contract.

## Selectable rows are curated restore points

Equivalent behavior should preserve:

- only real user-authored prompts being selectable restore targets
- synthetic prompts, tool-result envelopes, meta messages, compact summaries, transcript-only rows, command-output wrappers, task notifications, ticks, and teammate control messages being excluded
- the current unsent draft appearing as a virtual `(current)` row so the list has a present-time anchor, without turning that row into a real historical restore point
- when file-history preview is enabled, each candidate row showing derived file-count and line-count metadata or an explicit "no code restore" signal

## Direct restore versus confirmation

Equivalent behavior should preserve:

- file-history-disabled sessions restoring the conversation immediately after selection instead of opening a confirmation menu
- preselected edit or rewind flows being able to land directly on the confirm screen when the caller already identified a target message
- the no-confirm fast path only triggering when there are no restorable file changes and every later message is semantically synthetic
- that synthetic-tail test ignoring tool results, progress rows, system rows, attachments, and meta wrappers while still treating substantive assistant output or later user prompts as meaningful

## Restore options and summarize variants

Equivalent behavior should preserve:

- restore options including conversation-only, code-only, and both when code can actually be rewound, otherwise collapsing to conversation-only
- code restore explicitly covering tracked file-history edits without claiming to undo manual edits or bash-side mutations
- summarize-from being a restore-like option that compresses later context and then repopulates the selected prompt back into the composer
- some builds exposing summarize-up-to as a separate option that summarizes earlier context while leaving the session positioned at the conversation end
- summarize options accepting optional inline guidance from the user
- summarize refusing silently-no-op behavior when the chosen message is no longer in the active context window

## What restore actually resets

Equivalent behavior should preserve:

- conversation restore slicing the transcript back to just before the selected prompt, issuing a fresh conversation ID, and clearing cached projection state tied to removed messages
- rewind restoring permission mode from the selected prompt when that prompt carried a different approval mode than the current session state
- conversation restore repopulating both the draft text and the input mode derived from the selected prompt
- image-bearing prompts restoring pasted image attachments back into composer state
- code restore and conversation restore being allowed to succeed or fail independently, with combined error reporting instead of hidden partial failure

## Cancel-time auto-restore

Equivalent behavior should preserve:

- a user-cancelled turn automatically undoing the last submit only when no meaningful response arrived, no newer query started, the current draft is still empty, no queued commands exist, and the user is not inspecting a teammate task
- the auto-restore path reusing the same selectable-message filter and synthetic-tail logic as the manual rewind surface
- undoing the just-submitted prompt's history entry before restoring it, so later history recall does not show duplicates
- selector-triggered restore deferring the actual rewind by one tick so an interrupt-status row can render before it disappears

## Failure modes

- **selector pollution**: synthetic or tool-generated rows appear as if they were restorable user prompts
- **false lossless restore**: confirmation is skipped even though meaningful assistant output or file changes would be discarded
- **partial restore amnesia**: text comes back but input mode or pasted images do not
- **overclaimed code rewind**: the UI implies bash or manual edits will be undone even though only tracked file-history edits are restorable

## Test Design

In the observed source, transcript and history behavior is verified through projection regressions, artifact-backed integration tests, and history-navigation end-to-end scenarios.

Equivalent coverage should prove:

- projection, filtering, search, selection, and restore behavior preserve the transcript contracts and cursor semantics documented here
- session artifacts, previews, exports, and restore paths compose correctly with real message stores and persisted history state
- users can navigate, resume, export, and restore history through the real product surface without replay duplication or state loss
