---
title: "Plugins and Skills"
owners: []
soft_links: [/ui-and-experience/terminal-ui.md, /tools-and-permissions/tool-families.md]
---

# Plugins and Skills

This subdomain captures the two main extension mechanisms beyond MCP.

Relevant leaves:

- **[plugin-and-skill-model.md](plugin-and-skill-model.md)** — Roles of plugins versus skills, trust boundaries, and lifecycle expectations.
- **[plugin-runtime-contract.md](plugin-runtime-contract.md)** — Discovery, admission, caching, deduplication, and failure handling for plugins.
- **[plugin-management-and-marketplace-flows.md](plugin-management-and-marketplace-flows.md)** — `/plugin` command routing, marketplace management, scope-aware plugin lifecycle actions, refresh signaling, and delist handling.
- **[lsp-plugin-and-diagnostics.md](lsp-plugin-and-diagnostics.md)** — How plugin-provided LSP servers are validated, trust-gated, routed, refreshed, and turned into diagnostics or install recommendations.
- **[skill-loading-contract.md](skill-loading-contract.md)** — Skill sources, load path, and the boundary between reusable guidance and executable extensions.
- **[markdown-prompt-shell-expansion.md](markdown-prompt-shell-expansion.md)** — How skills, plugin commands, and some built-in prompt commands substitute runtime variables, execute inline shell snippets, choose Bash versus PowerShell, and refuse untrusted MCP shell bodies before the model sees the final prompt.
