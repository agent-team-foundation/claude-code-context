---
title: "Platform Services"
owners: []
soft_links: [/integrations, /tools-and-permissions]
---

# Platform Services

This domain captures the supporting services that make the runtime operable in the real world: auth, settings, policy, usage, telemetry, updates, and migrations.

Relevant leaves:

- **[auth-config-and-policy.md](auth-config-and-policy.md)** — Authentication, layered settings, and policy gating.
- **[auth-login-logout-and-token-lifecycle.md](auth-login-logout-and-token-lifecycle.md)** — How login, account switching, logout, OAuth transport, and auth-sensitive runtime refreshes behave as one coordinated lifecycle.
- **[workspace-trust-dialog-and-persistence.md](workspace-trust-dialog-and-persistence.md)** — How interactive trust review, repo-root persistence, home-directory session trust, and ancestor inheritance decide whether a workspace counts as trusted.
- **[trust-and-capability-hydration.md](trust-and-capability-hydration.md)** — Workspace trust as the gate that unlocks experiments, env vars, approvals, and telemetry.
- **[sync-and-managed-state.md](sync-and-managed-state.md)** — User settings sync, managed settings, and shared memory synchronization.
- **[user-settings-sync-contract.md](user-settings-sync-contract.md)** — The asymmetric upload/download rules, artifact map, cache invalidation, and startup ordering for personal settings sync.
- **[team-memory-sync-and-secret-guardrails.md](team-memory-sync-and-secret-guardrails.md)** — Repo-scoped shared-memory pull/push semantics, watcher behavior, conflict handling, and secret blocking.
- **[policy-and-managed-settings-lifecycle.md](policy-and-managed-settings-lifecycle.md)** — Fetch, cache, polling, and reload behavior for remote settings overlays and policy restrictions.
- **[privacy-level-and-grove-policy-flow.md](privacy-level-and-grove-policy-flow.md)** — Environment-driven privacy levels, Grove eligibility caching, and how startup, `/privacy-settings`, and headless flows enforce consumer privacy-policy choices.
- **[settings-change-detection-and-runtime-reload.md](settings-change-detection-and-runtime-reload.md)** — How file-watch and programmatic settings changes are gated, fanned out, and hot-applied across interactive state, headless state, permissions, env, sandbox, and plugin hooks.
- **[usage-analytics-and-migrations.md](usage-analytics-and-migrations.md)** — Telemetry, quotas, updates, and local evolution over time.
- **[doctor-command-and-health-diagnostics.md](doctor-command-and-health-diagnostics.md)** — How `/doctor`, `claude doctor`, shared install health checks, and persistent diagnostics aggregate warnings across settings, sandboxing, plugins, MCP, and context.
- **[bootstrap-and-service-failures.md](bootstrap-and-service-failures.md)** — Startup sequencing and how non-core service failures should degrade.
- **[interactive-startup-and-project-activation.md](interactive-startup-and-project-activation.md)** — How import-time prewarm, cwd-sensitive setup, trust gating, post-trust activation, and deferred prefetch divide the local startup pipeline.
