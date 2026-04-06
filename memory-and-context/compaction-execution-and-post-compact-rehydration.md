---
title: "Compaction Execution and Post-Compact Rehydration"
owners: []
soft_links: [/memory-and-context/compact-path.md, /memory-and-context/autocompact-gating-and-circuit-breakers.md, /runtime-orchestration/turn-flow/query-recovery-and-continuation.md]
---

# Compaction Execution and Post-Compact Rehydration

Compaction is a full runtime workflow, not just "summarize old messages." A reconstructive implementation needs matching execution phases, retry logic, and rehydration guarantees.

## Execution modes

The runtime supports multiple compaction modes with shared primitives:

- full compaction (auto or manual)
- partial compaction around a user-selected pivot
- session-memory-driven compaction when eligible
- resumed-session session-memory compaction when a working summary exists but no precise summarized-boundary marker survived the resume path

All modes still produce the same core artifact shape: compact boundary, summary message(s), optional preserved segment, post-compact attachments, and hook outputs.

## Summary generation contract

Before requesting a summary, the compaction worker applies strict preparation rules:

- run pre-compact hooks and merge hook-provided instructions with user instructions
- disallow tool execution inside the summarizer request
- strip heavy media payloads from summarizer input so compaction itself does not overflow
- drop attachment classes that are explicitly re-announced post-compact

The request path prefers a cache-sharing forked worker, then falls back to normal streaming if cache-sharing fails or yields unusable output.

## Prompt-too-long self-recovery while compacting

Compaction has its own overflow recovery loop. If the summary request itself is too large:

- truncate oldest API-round groups from the summarize set
- preserve API validity (for example user-first ordering and tool pairing)
- retry a bounded number of times
- fail with an explicit terminal error when further truncation would become meaningless

Without this loop, compaction can fail exactly when it is most needed.

## Boundary and preserved-segment semantics

A compact boundary message does more than mark chronology:

- records trigger class (auto or manual) and pre-compact token context
- carries discovered-tool state needed for post-compact tool-schema continuity
- can store preserved-segment relink metadata (anchor and tail pointers) so loader-time chain repair remains possible when only a suffix or prefix is kept

This metadata is required for loss-minimized partial and session-memory paths.

## Post-compact rehydration obligations

After summary generation, the runtime rebuilds critical working context:

- recent file-context attachments, constrained by both per-file and total token budgets
- plan artifacts and plan-mode posture
- invoked-skill payloads (truncated and budgeted, not dropped wholesale)
- in-flight async agent status attachments
- deferred-tool, agent-listing, and MCP-instruction delta attachments
- session-start hook outputs, so instruction surfaces are reintroduced in a consistent way
- session-memory summaries being section-truncated when needed before reinsertion, so one bloated working note cannot consume the entire post-compact budget

If this rehydration is skipped, the next turn sees a syntactically valid but operationally incomplete context.

## Session-memory-specific safety rails

Equivalent behavior should preserve:

- missing or template-only session-memory artifacts falling back to legacy compaction instead of pretending a usable working summary exists
- stale summarized-boundary markers that no longer resolve in the live transcript also falling back to legacy compaction instead of guessing a cutoff
- resumed sessions with a real working summary but no boundary marker still being able to use the session-memory path by preserving a fresh recent tail selected from the current transcript

## Cleanup and cache-state resets

Post-compact cleanup resets caches and transient state invalidated by transcript collapse, including:

- microcompact/cached-microcompact state
- memory-file and context caches (with main-thread safeguards to avoid clobbering shared module state from subagent compactions)
- classifier/speculative/beta-tracing caches
- session message cache

Compaction paths also reset prompt-cache-break baselines and re-append session metadata so resume surfaces keep correct session identity.

## Failure modes

- **compact-request overflow loop**: compaction request overflows and cannot recover
- **orphaned preserved segment**: kept tail/prefix loses chain-link metadata
- **rehydration loss**: plan/skill/tool delta state not restored after summary
- **cross-thread cache corruption**: subagent compaction resets main-thread module state
- **cache false positives**: post-compact cache read drops misclassified as unexpected breaks
