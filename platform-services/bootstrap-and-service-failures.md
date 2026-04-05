---
title: "Bootstrap and Service Failures"
owners: []
soft_links: [/platform-services/auth-config-and-policy.md, /platform-services/policy-and-managed-settings-lifecycle.md, /platform-services/user-settings-sync-contract.md, /platform-services/trust-and-capability-hydration.md, /platform-services/usage-analytics-and-migrations.md, /platform-services/interactive-startup-and-project-activation.md]
---

# Bootstrap and Service Failures

Claude Code starts a large set of supporting services, but it does not treat them all as equally blocking. A faithful rebuild needs the startup staging, waiter semantics, and degrade rules that decide which services may arrive late and which capabilities must wait for them.

## Scope boundary

This leaf covers:

- the staged startup contract for platform services
- early loading promises and waiter behavior
- which downstream features explicitly wait for policy, managed settings, or synced user settings
- fail-open versus explicit-gate behavior when services are unavailable

It does not re-document:

- the detailed trust boundary itself
- remote managed-settings and policy fetch internals
- the dedicated quota-state model
- general settings hot-reload behavior after a service result lands

## Staged startup contract

Equivalent behavior should preserve at least these phases:

1. **Import-time overlap.**
   Lightweight side effects and cache prefetches that can overlap heavy module load begin immediately.
2. **Core initialization.**
   Session identity, settings access, auth helpers, cleanup registries, and service waiters are established.
3. **Non-blocking service launch.**
   Managed settings, policy limits, and similar remote services are started only after config access is safe, but they do not block the whole product by default.
4. **Trust/project activation.**
   Interactive startup decides whether repo-scoped surfaces may proceed and when trust-gated environment or settings effects can become live.
5. **Trust-gated hydration and cache warming.**
   Optional startup prefetches, quota checks, bootstrap cache updates, sync join points, and telemetry initialization happen only after the runtime has enough trust/auth context to use them safely.
6. **Ready, full or degraded.**
   The session becomes usable even if some non-core services never arrived.

The important contract is that startup is layered. Services shape capability, but they should not all hold first interaction hostage.

## Loading promises and waiters must exist before the fetches finish

Equivalent behavior should preserve early waiter creation for remote managed settings and policy limits.

- waiter promises should be initialized as soon as the runtime can determine service eligibility, not only when the fetch actually starts
- those waiters must always resolve eventually, even if the service load never begins, never becomes eligible, or fails
- a timeout-backed resolve is part of the product contract, because headless or test-only surfaces can await these promises without going through the usual interactive startup path
- consumers should wait only when the capability truly depends on the service, not by default for all startup work

## Not every dependency is just a cache warm

Equivalent behavior should preserve several distinct dependency patterns:

- remote managed settings may start non-blocking, but some consumers such as telemetry initialization deliberately wait until those settings have been applied
- policy limits may also start non-blocking, but feature entrypoints such as remote-session or bridge-style commands wait for policy and deny clearly if the relevant capability is disabled
- remote/headless user-settings download starts early for overlap, then later becomes a join point before plugin installation or plugin refresh reads synced settings
- trust- and login-driven rehydration can trigger another round of managed-settings and policy refresh after credentials change mid-startup

The clean-room requirement is that "started in background" and "never awaited by anything" are not the same thing.

## Fail-open is the default, but not the whole story

Equivalent behavior should preserve:

- non-essential services continuing with defaults or cached state on failure
- privacy/essential-traffic modes skipping some startup calls entirely instead of treating them as failed mandatory work
- bare/simple sessions suppressing optional background prefetches and other first-turn optimizations that do not help minimal/headless operation
- cached or stale service data being preferable to a startup stall when the service only improves capability
- explicit capability gates remaining user-visible when policy or auth is required for a feature, instead of letting the user enter a path that fails opaquely later

This means the product should fail open for background enrichment, but fail clearly for gated capability entry.

## Failure modes

- **cold-start stall**: too much service work blocks startup instead of overlapping or degrading
- **dead waiter**: a headless or test surface awaits managed-settings or policy completion forever because the promise was never created or never resolved
- **hidden gate miss**: a policy- or auth-gated feature looks available until first use, then fails late with no clear startup-time denial
- **sync ordering skew**: plugin or extension activation reads settings before the remote/headless sync join point finishes applying them
- **late-service drift**: managed settings or post-login refreshes arrive, but downstream capability state never reconciles
- **non-essential service becoming critical**: telemetry, quota warming, or other support services accidentally gate core interaction
