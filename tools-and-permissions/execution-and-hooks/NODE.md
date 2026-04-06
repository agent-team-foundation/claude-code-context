---
title: "Execution and Hooks"
owners: []
---

# Execution and Hooks

This subdomain captures how admitted tools actually run: execution state, batching, hook participation, and the final shape of a launched worker's tool set.

Relevant leaves:

- **[tool-execution-state-machine.md](tool-execution-state-machine.md)** — How tools move from selection to execution, denial, retry, and result integration.
- **[tool-batching-and-streaming-execution.md](tool-batching-and-streaming-execution.md)** — How concurrent-safe tools, streaming execution, progress, and synthetic repairs work.
- **[tool-hook-control-plane.md](tool-hook-control-plane.md)** — Hook source merge, matcher and dedup semantics, structured outputs, lifecycle integration points, and out-of-band execution boundaries.
- **[agent-runtime-context-and-tool-shaping.md](agent-runtime-context-and-tool-shaping.md)** — How a selected worker gets its final tool set, permission posture, inherited context, preloaded skills, frontmatter hooks, and additive MCP clients before the query loop starts.
