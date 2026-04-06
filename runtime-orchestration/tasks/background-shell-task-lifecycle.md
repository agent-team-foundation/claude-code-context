---
title: "Background Shell Task Lifecycle"
owners: []
soft_links: [/runtime-orchestration/tasks/task-model.md, /runtime-orchestration/tasks/monitor-task-families-and-watch-lifecycle.md, /tools-and-permissions/filesystem-and-shell/shell-execution-and-backgrounding.md, /runtime-orchestration/turn-flow/turn-attachments-and-sidechannels.md]
---

# Background Shell Task Lifecycle

Claude Code does not treat a background shell command as "just a detached process." It registers it as structured task state, gives it a stable output file, deduplicates notifications, and preserves enough metadata for the UI, SDK, and task tools to reason about it later.

Shared registration, generic stop dispatch, `notified` barriers, terminal eviction rules, and SDK lifecycle ordering are captured in [shared-task-control-plane-and-lifecycle-events.md](shared-task-control-plane-and-lifecycle-events.md). This leaf focuses on the shell-specific backgrounding, watchdog, and completion details layered on top of that base.

## Foreground versus background registration

Shell task state has two distinct registration modes:

- a foreground registration used for long-running commands that are still visible in the main turn
- a background registration used once the command has actually been detached from the turn

The durable rule is that foreground tasks live in task state early enough to support backgrounding, but they are not yet counted as true background tasks until a dedicated `isBackgrounded` flag flips.

## Stable task identity

The shell process and the task registry must share one identifier.

Equivalent behavior should preserve:

- the task ID comes from the shell output owner, not from a second independently generated task record
- the same ID names the task, the output file, the background handle returned to tools, and later task-notification payloads
- in-place backgrounding must reuse the existing task record rather than re-registering and emitting a second `task_started` event

## State that must survive

A registered background shell task needs more than command text.

At minimum it should preserve:

- status (`running`, `completed`, `failed`, `killed`)
- the original command and a user-facing description
- the originating tool-use ID when one exists
- the live shell-handle reference while the task is still killable
- whether the task is foregrounded or backgrounded
- which agent, if any, spawned it
- whether a completion notification has already been sent
- the task kind when the UI needs a special monitor-style presentation

Cleanup callbacks should be tied to task registration so orphaned shell work can be killed on session or agent teardown.

## Backgrounding paths

Equivalent behavior should support all of these transitions:

- spawn a task already backgrounded
- register a foreground shell task and later background only that task
- background every currently foregrounded shell or agent task from a single UI gesture
- background an already-registered foreground shell task in place when an auto-background timer fires

That last case is load-bearing because it avoids duplicate task-start signals and leaked cleanup handlers.

## Completion handling

Background completion is owned by the task implementation, not by a generic "finished process" callback.

A correct rebuild should preserve this sequence:

1. flush task output and release shell-stream resources
2. transition the stored task to `completed`, `failed`, or `killed`
3. clear the live shell-handle pointer so later stop attempts cannot reuse stale state
4. stamp end time
5. enqueue exactly one completion notification unless the task was already marked notified
6. evict the in-memory output writer while leaving the persisted file readable

Generic task polling should not emit a second completion attachment for shell tasks. Per-task completion callbacks own that message.

## Notification contract

Completion notifications must be structured and deduplicated.

Equivalent behavior should preserve:

- task ID, task output path, and optional originating tool-use ID in the notification payload
- distinct status values for completed, failed, and killed tasks
- a summary string chosen for collapse-friendly UI grouping
- an atomic "already notified" barrier so race paths cannot deliver both a tool-owned completion and a background-task completion

Monitor-style shell tasks should have a distinct completion summary family so they do not collapse into the generic "background command completed" bucket.

## Stall watchdog

Background shell tasks also need a deadlock detector.

The runtime should:

- periodically inspect output growth for non-monitor shell tasks
- if output stops growing for a long interval, inspect the tail for prompt-like last-line patterns
- if the tail looks like interactive input is required, send a one-shot advisory notification
- omit terminal status in that advisory so SDK consumers do not mistake it for task completion

Slow commands that do not look interactive should remain quiet rather than generating false alarms every poll cycle.

## Stop semantics

Stopping a task is stricter than sending a signal blindly.

A faithful rebuild should require:

- the task exists
- the task is still running
- the task type has a registered stop implementation

For shell tasks specifically, a stop action should also mark the task as notified before the process exit lands, so the later shell-exit callback does not emit a second noisy completion message. SDK consumers still need an explicit stopped event even when the XML notification is suppressed.

## Eviction and freshness

Terminal tasks may be garbage-collected once they are both terminal and already notified.

Equivalent behavior should re-check fresh state at eviction time rather than trusting a stale pre-await snapshot. Otherwise a resumed or replaced task can be accidentally evicted by an older polling pass.

## Failure modes

- **double start**: auto-backgrounding re-registers an existing task and emits duplicate task-start events
- **background misclassification**: a foreground shell task shows up as a background task before it is truly detached
- **duplicate completion**: stop paths and shell-exit paths both notify because the task was not atomically marked as already handled
- **silent prompt deadlock**: a background task waits for interactive input indefinitely with no advisory signal
- **stale eviction**: a polling pass removes a task that was resumed or replaced after the poll began
