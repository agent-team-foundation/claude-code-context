---
title: "Knowledge Lifecycle"
owners: []
soft_links: [/reconstruction-guardrails/source-boundary.md, /reconstruction-guardrails/rebuild-standard.md]
---

# Knowledge Lifecycle

This repository needs a state machine for knowledge itself, otherwise it will gradually drift toward either thin summaries or source-shaped leakage.

## States

1. Candidate signal.
   A source observation exists, but has not yet been translated into tree language.
2. Normalized reconstruction fact.
   The observation has been restated as behavior, contract, rationale, or boundary.
3. Linked tree knowledge.
   The fact is placed in the correct domain and connected to related nodes.
4. Verified reconstruction guidance.
   The fact is specific enough that another team could design from it.
5. Stale or suspect knowledge.
   A newer observation, contradiction, or uncertainty suggests the node may be wrong.

## Transition rules

- Candidate signal must not be committed directly as repo inventory or copied wording.
- Normalized facts should be attached to the smallest domain that actually owns the decision.
- Linked knowledge becomes verified only when it explains consequences, not merely existence.
- Suspect knowledge should be corrected in place rather than preserved as history.

## Failure modes

- **Source mirroring**: the tree repeats filenames, strings, or implementation structure instead of durable meaning.
- **Over-compression**: a node is too vague to guide a clean-room rebuild.
- **Execution-detail creep**: the node starts describing how one codebase happened to implement the feature.
- **Unowned ambiguity**: information spans domains but is not linked, so rebuilders miss a constraint.
- **Silent contradiction**: later findings conflict with the tree and the tree is not updated.
