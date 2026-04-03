---
title: "Background Task Row And Progress Semantics"
owners: []
soft_links: [/ui-and-experience/background-task-status-surfaces.md, /ui-and-experience/background-task-detail-dialogs.md, /runtime-orchestration/task-model.md, /runtime-orchestration/review-path.md, /runtime-orchestration/dream-task-visibility.md, /runtime-orchestration/foregrounded-worker-steering.md]
---

# Background Task Row And Progress Semantics

Background-task lists and compact status surfaces do not render each task through one generic formatter. Claude Code uses task-type-specific one-line renderers plus a few shared helpers for status words, unread markers, teammate activity, and remote-review progress. A faithful rebuild needs this layer to preserve title ownership, truncation boundaries, status normalization, and compact progress behavior, or the same task will communicate differently across the footer, list dialogs, and foreground-steering surfaces.

## Type-specific row ownership

Equivalent behavior should preserve:

- one shared activity-width cap of about 40 characters for the task-owned text, with truncation happening before appended status or progress segments so terminal-state labels remain visible in narrow terminals
- local shell rows choosing `description` for monitor-kind shells and raw `command` text for ordinary shells, then appending the shared shell-status suffix
- remote review rows delegating the entire line to the specialized remote-review progress renderer instead of prepending the session title, because that compact renderer already owns the branded identity and live progress tail
- ordinary remote-session rows prepending an open diamond while status is `running` or `pending`, switching to a filled diamond once the session is terminal, then rendering truncated title, a separator dot, and the shared remote-session progress text
- local background-agent rows truncating the human description and appending shared task-status text that normalizes successful completion to `done`
- notification-bearing local background-agent rows appending `, unread` only when status is `completed` and the task has not yet been surfaced to the user
- in-process teammate rows reserving the leading slot for a colored `@agent` handle and rendering the trailing `: activity` segment in dim styling
- local workflow rows choosing label fallback order `workflowName -> summary -> description`, showing `N agent(s)` while running, showing `done` when completed, and using the same unread suffix contract as other notification-bearing task types
- monitor MCP rows behaving like local background-agent rows: truncated description, shared task-status text, and the unread suffix on unseen successful completion
- dream rows keeping the task description as the title portion, then inserting a dimmed `phase · detail` segment where detail is touched-file count only during the updating phase when at least one file has been touched and otherwise falls back to sessions-under-review count
- dream rows also using the same completed-to-`done` normalization and unread suffix contract as the other notification-bearing background tasks

## Shared status normalization

Equivalent behavior should preserve:

- one shared status-text helper rendering compact status as a dimmed parenthetical suffix rather than a standalone badge
- semantic coloring applying only to terminal statuses: success for `completed`, error for `failed`, warning for `killed`, and neutral styling for nonterminal states
- shell tasks normalizing backend states into `done`, `error`, `stopped`, or `running`, with both `running` and `pending` sharing the same visible `running` label
- local background-agent, workflow, monitor-MCP, and dream rows all reusing that same status-text helper so the unread suffix format cannot drift between task types

## Teammate activity precedence

Equivalent behavior should preserve:

- teammate activity summaries resolving in strict priority order: shutdown requested, awaiting plan approval, idle, summarized recent activities, last activity description, then a generic working fallback
- the colored teammate handle and the dimmed activity suffix being rendered by separate text spans so color stays attached only to the handle
- recent-activity summaries taking precedence over last-activity text only when there is a non-empty summarized recent-activity payload

## Compact remote-session progress

Equivalent behavior should preserve:

- remote review rows using a dedicated branded keyword plus a progress tail, with only that keyword receiving the rainbow gradient treatment while diamonds and counts remain ordinary or dimmed
- running remote review rows keeping the open diamond, while completed or failed review rows switch to the filled diamond
- review rows showing a setup state before the first progress snapshot exists, instead of exposing zero counts as if work had already started
- review-stage counts following one canonical formatter so compact rows and expanded review detail cannot drift
- pre-stage review counts rendering as `X found · Y verified` when counts exist but no explicit stage has been published yet
- the finding stage showing either `finding` or `X found`, depending on whether any findings have appeared yet
- the verifying stage showing `X found · Y verified` and appending a refuted count only when that count is nonzero
- the synthesizing stage showing verified count first, optional refuted count second, and a trailing deduping marker
- running review counts advancing smoothly upward by one increment per animation tick, at roughly 80 ms intervals, instead of snapping directly to larger target counts
- those animated counts snapping immediately whenever values decrease, whenever reduced motion is preferred, or whenever the review session is no longer running
- completed review rows replacing live counts with a ready state plus an inline shortcut hint for opening the result
- failed review rows collapsing the tail to a simple error state instead of continuing to show stale counts
- ordinary remote-session progress using a simpler fallback ladder: `done` on completion, `error` on failure, raw `status...` while no todo list exists yet, and `completed/total` once todo items are available

## Shared footer suppression dependency

Equivalent behavior should preserve:

- the teammate-activity utility layer also owning the predicate that hides the generic tasks footer when the spinner tree is open and every visible background task is an in-process teammate
- that footer-suppression predicate using the same background-task visibility filter as the broader status surfaces before deciding whether the generic footer would be redundant
- ant or coordinator-only panel-managed named local agents being excluded from that redundancy check the same way they are excluded from the generic footer itself

## Failure modes

- **review-line duplication**: a remote review row prepends title text and then also renders the branded compact review line, wasting width and repeating identity
- **unread-loss regression**: completed local-agent, workflow, monitor, or dream tasks lose the unread suffix and appear already acknowledged
- **status drift**: shell, workflow, and remote rows expose backend lifecycle words inconsistently instead of reusing one normalization contract
- **activity-precedence inversion**: teammate rows show stale work summaries even though stop, approval, or idle states should dominate the one-line description
- **count-animation mismatch**: review counters either jump abruptly despite being live and motion-enabled, or remain frozen because the animation clock and snap rules are not coordinated
- **redundant footer echo**: the generic tasks footer remains visible even though the spinner tree already exposes every teammate-only background task
