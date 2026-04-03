---
title: "Server Contract"
owners: []
soft_links: [/tools-and-permissions/permission-model.md, /product-surface/command-surface.md]
---

# Server Contract

MCP support should not be modeled as a thin network client. It is a runtime extension system.

Important responsibilities:

- discover and parse server configuration from local and managed sources
- authenticate to servers when needed
- establish and monitor transport connections
- expose server tools, commands, and resources to the rest of the runtime
- enforce allowlists, permissions, and policy controls before use
- surface errors and elicitation flows in the same UX as built-in tools

The user experience should make MCP feel native while preserving strong boundaries around trust and permission.
