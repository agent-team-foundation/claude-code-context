---
title: "State Machines and Failures"
owners: []
soft_links: [/runtime-orchestration/query-loop.md, /runtime-orchestration/task-model.md, /memory-and-context/compaction-and-dream.md]
---

# State Machines and Failures

The runtime has two core dynamic systems: the foreground turn loop and the background task lattice.

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

## Runtime failure classes

- **Tool-path interruption**: a tool is selected but cannot execute, times out, or returns an error result.
- **Budget pressure**: input or output limits force compaction, truncation, or continuation.
- **Session corruption risk**: partial state updates would leave the turn inconsistent if not rolled forward or cancelled cleanly.
- **Feature-gate mismatch**: a command or task exists in code but is unavailable in the current build or entitlement posture.
- **Remote divergence**: local and remote runtimes disagree about permissions, history, or task ownership.

The runtime should prefer recoverable branching over hard failure whenever session continuity can be preserved.
