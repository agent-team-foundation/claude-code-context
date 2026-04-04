---
title: "Memory and Context"
owners: []
soft_links: [/runtime-orchestration, /ui-and-experience]
---

# Memory and Context

This domain captures how Claude Code decides what the model sees at the start of a turn and what durable knowledge survives across turns and sessions.

Relevant leaves:

- **[context-bootstrap.md](context-bootstrap.md)** — System and user context assembled before a turn.
- **[instruction-sources-and-precedence.md](instruction-sources-and-precedence.md)** — Exact ordering, filtering, and selective loading rules for instruction-bearing memory.
- **[memory-layers.md](memory-layers.md)** — Ephemeral and durable memory stores.
- **[durable-memory-recall-and-auto-memory.md](durable-memory-recall-and-auto-memory.md)** — Project-scoped durable memory storage, selective recall, and assistant-mode auto-memory flows.
- **[relevant-memory-selection-and-session-memory-upkeep.md](relevant-memory-selection-and-session-memory-upkeep.md)** — Exact turn-time relevant-memory selection contract and the thresholded upkeep path for session memory.
- **[session-memory.md](session-memory.md)** — Background upkeep of a session-scoped working memory file.
- **[memory-management-and-context-inspection.md](memory-management-and-context-inspection.md)** — How `/memory` edits and opens memory surfaces, and how `/context` plus SDK inspection report the real model-facing context budget.
- **[compaction-and-dream.md](compaction-and-dream.md)** — Context pressure management and background consolidation.
- **[context-cache-and-invalidation.md](context-cache-and-invalidation.md)** — Session caches, prompt-prefix rebuilding, and the difference between hard clears and semantic reloads.
- **[context-lifecycle-and-failure-modes.md](context-lifecycle-and-failure-modes.md)** — State transitions for context assembly, caching, compaction, and memory upkeep.
- **[compact-path.md](compact-path.md)** — End-to-end path for proactive, reactive, and manual compaction flows.
