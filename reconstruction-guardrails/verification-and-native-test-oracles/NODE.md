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

- **[test-framework-overview.md](test-framework-overview.md)** — The layered shape of the current test system, including the visible tier model and the boundary between confirmed and inferred runner details.
- **[test-environment-fixtures-and-ci-fail-closed-policy.md](test-environment-fixtures-and-ci-fail-closed-policy.md)** — How test posture suppresses side effects, how fixture replay works, and why missing recordings fail closed in CI.
- **[test-seams-reset-hooks-and-injected-dependencies.md](test-seams-reset-hooks-and-injected-dependencies.md)** — The narrow seams the product uses to keep hard behaviors testable without turning the whole runtime into a debug harness.
- **[native-test-derived-asset-provenance-and-acceptance-rules.md](native-test-derived-asset-provenance-and-acceptance-rules.md)** — How native test knowledge should be normalized into clean-room contract assets and how those assets should be linked back to their owning domains.
- **[evidence-levels-and-missing-artifacts.md](evidence-levels-and-missing-artifacts.md)** — What this source snapshot proves, what it only strongly suggests, and which missing artifacts still block exact runner-level reproduction.
