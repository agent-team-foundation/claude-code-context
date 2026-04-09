---
title: "Evidence Levels and Missing Artifacts"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/source-boundary.md
  - /reconstruction-guardrails/knowledge-lifecycle.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-framework-overview.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-lane-coverage-map.md
---

# Evidence Levels and Missing Artifacts

This repository should distinguish between what the current source snapshot proves, what it strongly suggests, and what it does not expose yet.

## Confirmed from the current snapshot

The snapshot is sufficient to confirm all of these:

- `NODE_ENV=test` is a supported runtime posture rather than a one-off conditional
- fixture and VCR replay are first-class testing mechanisms
- there are direct signals for multiple lane families, including at least one compatibility lane, at least one integration lane, dedicated end-to-end harnesses, conformance-sensitive auth verification, and many narrow regression or fidelity oracles
- narrow seams such as injected dependencies, exported testing helpers, resets, and test-only helper surfaces are part of the current design

The tree should treat those as lane-family and architecture facts, not as proof of the full hidden runner inventory.

## Strongly suggested but not fully proven

The tree can safely treat these as strong signals rather than as closed facts:

- the TypeScript runner environment is Bun-oriented in at least part of the stack
- the regression or unit layer is broader than the few directly named test references exposed in comments and helper exports
- repo-level scripts wrap at least some runner commands instead of every lane being invoked directly

## Still missing for exact runner-level reproduction

The current snapshot does not fully expose:

- the top-level repository manifest and script table
- the complete test directory layout
- the exhaustive lane inventory and lane-to-command matrix
- the full committed fixture corpus
- the CI workflow and any sharding or coverage rules

Those artifacts are the main blockers for claiming exact reproduction of upstream test plumbing.

## Clean-room rule

While those artifacts are missing, the tree should:

- document the confirmed architecture and tier model
- preserve clear evidence labels for inferred versus confirmed details
- claim lane purpose and behavior ownership more confidently than lane naming or runner wiring
- refuse to guess exact runner wiring that the snapshot did not show

This is a knowledge-quality rule, not a refusal to make progress. The visible framework is already rich enough to guide a clean-room rebuild of the verification architecture itself.
