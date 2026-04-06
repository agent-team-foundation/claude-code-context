---
title: "Config Layering, Policy, and Dedup"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /integrations/mcp/connection-and-recovery-contract.md, /integrations/plugins/plugin-runtime-contract.md, /platform-services/auth-config-and-policy.md, /tools-and-permissions/permissions/permission-model.md]
---

# Config Layering, Policy, and Dedup

Claude Code does not treat MCP as "read one config file and connect." The effective MCP server set is assembled from several source families, filtered by policy, gated by trust, and deduplicated against plugin-provided or hosted connectors before the runtime ever opens a transport.

## Source families and precedence

Equivalent behavior should preserve these distinct configuration families:

- enterprise-managed MCP configuration with its own dedicated file and authority boundary
- user-scoped MCP configuration
- checked-in project-scoped MCP configuration
- local private project MCP configuration
- session-scoped dynamic MCP configuration provided by CLI flags, SDK calls, or other runtime control surfaces
- plugin-provided MCP servers that are materialized from enabled plugins rather than handwritten config
- hosted connector catalogs that can be fetched from a first-party surface and merged in later

The clean-room requirement is not the literal file names. It is that these sources do not all have the same trust, mutability, or precedence.

## Exclusive and plugin-only modes

Two higher-level gates reshape the source graph:

- if an enterprise MCP config exists, it has exclusive control and other handwritten or hosted sources should be suppressed
- if managed policy locks MCP to plugin-only use, user, project, and local handwritten servers disappear while plugin-provided servers remain eligible

Those two modes are different. Enterprise exclusivity removes everything except the enterprise authority. Plugin-only mode still allows the extension system to supply MCP servers.

## Approval and visibility boundary

Not every configured server is immediately runnable.

Equivalent behavior should preserve:

- project-scoped servers requiring explicit approval before they are considered active connection targets
- disabled or policy-blocked servers remaining visible to administration surfaces even when they will not actually connect
- name-based lookup respecting the same gating model as bulk startup assembly, so an admin view cannot reach a server that the live runtime would otherwise suppress

This matters because the management UI and the transport layer should agree on which servers are merely configured and which are actually eligible to run.

## Policy matching model

MCP policy is more expressive than a simple server-name allowlist.

Equivalent behavior should preserve:

- name-based allow and deny rules
- command-signature matching for stdio servers
- URL-pattern matching for remote servers
- deny rules taking absolute precedence over allow rules
- the ability for managed policy to make the allowlist come only from managed sources while still allowing users to apply personal denylists

One special case is important: SDK-managed placeholder servers should be exempt from the local command or URL launch policy because the CLI is not spawning or dialing them directly.

## Dedup by underlying connection, not just by display name

The effective server set must be deduplicated across source families using the server's real launch signature.

Equivalent behavior should preserve:

- deduplication by canonical stdio command vector for process-backed servers
- deduplication by canonical URL for remote servers
- unwrapping of proxy-wrapped remote URLs when a transport layer rewrites a connector URL but still points at the same underlying vendor endpoint
- manual or handwritten servers winning over plugin-provided or hosted-connector equivalents
- disabled handwritten servers not suppressing enabled equivalents, because a disabled entry should not leave the runtime with no usable server
- first-loaded plugin server winning when multiple enabled plugins materialize the same underlying MCP endpoint

Without content-based dedup, the runtime wastes context budget and may surface the same integration twice under different names.

## Parse, expansion, and persistence contract

Equivalent behavior should preserve:

- JSON-schema validation with error collection instead of all-or-nothing rejection
- environment-variable expansion for commands, arguments, URLs, and headers, with missing-variable reporting
- atomic project-config rewrites that preserve existing file permissions when updating the checked-in config file
- explicit scope tagging on parsed server records so later management flows know where an entry came from

The important clean-room point is that config parsing yields both surviving server records and structured validation errors.

## Failure modes

- **authority confusion**: enterprise-exclusive mode still leaks user or project servers into the live pool
- **policy shadowing**: name-only policy logic misses blocked command or URL signatures
- **approval bypass**: project servers connect before the user accepts them
- **duplicate surface**: manual, plugin, and hosted connectors all surface the same underlying integration
- **dead-server suppression**: a disabled handwritten entry suppresses the only enabled equivalent server
- **unsafe rewrite**: config edits clobber permissions or partially rewrite the project config file
