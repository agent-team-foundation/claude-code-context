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
- **[provider-specific-api-clients-and-auth-routing.md](provider-specific-api-clients-and-auth-routing.md)** — How provider selection, managed-session exceptions, auth-source precedence, and first-party versus Bedrock versus Vertex versus Foundry client construction stay aligned.
- **[provider-model-mapping-and-capability-gates.md](provider-model-mapping-and-capability-gates.md)** — How one canonical model catalog fans out into provider-specific runtime IDs, overrides, validation rules, and provider-aware feature gates.
- **[workspace-trust-dialog-and-persistence.md](workspace-trust-dialog-and-persistence.md)** — How interactive trust review, repo-root persistence, home-directory session trust, and ancestor inheritance decide whether a workspace counts as trusted.
- **[trust-and-capability-hydration.md](trust-and-capability-hydration.md)** — Workspace trust as the gate that unlocks experiments, env vars, approvals, and telemetry.
- **[sync-and-managed-state.md](sync-and-managed-state.md)** — User settings sync, managed settings, and shared memory synchronization.
- **[user-settings-sync-contract.md](user-settings-sync-contract.md)** — The asymmetric upload/download rules, artifact map, cache invalidation, and startup ordering for personal settings sync.
- **[team-memory-sync-and-secret-guardrails.md](team-memory-sync-and-secret-guardrails.md)** — Repo-scoped shared-memory pull/push semantics, watcher behavior, conflict handling, and secret blocking.
- **[policy-and-managed-settings-lifecycle.md](policy-and-managed-settings-lifecycle.md)** — Fetch, cache, polling, and reload behavior for remote settings overlays and policy restrictions.
- **[privacy-level-and-grove-policy-flow.md](privacy-level-and-grove-policy-flow.md)** — Environment-driven privacy levels, Grove eligibility caching, and how startup, `/privacy-settings`, and headless flows enforce consumer privacy-policy choices.
- **[settings-change-detection-and-runtime-reload.md](settings-change-detection-and-runtime-reload.md)** — How file-watch and programmatic settings changes are gated, fanned out, and hot-applied across interactive state, headless state, permissions, env, sandbox, and plugin hooks.
- **[usage-analytics-and-migrations.md](usage-analytics-and-migrations.md)** — Telemetry, quotas, updates, and local evolution over time.
- **[claude-ai-limits-and-extra-usage-state.md](claude-ai-limits-and-extra-usage-state.md)** — The shared Claude.ai quota state machine, warning and recovery surfaces, `/usage`, `/extra-usage`, and the extra-usage couplings that affect fast mode, prompt caching, and 1M model access.
- **[doctor-command-and-health-diagnostics.md](doctor-command-and-health-diagnostics.md)** — How `/doctor`, `claude doctor`, shared install health checks, and persistent diagnostics aggregate warnings across settings, sandboxing, plugins, MCP, and context.
- **[startup-service-sequencing-and-capability-gates.md](startup-service-sequencing-and-capability-gates.md)** — How startup creates governance waiters, launches managed settings/policy/sync work, and keeps interactive, headless, and bare readiness distinct.
- **[bootstrap-and-service-failures.md](bootstrap-and-service-failures.md)** — How late or failed startup services degrade, reconcile, and still preserve explicit capability denials when required.
- **[interactive-startup-and-project-activation.md](interactive-startup-and-project-activation.md)** — How import-time prewarm, cwd-sensitive setup, trust gating, post-trust activation, and deferred prefetch divide the local startup pipeline.
- **[deep-link-protocol-trampoline-and-origin-banner.md](deep-link-protocol-trampoline-and-origin-banner.md)** — How external `claude-cli://open` links are sanitized, resolved into a terminal launch, and marked so startup can show cwd and prompt provenance warnings.
- **[background-housekeeping-and-deferred-maintenance.md](background-housekeeping-and-deferred-maintenance.md)** — How opportunistic services, idle-gated cleanup, recurring maintenance, and process-detached timers are orchestrated after startup.
- **[magic-docs-background-maintenance.md](magic-docs-background-maintenance.md)** — How `# MAGIC DOC` files are discovered, tracked, and rewritten by a constrained background agent that keeps docs current instead of historical.
