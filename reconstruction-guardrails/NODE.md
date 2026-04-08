---
title: "Reconstruction Guardrails"
owners: []
soft_links: [/product-surface, /runtime-orchestration]
---

# Reconstruction Guardrails

This domain defines what this repository is allowed to contain and what "complete enough to rebuild" means.

Use these leaves before adding any new knowledge:

- **[source-boundary.md](source-boundary.md)** — What can be extracted from source analysis and what must be excluded.
- **[rebuild-standard.md](rebuild-standard.md)** — The bar a node must clear to be useful for a clean-room implementation.
- **[knowledge-lifecycle.md](knowledge-lifecycle.md)** — How extracted knowledge moves from observation to durable tree state, and how bad knowledge is detected.
- **[rebuild-phasing.md](rebuild-phasing.md)** — Implementation order for a clean-room rebuild, including what must ship together.
- **[tree-expansion-strategy.md](tree-expansion-strategy.md)** — How this repository should deepen from high-level coverage into reconstruction-ready subsystem contracts over repeated passes.
- **[verification-and-native-test-oracles/](verification-and-native-test-oracles/NODE.md)** — How cross-domain test framework knowledge, fixture oracles, and native-test-derived contract assets should be normalized without becoming a source mirror.
