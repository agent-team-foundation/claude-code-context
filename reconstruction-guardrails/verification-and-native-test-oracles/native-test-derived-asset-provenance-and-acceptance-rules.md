---
title: "Native-Test-Derived Asset Provenance and Acceptance Rules"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/source-boundary.md
  - /reconstruction-guardrails/knowledge-lifecycle.md
  - /platform-services/mock-rate-limit-scenarios-and-test-contracts.md
  - /tools-and-permissions/filesystem-and-shell/sed-command-validation-contracts.md
  - /tools-and-permissions/permissions/yolo-classifier-contracts.md
---

# Native-Test-Derived Asset Provenance and Acceptance Rules

The tree already contains subsystem leaves whose primary value comes from upstream-native test knowledge. That pattern is useful, but it needs guardrails so the tree stays a reconstruction spec instead of drifting into source mirroring.

## Current pattern

The current repo already uses domain-owned leaves for native-test-derived assets such as:

- rate-limit mock scenario contracts
- sed command validation contracts
- YOLO classifier contracts

This is the right ownership model: the acceptance oracle lives with the subsystem that owns the behavior.

## Provenance rules

When a leaf is derived primarily from upstream-native tests or testing-oriented helpers, it should preserve:

- the owning concern domain
- explicit provenance markers such as `native_source` where that is clear and useful
- a verification marker such as `verification_status: native_test_derived` when the leaf is intentionally restating upstream test oracles
- behavior and acceptance guidance, not copied prompts, copied code, or repo-internal execution trivia

## What these leaves should contain

A good native-test-derived leaf should usually include:

- scope boundary
- the contract or family of contracts being protected
- important state or parser edge cases
- the likely reconstruction mistakes another team would make without this oracle
- acceptance criteria when the evidence is strong enough to phrase them safely

## What they should not become

These leaves should not become:

- hidden inventories of upstream test files
- runner-specific setup notes that are only useful inside the original repo
- copied schemas or copied implementation detail whose only purpose is literal reimplementation

## Relationship to the broader framework

The broader test framework docs in this subdomain explain cross-cutting posture, fixture strategy, and seam design.

Native-test-derived leaves answer a different question:

- what exact nuanced behaviors did upstream consider important enough to defend with tests?

Both layers are necessary. The framework without the oracles is too generic. The oracles without the framework feel isolated and accidental.

## Failure modes

- **orphaned oracle**: a native-test-derived leaf has no framework links and reads like trivia
- **source-shaped leakage**: a contract leaf starts copying implementation detail instead of restating behavior
- **ownership drift**: test-derived assets collect in one generic place and stop reinforcing the domain that actually owns the behavior
