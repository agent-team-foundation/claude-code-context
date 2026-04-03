---
title: "Control-Plane Tools"
owners: []
soft_links: [/tools-and-permissions/delegation-modes.md, /runtime-orchestration/task-model.md, /integrations/clients/sdk-control-protocol.md]
---

# Control-Plane Tools

Some Claude Code tools do not primarily act on the outside world. They mutate the runtime itself: its mode, task graph, coordination topology, or approval state.

These control-plane tools fall into a few recurring groups:

- **elicitation tools** that ask the user structured questions or request narrow confirmations
- **mode-switch tools** that enter or exit plan mode, worktree mode, or similar execution envelopes
- **task-management tools** that create, inspect, update, list, stream, or stop background work
- **coordination tools** that create teams, send messages, or route work across cooperating agents
- **runtime discovery tools** that search the tool registry, inspect integration resources, or expose configuration state
- **trigger tools** that schedule or remotely start work outside the current foreground turn

Equivalent implementations should preserve these invariants:

- Control-plane actions must create explicit, inspectable state transitions rather than hidden side effects.
- A host UI or SDK should be able to observe these transitions in real time.
- The same permission and policy system used for world-facing tools must also gate sensitive control-plane actions.
- Control-plane tools need stable schemas because other subsystems depend on them for orchestration.
- Entering a specialized mode should tighten the runtime contract for later turns; it should not behave like a cosmetic flag.

This distinction is important for reconstruction because Claude Code is not just a bundle of file and shell tools. It is also a runtime that can reconfigure itself while work is in progress.
