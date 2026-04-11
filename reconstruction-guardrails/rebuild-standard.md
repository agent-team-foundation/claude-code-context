---
title: "Rebuild Standard"
owners: []
soft_links: [/product-surface, /tools-and-permissions, /integrations]
---

# Rebuild Standard

The goal of this tree is not "describe the repo." The goal is "enable an equivalent implementation."

A node is useful when it helps another team answer at least one of these questions:

- What user-facing behavior must exist?
- Which subsystems must cooperate to deliver that behavior?
- What state, safety, or permission boundaries must the implementation preserve?
- Which extension points and transports are first-class rather than incidental?
- Which constraints are durable enough that a future maintainer should design around them?

A node is not yet complete if it only says "there is a folder named X" or "there is a file named Y."

Equivalent implementations may choose different languages, libraries, transport layers, or UI widgets. What must stay aligned is the product capability envelope and the architectural contracts captured in this tree.

## Logic leaves must explain how they are tested

For logic-bearing leaves, "complete enough to rebuild" includes a verification shape, not just a behavior description.

A reconstruction-ready logic leaf should therefore include a `## Test Design` section that explains, in clean-room language:

- which invariants or failure paths deserve fast regression coverage
- which cross-subsystem interactions need integration coverage
- which user-visible or transport-sensitive behaviors need end-to-end or compatibility coverage
- when deterministic fixtures, replay, reset hooks, or test-only seams are part of the observed testing strategy

The goal is not to mirror upstream test files. The goal is to preserve how the source treats the behavior as something that must be proven.
