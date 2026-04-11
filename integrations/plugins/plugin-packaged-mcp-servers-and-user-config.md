---
title: "Plugin-Packaged MCP Servers and User Config"
owners: []
soft_links: [/integrations/plugins/plugin-runtime-contract.md, /integrations/mcp/config-layering-policy-and-dedup.md, /integrations/mcp/channel-servers-and-permission-relay.md, /platform-services/settings-change-detection-and-runtime-reload.md]
---

# Plugin-Packaged MCP Servers and User Config

Plugins can ship MCP server definitions plus user-configurable fields. Equivalent behavior requires consistent loading order, secure config storage, and safe runtime expansion.

## Packaged MCP server source model

A plugin can contribute MCP servers from multiple source forms:

- default plugin-local MCP config file
- manifest-declared MCP entries (inline records or references)
- packaged MCP bundle artifacts that unpack into runtime server configs

Within one plugin, later manifest entries should override earlier ones deterministically.

## Deferred activation for unconfigured bundles

Packaged MCP bundles may require user config before activation.

Equivalent behavior should preserve:

- detecting required-but-missing config
- treating missing config as "not yet loadable", not a hard plugin failure
- surfacing enough metadata for plugin-management UI to prompt configuration

## Channel-specific and top-level user config merge

Plugins can define both:

- top-level plugin user options
- per-channel/per-server options

Per-server options should override top-level values on key conflict when building server runtime config.

## Variable expansion order and error surfacing

Runtime value substitution should preserve a strict order:

1. plugin-scoped variables
2. user-config variables
3. environment variables

Missing variables should produce per-server load errors without aborting other plugin servers.

## Sensitive config storage split

User configuration storage should preserve split persistence:

- sensitive fields in secure storage
- non-sensitive fields in settings storage

Equivalent behavior should also scrub stale copies when field sensitivity changes, so old plaintext secrets do not linger.

## Scoping and dedup with manual MCP config

Plugin MCP servers should be namespaced and marked as dynamic scope. They still need content-based dedup against manually configured servers and against earlier plugin servers that target the same underlying command or URL.

Key invariant: enabled manual config wins over plugin-config duplicates; disabled manual entries should not suppress active plugin servers.

## Failure modes

- **activation stall**: servers needing user config are treated as fatal plugin load errors
- **secret leakage**: sensitive per-server values remain in plaintext settings
- **partial-load crash**: one malformed server config aborts all plugin MCP server loading
- **dedup miss**: same endpoint appears as both manual and plugin server, duplicating tools
- **dedup overreach**: disabled manual server suppresses the only runnable plugin equivalent

## Test Design

In the observed source, plugin behavior is verified through registry regressions, loading-boundary integration tests, and management-surface end-to-end scenarios.

Equivalent coverage should prove:

- discovery, precedence, dependency resolution, feature gating, and skill exposure preserve the plugin contracts documented here
- hot reload, settings coupling, packaged servers, and cache invalidation behave correctly with resettable registries and on-disk plugin state
- the visible install, list, enablement, and runtime-exposure behavior stays aligned with the public plugin surfaces rather than private helper APIs
