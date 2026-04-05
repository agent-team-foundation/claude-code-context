---
title: "Bootstrap and Service Failures"
owners: []
soft_links: [/platform-services/startup-service-sequencing-and-capability-gates.md, /platform-services/auth-config-and-policy.md, /platform-services/policy-and-managed-settings-lifecycle.md, /platform-services/user-settings-sync-contract.md, /platform-services/trust-and-capability-hydration.md, /platform-services/usage-analytics-and-migrations.md, /platform-services/interactive-startup-and-project-activation.md]
---

# Bootstrap and Service Failures

Startup sequencing itself lives in [startup-service-sequencing-and-capability-gates.md](startup-service-sequencing-and-capability-gates.md). This leaf focuses on what happens when those services are late, unavailable, or only partially available. A faithful rebuild needs both the fail-open defaults and the narrower cases where Claude Code must deny a capability explicitly instead of bluffing readiness.

## Scope boundary

This leaf covers:

- how remote managed settings, policy limits, sync, telemetry-adjacent warmers, and similar support services degrade
- how late service arrival reconciles live state after startup has already continued
- when capability entry must fail clearly instead of coasting on defaults

It does not re-document:

- the shared startup ladder or mode split between interactive/headless/bare
- the detailed trust boundary itself
- remote managed-settings and policy fetch internals
- the dedicated quota-state model
- general settings hot-reload behavior after a service result lands

## Background enrichment versus explicit gates

Equivalent behavior should preserve:

- non-essential services continuing with defaults or cached state on failure
- cached or stale service data being preferable to a startup stall when the service only improves capability
- privacy/essential-traffic modes skipping some startup calls entirely instead of treating them as failed mandatory work
- bare/minimal sessions suppressing optional warmers and other first-turn optimizations that do not help stripped-down operation
- explicit capability gates remaining user-visible when policy or auth is required for a feature, instead of letting the user enter a path that fails opaquely later
- remediation ordering preferring the most actionable blocker when multiple prerequisites are missing, such as auth before org-policy denial for auth-gated remote features

This means the product should fail open for background enrichment, but fail clearly for gated capability entry.

## Late-arriving services must reconcile live state

Equivalent behavior should preserve:

- successful late managed-settings load or refresh notifying settings listeners so env, telemetry, permissions, plugin state, and other downstream readers can re-evaluate under the new overlay
- late user-settings download or plugin installation in headless mode being able to refresh commands, agents, hooks, and MCP state after startup already continued
- background policy refresh updating the synchronous gate map used by later feature checks instead of requiring restart
- graceful shutdown or early-exit branches preventing deferred activation from continuing once startup has already decided to abort

## Waiter and fallback expectations

Equivalent behavior should preserve:

- capability-specific waits resolving eventually even if the service never started or failed, so headless/test surfaces do not deadlock
- cache-first unblocks remaining distinct from network freshness; the session may proceed using cached/default data and still converge later
- services that shape first-turn convenience rather than core safety remaining skippable in stripped-down modes
- essential-traffic deny-on-miss exceptions remaining narrow rather than turning all background enrichment into hard requirements

## Failure modes

- **cold-start stall**: too much service work blocks startup instead of overlapping or degrading
- **dead waiter**: a headless or test surface awaits managed-settings or policy completion forever because the promise was never created or never resolved
- **false readiness**: a policy- or auth-gated feature looks available until first use, then fails late with no clear startup-time denial
- **sync ordering skew**: plugin or extension activation reads settings before the remote/headless sync join point finishes applying them
- **late-service drift**: managed settings or post-login refreshes arrive, but downstream capability state never reconciles
- **abort-afterglow**: startup has already chosen shutdown, but deferred reconciliation keeps mutating live state afterward
- **non-essential service becoming critical**: telemetry, quota warming, or other support services accidentally gate core interaction
