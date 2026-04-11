---
title: "Privacy Level Resolution"
owners: []
soft_links: [/platform-services/consumer-privacy-policy-flow.md, /platform-services/usage-analytics-and-migrations.md, /platform-services/policy-and-managed-settings-lifecycle.md]
---

# Privacy Level Resolution

Claude Code resolves privacy posture before most network-backed product conveniences decide whether they are allowed to run. This is a process-level gate, not a normal settings overlay.

## Scope boundary

This leaf covers:

- environment-driven privacy-level resolution
- the distinction between telemetry suppression and wider nonessential-traffic suppression
- how other subsystems should consume that resolved posture

It intentionally does not re-document:

- the downstream consumer-policy dialog flow, which lives in [consumer-privacy-policy-flow.md](consumer-privacy-policy-flow.md)
- generic telemetry sink details already covered in [usage-analytics-and-migrations.md](usage-analytics-and-migrations.md)

## Resolution contract

Equivalent behavior should preserve:

- three ordered levels: `default`, `no-telemetry`, and `essential-traffic`
- `essential-traffic` winning over `no-telemetry` when both environment signals are present
- one environment variable mapping to "disable nonessential traffic" and another mapping to "disable telemetry only," with the broader traffic mode taking precedence
- no file-backed or remotely managed setting overriding this resolver; it is an env-first process contract
- helper predicates splitting the result into two stable questions: whether telemetry is disabled, and whether all nonessential traffic is disabled
- user-facing diagnostics being able to explain which env source forced the broader traffic-suppression mode

## Global enforcement surface

Equivalent behavior should preserve:

- `no-telemetry` disabling analytics and lightweight feedback telemetry while leaving the rest of the product largely intact
- `essential-traffic` additionally suppressing optional network-backed helpers such as startup cache-warms, release notes, model-capability refreshes, consumer-policy checks, and similar nonessential API calls
- some product surfaces layering extra suppression on top of privacy level, rather than overloading the resolver with every special case
- compliance-sensitive checks being able to fail closed for a small allowlist of policies when `essential-traffic` is active and no cache exists, while the broader product still mostly fails open
- command visibility and runtime behavior consulting the same effective privacy posture so hidden-command state and execution stay aligned

## Failure modes

- **mode collapse**: telemetry-only suppression is incorrectly treated as full nonessential-traffic suppression
- **under-enforcement**: essential-traffic mode still allows optional network calls that should have been skipped
- **settings override leak**: file-backed or remotely managed settings silently override process-level privacy posture
- **diagnostic mismatch**: the UI says a feature is unavailable for one reason while the runtime suppressed it for another

## Test Design

In the observed source, platform-service behavior is verified through sequencing-sensitive integration tests, deterministic state regressions, and CLI-visible service flows.

Equivalent coverage should prove:

- config resolution, policy gates, persistence, and service startup ordering preserve the contracts and failure handling described above
- provider-backed or OS-bound branches use fixtures, seeded stores, or narrow seams so auth, update, telemetry, and trust behavior stays reproducible
- users still encounter the expected startup, settings, trust, diagnostics, and account-state behavior through the real CLI surface
