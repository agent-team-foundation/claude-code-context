---
title: "State Machines and Failures"
owners: []
soft_links: [/runtime-orchestration/turn-flow/query-loop.md, /runtime-orchestration/tasks/task-model.md, /runtime-orchestration/state/app-state-and-input-routing.md, /runtime-orchestration/sessions/session-reset-and-state-preservation.md, /memory-and-context/compaction-and-dream.md]
---

# State Machines and Failures

The runtime has three interacting dynamic systems: the foreground turn loop, the background task lattice, and the app-state projection that decides which transcript is visible, which target receives input, and which metadata is mirrored outward.

## Foreground turn states

1. Context assembled.
2. Request in flight.
3. Streaming output.
4. Tool dispatch pending.
5. Tool result integration.
6. Recovery branch.
   Used for compaction, retry, continuation, or output-budget handling.
7. Turn complete.

The loop may revisit states 2 through 6 multiple times inside one user turn.

## Background task states

1. Pending.
2. Running.
3. Terminal success.
4. Terminal failure.
5. Terminal killed.

Tasks should never accept new writes once terminal, and foreground UI must treat terminal tasks as immutable history rather than live infrastructure.

## Shared app-state transitions

A faithful rebuild should keep several state transitions coordinated even though they do not all belong to one turn or one task:

- the visible main transcript can switch to a background task without changing who receives new input
- a viewed worker can disappear and force input routing to fall back safely to the leader session
- local task records and remote background-work counts advance independently and should not be collapsed into one registry
- permission posture changes should flow through one externalization path before they are mirrored to SDK or remote metadata
- structured session reset should regenerate foreground identity while relinking preserved background artifacts instead of killing everything blindly

## Runtime failure classes

- **Tool-path interruption**: a tool is selected but cannot execute, times out, or returns an error result.
- **Budget pressure**: input or output limits force compaction, truncation, or continuation.
- **Session corruption risk**: partial state updates would leave the turn inconsistent if not rolled forward or cancelled cleanly.
- **Feature-gate mismatch**: a command or task exists in code but is unavailable in the current build or entitlement posture.
- **Remote divergence**: local and remote runtimes disagree about permissions, history, or task ownership.
- **Routing divergence**: the visible transcript, active input target, and task registry fall out of sync.
- **Artifact relink failure**: preserved background work survives a reset logically but keeps writing to dead transcript bindings.

The runtime should prefer recoverable branching over hard failure whenever session continuity can be preserved.
