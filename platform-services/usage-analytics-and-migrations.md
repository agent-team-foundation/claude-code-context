---
title: "Usage, Analytics, and Migrations"
owners: []
soft_links: [/platform-services/startup-service-sequencing-and-capability-gates.md, /platform-services/bootstrap-and-service-failures.md, /platform-services/claude-ai-limits-and-extra-usage-state.md, /product-surface/interaction-modes.md, /runtime-orchestration/build-profiles.md]
---

# Usage, Analytics, and Migrations

Claude Code includes several non-core support systems that still shape architecture: usage/quota awareness, analytics sinks, startup support caches, release evolution, and local migrations. The timing of startup warmers lives in [startup-service-sequencing-and-capability-gates.md](startup-service-sequencing-and-capability-gates.md); this leaf focuses on what those support systems cache, persist, and migrate.

## Scope boundary

This leaf covers:

- usage- and entitlement-adjacent startup support caches
- analytics and diagnostics initialization ordering
- local migrations and release-evolution behavior

It does not re-document:

- the full Claude.ai limit-state machine already covered in [claude-ai-limits-and-extra-usage-state.md](claude-ai-limits-and-extra-usage-state.md)
- remote managed-settings or policy transport internals
- privacy-level semantics beyond the fact that they suppress some analytics or nonessential traffic

## Usage-adjacent warm bundle

When startup chooses to run support warmers, several reads happen as one bundle rather than being lazily rediscovered one by one during the first turn.

The exact startup phase for this bundle lives elsewhere, but the contents and persistence contract should stay stable.

That bundle should include at least:

- quota/usage preflight for eligible subscriber-style sessions
- bootstrap cache hydration for server-provided client data and additional model options
- pass/referral-style eligibility checks
- fast-mode availability/status warming or a cache-only fallback when live refresh is intentionally skipped

Important invariants:

- this bundle runs only after trust has been established and the runtime has enough auth/config state to use these services safely
- bare/minimal sessions skip the whole bundle because these reads are first-turn responsiveness optimizations, not core startup requirements
- the bundle may be throttled by a persisted last-prefetched timestamp so every launch does not immediately repeat the same background network work

## Bootstrap cache hydration is a specific contract

Equivalent behavior should preserve a narrow bootstrap API/cache behavior rather than a vague "fetch some metadata" flow.

- the fetch is first-party-only and skipped for essential-traffic-only posture, third-party provider sessions, or sessions with no usable first-party auth
- OAuth use requires the profile-capable path, while API-key-style console sessions may still use the endpoint
- the payload hydrates durable cached client/entitlement-style data such as additional model options and client metadata rather than mutating live conversation state directly
- unchanged bootstrap data should not rewrite disk on every startup
- bootstrap-cache failure should stay non-fatal and leave the previous cached view in place

## Analytics and diagnostics initialize early, but not blindly

Equivalent behavior should preserve:

- lightweight logging/analytics sinks attaching early enough to record startup failures that happen after core init
- heavier telemetry initialization waiting until trust-gated environment/config effects are ready
- some telemetry paths deferring further until remote managed settings have loaded, so org-controlled env/config overlays affect telemetry posture before it starts
- privacy or essential-traffic posture being able to suppress outbound analytics work without suppressing the whole product
- telemetry or diagnostics failure remaining non-fatal to the interactive session

## Local migrations evolve persisted behavior

Equivalent behavior should preserve:

- local migrations running before later startup surfaces assume the new settings/default shape
- migrations being idempotent and tolerant of already-upgraded state
- failures avoiding half-applied local state that leaves different subsystems reading different schema generations
- migrations being part of product evolution, alongside background release-note/update flows, rather than one-off install-time scripts

## Failure modes

- **prefetch debt**: quota, bootstrap, or fast-mode state is not warmed, so first-turn UX pays cold network latency or shows stale pending state
- **cache churn**: unchanged bootstrap data rewrites disk every startup and turns a cache warm into persistent I/O noise
- **trust-order inversion**: analytics or usage-prefetch calls start before trust-gated env/config state is ready
- **privacy regression**: telemetry-suppressed or essential-traffic sessions still make nonessential support calls
- **migration skew**: stored settings evolve only partially and later services observe incompatible generations of the same local state
