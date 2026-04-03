---
title: "Runtime Orchestration"
owners: []
soft_links: [/tools-and-permissions, /memory-and-context]
---

# Runtime Orchestration

This domain captures the core assembly logic that turns a prompt, a tool registry, and session state into an agentic coding loop.

Relevant leaves:

- **[query-loop.md](query-loop.md)** — The streaming turn engine and its recovery paths.
- **[query-recovery-and-continuation.md](query-recovery-and-continuation.md)** — The precise recovery ladder for compaction, overflow, truncation, and continuation.
- **[turn-assembly-and-recovery.md](turn-assembly-and-recovery.md)** — The full turn envelope from context assembly through tool batches, recovery branches, and persistence.
- **[turn-attachments-and-sidechannels.md](turn-attachments-and-sidechannels.md)** — The post-tool attachment drain, queued prompts, memory/skill sidechannels, and recursion control signals.
- **[task-model.md](task-model.md)** — Background work and long-running task lifecycle.
- **[session-artifacts-and-sharing.md](session-artifacts-and-sharing.md)** — The session files, snapshots, subagent transcripts, and shareable artifacts around resume.
- **[build-profiles.md](build-profiles.md)** — Feature gates and environment-specific capability envelopes.
- **[state-machines-and-failures.md](state-machines-and-failures.md)** — Turn, task, and runtime transition model with the main failure classes.
- **[review-path.md](review-path.md)** — End-to-end path for local review and remote ultrareview-style flows.
- **[resume-path.md](resume-path.md)** — End-to-end path for resuming local and teleported sessions.
