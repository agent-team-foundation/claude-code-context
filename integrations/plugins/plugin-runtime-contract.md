---
title: "Plugin Lifecycle and Refresh Contract"
owners: []
soft_links: [/integrations/plugins/plugin-and-skill-model.md, /integrations/plugins/plugin-source-precedence-and-cache-loading.md, /integrations/plugins/plugin-hot-reload-and-settings-coupling.md, /integrations/mcp/connection-and-recovery-contract.md, /platform-services/auth-config-and-policy.md, /platform-services/settings-change-detection-and-runtime-reload.md]
---

# Plugin Lifecycle and Refresh Contract

Plugins are not just files that happen to load. A faithful rebuild needs three separate layers: user or policy intent, materialized plugin source on disk or in cache, and the live plugin-derived surfaces currently attached to the running session. Collapsing those layers loses refresh safety, hides stale state, and makes plugin failures look more global than they really are.

## Scope boundary

This leaf covers:

- the lifecycle layers a plugin moves through before it becomes live
- the separation between install scope, enablement intent, materialized source, and active runtime contribution
- how refresh rebuilds plugin-derived commands, agents, hooks, MCP servers, LSP config, and settings overlays
- how plugin failures remain visible and isolated instead of poisoning the whole extension system

It intentionally does not re-document:

- source precedence, cache identity, and session-only override details already covered in [plugin-source-precedence-and-cache-loading.md](plugin-source-precedence-and-cache-loading.md)
- hook-specific reload rules already covered in [plugin-hot-reload-and-settings-coupling.md](plugin-hot-reload-and-settings-coupling.md)
- plugin-management UX or marketplace browsing flows already covered in [plugin-management-and-marketplace-flows.md](plugin-management-and-marketplace-flows.md)

## Plugins live in three layers

Equivalent behavior should preserve three distinct lifecycle layers:

1. **Intent layer**
   Layered settings and managed policy say which plugin IDs are enabled, disabled, locked, or expected to exist.
2. **Materialized layer**
   Marketplaces, caches, session-only directories, and built-in bundles determine which plugin payloads are actually available to load right now.
3. **Active layer**
   The running session holds the currently attached plugin-derived commands, agents, hooks, settings overlays, MCP servers, LSP config, and error state.

The important invariant is that these layers do not move together automatically. A plugin can be desired but not materialized, materialized but disabled, or previously active but now stale and waiting on refresh.

## Install scope and enablement are separate

Equivalent behavior should preserve:

- installation scope and enablement intent being different questions, so a plugin can be installed in one scope while enabled or disabled by layered settings in another
- stale enablement intent remaining diagnosable even when the plugin payload is missing or delisted, rather than silently disappearing from management surfaces
- built-in plugins still participating in plugin lifecycle semantics such as enablement, policy gating, and refresh, instead of being treated like immutable core code
- session-only plugin injection joining the same lifecycle after source shaping, while still being allowed to override an installed copy only when managed policy does not lock that plugin name

## Startup and explicit refresh use the same logic at different materialization depth

Equivalent behavior should preserve:

- startup-facing consumers using a cache-only load mode so the first interactive session does not block on network fetches or clones
- explicit install or reload paths using a full materialization mode that may fetch, clone, or repopulate caches before rebuilding live state
- both modes sharing the same discovery, policy, merge, dependency-demotion, and plugin-settings pipeline so they cannot disagree about which plugins are enabled versus disabled
- a fresh full-load result being reusable by downstream cache-only consumers, so explicit refresh does not immediately race itself and rediscover stale plugin state

## Refresh is a coordinated live-state swap

Equivalent behavior should preserve:

- plugin refresh clearing plugin caches, hook caches, orphan filters, and derived plugin settings state before rebuilding the live plugin world
- the full plugin set being reloaded before downstream command, agent, MCP, and LSP consumers re-read their plugin contributions
- explicit refresh replacing active plugin-derived commands, agents, and errors from one coherent snapshot instead of letting each subsystem discover a different plugin world
- plugin-provided MCP contributions being reconnected through an explicit runtime signal rather than hoping existing connections notice plugin changes on their own
- plugin-provided LSP configuration being reinitialized after refresh so removed plugins stop influencing diagnostics and newly enabled ones become visible
- hook reload treating removed and newly enabled plugins as one coordinated swap, not as unrelated cache events

## Background reconciliation does not always imply immediate activation

Equivalent behavior should preserve:

- background marketplace reconciliation being able to track pending, installing, installed, and failed status separately from the active plugin surface
- newly installed plugin sources being allowed to auto-refresh live state when the product needs those capabilities immediately
- update-only or policy-change cases being allowed to mark the runtime as needing refresh instead of silently swapping active behavior in place
- management and notification surfaces making that "source changed but live runtime not yet rebuilt" state explicit

## Partial failure must stay isolated and visible

Equivalent behavior should preserve:

- per-plugin and per-marketplace errors being collected without blocking unrelated plugins from loading
- disabled, blocked, demoted, stale, or failed plugins remaining visible enough that management surfaces can explain why they are absent from the live runtime
- plugin-provided settings disappearing when the contributing plugin is no longer enabled, instead of lingering in merged settings caches after disablement or policy changes
- one broken plugin component, such as hooks or an MCP bundle, not forcing the entire plugin system to collapse into one global failure

## Failure modes

- **intent/live-state collapse**: settings intent is treated as proof that the plugin is already active, hiding stale caches or missing payloads
- **startup blocking or startup blindness**: startup either blocks on every plugin fetch or silently forgets uncached plugins without surfacing recoverable state
- **refresh half-swap**: commands come from one plugin snapshot while hooks, MCP servers, LSP config, or settings overlays still come from another
- **hidden stale intent**: a removed, blocked, or missing plugin vanishes from management surfaces instead of remaining diagnosable
- **global plugin outage**: one failing plugin or marketplace poisons unrelated plugin loading instead of being isolated as one plugin-scoped error

## Test Design

In the observed source, plugin behavior is verified through registry regressions, loading-boundary integration tests, and management-surface end-to-end scenarios.

Equivalent coverage should prove:

- discovery, precedence, dependency resolution, feature gating, and skill exposure preserve the plugin contracts documented here
- hot reload, settings coupling, packaged servers, and cache invalidation behave correctly with resettable registries and on-disk plugin state
- the visible install, list, enablement, and runtime-exposure behavior stays aligned with the public plugin surfaces rather than private helper APIs
