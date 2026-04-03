---
title: "Runtime Orchestration"
owners: []
soft_links: [/tools-and-permissions, /memory-and-context]
---

# Runtime Orchestration

This domain captures the core assembly logic that turns a prompt, a tool registry, and session state into an agentic coding loop.

Relevant leaves:

- **[query-loop.md](query-loop.md)** — The streaming turn engine and its recovery paths.
- **[task-model.md](task-model.md)** — Background work and long-running task lifecycle.
- **[build-profiles.md](build-profiles.md)** — Feature gates and environment-specific capability envelopes.
