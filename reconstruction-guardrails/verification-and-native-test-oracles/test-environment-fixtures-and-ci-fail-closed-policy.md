---
title: "Test Environment, Fixtures, and CI Fail-Closed Policy"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-runtime-mode-and-determinism.md
  - /platform-services/startup-service-sequencing-and-capability-gates.md
  - /platform-services/usage-analytics-and-migrations.md
  - /integrations/clients/structured-io-and-headless-session-loop.md
  - /runtime-orchestration/turn-flow/api-request-assembly-retry-and-prompt-cache-stability.md
---

# Test Environment, Fixtures, and CI Fail-Closed Policy

`NODE_ENV=test` is a real runtime posture in the current Claude Code build. It suppresses nonessential side effects, avoids certain expensive or cyclic startup work, and activates deterministic fixture replay for API-dependent tests.

## Test posture is system-wide, not local

The visible contract is that test mode can suppress or simplify behaviors such as:

- telemetry and feedback-like side effects
- exit-time bookkeeping that would otherwise write or emit support data
- selected startup enrichments or background loops whose value is production-only
- environment-sensitive helpers that would otherwise introduce nondeterministic noise

The important point is not one specific branch. It is that the runtime treats tests as a supported operating posture with different side-effect rules.

## Fixture replay is a first-class oracle

The snapshot exposes more than one fixture family for API-adjacent behavior.

Equivalent behavior should preserve:

- a generic fixture helper for deterministic caching of arbitrary expensive or externalized test oracles
- message-replay fixtures for API response and streaming behavior
- token-count fixtures for API-adjacent counting paths that still need deterministic replay semantics

Across those families, the shared contract preserves:

- explicit activation in test posture
- hash-based fixture naming from normalized inputs
- replay from a configurable fixture root
- rehydration back into runtime-shaped results rather than raw text blobs
- replayed results still participating in the same downstream usage, cost, or accounting paths that live responses would drive
- input dehydration and path normalization so equivalent tests keep hitting the same recordings across machines

## CI must fail closed on missing recordings

Equivalent behavior should preserve:

- missing fixtures failing the run in CI by default
- explicit opt-in recording refresh instead of silent fixture regeneration
- a clear distinction between replay mode and record mode

This is one of the most important stability contracts in the visible framework. It keeps network-backed tests deterministic and makes fixture refresh a deliberate maintenance act.

## Recording lifecycle must stay deliberate

Equivalent behavior should preserve:

- replay as the default posture once a fixture exists
- explicit record or refresh intent instead of incidental overwrites
- the ability for different API-adjacent callers to reuse the same fixture policy rather than inventing lane-specific caching rules

The important clean-room point is that recording is maintenance, not a side effect of ordinary CI execution.

## Transcript and hash stability matter

The broader runtime also treats transcript shape as part of fixture stability.

Equivalent behavior should preserve:

- careful normalization before hashing
- dehydration of machine-specific paths, config-home locations, and similar environment-local values
- placeholder treatment for incidental UUIDs, timestamps, counters, and other unstable runtime identifiers
- avoidance of unnecessary transcript-shape churn in replay-sensitive flows
- deterministic identity or placeholder handling where raw runtime IDs would otherwise destabilize recordings
- fresh per-run runtime identity where reused recorded IDs would otherwise cause resume or storage layers to treat distinct replayed responses as duplicates

The visible testing architecture therefore depends on transcript semantics, not only on a file cache.

## Reconstruction rule

If a clean-room rebuild keeps external API-backed tests, it should preserve all of these:

- a dedicated test posture
- multiple fixture families when different API-adjacent callers need different oracle shapes
- deterministic fixture hashing and hydration
- fail-closed CI behavior for missing recordings
- explicit recording refresh

## Failure modes

- **test-production blur**: automated tests still emit nonessential production side effects
- **layer collapse**: token-count or other API-adjacent lanes bypass the shared fixture policy and drift from replay behavior used elsewhere
- **machine-bound fixtures**: path, cwd, or tempdir differences cause needless cache misses
- **silent CI rewrite**: missing fixtures regenerate during CI and hide behavioral drift
- **hash instability**: transcript or input normalization changes break recordings even when behavior did not meaningfully change
- **usage-blind replay**: fixtures reproduce visible output but stop exercising the cost or usage paths that live responses update
- **resume dedupe pollution**: recorded identities are replayed too literally and later resume or storage layers collapse distinct runs into one response
