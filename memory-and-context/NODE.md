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
- **[auto-dream-consolidation-and-locking.md](auto-dream-consolidation-and-locking.md)** — The turn-end trigger, PID/mtime lock, forked memory-only worker, and rollback semantics for automatic durable-memory consolidation.
- **[relevant-memory-selection-and-session-memory-upkeep.md](relevant-memory-selection-and-session-memory-upkeep.md)** — Exact turn-time relevant-memory selection contract and the thresholded upkeep path for session memory.
- **[session-memory.md](session-memory.md)** — Background upkeep of a session-scoped working memory file.
- **[memory-management-and-context-inspection.md](memory-management-and-context-inspection.md)** — How `/memory` edits and opens memory surfaces, and how `/context` plus SDK inspection report the real model-facing context budget.
- **[compaction-and-dream.md](compaction-and-dream.md)** — Context pressure management and background consolidation.
- **[context-cache-and-invalidation.md](context-cache-and-invalidation.md)** — Session caches, prompt-prefix rebuilding, and the difference between hard clears and semantic reloads.
- **[context-lifecycle-and-failure-modes.md](context-lifecycle-and-failure-modes.md)** — State transitions for context assembly, caching, compaction, and memory upkeep.
- **[compact-path.md](compact-path.md)** — End-to-end path for proactive, reactive, and manual compaction flows.
- **[autocompact-gating-and-circuit-breakers.md](autocompact-gating-and-circuit-breakers.md)** — Effective-window thresholds, suppression rules, hard blocking guards, and failure-circuit shutdown for proactive compaction.
- **[compaction-execution-and-post-compact-rehydration.md](compaction-execution-and-post-compact-rehydration.md)** — Full or partial or session-memory compaction execution, retry ladders, boundary semantics, and mandatory context rehydration.
- **[tool-result-microcompaction-and-cache-editing.md](tool-result-microcompaction-and-cache-editing.md)** — Pre-autocompact tool-result reduction paths, cache-edit placement rules, and deferred deletion accounting.
- **[turn-end-auto-memory-extraction.md](turn-end-auto-memory-extraction.md)** — Stop-phase-triggered memory extraction, overlap coalescing, restricted forked-agent writes, and shutdown drain behavior.
