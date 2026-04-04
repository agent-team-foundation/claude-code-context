---
title: "Plugin Source Precedence and Cache Loading"
owners: []
soft_links: [/integrations/plugins/plugin-runtime-contract.md, /integrations/plugins/plugin-hot-reload-and-settings-coupling.md, /platform-services/user-settings-sync-contract.md, /platform-services/auth-config-and-policy.md]
---

# Plugin Source Precedence and Cache Loading

Claude Code does not discover plugins by scanning one folder. The effective plugin set is assembled from layered settings, session-only injections, built-in plugins, and managed policy, then materialized through either a cache-only startup path or a freshness-seeking full load path.

## Discovery inputs and precedence

Equivalent behavior should preserve these source lanes:

- layered `enabledPlugins` settings as the main declaration of marketplace-backed plugin intent
- additional-directory plugin settings contributing at the lowest priority so normal user, project, local, flag, or policy settings can override them
- session-only plugin directories supplied by CLI or SDK state, loaded outside the marketplace catalog path and treated as enabled only for the current process
- built-in shipped plugins loaded separately from marketplace entries instead of competing inside the same settings map

The important clean-room point is that "which plugins exist" and "which plugins are enabled for this session" are not the same question.

## Managed policy and source admission

Equivalent behavior should preserve:

- marketplace-source allowlists and blocklists being enforced before a plugin is materialized
- fail-closed behavior when enterprise marketplace policy is active but the runtime cannot verify a marketplace's underlying source
- managed `enabledPlugins` entries locking the plugin name whether the admin forced it on or forced it off
- session-only plugin copies being rejected when they collide with a managed plugin name, even though unmanaged session plugins can override installed copies
- per-plugin errors being collected without preventing unrelated plugins from loading

This matters because plugin policy applies at both the marketplace-source layer and the individual-plugin layer.

## Two load modes with one discovery pipeline

Equivalent behavior should preserve:

- one shared discovery, policy, merge, dependency, and plugin-settings pipeline for both load modes
- a cache-only mode for startup consumers that avoids network fetches and clones
- a full loader for explicit refresh or install flows that is allowed to fetch, clone, and populate caches
- an environment-controlled escape hatch that lets startup deliberately use the full loader when fresh plugin installation must complete before the first meaningful turn

The clean-room requirement is not the exact function split. It is that startup and explicit refresh share the same logical decisions while differing only in how aggressively they materialize source.

## Cache and materialization contract

Equivalent behavior should preserve:

- local marketplace-relative plugins being loadable directly from source for cache-only startup, while full refresh can copy them into a versioned cache
- external plugin sources using versioned cache directories or zip caches instead of one mutable install path
- seed caches being probeable before a network fetch so pre-baked environments can boot without recloning every external plugin
- cache misses degrading into explicit plugin errors rather than implicit silent disappearance
- zip-cached plugins being extracted into a session-scoped temp area before runtime loading, even during cache-only startup

Without this split, startup becomes too slow or ref-tracked plugins become permanently stale.

## Manifest and component synthesis

Equivalent behavior should preserve:

- manifest-bearing plugins being supplemented by marketplace metadata when that metadata is compatible
- manifest-less plugins being loadable directly from marketplace catalog entries so commands, agents, skills, hooks, or output styles can still materialize
- explicit rejection when marketplace component declarations conflict with an embedded manifest in ways that would make ownership ambiguous

The key behavior is that marketplace metadata is not just install-time packaging. It can participate in runtime component discovery.

## Merge and post-load semantics

Equivalent behavior should preserve:

- session-only plugins overriding installed plugins of the same name for the current session unless managed policy locked that name
- downstream consumer order seeing session plugins first, then non-overridden marketplace plugins, then built-in plugins
- dependency validation being able to demote a loaded plugin without rewriting user settings
- plugin-contributed settings being merged only from enabled plugins, with later plugins overriding earlier keys

That final setting merge is part of the extension contract because plugin loading changes later settings reads.

## Failure modes

- **policy fail-open**: enterprise marketplace policy is active, source verification fails, and the plugin still loads
- **session override bypass**: `--plugin-dir` cannot replace an installed plugin even when no managed lock exists
- **managed-lock bypass**: a session-only plugin overrides an admin-locked installed plugin
- **startup cache blindness**: cache-only startup silently drops uncached plugins without surfacing a miss
- **version drift**: ref-tracked external plugins reclone forever or never refresh because cache identity is unstable
- **manifest ambiguity**: embedded manifest data and marketplace component declarations both partially win, producing a plugin with inconsistent commands, hooks, or skills
