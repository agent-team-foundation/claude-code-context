---
title: "Plugin Runtime Contract"
owners: []
soft_links: [/integrations/plugins/plugin-and-skill-model.md, /integrations/plugins/plugin-source-precedence-and-cache-loading.md, /integrations/plugins/plugin-hot-reload-and-settings-coupling.md, /integrations/mcp/connection-and-recovery-contract.md, /platform-services/auth-config-and-policy.md]
---

# Plugin Runtime Contract

Plugins are operational extensions and therefore need a stricter lifecycle than skills.

## Discovery and precedence

- Built-in plugins may ship with the product and be user-toggleable.
- User-installed or marketplace-backed plugins should be discoverable from configured plugin directories and caches.
- Session-only plugin injection should be able to override an installed plugin of the same name for the current session.
- Managed policy must be able to block that session override when the plugin name is admin-locked.

## Admission contract

- plugin manifests and component shapes must validate before activation
- plugin sources must pass trust and policy checks
- plugin-provided commands, hooks, agents, or MCP servers must be namespaced or otherwise collision-safe
- plugin-provided MCP servers should be deduplicated against manually configured servers based on underlying connection intent, not just display name

## Lifecycle

1. Discover plugin source.
2. Resolve or fetch plugin contents.
3. Validate manifest and components.
4. Admit or reject by trust and policy.
5. Load commands, hooks, agents, and integration surfaces.
6. Cache, version, or reload as needed.

## Failure classes

- **fetch failure**: the plugin source exists conceptually but cannot be materialized locally
- **validation failure**: manifest or component shape is invalid
- **source blocked**: marketplace, policy, or trust rules reject the plugin
- **cache skew**: command or hook state no longer matches the installed plugin bits

The detailed source-precedence, cache-loading, and hot-reload contracts live in the dedicated plugin leaves linked above. This node is the umbrella runtime contract for why those subcontracts matter.
