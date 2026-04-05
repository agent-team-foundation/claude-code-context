---
title: "MCP Integration"
owners: []
soft_links: [/tools-and-permissions/tool-families.md, /platform-services/auth-config-and-policy.md]
---

# MCP Integration

This subdomain captures how Claude Code treats Model Context Protocol servers as first-class extensions to the runtime.

Relevant leaves:

- **[server-contract.md](server-contract.md)** — Umbrella contract from layered MCP server config through admission, connection, live surface exposure, interactive follow-up flows, and recovery.
- **[config-layering-policy-and-dedup.md](config-layering-policy-and-dedup.md)** — How layered MCP sources, managed policy, project approval, and cross-source dedup produce the live server set.
- **[oauth-step-up-and-client-registration.md](oauth-step-up-and-client-registration.md)** — How MCP OAuth discovery, callback handling, step-up scope requests, and secure reauth behave.
- **[connection-and-recovery-contract.md](connection-and-recovery-contract.md)** — Transport types, session recovery, and runtime failure boundaries for MCP servers.
- **[mcp-surface-state-assembly-and-live-refresh.md](mcp-surface-state-assembly-and-live-refresh.md)** — How connected MCP servers populate and replace session-state tools, commands, skills, and resources, and how `list_changed` refreshes avoid stale slices.
- **[channel-servers-and-permission-relay.md](channel-servers-and-permission-relay.md)** — Channel admission gates, structured inbound message injection, and optional MCP-mediated permission relay behavior.
- **[elicitation-request-and-completion-lifecycle.md](elicitation-request-and-completion-lifecycle.md)** — Elicitation intake, hook mediation, interactive form or URL handling, and URL completion signaling.
