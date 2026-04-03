---
title: "Platform Services"
owners: []
soft_links: [/integrations, /tools-and-permissions]
---

# Platform Services

This domain captures the supporting services that make the runtime operable in the real world: auth, settings, policy, usage, telemetry, updates, and migrations.

Relevant leaves:

- **[auth-config-and-policy.md](auth-config-and-policy.md)** — Authentication, layered settings, and policy gating.
- **[trust-and-capability-hydration.md](trust-and-capability-hydration.md)** — Workspace trust as the gate that unlocks experiments, env vars, approvals, and telemetry.
- **[sync-and-managed-state.md](sync-and-managed-state.md)** — User settings sync, managed settings, and shared memory synchronization.
- **[policy-and-managed-settings-lifecycle.md](policy-and-managed-settings-lifecycle.md)** — Fetch, cache, polling, and reload behavior for remote settings overlays and policy restrictions.
- **[usage-analytics-and-migrations.md](usage-analytics-and-migrations.md)** — Telemetry, quotas, updates, and local evolution over time.
- **[bootstrap-and-service-failures.md](bootstrap-and-service-failures.md)** — Startup sequencing and how non-core service failures should degrade.
