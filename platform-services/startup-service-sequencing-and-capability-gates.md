---
title: "Startup Service Sequencing and Capability Gates"
owners: []
soft_links: [/platform-services/interactive-startup-and-project-activation.md, /platform-services/policy-and-managed-settings-lifecycle.md, /platform-services/trust-and-capability-hydration.md, /platform-services/bootstrap-and-service-failures.md, /platform-services/user-settings-sync-contract.md, /platform-services/usage-analytics-and-migrations.md, /integrations/clients/structured-io-and-headless-session-loop.md, /reconstruction-guardrails/verification-and-native-test-oracles/test-environment-fixtures-and-ci-fail-closed-policy.md]
---

# Startup Service Sequencing and Capability Gates

Claude Code does not discover startup readiness by accident. It deliberately separates "start the fetch", "make a waiter available", "trust or auth boundary crossed", and "this capability may now rely on the result". Rebuilding the same services without that sequencing would either stall startup unnecessarily or let features read stale governance state.

## Scope boundary

This leaf covers:

- when managed settings, policy limits, and user-settings sync are allowed to start
- which startup surfaces may await them and at what phase
- how interactive, headless, and bare sessions differ in what they consider "ready"

It intentionally does not re-document:

- the detailed fetch/cache internals of managed settings or policy limits
- the interactive trust-dialog UI itself
- the general headless transport loop beyond the startup joins it depends on

## Shared startup ladder

Equivalent behavior should preserve:

- core init enabling config access, applying only safe environment state, setting up cleanup/network primitives, and creating governance waiters before deeper startup begins
- startup creating eligible waiters for managed settings and policy limits before the actual fetch begins, so SDK/test/headless consumers can join a stable promise even if the normal CLI pre-action path is bypassed
- CLI pre-action launching managed settings and policy fetches non-blocking only after config access is safe, alongside any eligible background settings-sync work
- interactive startup treating onboarding and workspace trust as a hard boundary before full environment application, telemetry, LSP, and other repo-scoped execution surfaces
- post-trust or post-login refreshes being able to rerun governance loads under fresh credentials instead of assuming the first startup result is final
- capability entrypoints waiting only when the capability truly depends on that service, rather than globally blocking first interaction on every remote startup read

## Waiter and cache-first semantics

Equivalent behavior should preserve:

- initial load waiters always resolving eventually, even if the fetch never starts, the session is ineligible, or the network path fails
- cached managed settings being able to unblock waiters immediately while a network refresh continues in the background
- policy and managed-settings waiters remaining separate because their eligibility rules and downstream consequences differ
- remote user-settings download using its own shared startup promise so early fire-and-forget kickoff and later plugin install or refresh paths join the same fetch instead of duplicating it

## Capability-specific join points

Equivalent behavior should preserve:

- Remote Control attach and standalone remote-control entry waiting for policy limits before claiming the feature is available, then denying clearly if org policy disables it
- remote session / teleport entry likewise waiting for policy results before creating or resuming remote work
- telemetry initialization waiting until trusted environment state is applied, and for eligible sessions also allowing managed-settings overlays to land before telemetry becomes authoritative
- headless plugin installation and plugin/MCP refresh joining both managed-settings completion and any remote user-settings download before they treat synced or policy-filtered plugin state as authoritative

## Interactive versus headless versus bare

Equivalent behavior should preserve:

- the interactive REPL being trust-gated: it applies only safe environment state before trust, then performs full environment application, system-context prefetch, approvals, repo mapping, and telemetry afterward
- headless/print sessions not being treated as "minimal" by default: because trust is implicit, they apply the full environment earlier, initialize telemetry before the first turn, kick startup hooks, connect MCPs, and may start deferred prefetches immediately
- bare/minimal sessions being the actual stripped-down branch: they skip optional warmers and many convenience integrations, but still retain core config enablement, auth/policy readiness, and essential session bookkeeping
- rebuilds not collapsing headless and bare into one generic non-interactive path, because headless preserves a rich first-turn environment while bare intentionally trades completeness for minimal overhead

## Failure modes

- **dead waiter**: a capability-specific wait never resolves because the startup path that should have created or resolved the promise was skipped
- **late gate drift**: a capability keeps using pre-refresh policy/settings state after login or trust hydration changed what should be allowed
- **false minimalism**: headless is treated like bare and loses plugin, sync, or telemetry joins that real headless sessions depend on
- **global startup stall**: one optional governance service is awaited universally instead of only at the capability entrypoints that need it
- **cache-first confusion**: cached settings unblock startup, but later network refresh never reconciles the live runtime
