---
title: "Context Cache and Invalidation"
owners: []
soft_links: [/memory-and-context/context-bootstrap.md, /runtime-orchestration/turn-flow/turn-assembly-and-recovery.md, /memory-and-context/compact-path.md]
---

# Context Cache and Invalidation

Claude Code caches context aggressively inside a session, but it does not treat every cache clear as the same kind of event. A faithful rebuild needs both memoization and explicit invalidation semantics.

## Session-scoped caches

Several context builders are intentionally memoized for the lifetime of an active session:

- **system context**, including stable repo-level facts such as the initial git snapshot when enabled
- **user context**, including discovered instruction content and the session's date anchor
- **memory-file discovery**, which is expensive because it walks directories, reads files, and expands includes
- **derived helper state** that other classifiers or recovery paths use instead of re-reading memory directly

These caches exist to keep repeated turns cheap and stable.

## What is allowed to go stale

The product intentionally freezes some inputs within a conversation:

- the git-status context is a snapshot of the repo at conversation start, not a live feed
- the date anchor is session-scoped once user context has been built
- the discovered baseline instruction stack is reused until an explicit invalidation path fires

This means a rebuild should not silently "help" by recomputing everything on every turn. That would change prompt prefixes, cache-hit behavior, and turn-to-turn consistency.

## Hard clear versus semantic reload

The important distinction is between:

- **hard clears for correctness**
- **semantic resets that represent a real instruction reload**

For memory discovery, those are different operations.

Hard clears should simply drop memoized results so the next read is fresh. They are appropriate when cwd, synced settings, or a memory-management dialog changed the underlying files and the session just needs the next read to be accurate.

Semantic resets should do more:

- clear the memoized discovery result
- mark the next load with a reason such as session start or compaction
- re-enable any one-shot hooks or observers that care that instructions were genuinely reloaded into active context

If a rebuild uses one generic `clearCache()` path for both cases, observability and runtime behavior will drift.

## Injection-driven invalidation

Some invalidations are caused by prompt composition, not file changes.

One important example is a transient system-prompt injection used as a cache-breaker. When that value changes, both system and user context caches must be cleared immediately so the next turn cannot reuse a now-invalid prefix.

The main design rule is that prompt-prefix-affecting state must invalidate all memoized layers that contribute to the same cache key.

## Prompt assembly bypasses

The runtime can assemble prompt prefixes in more than one mode.

Normal operation builds:

- the default system prompt
- user context
- system context

But when a custom system prompt is supplied, the rebuild should preserve this bypass:

- the default system prompt build is skipped
- system context append is skipped as well
- user context still loads normally
- optional append-only prompt text can still be added after the custom prompt

This is not a cosmetic override. It changes which cached builders participate in the turn.

## Recovery-time prefix rebuilding

Some recovery paths need to reconstruct a cache-safe prompt prefix before a full turn has completed.

That fallback should:

- reuse the same user-context and system-context builders as the main loop whenever possible
- strip any in-progress assistant message that has not reached a stable stop state
- accept that some late-bound extras may be missing, while still preferring a compatible prefix over total failure

This is how resume and side-question flows preserve cache locality without pretending they have a perfect snapshot.

## Cache interaction with compaction

Compaction is not just a transcript concern. It changes the meaning of subsequent context assembly.

When compaction clears instruction-related caches, the next load should be treated as a semantic reload rather than a quiet correctness refresh. Otherwise hook consumers, analytics, and any reload-sensitive behavior will misclassify a post-compaction turn as ordinary steady-state reuse.

## Failure modes

- **silent stale context**: settings or memory changed, but memoized user context keeps injecting old instructions
- **over-eager recomputation**: context builders rerun every turn and destroy prompt-prefix stability
- **reload misclassification**: compaction or other meaningful reloads are recorded as ordinary cache clears
- **custom-prompt leakage**: default system context still sneaks in even though a custom prompt was supposed to replace it
- **recovery skew**: fallback prefix rebuilding includes unstable in-progress content or drops too much state to preserve cache compatibility

## Test Design

In the observed source, memory and context behavior is verified through deterministic transformation regressions, persistence-aware integration tests, and continuity-focused conversation scenarios.

Equivalent coverage should prove:

- selection, compaction, extraction, and invalidation rules preserve the invariants and bounded-resource behavior documented above
- cache state, memory layers, session persistence, and rehydration paths compose correctly across resume, compact, and recovery flows
- visible context continuity still matches the product contract when deterministic fixtures or replay replace live upstream variability
