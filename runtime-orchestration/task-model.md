---
title: "Task Model"
owners: []
soft_links: [/collaboration-and-agents/multi-agent-topology.md, /tools-and-permissions/delegation-modes.md]
---

# Task Model

Claude Code treats background work as explicit tasks with typed lifecycle management.

Required task qualities:

- A task has a stable identifier, type, status, description, and output location.
- A task can move through non-terminal and terminal states; terminal tasks must reject further writes.
- The UI and tool surface can inspect, stream, update, and stop task execution.
- Task types distinguish local shell execution, local agents, remote agents, and other background workers such as memory consolidation or workflow monitors.

This separation matters because the product mixes interactive foreground turns with background work that may outlive a single turn, use different permission rules, or surface output asynchronously.
