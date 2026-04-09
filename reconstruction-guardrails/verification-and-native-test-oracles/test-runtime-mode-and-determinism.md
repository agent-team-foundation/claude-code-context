---
title: "Test Runtime Mode and Determinism"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-environment-fixtures-and-ci-fail-closed-policy.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-seams-reset-hooks-and-injected-dependencies.md
  - /platform-services/startup-service-sequencing-and-capability-gates.md
  - /platform-services/usage-analytics-and-migrations.md
  - /tools-and-permissions/tool-catalog/tool-pool-assembly.md
  - /tools-and-permissions/permissions/e2e-permission-testing-contracts.md
  - /ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md
---

# Test Runtime Mode and Determinism

`NODE_ENV=test` is not just a hint for one subsystem. In the observed Claude Code snapshot it acts as a supported runtime posture with its own rules for config state, background work, helper-surface admission, and deterministic output.

## Test mode owns config isolation

Equivalent behavior should preserve:

- global and project-scoped config mutations being able to live in memory during automated runs instead of forcing persistent on-disk writes
- read paths being able to return that in-memory state directly under test posture
- config freshness watchers and similar cross-process sync helpers staying out of the way during ordinary tests unless a test intentionally exercises them

This matters because the product otherwise has many persistent caches and watch paths that would make tests order-dependent or racy.

## Background fetches and startup enrichments can go quiet

Equivalent behavior should preserve:

- remote or experiment-driven config hooks being able to short-circuit under test posture instead of waiting on asynchronous fetches
- startup-only enrichments and best-effort service work being suppressible when their production value is nondeterministic test noise
- tests not being forced to boot the full live startup graph when the lane is only trying to validate a narrow subsystem contract

The goal is not to disable the product. The goal is to keep automated runs from blocking on unrelated network or environment dependencies.

## Nonessential side effects stay suppressed

Equivalent behavior should preserve:

- telemetry and feedback-style emissions being suppressed in automated runs
- exit-time bookkeeping and adjacent support traffic being suppressible in test posture
- other background effects that only matter in production being able to stay dormant during verification

This suppression is part of determinism. It keeps tests from coupling themselves to slow, flaky, or privacy-sensitive side channels.

## Test-only helper surfaces can be admitted narrowly

Equivalent behavior should preserve:

- narrow helper surfaces that are admitted only in test posture
- those helpers still entering through the normal runtime assembly path rather than bypassing tool registration or permission routing entirely
- a clear difference between a test harness surface and an end-user product capability

This is how the current design can expose purpose-built harnesses without turning them into public features.

## Deterministic branches are allowed when production heuristics are unstable

Equivalent behavior should preserve:

- stable ordering in places where production normally uses recency, filesystem timing, or other environment-sensitive heuristics
- render or scheduling branches that make test output observable immediately and consistently
- deterministic normalization where incidental IDs, timestamps, or path forms would otherwise churn acceptance outputs

Not every tiny tie-breaker belongs in the tree. The product-level rule is that test posture may replace unstable heuristics with deterministic ones when that preserves the same user-visible contract.

## Failure modes

- **disk-coupled tests**: automated runs mutate persistent config or shared caches and then influence later tests
- **startup drag**: a narrow regression lane still waits on unrelated remote config or background init
- **helper leak**: a test-only helper surface escapes test posture and becomes user-visible
- **nondeterministic output**: sort order, rendering, or timing-sensitive branches make acceptance outputs depend on machine state
