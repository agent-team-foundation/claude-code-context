---
title: "Autocompact Gating and Circuit Breakers"
owners: []
soft_links: [/memory-and-context/compact-path.md, /runtime-orchestration/turn-flow/query-recovery-and-continuation.md, /memory-and-context/context-lifecycle-and-failure-modes.md]
---

# Autocompact Gating and Circuit Breakers

Autocompact is a guarded recovery mechanism, not an always-on summarizer. A clean-room rebuild needs the same gating logic or it will either compact too aggressively or enter retry spirals.

## Threshold model

The trigger threshold is based on an effective context window, not raw model context:

1. Start from the model context window.
2. Reserve a fixed output budget for the compaction response itself.
3. Subtract an autocompact safety buffer.

The result is the proactive compaction trigger. The runtime also derives warning/error bands and a separate hard blocking limit used only when automatic compaction is disabled.

## When proactive autocompact is suppressed

Autocompact must refuse to run in specific modes:

- explicit global disable toggles
- sources that are already compaction workers or memory workers
- modes where another context-management system owns headroom (for example collapse-oriented flows)
- reactive-only experiments where proactive compact is intentionally suppressed

This suppression is necessary to avoid deadlocks and cache churn in forked workers.

## Token accounting subtleties

Before autocompact, the runtime may apply lightweight history reduction steps. Some reductions change effective context size without changing all usage counters immediately. Autocompact therefore receives correction signals (for example tokens already freed by pre-processing) so threshold checks reflect real pressure.

## Circuit breaker behavior

Autocompact keeps a consecutive failure counter in turn state.

- success resets the counter
- failure increments the counter
- after a small fixed number of consecutive failures, proactive autocompact is skipped for the rest of the session

This is a hard guard against repeated doomed compaction attempts when the session is already irrecoverably oversized.

## Interaction with blocking guardrails

When automatic compaction is off, the runtime enforces a hard blocking limit to preserve room for manual recovery commands. That preemptive block is skipped in flows where reactive recovery should get first chance (for example prompt-too-long handling paths), otherwise the runtime would prevent the very API error signal needed to trigger reactive compact.

## Failure contracts

- **false positive pressure**: stale token accounting causes unnecessary compact attempts
- **false negative pressure**: missed trigger leads to avoidable hard API errors
- **retry storm**: repeated autocompact failures without a breaker
- **deadlock paths**: autocompact allowed inside compaction/memory workers
- **recovery starvation**: hard preempt blocks reactive recovery branches

## Test Design

In the observed source, memory and context behavior is verified through deterministic transformation regressions, persistence-aware integration tests, and continuity-focused conversation scenarios.

Equivalent coverage should prove:

- selection, compaction, extraction, and invalidation rules preserve the invariants and bounded-resource behavior documented above
- cache state, memory layers, session persistence, and rehydration paths compose correctly across resume, compact, and recovery flows
- visible context continuity still matches the product contract when deterministic fixtures or replay replace live upstream variability
