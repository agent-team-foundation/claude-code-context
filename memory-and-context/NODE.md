---
title: "Memory and Context"
owners: []
soft_links: [/runtime-orchestration, /ui-and-experience]
---

# Memory and Context

This domain captures how Claude Code decides what the model sees at the start of a turn and what durable knowledge survives across turns and sessions.

Relevant leaves:

- **[context-bootstrap.md](context-bootstrap.md)** — System and user context assembled before a turn.
- **[memory-layers.md](memory-layers.md)** — Ephemeral and durable memory stores.
- **[session-memory.md](session-memory.md)** — Background upkeep of a session-scoped working memory file.
- **[compaction-and-dream.md](compaction-and-dream.md)** — Context pressure management and background consolidation.
- **[context-lifecycle-and-failure-modes.md](context-lifecycle-and-failure-modes.md)** — State transitions for context assembly, caching, compaction, and memory upkeep.
- **[compact-path.md](compact-path.md)** — End-to-end path for proactive, reactive, and manual compaction flows.
