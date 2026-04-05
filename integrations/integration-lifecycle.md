---
title: "Integration Lifecycle"
owners: []
soft_links: [/integrations/mcp/connection-and-recovery-contract.md, /integrations/plugins/plugin-runtime-contract.md, /integrations/clients/surface-adapter-contract.md]
---

# Integration Lifecycle

Plugins, MCP servers, and client surfaces are built through different mechanisms, but they do not become "live" in one step. Each one moves from some source of record into a runtime contribution through discovery, shaping, admission, activation, degradation, and refresh. A faithful rebuild needs that shared lifecycle vocabulary so management UI, live runtime state, and recovery flows can agree on what exists, what is merely blocked, what is active now, and what has gone stale.

## Scope boundary

This leaf covers:

- the shared lifecycle layers that apply across plugins, MCP integrations, and client surfaces
- the difference between known, admitted, active, degraded, and stale integration state
- how refresh, reconnect, or reload should rebuild live state after source changes
- a cross-integration failure taxonomy that explains where lifecycle broke

It intentionally does not re-document:

- plugin-specific source, cache, and component-loading mechanics already covered in [plugins/plugin-runtime-contract.md](plugins/plugin-runtime-contract.md)
- MCP-specific config, auth, and transport details already covered in [mcp/connection-and-recovery-contract.md](mcp/connection-and-recovery-contract.md) and adjacent MCP leaves
- client-specific bootstrap and attachment details already covered in [clients/surface-adapter-contract.md](clients/surface-adapter-contract.md) and the client subdomain

## The lifecycle is layered, not one flat enum

Equivalent behavior should preserve several distinct questions about every integration:

- **known**: the runtime has discovered a candidate from config, bootstrap, cache, or a bundled source
- **shaped**: raw source has been normalized enough for the runtime to reason about it as one candidate integration
- **admitted**: policy, trust, approval, entitlement, or capability gates allow it to participate
- **active**: it is currently attached to live runtime surfaces and can actually contribute behavior
- **healthy**: its active contribution is functioning rather than merely present
- **fresh**: the current live contribution still matches the latest admitted source or configuration
- **visible**: it can still appear in management or diagnostic surfaces even when not admitted or not active

The important invariant is that these questions do not collapse into one boolean. An integration can be:

- known but withheld by policy or trust
- active but degraded
- configured and admitted but not yet attached
- visible in management surfaces while intentionally disabled
- stale because its source changed even though the old live contribution is still present

## Different integration families traverse the same layers differently

Equivalent behavior should preserve:

- plugins often needing an explicit source-shaping or materialization step before admission because a named plugin may still need its manifest, cache, or contributed components resolved
- MCP integrations often needing config normalization, deduplication, auth preparation, and transport setup before they can become active
- client surfaces often skipping package-style materialization but still requiring bootstrap shaping and attachment before they become a live view or control surface over the shared runtime
- all three families still obeying the same clean-room rule: discovery alone does not imply live contribution

What differs is the mechanism. What must stay consistent is the layered transition from candidate source to active runtime participation.

## Shared transition rules

Equivalent behavior should preserve these cross-integration transitions:

- source or settings changes can mark an integration stale without immediately mutating the live runtime in place
- trust, policy, approval, or capability gates can hold a known integration in a withheld state instead of pretending it does not exist
- activation attaches the integration to shared runtime surfaces:
  - plugins load commands, skills, hooks, agents, or other extension surfaces
  - MCP integrations contribute connected tool, prompt, or resource namespaces
  - client surfaces attach a transport or rendering wrapper around the same runtime semantics
- degradation preserves identity while reducing usefulness, such as auth expiry, transport breakage, validation fallout, or stale live state
- recovery paths clear or rebuild the active layer from the current admitted source instead of trying to patch every subsystem piecemeal
- disable or removal transitions withdraw live contribution while management surfaces may still retain enough state to explain what changed

## Intent, live state, and visibility must stay separate

Equivalent behavior should preserve:

- source-of-record intent not being conflated with what is currently active in memory
- management surfaces being able to show integrations that are known but blocked, disabled, unapproved, or broken
- live runtime inventories being derived from admitted and current active state rather than from every known candidate indiscriminately
- errors and status surfaces telling the user which layer failed:
  - source discovery or parsing
  - shaping or materialization
  - admission
  - activation or handshake
  - active-runtime degradation
  - freshness or reload skew

Without this split, rebuilds either hide useful diagnostics or falsely advertise integrations that are not actually usable.

## Shared recovery contract

Equivalent behavior should preserve:

- one unhealthy integration not poisoning unrelated integrations in the same family
- refresh or reconnect paths being explicit enough that the user or host can tell when live state has been rebuilt
- cached or memoized live state being disposable when source, auth, transport, or policy changes invalidate it
- late attachment or resume paths rebuilding enough lifecycle context that a newly attached surface can tell which integrations are active, degraded, or waiting on recovery
- recovery being allowed to preserve durable intent while clearing transient live state

This is why plugin reloads, MCP reconnects, and client reattachments should be treated as first-class lifecycle steps rather than as hidden implementation details.

## Failure taxonomy

- **discovery failure**: the source of record exists conceptually, but the runtime cannot parse, resolve, or enumerate it into a candidate
- **shaping failure**: a candidate is found, but normalization, materialization, or deduplication cannot produce a valid runtime representation
- **admission failure**: policy, trust, approval, entitlement, or capability gates refuse participation
- **activation failure**: the integration is admitted, but loading, connection, bootstrap, or attachment does not complete
- **runtime degradation**: the integration remains known and may even stay attached, but part of its live behavior is unhealthy
- **freshness skew**: the runtime keeps exposing stale commands, tools, resources, or client capabilities after the admitted source changed
- **recovery failure**: the rebuild or reconnect path itself fails, leaving the runtime between states without a clean active or withheld outcome

## Failure modes

- **state collapse**: known, admitted, and active are treated as one state, so blocked or stale integrations appear usable
- **visibility loss**: disabled or policy-blocked integrations disappear entirely, leaving no management or diagnostic explanation
- **live-skew blindness**: settings or source changes happen, but caches and registries keep serving the old contribution without surfacing staleness
- **cross-integration poisoning**: one broken plugin, MCP server, or client attach path prevents unrelated integrations from loading or remaining visible
- **recovery opacity**: reload, reconnect, or reattach paths run silently, so users and hosts cannot tell whether the live layer still matches current sources
