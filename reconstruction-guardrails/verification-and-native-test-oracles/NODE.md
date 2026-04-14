---
title: "Verification and Native Test Oracles"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/source-boundary.md
  - /reconstruction-guardrails/knowledge-lifecycle.md
  - /platform-services/NODE.md
  - /tools-and-permissions/NODE.md
  - /integrations/NODE.md
---

# Verification and Native Test Oracles

This subdomain captures cross-cutting knowledge about how the observed Claude Code build verifies itself. It exists because the tree already has domain-owned test contracts, but it still lacked one place to describe the shared verification architecture that spans runtime posture, fixtures, seams, and evidence quality.

Relevant leaves:

- **[minimal-end-to-end-verification-chain.md](minimal-end-to-end-verification-chain.md)** — The shortest serious proof ladder a rewrite should clear before broader parity claims are considered credible.
- **[parity-capability-matrix.md](parity-capability-matrix.md)** — Which capability families are blocking for parity, which are extension-level, and what evidence bar each family must clear before a rebuild can claim success.
- **[reconstruction-target-and-evidence-boundary.md](reconstruction-target-and-evidence-boundary.md)** — How source-snapshot evidence and later released-binary evidence can both inform the tree without collapsing into one false versionless parity claim.
- **[test-framework-overview.md](test-framework-overview.md)** — The layered shape of the current test system, including the visible tier model and the boundary between confirmed and inferred runner details.
- **[real-cli-e2e-scenario-corpus.md](real-cli-e2e-scenario-corpus.md)** — A live-observed black-box scenario set for validating whether a rebuild behaves like a real Claude Code CLI across startup, headless runs, session continuity, structured I/O, and diagnostics.
- **[test-runtime-mode-and-determinism.md](test-runtime-mode-and-determinism.md)** — How `NODE_ENV=test` behaves as a supported runtime posture, including in-memory config behavior, reduced side effects, and deterministic test-only branches.
- **[test-environment-fixtures-and-ci-fail-closed-policy.md](test-environment-fixtures-and-ci-fail-closed-policy.md)** — How test posture suppresses side effects, how fixture replay works, and why missing recordings fail closed in CI.
- **[test-lane-coverage-map.md](test-lane-coverage-map.md)** — Which subsystem contracts are guarded by fast regression, integration, end-to-end, conformance, and compatibility lanes, without overclaiming the hidden runner layout.
- **[e2e-harness-reality-boundaries.md](e2e-harness-reality-boundaries.md)** — Which end-to-end harnesses may shorten setup but still need to preserve real permission, transport, auth-proxy, and credential-cache paths.
- **[released-cli-e2e-test-set.md](released-cli-e2e-test-set.md)** — Public-runtime end-to-end oracles gathered by exercising a shipped Claude CLI build against a real local workspace, plus the parity-critical cases a rebuild must not skip.
- **[test-seams-reset-hooks-and-injected-dependencies.md](test-seams-reset-hooks-and-injected-dependencies.md)** — The narrow seams the product uses to keep hard behaviors testable without turning the whole runtime into a debug harness.
- **[native-test-derived-asset-provenance-and-acceptance-rules.md](native-test-derived-asset-provenance-and-acceptance-rules.md)** — How native test knowledge should be normalized into clean-room contract assets and how those assets should be linked back to their owning domains.
- **[evidence-levels-and-missing-artifacts.md](evidence-levels-and-missing-artifacts.md)** — What this source snapshot proves, what it only strongly suggests, and which missing artifacts still block exact runner-level reproduction.
