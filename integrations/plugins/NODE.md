---
title: "Plugins and Skills"
owners: []
soft_links: [/ui-and-experience/terminal-ui.md, /tools-and-permissions/tool-families.md]
---

# Plugins and Skills

This subdomain captures the two main extension mechanisms beyond MCP.

Relevant leaves:

- **[plugin-and-skill-model.md](plugin-and-skill-model.md)** — Boundary between installable plugin bundles and prompt-layer skills, including built-in-plugin versus bundled-skill distinctions.
- **[plugin-source-precedence-and-cache-loading.md](plugin-source-precedence-and-cache-loading.md)** — How layered settings, session-only injections, managed policy, cache-only startup, and full refresh assemble the effective plugin set.
- **[plugin-runtime-contract.md](plugin-runtime-contract.md)** — Lifecycle, refresh, and partial-failure isolation for plugins across intent, materialization, and live runtime state.
- **[plugin-dependency-resolution-and-demotion.md](plugin-dependency-resolution-and-demotion.md)** — Install-time dependency closure, marketplace-aware resolution, and runtime fixed-point demotion when prerequisites are missing.
- **[plugin-hot-reload-and-settings-coupling.md](plugin-hot-reload-and-settings-coupling.md)** — How plugin hooks and plugin-contributed settings react to managed-settings changes, cache invalidation, and reload timing.
- **[plugin-management-and-marketplace-flows.md](plugin-management-and-marketplace-flows.md)** — `/plugin` command routing, marketplace management, scope-aware plugin lifecycle actions, refresh signaling, and delist handling.
- **[plugin-packaged-mcp-servers-and-user-config.md](plugin-packaged-mcp-servers-and-user-config.md)** — How plugin-packaged MCP servers, user-config merges, sensitive-field storage, and manual-config dedup produce live MCP contributions.
- **[lsp-plugin-and-diagnostics.md](lsp-plugin-and-diagnostics.md)** — How plugin-provided LSP servers are validated, trust-gated, routed, refreshed, and turned into diagnostics or install recommendations.
- **[skill-loading-contract.md](skill-loading-contract.md)** — Skill sources, load path, and the boundary between reusable guidance and executable extensions.
- **[skill-discovery-and-listing-surfaces.md](skill-discovery-and-listing-surfaces.md)** — How skills are surfaced to the model, the `/skills` dialog, and other inventory summaries, including listing filters, budgets, and delta-announcement behavior.
- **[feature-gated-remote-skill-discovery-overlay.md](feature-gated-remote-skill-discovery-overlay.md)** — How feature-gated skill discovery, per-turn discovery reminders, session-scoped discovered names, and previously discovered remote skills behave without collapsing into the ordinary local skill registry.
- **[legacy-commands-directory-compatibility.md](legacy-commands-directory-compatibility.md)** — How deprecated `.claude/commands` discovery, naming, normalization, and deduplication stay compatible alongside modern `/skills`.
- **[feature-gated-project-skill-improvement-loop.md](feature-gated-project-skill-improvement-loop.md)** — How a feature-gated post-sampling loop turns repeated project-skill corrections into approval-gated project skill rewrites.
- **[markdown-prompt-shell-expansion.md](markdown-prompt-shell-expansion.md)** — How skills, plugin commands, and some built-in prompt commands substitute runtime variables, execute inline shell snippets, choose Bash versus PowerShell, and refuse untrusted MCP shell bodies before the model sees the final prompt.
