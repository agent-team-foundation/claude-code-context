---
title: "Auth, Config, and Policy"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /collaboration-and-agents/remote-and-bridge-flows.md]
---

# Auth, Config, and Policy

Claude Code relies on layered configuration and policy enforcement rather than a single static config file.

The reconstructed platform should support:

- user authentication through OAuth and other supported credentials
- managed settings from local, enterprise, or remotely controlled sources
- policy limits that enable or disable specific capabilities
- validated configuration loading with source attribution and migration paths
- integration-specific auth such as MCP, GitHub app installation, or remote session ingress

This domain governs whether a feature is merely implemented or actually available in a given environment.
