---
title: "Integration Lifecycle"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /integrations/plugins/plugin-and-skill-model.md, /integrations/clients/client-surfaces.md]
---

# Integration Lifecycle

Integrations in Claude Code follow a common lifecycle even when the underlying mechanisms differ.

## Shared states

1. Discoverable.
   The runtime can see a config, plugin, skill, or client endpoint.
2. Admitted.
   Policy and trust checks allow the integration to participate.
3. Connected or loaded.
   The integration is active and contributes commands, tools, resources, or UI.
4. Degraded.
   The integration remains known, but some capability is unavailable due to auth, transport, or validation issues.
5. Disabled.
   The integration is intentionally present but not active.
6. Evicted.
   The runtime clears or reloads the integration because state is stale.

## Failure taxonomy

- **Discovery failure**: configuration exists but cannot be parsed or resolved.
- **Admission failure**: policy, trust, or entitlement blocks the integration.
- **Handshake failure**: transport, auth, or initialization does not complete.
- **Runtime degradation**: the integration stays loaded but some commands or tools become unavailable.
- **Cache mismatch**: the runtime keeps stale commands, skills, or resources after the integration changed.
