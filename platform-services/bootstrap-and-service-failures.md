---
title: "Bootstrap and Service Failures"
owners: []
soft_links: [/platform-services/auth-config-and-policy.md, /platform-services/usage-analytics-and-migrations.md]
---

# Bootstrap and Service Failures

Platform services should shape capability, not hold the entire product hostage.

## Startup states

1. Early prefetch.
   Optional service reads begin in parallel with heavy imports.
2. Core initialization.
   Essential session state, settings, and runtime invariants are established.
3. Capability hydration.
   Auth, policy, plugin, MCP, and telemetry layers supply the rest of the envelope.
4. Ready with full services.
5. Ready with degraded services.

## Failure handling expectations

- If a non-essential service fails, the runtime should continue with defaults or cached state.
- If auth or policy is missing, affected capabilities should degrade explicitly rather than fail opaquely later.
- If migrations fail, local state should not be left half-updated.
- If analytics or diagnostics fail, user work must continue.

## Failure modes

- **Cold-start stall**: too much startup work is blocking instead of prefetched.
- **Hidden entitlement miss**: a feature seems available until first use, then fails unexpectedly.
- **Migration skew**: persisted settings represent an old shape that only some subsystems understand.
- **Non-essential service becoming critical**: analytics, updates, or diagnostics accidentally gate core interaction.
