---
title: "App State and Input Routing"
owners: []
soft_links: [/runtime-orchestration/task-registry-and-visibility.md, /runtime-orchestration/session-reset-and-state-preservation.md, /tools-and-permissions/permission-mode-transitions-and-gates.md, /ui-and-experience/background-task-status-surfaces.md]
---

# App State and Input Routing

One central application-state object acts as the runtime glue between the turn engine, background tasks, collaborative views, remote clients, and terminal UI. Reconstructing Claude Code requires more than a transcript and a task list; it requires this shared state model and the routing rules built on top of it.

## State partitions

Equivalent behavior should keep these partitions distinct even if one implementation stores them differently:

- session-scoped settings and model choices
- terminal chrome state such as expanded panels, footer focus, and status text
- the local task registry
- a main-view foreground pointer for whichever background transcript is currently shown inline
- a separate viewed-worker pointer for whichever teammate or named local agent should receive routed input
- remote-session transport state and remote background-task counts that are not derived from the local task registry
- collaboration state such as team membership, mailbox messages, worker approval queues, and pending worker-side waits
- notification and elicitation queues
- feature-specific transient state such as prompt suggestions, speculative execution, remote-planning launch state, and bridge connectivity

The clean-room requirement is not the exact field list. It is that these concerns can change independently without corrupting one another.

## Input-routing contract

User input does not always target the leader session.

Equivalent routing should follow this order:

1. if the current viewed target still resolves to an in-process teammate, route input there
2. else if the current viewed target still resolves to a named local agent transcript, route input there
3. else route input to the leader session

Important invariants:

- stale or mismatched viewed IDs must degrade safely back to the leader
- "shown in the main transcript view" and "receives new input" are different state machines
- changing the view target must not require re-registering the underlying task

Without that separation, a background transcript can become visible without becoming steerable, or vice versa.

## External metadata synchronization

The permission posture carried in session metadata is derived from application state, not recomputed ad hoc at every external surface.

Equivalent behavior should preserve:

- one choke point that detects permission-mode changes
- externalization of internal-only runtime modes before they are mirrored to remote or SDK surfaces
- suppression of metadata updates when the externalized meaning did not actually change
- one-way hydration from remote metadata back into local state for the small subset of fields that must survive worker restart or remote restore

This matters because local state can include modes that are meaningful for internal routing but should not leak verbatim into companion clients.

## Persistence side effects

Application-state changes can trigger durable side effects outside the state store.

A faithful rebuild should preserve at least these classes of write-through behavior:

- model changes update both session override state and user-visible persisted settings
- view or verbosity toggles persist to global preferences when those toggles are intended to survive restart
- terminal-panel visibility that is meant to be sticky persists separately from transient per-turn hide or show state
- settings changes clear cached auth or provider state so later turns observe the new credentials
- environment-variable settings are re-applied additively when config-driven env state changes

The important contract is that these effects happen from state diffs, not from scattered command-specific write paths.

## Failure modes

- **state coupling**: remote task counts, local task visibility, and collaboration state are collapsed into one registry and drift out of sync
- **routing dead-end**: a viewed worker disappears and input keeps targeting a non-existent recipient
- **metadata leak**: internal-only permission or planning states surface verbatim to remote clients
- **stale persistence**: settings change in memory but auth, environment, or model override caches are not refreshed
