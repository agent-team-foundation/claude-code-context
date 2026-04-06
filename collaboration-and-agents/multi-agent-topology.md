---
title: "Multi-Agent Topology"
owners: []
soft_links: [/tools-and-permissions/agent-and-task-control/delegation-modes.md, /runtime-orchestration/tasks/task-model.md, /collaboration-and-agents/peer-addressing-discovery-and-routing.md]
---

# Multi-Agent Topology

The baseline product is a single coding agent, but the architecture supports multiple cooperating agents.

Key patterns:

- A coordinator can decompose work into research, synthesis, implementation, and verification phases.
- Worker agents should receive bounded scopes, narrower tool access, and explicit ownership of outputs.
- Teams and message-passing constructs let agents communicate without collapsing back into one shared mutable prompt.
- Swarm teammates are only one messaging plane; the runtime can also surface same-process local agents, other live local sessions, and Remote Control sessions as distinct addressable peers with different trust and delivery rules.
- Background agents must tolerate reduced interactivity and use task output channels instead of assuming they can always ask the user immediately.

Equivalent implementations should preserve the distinction between orchestration logic, worker execution logic, and the separate routing rules for swarm-local versus cross-session communication.
