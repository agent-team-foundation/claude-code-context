---
title: "Settings Schema Compatibility and Invalid-Field Preservation"
owners: [bingran-you]
soft_links:
  - /platform-services/auth-config-and-policy.md
  - /platform-services/settings-change-detection-and-runtime-reload.md
  - /platform-services/doctor-command-and-health-diagnostics.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-framework-overview.md
---

# Settings Schema Compatibility and Invalid-Field Preservation

Settings evolution in Claude Code is guarded as a stable product contract, not as an incidental implementation detail. The visible snapshot treats backward compatibility tests as the oracle for safe schema changes and preserves invalid or unknown content rather than rewriting user files into a narrower shape.

## Compatibility contract

Equivalent behavior should preserve:

- additive evolution as the default posture for public settings
- a dedicated compatibility lane guarding settings-file changes
- rejection of breaking schema changes as a product-level regression, not only as a typing concern

The important design point is that settings compatibility is not left to convention alone. It is explicitly treated as something tests must defend.

## Invalid and unknown field preservation

Equivalent behavior should preserve:

- unknown or invalid settings surviving on disk even when they are not currently usable
- selective filtering of bad sub-rules where the system can safely preserve the rest of the file
- type coercion or passthrough behavior where that protects durable compatibility instead of silently narrowing the accepted shape
- user-facing repair surfaces being able to report problems without having already destroyed the offending data

This means the system prefers "ignore and report" over "drop and rewrite" for many invalid settings scenarios.

## Why this belongs in platform services

This is not just a test note. It shapes:

- configuration loading behavior
- validation reporting
- hot reload semantics
- migration safety
- doctor and diagnostics surfaces

The test lane is the oracle, but the contract itself is a platform behavior.

## Failure modes

- **breaking-tightening regression**: a schema change makes existing user files invalid without an intentional migration path
- **destructive cleanup**: invalid or unknown fields are removed from disk and users lose the information needed to repair them
- **all-or-nothing rejection**: one malformed rule causes the whole settings file to become unusable when narrower preservation was possible
- **testless drift**: schema evolution continues without compatibility tests defending the user-facing contract

## Test Design

In the observed source, platform-service behavior is verified through sequencing-sensitive integration tests, deterministic state regressions, and CLI-visible service flows.

Equivalent coverage should prove:

- config resolution, policy gates, persistence, and service startup ordering preserve the contracts and failure handling described above
- provider-backed or OS-bound branches use fixtures, seeded stores, or narrow seams so auth, update, telemetry, and trust behavior stays reproducible
- users still encounter the expected startup, settings, trust, diagnostics, and account-state behavior through the real CLI surface
