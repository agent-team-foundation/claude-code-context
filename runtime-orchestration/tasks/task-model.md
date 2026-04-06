---
title: "Task Model"
owners: []
soft_links: [/collaboration-and-agents/multi-agent-topology.md, /tools-and-permissions/agent-and-task-control/delegation-modes.md, /runtime-orchestration/tasks/shared-task-control-plane-and-lifecycle-events.md, /runtime-orchestration/automation/workflow-script-runtime.md, /runtime-orchestration/tasks/monitor-task-families-and-watch-lifecycle.md]
---

# Task Model

Claude Code treats long-running work as explicit tasks with typed lifecycle management rather than as anonymous detached side effects.

One shared task control plane owns registration, replacement, generic stop dispatch, offset polling, terminal eviction, and SDK lifecycle bookends across those families. Family-specific leaves then define what completion means, what summary gets emitted, and what extra state each family carries on top of that shared base.

## Finite task universe and base state

Equivalent behavior should preserve that tasks come from a finite runtime family set, not arbitrary caller-defined labels.

The load-bearing shared fields are:

- stable task ID
- stable coarse type
- one status from a finite lifecycle universe
- human description
- one output file binding and read offset
- one `notified` flag that acts as the terminal closeout barrier

Terminal status is a hard invariant. Once a task is terminal, generic runtime code should stop accepting new writes, follow-up injections, or duplicate notifications for that task.

## IDs and statuses are structural, not cosmetic

Equivalent behavior should preserve:

- per-family task ID namespaces rather than one flat random ID pool
- stable task-status values such as pending, running, completed, failed, and killed
- birth-time initialization of output offset and `notified = false` before any family-specific progress starts
- shared terminality checks that every family respects

The point is not the literal prefix characters. It is that task identity and terminality are part of the runtime contract, not UI decoration.

## Registration and replacement semantics

Equivalent behavior should preserve:

- one shared registration path that creates the base task record before the family starts doing real work
- replacement semantics for families that swap runtime handles while keeping the same task identity
- replacement intentionally not re-emitting a second "started" lifecycle event
- carry-forward of user-held state such as loaded transcript slices, retain posture, pending follow-up messages, and other viewing metadata when the family logically continues the same task

This is what lets backgrounding, restore, and family-specific refreshes feel like continuity rather than a new row every time.

## Family-specific identity still matters

Important runtime families include:

- local shell tasks
- local agent tasks
- remote agent shadow tasks
- in-process teammate tasks
- local workflow tasks
- monitor-MCP tasks
- dream/maintenance tasks

One special case is load-bearing: backgrounded main-session work reuses the `local_agent` family shape for compatibility, but still needs an explicit "main-session" identity branch so it remains distinguishable from an ordinary spawned subagent. A faithful rebuild cannot collapse that distinction away.

## Task lifetime exceeds one foreground turn

Equivalent behavior should preserve:

- tasks outliving the foreground prompt that created them
- some families surviving session clear or reconnect through isolated transcript/output storage
- task visibility, stop semantics, and SDK lifecycle bookends staying available even when the user is no longer focused on the originating turn

This separation matters because Claude Code mixes interactive foreground work with runtime activity that can continue, reappear, or notify later.

## Failure modes

- **identity drift**: a handoff or replacement silently creates a second task instead of continuing the first
- **terminal mutation**: finished tasks still accept output or follow-up messages
- **type collapse**: main-session background work becomes indistinguishable from ordinary local-agent work
- **double start**: replacement or resume emits a second lifecycle-start event for the same logical task
- **closeout leak**: completion and explicit stop both notify because `notified` is not treated as the barrier
