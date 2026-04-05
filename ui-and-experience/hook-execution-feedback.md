---
title: "Hook Execution Feedback"
owners: []
soft_links: [/ui-and-experience/system-feedback-lines.md, /ui-and-experience/interaction-feedback.md, /runtime-orchestration/turn-attachments-and-sidechannels.md, /tools-and-permissions/tool-execution-state-machine.md]
---

# Hook Execution Feedback

Claude Code does not treat hooks as invisible background plumbing. Hook execution produces its own progress rows, async-completion attachments, stop-hook spinner suffixes, and post-run summaries, with different visibility rules depending on hook event and surface mode. A faithful rebuild needs the same count semantics and suppression boundaries or the UI will either freeze on stale “running hooks” rows or flood the transcript with low-signal hook chatter.

## Progress emission and count semantics

Equivalent behavior should preserve:

- one `hook_progress` progress message being emitted for each matching hook before execution begins, not one aggregate batch record
- each progress message carrying the hook event, hook name, display command text, and optional prompt text or custom status message
- progress and resolution lookups being keyed by `toolUseID` plus hook event, so hook feedback stays attached to the correct tool invocation
- in-progress counts being derived from progress-message multiplicity, while resolved counts are deduplicated by hook name because one hook can emit multiple attachment records during completion
- tool-specific progress renderers explicitly excluding `hook_progress`, so hook status cannot be mistaken for ordinary tool progress

## PreToolUse and PostToolUse feedback path

Equivalent behavior should preserve:

- `PreToolUse` hook feedback being rendered alongside the assistant tool-use row before tool-specific progress output
- `PostToolUse` hook feedback being rendered after the successful tool-result content rather than inside the tool result body itself
- transcript mode showing `PreToolUse` and `PostToolUse` as static past-tense summaries once observed, because transcript rows do not re-render and a transient “running” line would become permanently stale
- non-transcript surfaces hiding `PreToolUse` and `PostToolUse` completion rows, relying instead on async hook attachments or later summaries when detail is needed
- any tool-use message with unresolved `PostToolUse` hooks remaining dynamically rendered even after the main tool result has resolved, so the trailing hook progress row can still update

## Live progress for Stop and other hook events

Equivalent behavior should preserve:

- hook progress rows disappearing entirely when no in-progress count exists for the requested hook event
- non-`PreToolUse` and non-`PostToolUse` hook progress rows rendering only while resolved-hook count is still lower than in-progress count
- those live rows using compact dimmed phrasing that communicates “running <event> hook(s)” rather than exposing raw progress payloads
- `Stop` and `SubagentStop` progress also feeding the REPL spinner suffix while a turn is loading
- the stop-hook spinner suffix using only the most recent stop-hook execution batch, not summing multiple historical batches together
- that spinner suffix disappearing as soon as a stop-hook summary exists for the same execution, handing ownership over to the summary surface
- completed-stop counts for the spinner suffix being derived from matching stop-hook attachment records rather than from progress-message counts alone
- custom stop-hook status messages overriding the generic spinner text, with multi-hook runs appending a `completed/total` style counter
- build-profile-specific stop-hook suffix details being allowed: richer internal builds can include the current hook command label, while generic builds fall back to a plain stop-hook phrase

## Async hook attachments and visibility gates

Equivalent behavior should preserve:

- async hook completion attachments being globally hidden outside verbose mode unless the user is in transcript mode
- `SessionStart` async hook completions being even quieter: they stay hidden unless verbose mode is on, including outside transcript mode
- stop-hook and subagent-stop hook error or continuation attachments being suppressed from the generic attachment renderer because stop-hook summaries own the user-facing explanation
- non-stop hook blocking errors surfacing both the hook name and trimmed blocking stderr, so users can understand why continuation was blocked
- non-stop hook non-blocking errors and execution warnings surfacing as compact error or warning lines without dumping full hook output into the transcript
- hook-success attachments rendering nothing in the generic attachment list, treating success as bookkeeping unless another surface promotes it
- hook system-message and hook permission-decision attachments remaining visible as compact informational lines

## Dynamic versus static message lifetime

Equivalent behavior should preserve:

- `hook_progress` being explicitly non-ephemeral in the message store, unlike one-per-tool tick streams such as sleep or shell pacing updates
- that non-ephemeral storage preserving the distinct hook trail needed by tool rows, stop-hook suffix derivation, and transcript history
- message rows in transcript mode being treated as static regardless of unresolved hooks, because transcript is a historical snapshot
- prompt-mode assistant, attachment, and user rows staying transient while their associated tool use is streaming, still unresolved, or blocked on unresolved `PostToolUse` hooks
- stop-hook completion transitioning from live progress to summary or attachment surfaces rather than continuing to animate after completion

## Failure modes

- **stuck hook row**: transcript captures a transient “running” hook row that never re-renders into a completed summary
- **false completion**: resolved-hook counting ignores hook-name deduplication and declares a hook batch finished too early
- **tool-progress conflation**: hook progress is mixed into ordinary tool progress and obscures the actual tool state
- **stop-hook double surfacing**: stop-hook attachments render alongside stop-hook summaries and duplicate the same completion or failure story
- **spinner drift**: the REPL suffix keeps reading an old stop-hook batch or ignores custom status text and shows the wrong execution state
