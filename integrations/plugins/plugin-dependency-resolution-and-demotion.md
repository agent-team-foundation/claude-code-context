---
title: "Plugin Dependency Resolution and Demotion"
owners: []
soft_links: [/integrations/plugins/plugin-source-precedence-and-cache-loading.md, /integrations/plugins/plugin-runtime-contract.md, /platform-services/auth-config-and-policy.md, /tools-and-permissions/tool-catalog/tool-pool-assembly.md]
---

# Plugin Dependency Resolution and Demotion

Plugin dependency handling uses two different phases: install-time closure resolution and load-time demotion checks.

## Dependency semantics

Dependencies are treated as runtime presence guarantees, not language-level import graphs. A dependent plugin expects specific namespaced capabilities (commands, hooks, MCP servers, agents) to be available when enabled.

## Identifier normalization

Equivalent behavior should preserve dependency normalization rules:

- fully-qualified references stay as-is
- bare references inherit marketplace identity from the declaring plugin when that identity is meaningful
- inline/session-only plugin sources may keep bare references that resolve by plugin name only

This avoids accidental cross-marketplace drift while still supporting local development plugins.

## Install-time closure resolution

Transitive dependency resolution should preserve:

- depth-first traversal with cycle detection
- explicit "not found" errors when a required dependency cannot be discovered
- cross-marketplace blocking by default
- optional root-marketplace allowlists for controlled cross-marketplace pulls
- skipping already-enabled dependencies to avoid rewriting unrelated scope state

The requested root plugin remains installable even if already enabled, so reinstall/repair can still refresh local materialization.

## Load-time demotion (fixed point)

After plugins are loaded, dependency validity is rechecked against the enabled set.

Equivalent behavior should preserve:

- iterative fixed-point demotion (disabling one plugin can invalidate others)
- distinction between dependency "not installed" vs "installed but disabled"
- demotion as session/runtime state only (no implicit settings rewrites)
- surfacing dependency errors for diagnostics and plugin management UI

This keeps startup resilient while making dependency failures visible.

## Reverse-dependent warnings

Disable/uninstall operations should warn when other enabled plugins depend on the target plugin. Warning-only behavior is important: hard blocking can strand users when dependency graphs include delisted or broken artifacts.

## Failure modes

- **marketplace confusion**: bare dependencies resolve into unintended marketplaces
- **non-terminating demotion**: cascading demotion logic fails to converge
- **silent breakage**: unsatisfied dependencies do not generate user-visible errors
- **settings corruption**: load-time demotion writes persistent settings unexpectedly
- **teardown deadlock**: uninstall is blocked by reverse dependencies and cannot remove a broken plugin
