---
title: "Tool-Result Microcompaction and Cache Editing"
owners: []
soft_links: [/memory-and-context/compact-path.md, /memory-and-context/context-cache-and-invalidation.md, /runtime-orchestration/turn-flow/query-recovery-and-continuation.md]
---

# Tool-Result Microcompaction and Cache Editing

Microcompaction is the pre-autocompact pressure reducer for tool-result-heavy turns. It has two distinct implementations with different invariants.

## Position in the turn pipeline

Microcompaction runs before full autocompaction. It is fed post-budget and optional-snipped messages, so reductions compose in order:

1. bound oversized tool-result persistence
2. optional history snip
3. microcompact
4. larger context-management paths (collapse or full compact)

This ordering preserves detail-first reduction and keeps summarization as the last resort.

## Path A: time-based content clearing

When a long idle gap implies prompt cache expiry, the runtime can clear old compactable tool results in-message:

- trigger only on explicit main-thread sources
- require elapsed-time threshold and at least one eligible tool-result target
- keep the most recent N compactable tool results, clear older ones to a fixed placeholder
- emit telemetry with estimated tokens saved

Because this mutates prompt content directly, it resets cached-microcompact state and marks cache-read drops as expected.

## Path B: cached microcompact via cache editing

On supported models/providers, cached microcompact avoids changing message content:

- register compactable tool results by `tool_use_id`
- select deletion candidates by configured keep/trigger policy
- queue `cache_edits` deletions and defer visible boundary emission until after API usage returns
- keep local transcript content unchanged; deletions happen in API-layer cache semantics

This path is main-thread-scoped to avoid subagent pollution of shared cache-edit state.

## API-layer insertion contract

Request assembly must preserve strict ordering and dedup guarantees:

- emit exactly one request-level cache marker
- reinsert previously pinned `cache_edits` at their original user-message positions
- deduplicate delete references across pinned and new blocks
- insert new `cache_edits` into the latest user message after tool-result blocks, then pin them for replay
- add `cache_reference` fields only on tool-result blocks inside the cacheable prefix window

If placement is wrong, cache-edit requests become invalid or ineffective.

## Deferred boundary reporting

Cached microcompact does not emit its boundary immediately. Instead:

- store baseline cumulative deleted-token usage before the request
- after response, compute per-request deletion delta from API usage
- only emit a user-visible microcompact boundary when delta is positive

This avoids optimistic client-side estimates and aligns user-visible accounting with server truth.

## Lifecycle resets

Cached microcompact state is reset after compaction and after time-based content-clearing paths that invalidate cached assumptions. Failing to reset can cause deletion attempts for stale/nonexistent references.

## Failure modes

- **state leakage across agents**: subagent tool IDs contaminate main-thread cache-edit state
- **invalid edit placement**: `cache_edits` or `cache_reference` inserted outside allowed cache-control region
- **duplicate deletion refs**: repeated deletes in pinned/new blocks create API instability
- **false boundary accounting**: boundary emitted without real server-side deleted-token delta
- **stale-state deletions**: time-based content mutation without cached-MC reset

## Test Design

In the observed source, memory and context behavior is verified through deterministic transformation regressions, persistence-aware integration tests, and continuity-focused conversation scenarios.

Equivalent coverage should prove:

- selection, compaction, extraction, and invalidation rules preserve the invariants and bounded-resource behavior documented above
- cache state, memory layers, session persistence, and rehydration paths compose correctly across resume, compact, and recovery flows
- visible context continuity still matches the product contract when deterministic fixtures or replay replace live upstream variability
