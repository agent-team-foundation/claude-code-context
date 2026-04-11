---
title: "Compaction and Dream"
owners: []
soft_links: [/runtime-orchestration/turn-flow/query-loop.md, /collaboration-and-agents/multi-agent-topology.md, /runtime-orchestration/tasks/dream-task-visibility.md]
---

# Compaction and Dream

Long-lived sessions require two complementary systems.

First, the interactive path needs compaction:

- summarize or collapse older turns
- preserve critical decisions and tool outcomes
- stay within context and output budgets
- keep the current session understandable after recovery

Second, the product needs durable consolidation:

- periodic background passes over recent sessions
- promotion of stable insights into durable memory
- pruning of contradictions and stale pointers
- strict separation between memory maintenance and arbitrary source edits
- a UI-visible dream-task surface so users can inspect or stop consolidation without turning it into an ordinary model-facing background notification

The broad distinction belongs here. The exact auto-dream trigger, lock, and forked-worker contract lives in [auto-dream-consolidation-and-locking.md](auto-dream-consolidation-and-locking.md).

The design point is not merely "summarize when long." It is "keep sessions responsive while preserving durable knowledge quality over time."

## Test Design

In the observed source, memory and context behavior is verified through deterministic transformation regressions, persistence-aware integration tests, and continuity-focused conversation scenarios.

Equivalent coverage should prove:

- selection, compaction, extraction, and invalidation rules preserve the invariants and bounded-resource behavior documented above
- cache state, memory layers, session persistence, and rehydration paths compose correctly across resume, compact, and recovery flows
- visible context continuity still matches the product contract when deterministic fixtures or replay replace live upstream variability
