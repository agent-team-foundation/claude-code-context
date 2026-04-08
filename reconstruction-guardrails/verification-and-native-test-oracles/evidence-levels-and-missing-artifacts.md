---
title: "Evidence Levels and Missing Artifacts"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/source-boundary.md
  - /reconstruction-guardrails/knowledge-lifecycle.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-framework-overview.md
---

# Evidence Levels and Missing Artifacts

This repository should distinguish between what the current source snapshot proves, what it strongly suggests, and what it does not expose yet.

## Confirmed from the current snapshot

The snapshot is sufficient to confirm all of these:

- there are distinct unit or regression, integration, end-to-end, conformance, and compatibility lanes
- `NODE_ENV=test` is a real runtime posture
- fixture and VCR replay are first-class testing mechanisms
- narrow seams such as injected dependencies, exported testing helpers, resets, and test-only helper surfaces are part of the current design

## Strongly suggested but not fully proven

The tree can safely treat these as strong signals rather than as closed facts:

- the TypeScript runner environment is Bun-oriented in at least part of the stack
- repo-level scripts wrap at least some runner commands instead of every lane being invoked directly

## Still missing for exact runner-level reproduction

The current snapshot does not fully expose:

- the top-level repository manifest and script table
- the complete test directory layout
- the full committed fixture corpus
- the CI workflow and any sharding or coverage rules

Those artifacts are the main blockers for claiming exact reproduction of upstream test plumbing.

## Clean-room rule

While those artifacts are missing, the tree should:

- document the confirmed architecture and tier model
- preserve clear evidence labels for inferred versus confirmed details
- refuse to guess exact runner wiring that the snapshot did not show

This is a knowledge-quality rule, not a refusal to make progress. The visible framework is already rich enough to guide a clean-room rebuild of the verification architecture itself.
