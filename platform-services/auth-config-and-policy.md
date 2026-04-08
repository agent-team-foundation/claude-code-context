---
title: "Auth, Config, and Policy"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /collaboration-and-agents/remote-and-bridge-flows.md, /platform-services/settings-schema-compatibility-and-invalid-field-preservation.md]
---

# Auth, Config, and Policy

Claude Code relies on layered configuration and policy enforcement rather than a single static config file.

The reconstructed platform should support:

- layered setting sources whose authority boundaries differ by feature, including general settings, remote-environment defaults, plugin enablement, and MCP server configuration
- managed overlays that can constrain or replace lower-priority local config instead of merely annotating it
- user authentication through OAuth and other supported credentials
- policy limits that can enable, disable, or lock specific capabilities and extension sources
- validated configuration loading with source attribution, migration paths, and feature-specific fail-open versus fail-closed behavior
- integration-specific auth such as MCP step-up OAuth, GitHub bootstrap import, or remote session ingress

This node is the umbrella contract for the more specific plugin, MCP, remote, and sync leaves in adjacent domains.

This domain governs whether a feature is merely implemented or actually available in a given environment.
