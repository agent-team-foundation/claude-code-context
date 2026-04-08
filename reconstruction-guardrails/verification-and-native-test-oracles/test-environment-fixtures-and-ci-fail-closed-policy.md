---
title: "Test Environment, Fixtures, and CI Fail-Closed Policy"
owners: [bingran-you]
soft_links:
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

The snapshot exposes a VCR-style replay layer for API-dependent behavior.

That layer preserves:

- explicit activation in test posture
- hash-based fixture naming from normalized inputs
- replay from a configurable fixture root
- rehydration back into runtime-shaped results rather than raw text blobs
- input dehydration and path normalization so equivalent tests keep hitting the same recordings across machines

## CI must fail closed on missing recordings

Equivalent behavior should preserve:

- missing fixtures failing the run in CI by default
- explicit opt-in recording refresh instead of silent fixture regeneration
- a clear distinction between replay mode and record mode

This is one of the most important stability contracts in the visible framework. It keeps network-backed tests deterministic and makes fixture refresh a deliberate maintenance act.

## Transcript and hash stability matter

The broader runtime also treats transcript shape as part of fixture stability.

Equivalent behavior should preserve:

- careful normalization before hashing
- avoidance of unnecessary transcript-shape churn in replay-sensitive flows
- deterministic identity or placeholder handling where raw runtime IDs would otherwise destabilize recordings

The visible testing architecture therefore depends on transcript semantics, not only on a file cache.

## Reconstruction rule

If a clean-room rebuild keeps external API-backed tests, it should preserve all of these:

- a dedicated test posture
- deterministic fixture hashing and hydration
- fail-closed CI behavior for missing recordings
- explicit recording refresh

## Failure modes

- **test-production blur**: automated tests still emit nonessential production side effects
- **machine-bound fixtures**: path, cwd, or tempdir differences cause needless cache misses
- **silent CI rewrite**: missing fixtures regenerate during CI and hide behavioral drift
- **hash instability**: transcript or input normalization changes break recordings even when behavior did not meaningfully change
