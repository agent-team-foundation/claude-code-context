---
title: "Turn-End Auto-Memory Extraction"
owners: []
soft_links: [/memory-and-context/durable-memory-recall-and-auto-memory.md, /runtime-orchestration/turn-flow/turn-assembly-and-recovery.md, /runtime-orchestration/turn-flow/stop-hook-orchestration-and-turn-end-bookkeeping.md]
---

# Turn-End Auto-Memory Extraction

Auto-memory extraction is a best-effort turn-end side workflow. It should improve durable memory quality without blocking normal response completion.

## Turn-end trigger point

Extraction is launched from the stop-hook phase for completed main-agent turns (no pending tool follow-up). It is fire-and-forget in interactive flows, with a later drain step for non-interactive shutdown paths.

## Eligibility gates

Extraction must skip unless all of these hold:

- extract-memory feature gate is enabled
- extraction mode is active
- auto-memory is enabled for the project
- runtime is not in remote-only mode
- query belongs to the main agent (not subagents)
- session is not in bare/simplified execution mode that suppresses background turn-end workers

## Overlap and coalescing model

The extractor uses closure-scoped state with two key guards:

- single active run at a time
- latest-context coalescing: if a new trigger arrives during a run, stash only the newest context and execute one trailing pass

It also tracks a cursor UUID so each run processes only new model-visible messages since the last successful extraction.

## Mutual exclusion with direct memory writes

If the main conversation already wrote to auto-memory files in the new range, background extraction skips that range and advances the cursor. This prevents duplicate or conflicting writes by two actors in the same turn era.

## Forked-agent execution contract

Extraction runs as a forked agent with cache-safe context sharing and strict tool limits:

- read-only discovery tools are allowed
- shell is allowed only for read-only commands
- write/edit is allowed only inside the auto-memory directory
- loop-level hard cap prevents long verification rabbit holes
- extraction transcript recording is skipped to avoid race-heavy transcript side effects

The prompt is built from new-message count plus a scanned memory manifest so the worker can update memory files without spending turns on directory discovery.

## User-visible side effects

Successful writes may emit a compact system notice listing saved memory topics. Mechanical index-file updates are filtered so the user-facing signal focuses on substantive memory entries.

Errors are logged as telemetry/debug only; extraction is explicitly non-blocking and non-fatal.

## Shutdown-drain contract

A drain API waits (with timeout) for in-flight extraction promises, including trailing coalesced runs. Non-interactive runners call this during shutdown sequencing so turn-end extraction can finish without hanging indefinitely.

## Failure modes

- **overlap race**: concurrent runs process the same delta range
- **cursor stall**: failed cursor advancement causes repeated extraction of old turns
- **permission escape**: extractor writes outside allowed memory directory
- **shutdown loss**: process exits before in-flight extraction settles
- **duplicate authoring**: main-agent memory writes and extractor writes conflict in the same range

## Test Design

In the observed source, memory and context behavior is verified through deterministic transformation regressions, persistence-aware integration tests, and continuity-focused conversation scenarios.

Equivalent coverage should prove:

- selection, compaction, extraction, and invalidation rules preserve the invariants and bounded-resource behavior documented above
- cache state, memory layers, session persistence, and rehydration paths compose correctly across resume, compact, and recovery flows
- visible context continuity still matches the product contract when deterministic fixtures or replay replace live upstream variability
