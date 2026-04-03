---
title: "Tree Expansion Strategy"
owners: []
soft_links: [/reconstruction-guardrails/rebuild-standard.md, /runtime-orchestration/turn-assembly-and-recovery.md, /integrations/clients/surface-adapter-contract.md]
---

# Tree Expansion Strategy

This repository already has broad domain coverage. The next challenge is depth: every important Claude Code capability needs to be restated as enough linked contracts that another team could implement it without ever reading the original source.

## Expansion order

Deepening should follow the product's dependency graph rather than the source tree.

1. **Shared runtime spine**  
   Turn assembly, command dispatch, tool-pool assembly, permission posture, and task orchestration.
2. **Durability spine**  
   Session persistence, resume, compaction, session memory, and durable memory upkeep.
3. **Extension and surface spine**  
   Skills, MCP, plugins, SDK transport, remote-capable clients, and managed overlays.
4. **Differentiated feature branches**  
   Specialized surfaces and heavily gated capabilities such as advanced review modes, proactive assistants, browser control, voice, or companion features.

This order keeps later nodes grounded in the central state machine instead of documenting edge features in isolation.

## What one iteration should accomplish

A good deepening pass should do at least one of the following:

- replace a summary-only node with a more specific behavioral contract
- capture the invariants, gating, and failure modes of a core subsystem
- explain how one user-visible capability traverses several domains
- make a previously implied relationship explicit through soft links

Each pass should leave the tree more generative for a clean-room builder than before.

## Acceptance test for new deep nodes

Before a new node is committed, it should answer most of these questions:

- What user-visible behavior or subsystem boundary does this node own?
- What other domains must cooperate with it?
- What state transitions or gating rules shape it?
- What are the major failure or degradation paths?
- What would another implementation team get wrong if this node did not exist?

If a draft node cannot answer these questions, it is probably still too shallow.

## Stop conditions

Stop deepening a node when the next facts would mostly become:

- file inventories
- copied prompts or copied strings
- line-by-line execution narratives
- implementation trivia that does not change design choices

At that point the tree is drifting toward source mirroring instead of reconstruction guidance.

## Validation hygiene

`context-tree verify` only stays meaningful when the repository visible to the validator is mostly tree content.

If the repo also contains:

- raw source snapshots used only for analysis
- synced skill artifacts or other maintenance payloads
- helper scripts that are not part of the tree itself

then those assets should eventually move to hidden paths or external analysis workspaces. Otherwise the validator will correctly demand `NODE.md` coverage for material that is not intended to be part of the reconstruction tree.

For this repository, validator cleanliness is therefore a structural follow-up item, not just a documentation polish step.
