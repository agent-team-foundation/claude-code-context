---
title: "Runtime Orchestration"
owners: []
soft_links: [/tools-and-permissions, /memory-and-context]
---

# Runtime Orchestration

This domain captures the core assembly logic that turns a prompt, a tool registry, and session state into an agentic coding loop.

Subdomains:

- **[turn-flow/](turn-flow/NODE.md)** — One-turn request assembly, command intake, tool/result handling, and recovery around the active query.
- **[tasks/](tasks/NODE.md)** — Shared task records, lifecycle events, visibility, output persistence, and task-family runtime behavior.
- **[sessions/](sessions/NODE.md)** — Session artifacts, branching, resume, reset, worktree posture, and remote restoration.
- **[automation/](automation/NODE.md)** — Persistent assistant posture, workflow runners, scheduled prompts, remote planning, and review-style runtime paths.
- **[state/](state/NODE.md)** — App-state partitions, build capability envelopes, and the runtime failure/state-machine model.
