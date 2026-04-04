---
title: "Control-Plane Tools"
owners: []
soft_links: [/tools-and-permissions/delegation-modes.md, /tools-and-permissions/permission-mode-transitions-and-gates.md, /tools-and-permissions/task-and-team-control-tool-contracts.md, /tools-and-permissions/config-discovery-and-trigger-tool-contracts.md, /runtime-orchestration/task-model.md, /runtime-orchestration/shared-task-control-plane-and-lifecycle-events.md, /runtime-orchestration/worktree-session-lifecycle.md, /integrations/clients/sdk-control-protocol.md]
---

# Control-Plane Tools

Some Claude Code tools do not primarily act on the outside world. They mutate the runtime itself: its mode, task graph, coordination topology, or approval state.

These control-plane tools fall into a few recurring groups:

- **elicitation tools** that ask the user structured questions or request narrow confirmations
- **mode-switch tools** that enter or exit plan mode, worktree mode, or similar execution envelopes
- **task-management tools** that create, inspect, update, list, stream, assign, or stop background work
- **coordination tools** that create teams, send messages, or route work across cooperating agents
- **runtime discovery tools** that search the tool registry, inspect integration resources, browse permission state, or expose configuration state
- **trigger and admin tools** that schedule or remotely start work outside the current foreground turn, retry previously denied actions, or mutate narrow policy-backed runtime settings

Equivalent implementations should preserve these invariants:

- Control-plane actions must create explicit, inspectable state transitions rather than hidden side effects.
- A host UI or SDK should be able to observe these transitions in real time.
- The same permission and policy system used for world-facing tools must also gate sensitive control-plane actions.
- Control-plane tools need stable schemas because other subsystems depend on them for orchestration.
- Entering a specialized mode should tighten the runtime contract for later turns; it should not behave like a cosmetic flag.
- mode-switch tools that enter or exit worktree posture must mutate persisted resume state, prompt-visible environment context, and session-owned cleanup state together rather than toggling a display-only badge

Some control-plane families need stronger guarantees than a generic schema:

- task and team tools should be transactional, with rollback or veto paths when hooks reject a mutation
- config and trigger tools should write only through registry-backed, type-aware mutation paths
- permission-management surfaces should operate on source-attributed rule state rather than on flattened raw text blobs

Runtime task-management tools also need a clear boundary: file-backed team task lists are one contract, while live background-task registration, stop dispatch, and lifecycle bookends are the runtime contract captured in [shared-task-control-plane-and-lifecycle-events.md](../runtime-orchestration/shared-task-control-plane-and-lifecycle-events.md).

This distinction is important for reconstruction because Claude Code is not just a bundle of file and shell tools. It is also a runtime that can reconfigure itself while work is in progress.
