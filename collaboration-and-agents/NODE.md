---
title: "Collaboration and Agents"
owners: []
soft_links: [/runtime-orchestration, /tools-and-permissions]
---

# Collaboration and Agents

This domain captures how Claude Code scales from one foreground agent to many cooperating workers and remote execution contexts.

Relevant leaves:

- **[multi-agent-topology.md](multi-agent-topology.md)** — Agent roles, teams, and coordination patterns.
- **[worker-execution-boundaries.md](worker-execution-boundaries.md)** — Context isolation, executor modes, identity, and permission boundaries for worker agents.
- **[team-formation-and-spawn-contract.md](team-formation-and-spawn-contract.md)** — Team creation, teammate membership, shared task-list binding, spawn-time identity rules, and teardown cleanup.
- **[in-process-teammate-lifecycle.md](in-process-teammate-lifecycle.md)** — The long-lived same-process teammate loop, idle semantics, task-list claiming, and kill versus shutdown behavior.
- **[teammate-mailbox-and-permission-bridge.md](teammate-mailbox-and-permission-bridge.md)** — Shared mailbox protocol, structured teammate control messages, and the leader-permission bridge for workers.
- **[teammate-backend-and-context-bootstrap.md](teammate-backend-and-context-bootstrap.md)** — Backend detection, teammate-mode snapshotting, team-context recovery, and spawn inheritance rules.
- **[pane-backed-teammate-layout-and-control.md](pane-backed-teammate-layout-and-control.md)** — Pane creation, layout rules, focus or hide behavior, and cleanup contracts for tmux and native iTerm-style workers.
- **[inbox-polling-and-control-delivery.md](inbox-polling-and-control-delivery.md)** — How leader and worker inbox polling classifies control traffic, queues regular messages, and avoids duplicate or lost delivery.
- **[remote-and-bridge-flows.md](remote-and-bridge-flows.md)** — Remote execution, bridge transport, and session handoff behavior.
- **[collaboration-state-machine.md](collaboration-state-machine.md)** — How local, delegated, remote, and bridge-mediated work transitions over time.
- **[remote-session-contract.md](remote-session-contract.md)** — Contract for remote session ownership, messaging, approval, and reconnect.
- **[bridge-contract.md](bridge-contract.md)** — Contract for bridge-mediated control from constrained companion clients.
- **[remote-handoff-path.md](remote-handoff-path.md)** — End-to-end path for teleport, remote review or planning, and cross-machine continuation.
