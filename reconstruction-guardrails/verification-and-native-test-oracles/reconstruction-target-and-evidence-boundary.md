---
title: "Reconstruction Target and Evidence Boundary"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/verification-and-acceptance-strategy.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/evidence-levels-and-missing-artifacts.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/real-cli-e2e-scenario-corpus.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/released-cli-e2e-test-set.md
---

# Reconstruction Target and Evidence Boundary

This tree currently draws on two different evidence families:

- a partial local source snapshot captured from the March 31, 2026 leak window
- black-box runs against released Claude Code binaries observed later on local machines

Both evidence families are useful. They are not interchangeable. A faithful rebuild needs an explicit rule for how to use them without accidentally mixing incompatible version-sensitive details into one false "100% parity" claim.

## Scope boundary

This leaf covers:

- how to choose the reconstruction target before claiming parity
- which evidence family is authoritative for which kind of question
- what must be stated when a rebuild claims Claude Code equivalence

It intentionally does not re-document:

- the source-packaging limitations already captured in [evidence-levels-and-missing-artifacts.md](evidence-levels-and-missing-artifacts.md)
- the scenario corpus itself, already captured in [real-cli-e2e-scenario-corpus.md](real-cli-e2e-scenario-corpus.md)
- the current released-binary observations already captured in [released-cli-e2e-test-set.md](released-cli-e2e-test-set.md)

## One parity claim needs one explicit target

Equivalent behavior should preserve one declared target at a time.

That target may be:

- the leaked-source snapshot line, when the goal is to reconstruct the internal product shape visible in that snapshot
- a specific released CLI line, when the goal is to match what end users actually saw from a shipped binary
- a deliberately versioned hybrid milestone, but only if the milestone says exactly which behaviors come from which source of truth

What must not happen is an unqualified "Claude Code parity" claim that silently mixes source-snapshot internals with later released-binary behavior when those two lines visibly drift.

## Source snapshot answers shape questions

The March 31, 2026 snapshot is authoritative for questions such as:

- which subsystems exist
- which contracts, seams, fixtures, and state machines are visible in code
- which feature-gated surfaces or hidden verification hooks are proven by source evidence
- which behaviors were important enough upstream to defend with tests or dedicated helper seams

The snapshot is not authoritative for:

- the exact behavior of later released binaries after subsequent updates
- the full hidden runner manifest or CI layout when those artifacts were not included in the snapshot packaging
- exact claims about public surfaces that visibly changed after the leak window

## Released binaries answer public-behavior questions

Released CLI observations are authoritative for questions such as:

- what a real user-facing command or flag did on a real machine
- how startup, onboarding, doctor, install, update, print mode, resume, plugin, and MCP flows behaved from outside the binary
- which behaviors are version-sensitive enough that a rebuild must avoid overfitting to the leaked snapshot alone

Released-binary evidence is not authoritative for:

- hidden subsystem boundaries that are only visible in source
- internal feature-gated flows that were compiled out or otherwise unreachable from the tested build
- source-era contracts that the public build no longer exposed directly

## Public parity must name the target and environment

Any serious parity claim should explicitly name:

- the target line being matched
- the evidence family used for that claim
- the environment posture when that matters, such as provider mode, auth shape, OS, or interactive versus headless surface

For example, a useful claim looks like:

- "Matches the March 31, 2026 source snapshot for test posture, fixture policy, and visible tool/runtime contracts."
- "Matches the April 9, 2026 observed native CLI line for provider-backed local print-mode, startup, and doctor behavior on macOS."

A weak claim is simply "matches Claude Code" with no target, no date, and no runtime posture.

## Version-sensitive observations must stay labeled

Equivalent behavior should preserve explicit labeling for observations that are known to drift between builds, including:

- install and update reporting
- `--continue` and `--no-session-persistence` behavior
- plugin update restart semantics
- onboarding and trust-flow details that changed across released binaries

Those observations are valuable, but they must stay attached to the version line that produced them. Otherwise the tree invites rebuilds to combine incompatible facts into one impossible target.

## Decision rule for future tree work

When adding a new verification or parity asset:

- use source evidence when the question is about hidden shape, subsystem design, or native test intent
- use released-binary evidence when the question is about externally visible runtime behavior
- if both evidence families are needed, state the split directly instead of flattening them into one undifferentiated conclusion
- if the two families disagree, record that disagreement as version drift unless there is direct evidence they still refer to the same build line

## Failure modes

- **version blur**: one leaf silently mixes source-era and later released-binary behavior as if both described one immutable product
- **false 100% claim**: a rewrite is declared complete without naming the target line or evidence family
- **public-over-internal inversion**: a later binary observation is used to override a source-proven hidden contract with no evidence that the underlying design changed
- **snapshot-over-public inversion**: a leaked-source detail is treated as the final word on a user-visible command even after later released binaries show drift
