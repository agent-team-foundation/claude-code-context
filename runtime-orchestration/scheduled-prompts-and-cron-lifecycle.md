---
title: "Scheduled Prompts and Cron Lifecycle"
owners: []
soft_links: [/product-surface/command-surface.md, /runtime-orchestration/build-profiles.md, /tools-and-permissions/control-plane-tools.md, /collaboration-and-agents/in-process-teammate-lifecycle.md, /ui-and-experience/system-feedback-lines.md]
---

# Scheduled Prompts and Cron Lifecycle

Claude Code's local scheduling system is not just a thin reminder command. It is a full runtime subsystem that spans tool surfaces, a bundled `/loop` skill, file-backed and session-only task stores, deterministic jitter, missed-task recovery, and a multi-session ownership lock so the same durable task does not fire twice.

## Scope boundary

This leaf covers:

- the local scheduled-prompt surfaces built around `CronCreate`, `CronDelete`, `CronList`, and the bundled `/loop` wrapper
- the data contract for file-backed and session-only cron tasks
- cron parsing, next-fire calculation, jitter, expiry, and restart reconstruction
- the shared scheduler core used by the REPL and headless `-p` style execution paths
- multi-session ownership, teammate routing, and missed-task catch-up behavior

It intentionally does not re-document:

- remote scheduled agents or cloud-side triggers, which are a separate product surface
- the generic task abstraction already covered in [task-model.md](task-model.md)
- the generic system-message rendering rules already covered in [system-feedback-lines.md](../ui-and-experience/system-feedback-lines.md)

## User-facing entry points and gate model

Equivalent behavior should preserve:

- the local scheduler existing only when the build ships the agent-trigger capability at all
- runtime availability being controlled by a live kill-switch gate plus a local environment override, with the gate able to stop already-running schedulers mid-session rather than only hiding new entry points
- a narrower durable-task gate controlling whether disk persistence is allowed, independently of whether session-only scheduling still works
- `durable: true` being silently coerced down to session-only behavior when durable scheduling is disabled, instead of surfacing a user-visible validation failure
- `CronCreate`, `CronDelete`, and `CronList` being deferred control-plane tools rather than ordinary foreground shell actions
- the bundled `/loop` skill being a thin recurring wrapper over `CronCreate`, not a second scheduler implementation
- `/loop` defaulting to a recurring ten-minute interval when no explicit interval is parsed
- `/loop` supporting both leading interval syntax and trailing `every ...` syntax, then immediately executing the parsed prompt once now after scheduling the recurring job
- local scheduled prompts and remote scheduled agents remaining distinct systems even though both use cron-like ideas

## Task contract and storage model

Equivalent behavior should preserve:

- durable tasks living in `.claude/scheduled_tasks.json` under the current project root
- the durable file shape being one `tasks` array whose entries carry an id, cron string, prompt, creation time, and optional recurrence or fire-history fields
- recurring tasks storing a persisted `lastFiredAt` so a future process can reconstruct the same next-fire time instead of acting like the task never ran before
- assistant-installed permanent recurring tasks being expressible in the on-disk format even though normal user creation does not expose that flag
- runtime-only fields such as `durable: false` and teammate ownership metadata staying out of the on-disk JSON
- session-only tasks being stored in in-memory bootstrap state and dying with the current Claude process
- list and scheduler reads merging file-backed tasks with session-only tasks for ordinary REPL operation, while explicit non-REPL callers can choose a pure file-backed view
- malformed files, empty files, and individual malformed tasks degrading to partial or empty results instead of blocking the subsystem
- invalid cron strings inside a hand-edited file being dropped task-by-task rather than poisoning the whole file
- removing the last durable task leaving an empty `scheduled_tasks.json` file behind so the file watcher still observes a change

## Creation, deletion, and listing rules

Equivalent behavior should preserve:

- cron creation rejecting syntactically invalid expressions before anything is stored
- cron creation also rejecting expressions that never match a calendar instant in roughly the next year
- creation enforcing a combined job-count ceiling of fifty jobs across durable and session-only tasks
- durable teammate-owned tasks being rejected because teammate identity does not survive process restarts
- creation returning a short user-facing job id plus a human-readable schedule summary
- creation turning on the session's scheduler-enable flag immediately so new jobs can start firing without requiring a reload or file-change event
- deletion treating session-only and durable ids uniformly from the caller's point of view, while internally removing them from the correct backing store
- teammates being allowed to delete only their own scheduled tasks
- listing merging durable and session-only tasks for the leader view, marking session-only jobs distinctly, and filtering teammates down to their own jobs

## Cron grammar and calendar semantics

Equivalent behavior should preserve:

- support for the standard five local-time cron fields: minute, hour, day-of-month, month, and day-of-week
- support for wildcard, single numeric values, ranges, step syntax, and comma-separated lists
- absence of extended cron syntax such as symbolic month names or special operators outside that narrow subset
- day-of-week accepting `7` as an alias for Sunday
- day-of-month and day-of-week using ordinary cron OR semantics when both are constrained, rather than requiring both to match
- next-run calculation being strictly after the anchor time, not inclusive of the current minute
- matching being bounded to about one year of future search before declaring "no match"
- all evaluation happening in the process's local timezone, so "9am" means local 9am where the CLI runs
- spring-forward gaps skipping fixed local times that never occur on that date
- fall-back repeats firing only once instead of repeating on both copies of the same local wall-clock time
- human-readable schedule formatting covering only common patterns and falling back to the raw cron expression for the rest

## Jitter, rescheduling, and expiry

Equivalent behavior should preserve:

- recurring tasks using deterministic per-task forward jitter so jobs that share the same nominal cron expression do not stampede the backend at the exact same second
- recurring jitter defaulting to ten percent of the interval between fires while still being capped at fifteen minutes
- one-shot tasks using deterministic backward jitter on hotspot wall-clock marks rather than being delayed later than the requested time
- one-shot jitter defaulting to hotspot minutes such as `:00` and `:30`, with up to roughly ninety seconds of early fire and off-minute schedules usually firing exactly when requested
- one-shot jitter never moving a newly created task to a moment before its creation time
- the REPL path being able to refresh jitter and expiry tuning from a live remote config cache without restarting the process
- malformed or out-of-range remote jitter config falling back wholesale to safe defaults instead of partially trusting a bad config object
- recurring tasks computing their first visible next-fire time from `lastFiredAt` when available, otherwise from `createdAt`
- recurring tasks rescheduling from the actual fire moment rather than trying to replay every skipped interval while the session was busy or absent
- recurring tasks auto-expiring after seven days by default
- aged recurring tasks firing one final time and then being deleted
- permanent recurring tasks staying exempt from age-based cleanup

## Scheduler lifecycle and multi-session ownership

Equivalent behavior should preserve:

- one non-React scheduler core shared between the REPL hook and headless `-p` style execution
- REPL startup polling a session-only "scheduler enabled" flag until a job exists, rather than mounting the full watcher and timer machinery unconditionally
- startup auto-enabling the scheduler when durable jobs already exist on disk, or when assistant-mode behavior requires built-in scheduled tasks to become active immediately
- explicit non-REPL callers being able to skip bootstrap-state assumptions and start the scheduler directly against a chosen directory
- a file watcher on `.claude/scheduled_tasks.json` reloading durable tasks after add or change events and clearing the loaded set after unlink
- a one-second check timer driving actual fire decisions
- scheduler timers and watchers not keeping an otherwise-idle headless process alive on their own
- loading-state deferral in ordinary REPL mode, so scheduled prompts wait until the foreground turn is idle before enqueuing
- assistant-oriented mode being allowed to bypass that loading gate when lower-latency background enqueueing matters
- only one live session in the same project directory owning durable-task firing at a time
- ownership being coordinated through a per-project lock file that records a stable owner identity plus the current pid
- lock acquisition using an atomic create-first strategy, not a racy read-then-write protocol
- a restarted process that kept the same logical session identity being able to refresh the lock with its new pid instead of losing ownership
- passive sessions probing the lock periodically and taking over when the owning pid is gone
- file-backed tasks firing only in the owning session, while session-only tasks remain process-private and therefore bypass the ownership lock

## Fire routing and execution paths

Equivalent behavior should preserve:

- each normal fire producing either a full-task callback or a prompt-only callback depending on the caller's needs
- REPL leader tasks appending a scheduled-task system message and enqueueing the prompt as a hidden later-priority notification rather than injecting it directly into the visible transcript
- scheduled prompts carrying a dedicated workload attribution so cron-initiated model work can be treated differently from an actively waiting human turn
- teammate-created session tasks being routed back into that teammate's pending input queue instead of the leader's main queue
- orphaned teammate recurring tasks being removed once the owning teammate is gone, rather than firing forever into nowhere
- headless `-p` mode enqueueing the hidden prompt and immediately kicking the main run loop, while still relying on the run mutex to avoid overlap during an active turn
- one-shot session tasks being removed synchronously from memory after firing
- one-shot durable tasks being removed asynchronously from disk with in-flight guards so a slow write does not cause duplicate fires on the next tick
- recurring durable tasks batching their `lastFiredAt` writes so multiple fires in one tick do not cause multiple read-modify-write cycles

## Missed-task catch-up behavior

Equivalent behavior should preserve:

- missed-task detection running only on the scheduler's initial durable-task load, not on every later file reload
- only missed one-shot durable tasks surfacing as catch-up work
- missed recurring tasks not opening a special recovery prompt and instead simply firing on the next normal scheduler tick
- missed one-shot tasks being removed from durable storage before the model ever sees their prompt bodies
- repeated reloads not re-asking about the same missed one-shot task after it has already been surfaced once
- the default missed-task notification explicitly requiring an `AskUserQuestion` confirmation before the prompt is executed
- each missed prompt body being fenced safely enough that embedded backticks cannot break out and turn the recovery notice into accidental immediate instructions

## Failure modes

- **gate split-brain**: the UI still exposes `/loop` or cron tools after the runtime kill switch has disabled live firing, or vice versa
- **double fire**: two Claude sessions in the same project both believe they own `.claude/scheduled_tasks.json` and execute the same durable task twice
- **restart replay storm**: recurring durable tasks fail to persist `lastFiredAt`, so every restart reinterprets old tasks as immediately due
- **teammate orphan leak**: recurring teammate jobs outlive the teammate that created them and keep firing into a dead mailbox
- **exact-minute herd**: deterministic jitter or off-minute guidance is missing, so large numbers of users all hit the backend on `:00`
- **expiry drift**: recurring jobs either never age out or disappear before their promised final fire
- **missed-task prompt injection**: catch-up prompts are surfaced raw without the confirm-first wrapper and fenced body
- **store confusion**: deletion, listing, or scheduler firing loses track of whether an id lives on disk or only in session memory
