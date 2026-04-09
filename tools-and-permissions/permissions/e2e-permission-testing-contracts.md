---
title: "E2E Permission Testing Contracts"
owners: [bingran-you]
soft_links: [/tools-and-permissions/permissions/permission-decision-pipeline.md, /ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md, /reconstruction-guardrails/verification-and-native-test-oracles/test-runtime-mode-and-determinism.md, /reconstruction-guardrails/verification-and-native-test-oracles/e2e-harness-reality-boundaries.md]
native_source: tools/testing/TestingPermissionTool.tsx
verification_status: native_test_derived
---

# E2E Permission Testing Contracts

This leaf captures the verification contract for a test-only approval harness. The clean-room value is not one exact tool implementation. It is the existence of a narrow probe that can reliably force the ordinary permission flow to happen on demand without turning that probe into a public product feature.

## Scope boundary

This leaf covers:

- how a test-only approval probe is admitted
- what that probe must prove about the ordinary permission path
- what properties keep the harness deterministic and low-risk

It intentionally does not cover:

- the general permission-decision pipeline
- automatic-approval classifier behavior
- every specialized approval surface already documented in the UI domain

## The approval probe is a harness, not a product feature

Equivalent behavior should preserve:

- admission only in test posture
- normal runtime registration through the ordinary tool pool rather than through a fake backdoor
- exclusion from ordinary production-facing tool surfaces
- a low-risk, read-only execution shape once the approval is granted

The important contract is that the harness is narrow enough to be safe, but real enough to exercise the same approval path users see.

## The harness must force the ordinary ask path

Equivalent behavior should preserve:

- a test-only action that contributes an explicit approval request instead of auto-allowing through the normal safe-action shortcuts
- grant, deny, cancel, and queue-advance behavior all flowing through the same permission shell and callback machinery as ordinary approvals
- the same approval route being usable for foreground sessions and forwarded-worker or delegated approval cases when those flows are under test

An approval harness that manipulates dialog state directly would miss the contract this leaf is meant to defend.

## Post-approval behavior should stay deterministic and low-noise

Equivalent behavior should preserve:

- a deterministic success path after the user approves the harness action
- minimal or no external side effects beyond the permission event itself
- concurrency safety appropriate for automated suites that may run many permission cases in one process

The purpose of the harness is to validate the approval machinery, not to add unrelated filesystem or network variables.

## What the e2e lane should prove

Equivalent end-to-end coverage should be able to prove at least:

- the approval prompt actually appears when the harness is invoked
- user grant allows the action to finish through the normal continuation path
- user denial blocks execution and clears the queue correctly
- cancellation and queue-head transitions do not leave stale waiting state behind
- worker-forwarded or remote-capable approval surfaces, when exercised, still reuse the same underlying approval semantics

## Failure modes

- **public harness leak**: the approval probe becomes visible outside test posture
- **fake dialog coverage**: tests bypass the normal permission shell and therefore stop proving real user behavior
- **side-effect pollution**: the harness action itself mutates unrelated runtime state and makes permission tests flaky
- **queue drift**: grant, deny, or cancel paths leave stale approval rows or waiting state behind
