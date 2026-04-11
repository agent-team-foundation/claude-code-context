---
title: "System Feedback Lines"
owners: []
soft_links: [/ui-and-experience/feedback-and-notifications/interaction-feedback.md, /ui-and-experience/background-and-teamwork/background-task-summary-labels.md, /ui-and-experience/feedback-and-notifications/idle-return-and-away-summary.md, /runtime-orchestration/turn-flow/query-recovery-and-continuation.md, /runtime-orchestration/turn-flow/advisor-and-thinking-lifecycle.md, /memory-and-context/session-memory.md, /collaboration-and-agents/remote-and-bridge-flows.md]
---

# System Feedback Lines

Claude Code does not render runtime and orchestration events as one generic gray log line. System-originated feedback rows are subtype-driven: some always render, some collapse completely unless the user asks for detail, and others specialize into richer multi-line blocks with links, file rows, or transcript-only expansion. A faithful rebuild needs the same routing and suppression rules or the product will either drown the transcript in low-signal chatter or hide recovery state the user still needs.

## Top-level dispatch and suppression

Equivalent behavior should preserve:

- one top-level dispatcher for system messages that routes known subtypes into specialized renderers before any generic info-suppression rule runs
- turn-duration summaries, memory-saved rows, away summaries, agent-stop confirmations, bridge-status rows, scheduled-task-fire notices, permission-retry confirmations, stop-hook summaries, and API errors all bypassing the generic plain-text path
- plain system info messages outside those specialized branches collapsing entirely when verbose mode is off
- stop-hook summaries being exempt from that generic info suppression so recovery-relevant hook state can still surface
- generic fallback rows rendering only when `content` is actually string-shaped; malformed or contentless payloads producing no output instead of crashing
- the current build suppressing `thinking` system rows entirely, even though a dedicated renderer still exists behind the dispatcher

## Turn-duration summary contract

Equivalent behavior should preserve:

- turn-duration rows always rendering in subdued styling through their own specialized branch rather than competing with ordinary system warnings or errors
- the completion line choosing a playful past-tense verb from a curated set once per rendered message and then preserving that chosen verb for that row
- the duration segment honoring the global `showTurnDuration` setting while still allowing budget details to appear even when raw duration text is hidden
- budget formatting splitting into two modes: `used (min ✓)` once spent tokens reach the minimum target, otherwise `spent / limit (percent%)`
- continuation-nudge counts appending only when at least one budget nudge occurred
- the row disappearing entirely only when duration display is disabled and no budget data exists
- the background-task suffix snapshotting the current running-background summary once when the row is created, then appending `still running` as historical context instead of live-updating as tasks later start or finish

## Stop-hook summary compression

Equivalent behavior should preserve:

- clean unlabeled stop-hook summaries disappearing entirely when they contain no hook errors and did not block continuation
- hook-labeled summaries taking a different rendering path from generic stop-hook summaries
- hook-labeled summaries showing a compact dimmed `Ran N <label> hook(s)` line and, in transcript mode, immediately listing per-hook command rows underneath without requiring verbose mode
- generic stop-hook summaries using a prominent bullet row, with non-verbose mode showing only the summary plus an expand hint when hook detail exists
- verbose generic stop-hook summaries expanding hook commands inline as dimmed child rows
- continuation-prevention reasons surfacing as their own child line only when a stop hook actually blocked continuation
- hook errors appending one child line per error so hook failure details are visible without merging them into the top summary text
- hook timing text staying absent in the current build even when duration data exists, because the timing suffix path is compiled out here

## Memory-saved rows

Equivalent behavior should preserve:

- memory-saved feedback using a two-part structure: a compact headline followed by one row per written memory path
- the headline combining private-memory count and feature-gated team-memory count into one joined summary, omitting any segment whose count is zero
- the headline verb defaulting to a generic saved verb but honoring an explicit verb override when the event provides one
- written-memory rows showing the basename as the visible label while keeping the full absolute path as the open target
- those file rows being clickable and hover-sensitive, with dim text by default and underline emphasis on hover
- click behavior opening the target path directly from the feedback row instead of requiring navigation to another surface first

## Other specialized system lines

Equivalent behavior should preserve:

- away summaries rendering with a reference-style marker and dimmed content instead of a warning or error presentation
- background-agent stop confirmations rendering as an error-colored bullet plus a fixed all-agents-stopped message
- scheduled-task-fire notices rendering as a compact teardrop-prefixed gray line with the scheduler-provided content
- permission-retry confirmations rendering as a compact line that spells out the newly allowed commands and bolds the joined command list
- bridge-status feedback rendering as a small multi-line remote-control status block with a highlighted command name, a clickable destination URL, and an optional dimmed upgrade nudge

## Failure modes

- **info flood**: ordinary low-priority system info bypasses the verbose gate and starts crowding the transcript
- **snapshot drift**: a turn-completion row keeps re-reading live background-task state and rewrites history after the turn already ended
- **silent hook blockage**: stop hooks block continuation or fail, but the summary path is suppressed as if nothing unusual happened
- **memory-path opacity**: memory-saved rows expose only vague counts with no clickable path breakdown
- **bridge handoff ambiguity**: remote-control activation lacks its destination link or upgrade nudge and leaves the user unsure where to continue

## Test Design

In the observed source, feedback and notification behavior is verified through event-to-message regressions, runtime-backed integration tests, and terminal-visible interaction scenarios.

Equivalent coverage should prove:

- message selection, prioritization, suppression, and summarization rules preserve the user-facing semantics documented here
- status lines, hook feedback, away summaries, and notification stacks stay in sync with real runtime events and reset cleanly between cases
- the observable terminal text and ordering remain correct for users rather than only the internal event log or analytics stream
