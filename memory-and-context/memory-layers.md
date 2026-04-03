---
title: "Memory Layers"
owners: []
soft_links: [/collaboration-and-agents/remote-and-bridge-flows.md, /integrations/plugins/plugin-and-skill-model.md]
---

# Memory Layers

Claude Code uses multiple memory layers instead of one flat conversation history.

The layers that matter for reconstruction are:

- current-turn transcript and tool results
- session summaries or compacted memory for long conversations
- durable memory files that survive across sessions
- team or shared memory for collaborative contexts

A correct implementation should selectively preload relevant memory rather than dump everything into every turn. Memory must be discoverable, deduplicated, and separated from user-editable source files.
