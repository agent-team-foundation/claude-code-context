---
title: "Memory Layers"
owners: []
soft_links: [/memory-and-context/instruction-sources-and-precedence.md, /memory-and-context/durable-memory-recall-and-auto-memory.md, /memory-and-context/session-memory.md, /memory-and-context/compaction-and-dream.md, /collaboration-and-agents/remote-and-bridge-flows.md, /integrations/plugins/plugin-and-skill-model.md]
---

# Memory Layers

Claude Code uses multiple memory layers instead of one flat conversation history.

The layers that matter for reconstruction are:

- baseline instruction layers and path-conditioned rules discovered from managed, user, and project memory sources
- current-turn transcript and tool results
- session memory: a rolling working note for the current session
- compaction summaries or condensed conversation state for long conversations
- durable memory files that survive across sessions and are recalled selectively
- team or shared memory for collaborative contexts
- agent-specific memory roots when a specialized worker or assistant mode should search a narrower memory scope

A correct implementation should selectively preload relevant memory rather than dump everything into every turn. Memory must be discoverable, deduplicated, freshness-aware, and separated from ordinary user-editable source files.
