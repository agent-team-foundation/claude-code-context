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

## Snapshot packaging boundary

The current Claude Code snapshot behaves like a partial source export rather than a full repository checkout.

Direct root-level scanning did not expose:

- the top-level repository manifest or lockfiles
- committed workflow files or other CI orchestration assets
- the committed `test/`, `tests/`, `__tests__`, or `fixtures/` directories themselves
- runner-specific config files or coverage config files

That absence should be treated as evidence, not as an invitation to guess. The missing runner, CI, coverage, and fixture-corpus details are blocked first by snapshot packaging boundaries, not by tree organization.

## Confirmed from the current snapshot

The snapshot is sufficient to confirm all of these:

- `NODE_ENV=test` is a supported runtime posture rather than a one-off conditional
- fixture and VCR replay are first-class testing mechanisms
- there are direct signals for multiple lane families, including at least one compatibility lane, at least one integration lane, dedicated end-to-end harnesses, conformance-sensitive auth verification, and many narrow regression or fidelity oracles
- narrow seams such as injected dependencies, exported testing helpers, resets, and test-only helper surfaces are part of the current design
- a shared `test/preload.ts` layer exists for reset and shard-isolation work across same-process tests
- at least part of the suite runs in a Bun-flavored environment, and at least one visible lane is invoked through a script-wrapped `npm run test:file ...` entrypoint
- sharded execution exists, including explicit Windows-shard signals
- coverage output exists as a generated artifact, even though the tool and thresholds are not exposed

The tree should treat those as lane-family and architecture facts, not as proof of the full hidden runner inventory.

## Directly named family and layout signals

The current snapshot directly names enough test assets to anchor the framework:

- `test/utils/settings/backward-compatibility.test.ts` as a script-addressable compatibility lane
- `test/utils/transcriptSearch.renderFidelity.test.tsx`, `toolSearchText.test.tsx`, `test/utils/powershell/dangerousCmdlets.test.ts`, and `test/utils/sandbox/webfetch-preapproved-separation.test.ts` as narrow regression, fidelity, or policy-boundary contracts
- `managedSettingsHeadless.int.test.ts` as a true integration lane
- `daemon/auth.test.ts`, `bash/prefix.test.ts`, `officialRegistry.test.ts`, `backgroundShells.test.ts`, `diskOutput.test.ts`, `spawn.test.ts`, and `validate.test.ts` as additional family signals outside the visible `test/utils` path
- JSON `fixtures/` recordings rooted at configurable test fixture paths rather than at one hardcoded machine-local directory

These are evidence anchors, not the full upstream test tree.

## Strongly suggested but not fully proven

The tree can safely treat these as strong signals rather than as closed facts:

- the TypeScript runner environment is Bun-oriented in at least part of the stack, but Bun has not been proven to be the only runner for every lane
- the regression or unit layer is broader than the few directly named test references exposed in comments and helper exports
- repo-level scripts wrap at least some runner commands instead of every lane being invoked directly
- historical or local Jest constraints influenced some helper placement, but that does not prove Jest remains the current primary runner

## Still missing for exact runner-level reproduction

The current snapshot does not fully expose:

- the top-level repository manifest and script table
- the complete test directory layout and exhaustive file inventory
- the full contents of `test/preload.ts`
- the exhaustive lane inventory and lane-to-command matrix
- the full committed fixture corpus
- the CI workflow and the exact sharding or coverage rules

Those artifacts are the main blockers for claiming exact reproduction of upstream test plumbing.

## Clean-room rule

While those artifacts are missing, the tree should:

- document the confirmed architecture and tier model
- preserve clear evidence labels for inferred versus confirmed details
- claim lane purpose and behavior ownership more confidently than lane naming or runner wiring
- refuse to guess exact runner wiring that the snapshot did not show
- treat directly named test families as anchor examples rather than as an exhaustive file tree
- avoid treating generic mentions of external tools or generated workflow templates as proof of Claude Code's own hidden test stack

This is a knowledge-quality rule, not a refusal to make progress. The visible framework is already rich enough to guide a clean-room rebuild of the verification architecture itself.
