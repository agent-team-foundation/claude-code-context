---
title: "Agent and Task Control"
owners: []
---

# Agent and Task Control

This subdomain captures the control-plane tools that mutate runtime state, schedule work, manage task state, or choose a delegated execution path.

Relevant leaves:

- **[control-plane-tools.md](control-plane-tools.md)** — Tools that mutate runtime state, teams, tasks, or execution modes.
- **[task-and-team-control-tool-contracts.md](task-and-team-control-tool-contracts.md)** — Transactional contracts for task creation, task updates, ownership routing, and team initialization.
- **[task-stop-and-output-legacy-compatibility.md](task-stop-and-output-legacy-compatibility.md)** — Canonical task stop/output behavior, deprecated aliases/parameters, notification side effects, and SDK closeout compatibility.
- **[todowrite-legacy-bridge-and-task-list-v2.md](todowrite-legacy-bridge-and-task-list-v2.md)** — How legacy `TodoWrite`, file-backed Task V2 tools, reminder nudges, shared task-list IDs, and UI watchers stay compatible during the migration.
- **[local-scheduled-prompt-tool-contracts.md](local-scheduled-prompt-tool-contracts.md)** — How local recurring and one-shot scheduled prompts stay separate from remote triggers, including durability and worker-boundary rules.
- **[remote-trigger-control-tool-contracts.md](remote-trigger-control-tool-contracts.md)** — How policy-gated remote trigger APIs expose list/get/create/update/run control without collapsing into local cron semantics.
- **[agent-tool-launch-routing.md](agent-tool-launch-routing.md)** — How the Agent tool chooses between teammate, fork, background, worktree, and remote execution paths.
- **[delegation-modes.md](delegation-modes.md)** — Plan mode, worktree mode, and delegated execution patterns.
