---
title: "Shared Task-List Contract"
owners: []
soft_links: [/runtime-orchestration/tasks/task-model.md, /collaboration-and-agents/in-process-teammate-lifecycle.md, /tools-and-permissions/agent-and-task-control/control-plane-tools.md]
---

# Shared Task-List Contract

Claude Code uses a durable file-backed task list as the coordination substrate for shared project work. The same underlying task-list model supports swarm teammates, standalone tasks mode, and leader-facing progress UI, so a faithful rebuild needs one coherent contract for storage, claiming, watcher pickup, and presentation.

## Task-list identity and storage

Equivalent behavior should preserve:

- task-list ID resolution that prefers an explicit override, then shared team identity for teammates, then leader-owned team identity, and only falls back to the current session when no team exists
- storage under a sanitized task-list directory inside the product config home
- one JSON file per task plus separate lock and monotonic high-water-mark artifacts for the list itself
- high-water-mark persistence across resets or deletions so task IDs are never reused accidentally
- same-process change notifications so leader UI can refresh immediately without waiting for filesystem polling

## Mutation and dependency rules

Equivalent behavior should preserve:

- task creation under an exclusive list-level lock so concurrent writers cannot assign the same next ID
- task updates under a task-level lock after existence is rechecked
- deletion that also scrubs `blocks` and `blockedBy` references from other tasks
- blocker semantics where any non-completed dependency still blocks claiming
- filtering of completed blockers out of user-facing summaries even if old references remain on disk
- compatibility with both teammate name ownership and legacy agent-ID ownership when reading status

The data model is small, but the locking rules are load-bearing because multiple workers can mutate the same directory at once.

## Claiming and busy checks

Equivalent behavior should preserve:

- ordinary claiming that refuses missing, already claimed, already completed, or still-blocked tasks
- optional list-level busy checking that atomically verifies the claimant does not already own another unresolved task
- task ownership written before the work is announced to a worker
- promotion from claimed to in-progress by the caller that actually begins execution
- teammate shutdown or forced termination returning unfinished owned tasks to pending and clearing the owner field

Without the list-level busy check, one worker can race itself into owning more than one unresolved task.

## Watcher-driven pickup

The automatic pickup path needs more than "watch the directory."

A faithful rebuild should preserve:

- a debounced filesystem watcher on the task-list directory plus an initial scan
- stable refs for loading state and submit callbacks so the watcher is not torn down and recreated on every turn
- a current-task pointer that prevents the watcher from grabbing a second task before the first one completes or disappears
- eligibility limited to pending, unowned tasks with no unresolved blockers
- explicit rescan when the session returns to idle, even if no fresh filesystem event arrived
- claim release when prompt submission fails, so rejected pickup does not leave the task stranded under a dead owner

## Read surfaces and summary model

Equivalent behavior should preserve:

- a read-only task-list tool that is concurrency-safe and hides internal bookkeeping tasks from the model
- summaries that expose task ID, subject, status, owner, and only unresolved blockers
- UI ordering that briefly favors newly completed tasks, then in-progress work, then pending work with unblocked items ahead of blocked items
- owner badges and current-activity summaries derived from live teammate task state rather than stale task-file text alone
- visible owner labels only for teammates still considered active, so shut-down workers do not look like live assignees forever

## Reassignment and status reporting

Task ownership also drives team-level status surfaces.

A correct rebuild should preserve:

- agent busy or idle status computed from unresolved task ownership
- reassignment notifications that tell the leader which unfinished tasks were returned to the pool when a worker died or shut down
- task-list views that stay coherent whether ownership was written using teammate names or agent IDs

## Failure modes

- **ID reuse**: reset or delete reissues an old task number and corrupts dependency references
- **double claim**: two workers claim the same task because locking was too narrow
- **busy-check race**: one worker acquires multiple unresolved tasks because agent-busy validation was not atomic
- **blocked-task pickup**: auto-claim ignores unresolved blockers and starts downstream work too early
- **watcher churn**: the filesystem watcher is recreated every turn and eventually deadlocks or misses updates

## Test Design

In the observed source, task behavior is verified through lifecycle regressions, registry-backed integration tests, and concurrency-sensitive foreground or background scenarios.

Equivalent coverage should prove:

- state transitions for launch, running, streaming, cancellation, completion, and failure remain deterministic and resettable between cases
- task registries, monitor families, shared-control events, and persisted output compose correctly across main-session and worker contexts
- users can still observe, foreground, stop, and inspect task output through the same surfaces they use in normal interactive or automated runs
