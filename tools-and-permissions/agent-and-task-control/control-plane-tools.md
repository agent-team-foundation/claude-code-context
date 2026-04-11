---
title: "Control-Plane Tools"
owners: []
soft_links: [/tools-and-permissions/agent-and-task-control/delegation-modes.md, /tools-and-permissions/permissions/permission-mode-transitions-and-gates.md, /tools-and-permissions/agent-and-task-control/task-and-team-control-tool-contracts.md, /tools-and-permissions/permissions/config-permission-and-sandbox-admin-surfaces.md, /runtime-orchestration/tasks/task-model.md, /runtime-orchestration/tasks/shared-task-control-plane-and-lifecycle-events.md, /runtime-orchestration/sessions/worktree-session-lifecycle.md, /integrations/clients/sdk-control-protocol.md, /collaboration-and-agents/peer-addressing-discovery-and-routing.md]
---

# Control-Plane Tools

Some Claude Code tools do not primarily act on the outside world. They mutate the runtime itself: its mode, task graph, coordination topology, or approval state.

These control-plane tools fall into a few recurring groups:

- **elicitation tools** that ask the user structured questions or request narrow confirmations
- **mode-switch tools** that enter or exit plan mode, worktree mode, or similar execution envelopes
- **task-management tools** that create, inspect, update, list, stream, assign, or stop background work
- **coordination tools** that create teams, enumerate addressable peers, send follow-up messages, or route work across cooperating agents and live sessions
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
- config tools should write only through registry-backed, type-aware mutation paths, while remote trigger tools preserve backend-owned request bodies instead of inventing local field-by-field normalization
- permission-management surfaces should operate on source-attributed rule state rather than on flattened raw text blobs

Coordination tools need an additional boundary:

- same-process local-agent follow-up, team-local mailbox delivery, direct local-session delivery, and Remote Control peer delivery are different routing classes even when the user-facing send surface feels unified
- team-local structured control payloads must not leak onto cross-session routes; direct peer delivery is plain-text-only
- cross-machine peer sends require an explicit consent gate even though ordinary teammate messaging does not

Runtime task-management tools also need a clear boundary: file-backed team task lists are one contract, while live background-task registration, stop dispatch, and lifecycle bookends are the runtime contract captured in [shared-task-control-plane-and-lifecycle-events.md](../runtime-orchestration/tasks/shared-task-control-plane-and-lifecycle-events.md).

This distinction is important for reconstruction because Claude Code is not just a bundle of file and shell tools. It is also a runtime that can reconfigure itself while work is in progress.

## Test Design

In the observed source, agent and task-control behavior is verified through tool-contract regressions, shared-state integration tests, and interactive or automation control scenarios.

Equivalent coverage should prove:

- input shaping, launch routing, legacy-bridge rules, and control semantics stay aligned across the tool contracts described here
- shared team or task state, forwarded control, and scheduling boundaries behave correctly across main sessions, workers, and delegated flows
- users and clients can still spawn, steer, stop, list, and inspect work through the same real control surfaces the product exposes
