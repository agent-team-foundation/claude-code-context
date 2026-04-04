---
title: "Plugins and Skills"
owners: []
soft_links: [/ui-and-experience/terminal-ui.md, /tools-and-permissions/tool-families.md]
---

# Plugins and Skills

This subdomain captures the two main extension mechanisms beyond MCP.

Relevant leaves:

- **[plugin-and-skill-model.md](plugin-and-skill-model.md)** — Roles of plugins versus skills, trust boundaries, and lifecycle expectations.
- **[plugin-source-precedence-and-cache-loading.md](plugin-source-precedence-and-cache-loading.md)** — How layered settings, session-only injections, managed policy, cache-only startup, and full refresh assemble the effective plugin set.
- **[plugin-runtime-contract.md](plugin-runtime-contract.md)** — Discovery, admission, caching, deduplication, and failure handling for plugins.
- **[plugin-dependency-resolution-and-demotion.md](plugin-dependency-resolution-and-demotion.md)** — Install-time dependency closure, marketplace-aware resolution, and runtime fixed-point demotion when prerequisites are missing.
- **[plugin-hot-reload-and-settings-coupling.md](plugin-hot-reload-and-settings-coupling.md)** — How plugin hooks and plugin-contributed settings react to managed-settings changes, cache invalidation, and reload timing.
- **[plugin-management-and-marketplace-flows.md](plugin-management-and-marketplace-flows.md)** — `/plugin` command routing, marketplace management, scope-aware plugin lifecycle actions, refresh signaling, and delist handling.
- **[plugin-packaged-mcp-servers-and-user-config.md](plugin-packaged-mcp-servers-and-user-config.md)** — How plugin-packaged MCP servers, user-config merges, sensitive-field storage, and manual-config dedup produce live MCP contributions.
- **[lsp-plugin-and-diagnostics.md](lsp-plugin-and-diagnostics.md)** — How plugin-provided LSP servers are validated, trust-gated, routed, refreshed, and turned into diagnostics or install recommendations.
- **[skill-loading-contract.md](skill-loading-contract.md)** — Skill sources, load path, and the boundary between reusable guidance and executable extensions.
- **[legacy-commands-directory-compatibility.md](legacy-commands-directory-compatibility.md)** — How deprecated `.claude/commands` discovery, naming, normalization, and deduplication stay compatible alongside modern `/skills`.
- **[skill-improvement-detection-and-apply-flow.md](skill-improvement-detection-and-apply-flow.md)** — How ant-only post-sampling analysis turns repeated project-skill corrections into approval-gated `SKILL.md` rewrites.
- **[markdown-prompt-shell-expansion.md](markdown-prompt-shell-expansion.md)** — How skills, plugin commands, and some built-in prompt commands substitute runtime variables, execute inline shell snippets, choose Bash versus PowerShell, and refuse untrusted MCP shell bodies before the model sees the final prompt.
