---
title: "Plugin Hot Reload and Settings Coupling"
owners: []
soft_links: [/integrations/plugins/plugin-source-precedence-and-cache-loading.md, /integrations/plugins/plugin-runtime-contract.md, /platform-services/settings-change-detection-and-runtime-reload.md, /platform-services/user-settings-sync-contract.md]
---

# Plugin Hot Reload and Settings Coupling

Plugin hooks and plugin-provided settings are part of the live settings system, not an isolated extension sandbox. A correct reconstruction needs the invalidation rules that keep policy changes, marketplace changes, and hook registration in sync.

## Hook registration model

Equivalent behavior should preserve:

- hook registration loading only the currently enabled plugin set
- plugin hook matchers carrying plugin-root and plugin-identity metadata so later pruning can tell which callbacks came from which plugin
- re-registration happening as an atomic clear-then-register swap, so old hooks remain active until the new hook table is ready
- plain hook-cache invalidation not wiping the currently registered hooks on its own

That atomic swap matters because some hook families do not get an automatic second chance later in the session.

## Which settings actually affect plugin state

Equivalent behavior should preserve hot-reload awareness of more than just `enabledPlugins`.

The relevant state includes:

- enabled plugin IDs
- extra known marketplaces
- strict known marketplaces
- blocked marketplaces

The clean-room point is that plugin behavior changes when marketplace trust rules change, even if the user's enabled-plugin list did not.

## Managed-settings-driven reload flow

Equivalent behavior should preserve:

- subscription to settings-change notifications rather than ad hoc polling
- comparison against a stable snapshot of plugin-affecting settings so no-op policy refreshes do not trigger unnecessary reloads
- policy-originated changes clearing plugin discovery caches and hook memoization before reloading hooks
- the hook reload being fire-and-forget rather than blocking the broader settings-refresh path

This is specifically about managed or remotely supplied policy changes. Other plugin refresh flows can still be more explicit and user-driven.

## Removed-versus-added plugin behavior

Equivalent behavior should preserve:

- removed or disabled plugins stopping their hooks immediately after cache clearing
- newly enabled plugin hooks waiting for the explicit reload path that refreshes the whole plugin surface
- parity between hook behavior and the rest of the plugin runtime, so commands, agents, hooks, and plugin-backed integrations do not diverge wildly in when they become active

Without this asymmetry, the runtime either keeps firing stale hooks or surprises users by hot-adding new behavior in only one extension channel.

## Plugin settings as a derived settings layer

Equivalent behavior should preserve:

- enabled plugins contributing a derived settings layer into the ordinary settings cascade
- plugin-cache clearing also resetting settings caches when plugin settings had previously been merged
- reload completion rebuilding that derived layer from the newly enabled set instead of mutating it incrementally in place

This is why plugin reload is also a settings-cache problem, not just a hook-registration problem.

## Sync and startup coupling

Equivalent behavior should preserve:

- cache-only startup consumers seeing only plugins that are already installed or already synchronized locally
- explicit refresh flows being able to warm the full plugin loader before downstream consumers read commands, agents, MCP servers, or hooks
- synced settings or marketplace metadata being treated as extension-boundary changes rather than inert file updates

This coupling is what lets remote or headless sessions pick up the right plugin world after sync and managed-settings refreshes.

## Failure modes

- **hook blackout**: cache invalidation wipes live hooks before replacement hooks are ready
- **stale marketplace policy**: strict-known or blocked-marketplace changes do not invalidate plugin state because only `enabledPlugins` was watched
- **ghost hooks**: disabled plugins keep firing callbacks after they were removed from the enabled set
- **stale settings overlay**: plugin-contributed settings survive in cache after the contributing plugin was removed or blocked
- **reload thrash**: policy refreshes with no actual plugin-affecting change trigger repeated plugin reloads anyway
