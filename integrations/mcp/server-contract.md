---
title: "Server Contract"
owners: []
soft_links: [/integrations/mcp/config-layering-policy-and-dedup.md, /integrations/mcp/connection-and-recovery-contract.md, /integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md, /integrations/mcp/elicitation-request-and-completion-lifecycle.md, /integrations/mcp/oauth-step-up-and-client-registration.md]
---

# Server Contract

MCP support should not be modeled as a thin network client or a one-shot "remote tools" feature. Claude Code treats MCP servers as first-class runtime extensions whose lifecycle spans configuration authority, policy admission, auth and transport setup, live surface assembly, interactive follow-up flows, and recovery. A faithful rebuild needs that full contract or MCP will either expose dead or stale capabilities, bypass trust gates, or feel disconnected from the rest of the runtime.

## Scope boundary

This leaf covers:

- the umbrella contract from configured server candidate to live MCP contribution
- the relationship between server config, live client connection, and exposed session-state surface
- the shared safety and UX requirements that make MCP feel native instead of bolted on
- the high-level failure classes that subordinate MCP leaves refine further

It intentionally does not re-document:

- detailed source precedence, enterprise exclusivity, plugin-only mode, and dedup rules already covered in [config-layering-policy-and-dedup.md](config-layering-policy-and-dedup.md)
- transport classes, connection health, and reconnect semantics already covered in [connection-and-recovery-contract.md](connection-and-recovery-contract.md)
- per-server surface replacement, `list_changed` refresh, and MCP skill/resource state assembly already covered in [mcp-surface-state-assembly-and-live-refresh.md](mcp-surface-state-assembly-and-live-refresh.md)
- OAuth, step-up authorization, and client-registration behavior already covered in [oauth-step-up-and-client-registration.md](oauth-step-up-and-client-registration.md)
- elicitation request, queueing, and completion signaling already covered in [elicitation-request-and-completion-lifecycle.md](elicitation-request-and-completion-lifecycle.md)

## MCP has three distinct layers

Equivalent behavior should preserve three related but separate MCP layers:

- **configured server candidates**: records discovered from config, plugins, hosted catalogs, or other allowed sources
- **live client connections**: per-server transport and auth state such as disabled, pending, connected, failed, or needs-auth
- **derived session surfaces**: the tools, prompts, skills, commands, resources, and recovery affordances currently exposed from those live clients

The important invariant is that these layers do not collapse into one object or one state machine. A server can be known but blocked, connected but not yet surfaced, or still visible in management UI while its live contribution has been withdrawn.

## Admission happens before connection

Equivalent behavior should preserve:

- layered config discovery and normalization happening before any transport is opened
- policy, trust, project approval, or capability gates being able to withhold a server without pretending it never existed
- deduplication by underlying connection intent rather than by display name alone, so one logical connector does not surface multiple times
- disabled, blocked, or needs-auth servers remaining available to management and diagnostic flows even when they are not eligible for ordinary runtime use
- server admission agreeing with the broader permission and policy model rather than inventing a separate MCP-only exception path

This is why MCP server setup belongs in the same authority model as plugins and permissions, not in a hidden networking subsystem.

## Activation is more than opening a socket

Equivalent behavior should preserve:

- transport establishment being only one part of activation
- authentication being able to require per-server OAuth, step-up scope escalation, or alternate identity-provider paths depending on server configuration
- capability negotiation deciding whether follow-up features such as resources, prompts, skills, channels, or elicitation should even register
- auth-recovery or needs-auth states being able to surface a recovery affordance instead of ordinary MCP tools
- session expiry, connection breakage, or capability loss degrading one server without poisoning unrelated MCP servers

The clean-room requirement is that "connected" is not enough. A server becomes truly active only after auth, capability shaping, and surface assembly succeed.

## Live MCP contribution is a server-scoped session surface

Equivalent behavior should preserve:

- one connected server contributing a scoped slice of MCP state rather than blindly appending global tools forever
- that slice being able to include:
  - tools
  - prompt-style commands
  - MCP skills that stay distinct from plain prompts
  - resources
  - auth-recovery or other server-specific helper affordances
- per-server refresh replacing that server's own slice when prompts, resources, or tools change
- stale plugin-backed or reconfigured servers having their old contribution removed before a fresh connection is reintroduced
- the broader runtime later merging MCP surfaces with local command and tool registries instead of treating MCP as a disconnected side panel

This is what makes MCP feel like a native extension surface rather than an external plugin console.

## MCP-specific interactions must fit the core UX and safety model

Equivalent behavior should preserve:

- MCP tools participating in the same permission, progress, and result-handling expectations as built-in tools
- oversized or complex MCP outputs being normalized, truncated, or persisted through the same result-handling discipline as other tool families
- user-facing auth, elicitation, and recovery flows surfacing through the same approval and interaction model as the rest of the product
- headless or SDK-driven sessions bridging those same flows through structured control requests instead of inventing a separate MCP-only business path
- core runtime precedence rules still applying when local and MCP surfaces collide by name or capability

The product contract is that MCP extends Claude Code, not that it escapes Claude Code's safety and UX rules.

## Shared failure classes

- **config valid but withheld**: the server is known, but approval, policy, trust, or entitlement rules prevent activation
- **auth incomplete**: the server exists and may even be reachable, but consent, reauth, or step-up is still required
- **transport degraded**: the server was active but its session expired, connection dropped, or transport health failed
- **surface assembly failure**: connection succeeded, but tools, prompts, skills, or resources could not be enumerated or refreshed correctly
- **interaction failure**: auth callbacks, elicitation requests, or other interactive follow-up flows fail even though the server itself remains known
- **surface skew**: stale tools, prompts, skills, or resources remain exposed after config, plugin, or live-server state changed

## Failure modes

- **network-client flattening**: MCP is treated as a simple socket client and loses config authority, policy, auth, and live-surface semantics
- **admission bypass**: servers connect or surface tools before project approval, plugin-only gates, or managed policy have been applied
- **connected-but-dead UX**: a server counts as active as soon as transport opens, even though auth or surface enumeration never completed
- **append-only surfacing**: reconnects and `list_changed` refreshes keep stacking stale tools, prompts, or resources instead of replacing one server's slice
- **interaction exile**: OAuth, elicitation, or needs-auth recovery flows live outside the normal permission and user-interaction model

## Test Design

In the observed source, MCP behavior is verified through contract regressions, seeded or fixture-backed integration flows, and connection-realistic end-to-end scenarios.

Equivalent coverage should prove:

- config layering, server lifecycle, permission relay, and resource projection preserve the contracts described in this leaf
- auth, OAuth step-up, federated identity, and recovery branches can be exercised deterministically without depending on unstable live infrastructure
- users still see the expected MCP connection, gating, refresh, and failure behavior through the real runtime surfaces
