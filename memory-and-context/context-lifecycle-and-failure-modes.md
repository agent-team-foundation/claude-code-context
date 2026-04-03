---
title: "Context Lifecycle and Failure Modes"
owners: []
soft_links: [/memory-and-context/context-bootstrap.md, /memory-and-context/compaction-and-dream.md]
---

# Context Lifecycle and Failure Modes

Context in Claude Code is assembled, cached, pruned, and consolidated across multiple timescales.

## Lifecycle

1. Source discovery.
   The runtime identifies git state, memory files, settings-derived instructions, and session hooks.
2. Session cache fill.
   Stable context is memoized for the active session.
3. Turn assembly.
   Relevant context is prepended or appended for the current turn.
4. Pressure response.
   The runtime compacts, summarizes, or collapses earlier material.
5. Durable promotion.
   Longer-lived memories are updated outside the immediate turn.
6. Invalidation.
   Cache is cleared when cwd, settings, injected prompts, or memory sources change.

## Failure modes

- **Stale cache**: a setting or instruction changed, but the session keeps using the old context.
- **Over-injection**: too much context is attached, causing avoidable budget pressure.
- **Under-injection**: a session misses durable instructions and makes the wrong decision.
- **Compaction regression**: a summary keeps the conversation short but drops the constraints that justified prior work.
- **Memory contradiction**: durable memory preserves facts that newer sessions have invalidated.
