---
title: "Mock Rate Limit Scenarios and Test Contracts"
owners: [bingran-you]
soft_links: [/platform-services/claude-ai-limits-and-extra-usage-state.md, /reconstruction-guardrails/verification-and-native-test-oracles/native-test-derived-asset-provenance-and-acceptance-rules.md, /reconstruction-guardrails/verification-and-native-test-oracles/test-lane-coverage-map.md]
native_source: services/mockRateLimits.ts
verification_status: native_test_derived
---

# Mock Rate Limit Scenarios and Test Contracts

This leaf captures the internal mock surface used to verify Claude Code's rate-limit behavior without exhausting real quotas. The important clean-room value is not the exact helper API. It is the set of user-visible limit branches the upstream product considered important enough to simulate deterministically.

## Scope boundary

This leaf covers:

- the scenario families that need deterministic simulation
- the live-header semantics those scenarios must mimic
- the reset and round-trip behavior needed for reliable verification

It intentionally does not cover:

- live quota enforcement or server policy
- the user-facing quota state machine already captured in [claude-ai-limits-and-extra-usage-state.md](claude-ai-limits-and-extra-usage-state.md)

## Internal-only scenario surface

Equivalent behavior should preserve an internal-only scenario surface rather than a public user feature.

That surface should stay able to simulate at least these families:

- a nominal allowed state
- early-warning states before hard rejection
- hard subscription-limit rejection
- overage available, warning, and exhausted branches
- exhausted-credit or disabled-credit branches for wallet, org, member, or seat-level causes
- model-specific limit branches where one model family can be blocked independently of another
- fast-mode cooldown or similar short-horizon retry behavior
- an explicit clear or reset state that removes injected mock behavior

If a rebuild collapses those into one generic "rate limited" mock, it loses the nuance the upstream product was testing.

## Header-shape fidelity matters

Equivalent behavior should preserve:

- the mock surface driving the same downstream parsing and messaging branches as live quota responses
- status families that distinguish ordinary allowance, warning, rejection, and overage state
- representative claim and reset-time semantics that keep user messaging aligned with the active scenario
- disabled-reason variants that let downstream logic distinguish empty wallet, org cap, member cap, seat cap, and similar causes
- early-warning utilization signals that can be simulated separately from hard rejection

The exact helper names are implementation detail. What matters in the tree is that the mock data be shaped closely enough that downstream logic cannot tell whether it came from a live response or a controlled verification scenario.

## Scenario round-trip and reset behavior

Equivalent behavior should preserve:

- deterministic selection of each major user-visible quota branch
- the ability to clear injected state cleanly between cases
- stable scenario-to-visible-branch mapping, so acceptance tests can state which quota path they are exercising without depending on live quotas
- reset semantics that keep retry timing and representative-claim behavior coherent rather than leaving stale mock residue behind

## Reconstruction rule

A clean-room rebuild should preserve:

- internal-only admission for mock quota simulation
- coverage across the major quota and overage branches users actually experience
- mock data shaped like live quota inputs rather than bespoke fake objects

## Failure modes

- **public harness leak**: users can access internal quota simulation in ordinary product operation
- **branch collapse**: distinct warning, overage, model-specific, or disabled-credit states all map to one generic mock
- **header drift**: mock responses no longer exercise the same downstream parsing branches as live quota data
- **stale residue**: one scenario leaves behind timing or claim state that corrupts the next test

## Test Design

In the observed source, platform-service behavior is verified through sequencing-sensitive integration tests, deterministic state regressions, and CLI-visible service flows.

Equivalent coverage should prove:

- config resolution, policy gates, persistence, and service startup ordering preserve the contracts and failure handling described above
- provider-backed or OS-bound branches use fixtures, seeded stores, or narrow seams so auth, update, telemetry, and trust behavior stays reproducible
- users still encounter the expected startup, settings, trust, diagnostics, and account-state behavior through the real CLI surface
