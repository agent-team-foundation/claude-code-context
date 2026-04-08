---
title: "Tool Catalog"
owners: []
---

# Tool Catalog

This subdomain captures which tool families exist and how the runtime decides which concrete tool definitions are admitted into a session.

Relevant leaves:

- **[tool-families.md](tool-families.md)** — The major classes of tools that must exist.
- **[tool-pool-assembly.md](tool-pool-assembly.md)** — How the runtime assembles the exact tool list that the model and UI can see in one session.
- **[deferred-tool-discovery-and-tool-search.md](deferred-tool-discovery-and-tool-search.md)** — Deferred tool admission, ToolSearch-based discovery, discovered-tool persistence across compaction, and schema-mismatch recovery hints.
- **[agent-definition-loading-and-precedence.md](agent-definition-loading-and-precedence.md)** — How built-in, plugin, file-backed, and injected agent definitions assemble into one active catalog before launch routing begins.
- **[verification-agent-contract.md](verification-agent-contract.md)** — Native-test-derived contract for the built-in verification agent, including gating, disallowed tools, verification strategy, and verdict-format requirements.
