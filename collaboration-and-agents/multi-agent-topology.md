---
title: "Multi-Agent Topology"
owners: []
soft_links: [/tools-and-permissions/delegation-modes.md, /runtime-orchestration/task-model.md]
---

# Multi-Agent Topology

The baseline product is a single coding agent, but the architecture supports multiple cooperating agents.

Key patterns:

- A coordinator can decompose work into research, synthesis, implementation, and verification phases.
- Worker agents should receive bounded scopes, narrower tool access, and explicit ownership of outputs.
- Teams and message-passing constructs let agents communicate without collapsing back into one shared mutable prompt.
- Background agents must tolerate reduced interactivity and use task output channels instead of assuming they can always ask the user immediately.

Equivalent implementations should preserve the distinction between orchestration logic and worker execution logic.
