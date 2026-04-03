---
title: "Collaboration State Machine"
owners: []
soft_links: [/collaboration-and-agents/multi-agent-topology.md, /collaboration-and-agents/remote-and-bridge-flows.md]
---

# Collaboration State Machine

Collaboration spans more than one axis: local versus remote, single-agent versus multi-agent, and foreground versus background.

## Collaboration states

1. Local solo execution.
2. Local delegated execution.
   Worker agents or tasks exist, but the local session remains authoritative.
3. Remote-coupled execution.
   A remote runtime is performing work while the local client observes or steers.
4. Bridge-mediated interaction.
   Another client surface is driving the session through a constrained transport.
5. Reconnect or handoff recovery.
6. Completed or archived collaboration.

## Transition triggers

- task creation
- spawning or resuming a subagent
- entering remote mode
- attaching or reattaching a bridge client
- receiving a remote permission challenge
- archiving or terminating a shared session

## Failure modes

- **Authority confusion**: it is unclear whether local, remote, or worker state is canonical.
- **Permission split-brain**: remote execution requests approval through a channel that no longer exists.
- **Reconnect drift**: a reattached client sees partial history or mismatched session identity.
- **Background orphaning**: delegated work continues after the user no longer has clear control over it.
