---
title: "MCP Integration"
owners: []
soft_links: [/tools-and-permissions/tool-catalog/tool-families.md, /platform-services/auth-config-and-policy.md]
---

# MCP Integration

This subdomain captures how Claude Code treats Model Context Protocol servers as first-class extensions to the runtime.

Relevant leaves:

- **[server-contract.md](server-contract.md)** — Umbrella contract from layered MCP server config through admission, connection, live surface exposure, interactive follow-up flows, and recovery.
- **[claude-code-mcp-serve-surface.md](claude-code-mcp-serve-surface.md)** — How `claude mcp serve` exposes Claude Code itself as a tools-only MCP server over stdio.
- **[mcp-management-command-flows.md](mcp-management-command-flows.md)** — How `claude mcp add/list/get/remove/add-json/add-from-claude-desktop/reset-project-choices` mutate and inspect MCP config.
- **[config-layering-policy-and-dedup.md](config-layering-policy-and-dedup.md)** — How layered MCP sources, managed policy, project approval, and cross-source dedup produce the live server set.
- **[oauth-step-up-and-client-registration.md](oauth-step-up-and-client-registration.md)** — How MCP OAuth discovery, callback handling, step-up scope requests, and secure reauth behave.
- **[federated-auth-conformance-and-idp-test-seeding.md](federated-auth-conformance-and-idp-test-seeding.md)** — How the federated XAA path, SEP-990 expectations, and mock-IdP token seeding behave as a conformance-oriented auth contract.
- **[connection-and-recovery-contract.md](connection-and-recovery-contract.md)** — Transport types, session recovery, and runtime failure boundaries for MCP servers.
- **[mcp-surface-state-assembly-and-live-refresh.md](mcp-surface-state-assembly-and-live-refresh.md)** — How connected MCP servers populate and replace session-state tools, commands, skills, and resources, and how `list_changed` refreshes avoid stale slices.
- **[channel-servers-and-permission-relay.md](channel-servers-and-permission-relay.md)** — Channel admission gates, structured inbound message injection, and optional MCP-mediated permission relay behavior.
- **[elicitation-request-and-completion-lifecycle.md](elicitation-request-and-completion-lifecycle.md)** — Elicitation intake, hook mediation, interactive form or URL handling, and URL completion signaling.
