---
title: "Task Runtime"
owners: []
---

# Task Runtime

This subdomain captures the shared control plane and concrete runtime behavior for background work, worker tasks, and visible task records.

Relevant leaves:

- **[task-model.md](task-model.md)** — Background work and long-running task lifecycle.
- **[shared-task-control-plane-and-lifecycle-events.md](shared-task-control-plane-and-lifecycle-events.md)** — Shared task IDs, registration/replacement rules, generic stop/poll/eviction behavior, and SDK lifecycle bookends.
- **[task-registry-and-visibility.md](task-registry-and-visibility.md)** — Canonical local task records, family-specific identity, and the derived surfaces that make work visible.
- **[task-output-persistence-and-streaming.md](task-output-persistence-and-streaming.md)** — The single output owner, session-stable task files, shared polling, and bounded readback model.
- **[background-shell-task-lifecycle.md](background-shell-task-lifecycle.md)** — How shell tasks register, background in place, notify exactly once, and stop safely.
- **[monitor-task-families-and-watch-lifecycle.md](monitor-task-families-and-watch-lifecycle.md)** — How monitor-style shell tasks and monitor-MCP tasks diverge in entry guards, urgency, teardown, and UI partitioning.
- **[local-agent-task-lifecycle.md](local-agent-task-lifecycle.md)** — How local subagents register early, background in place, retain transcript state, and notify without duplicate starts.
- **[foregrounded-worker-steering.md](foregrounded-worker-steering.md)** — How viewed workers redirect prompt input, bootstrap transcripts, and retarget mailbox attachments.
- **[shared-task-list-contract.md](shared-task-list-contract.md)** — File-backed task-list storage, claiming, watcher pickup, and the summary model for team work queues.
- **[dream-task-visibility.md](dream-task-visibility.md)** — How auto-dream work becomes a UI-visible task without entering the normal model-facing notification path.
