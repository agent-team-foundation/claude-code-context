---
title: "Collaboration and Agents"
owners: []
soft_links: [/runtime-orchestration, /tools-and-permissions]
---

# Collaboration and Agents

This domain captures how Claude Code scales from one foreground agent to many cooperating workers and remote execution contexts.

Relevant leaves:

- **[multi-agent-topology.md](multi-agent-topology.md)** — Agent roles, teams, and coordination patterns.
- **[remote-and-bridge-flows.md](remote-and-bridge-flows.md)** — Remote execution, bridge transport, and session handoff behavior.
- **[collaboration-state-machine.md](collaboration-state-machine.md)** — How local, delegated, remote, and bridge-mediated work transitions over time.
- **[remote-session-contract.md](remote-session-contract.md)** — Contract for remote session ownership, messaging, approval, and reconnect.
- **[bridge-contract.md](bridge-contract.md)** — Contract for bridge-mediated control from constrained companion clients.
- **[remote-handoff-path.md](remote-handoff-path.md)** — End-to-end path for teleport, remote review or planning, and cross-machine continuation.
