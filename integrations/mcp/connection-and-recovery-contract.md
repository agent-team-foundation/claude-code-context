---
title: "Connection and Recovery Contract"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /platform-services/auth-config-and-policy.md, /tools-and-permissions/tool-catalog/tool-families.md]
---

# Connection and Recovery Contract

MCP integration must support multiple transport styles and still present a single coherent runtime abstraction.

## Required transport classes

- local process transports
- long-lived HTTP or SSE style transports
- streamable HTTP style transports
- WebSocket style transports
- session-ingress aware or control-channel aware variants where the surrounding runtime needs them

## Lifecycle

1. Config discovered and normalized.
2. Policy and trust admitted.
3. Auth and headers prepared.
4. Transport connected.
5. Tools, resources, and prompts enumerated.
6. Active use.
7. Session expired, auth needed, or transport degraded.
8. Connection cache cleared and recovered.

## Runtime boundaries

- built-in tools should retain precedence when names collide with extension tools
- deny rules must be able to hide an entire server namespace
- oversized descriptions or outputs should be truncated or persisted rather than blindly forwarded
- auth or elicitation flows must surface through the same user-facing control model as built-in capabilities
- insufficient-scope auth should be able to force an explicit higher-scope reauthorization instead of looping forever through ordinary refresh

## Failure classes

- **config valid but unusable**: a server is syntactically present yet impossible to connect to
- **auth stale**: the server remains known but shifts into a needs-auth posture
- **session expired**: the runtime must discard cached connection state and reconnect
- **transport-specific degradation**: one server is unhealthy without poisoning the rest of the tool pool

## Test Design

In the observed source, MCP behavior is verified through contract regressions, seeded or fixture-backed integration flows, and connection-realistic end-to-end scenarios.

Equivalent coverage should prove:

- config layering, server lifecycle, permission relay, and resource projection preserve the contracts described in this leaf
- auth, OAuth step-up, federated identity, and recovery branches can be exercised deterministically without depending on unstable live infrastructure
- users still see the expected MCP connection, gating, refresh, and failure behavior through the real runtime surfaces
