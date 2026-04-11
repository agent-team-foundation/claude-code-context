---
title: "Delegation Modes"
owners: []
soft_links: [/collaboration-and-agents/multi-agent-topology.md, /runtime-orchestration/tasks/task-model.md]
---

# Delegation Modes

Claude Code distinguishes between doing work directly and setting up safer execution contexts for work.

Important modes:

- Plan mode emphasizes analysis, scoping, and user alignment before edits.
- Worktree mode creates isolation for changes that should not share a mutable checkout.
- Delegated agent work runs through explicit worker or team constructs with narrower tool availability and different prompt expectations.

These modes are not separate products. They are overlays on the same runtime and should preserve the same message, tool, and permission semantics.

## Test Design

In the observed source, agent and task-control behavior is verified through tool-contract regressions, shared-state integration tests, and interactive or automation control scenarios.

Equivalent coverage should prove:

- input shaping, launch routing, legacy-bridge rules, and control semantics stay aligned across the tool contracts described here
- shared team or task state, forwarded control, and scheduling boundaries behave correctly across main sessions, workers, and delegated flows
- users and clients can still spawn, steer, stop, list, and inspect work through the same real control surfaces the product exposes
