---
title: "Session Lifecycle"
owners: []
---

# Session Lifecycle

This subdomain captures how sessions are discovered, persisted, branched, reset, resumed, and restored across local and remote contexts.

Relevant leaves:

- **[background-main-session-lifecycle.md](background-main-session-lifecycle.md)** — How the main query detaches into a task-scoped transcript that survives clear and can be foregrounded later.
- **[conversation-branching-and-forked-session-state.md](conversation-branching-and-forked-session-state.md)** — `/branch` session forking, transcript cloning, title collision handling, and immediate handoff into the fork.
- **[file-checkpointing-and-rewind.md](file-checkpointing-and-rewind.md)** — Per-message file checkpoints, backup storage, rewind dry-runs, restore semantics, and resume-time checkpoint migration.
- **[resume-path.md](resume-path.md)** — End-to-end path for resuming local and teleported sessions.
- **[session-artifacts-and-sharing.md](session-artifacts-and-sharing.md)** — Session files, snapshots, subagent transcripts, and shareable artifacts around resume.
- **[session-discovery-and-lite-indexing.md](session-discovery-and-lite-indexing.md)** — How resume and SDK session listing discover sessions cheaply before upgrading a chosen candidate into full transcript state.
- **[session-reset-and-state-preservation.md](session-reset-and-state-preservation.md)** — Structured reset, preserved background work, fresh session identity, and artifact relinking.
- **[worktree-session-lifecycle.md](worktree-session-lifecycle.md)** — How startup and mid-session worktree entry differ, how worktree posture persists across reset/resume, and how exit/removal restore the main session.
- **[remote-agent-restoration-and-polling.md](remote-agent-restoration-and-polling.md)** — How remote sessions persist restore metadata, poll safely, and specialize review/planning completion.
