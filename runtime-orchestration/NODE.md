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
- **[scheduled-prompts-and-cron-lifecycle.md](scheduled-prompts-and-cron-lifecycle.md)** — How local scheduled prompts, `/loop`, cron persistence, jitter, multi-session ownership, and missed-task catch-up behave as one runtime subsystem.
- **[shared-task-list-contract.md](shared-task-list-contract.md)** — File-backed task-list storage, claiming, watcher pickup, and the user-facing summary model for team work queues.
- **[background-shell-task-lifecycle.md](background-shell-task-lifecycle.md)** — How shell tasks register, background in place, notify exactly once, and stop safely.
- **[local-agent-task-lifecycle.md](local-agent-task-lifecycle.md)** — How local subagents register early, background in place, retain transcript state, and notify without duplicate starts.
- **[foregrounded-worker-steering.md](foregrounded-worker-steering.md)** — How viewed workers redirect prompt input, bootstrap transcripts, and retarget mailbox attachments.
- **[prompt-suggestion-and-speculation.md](prompt-suggestion-and-speculation.md)** — How leader-only next-input suggestions are generated, filtered, optionally pre-executed in overlays, and accepted or aborted.
- **[background-main-session-lifecycle.md](background-main-session-lifecycle.md)** — How the main query detaches into a task-scoped transcript that survives clear and can be foregrounded later.
- **[remote-agent-restoration-and-polling.md](remote-agent-restoration-and-polling.md)** — How remote sessions persist restore metadata, poll safely, and specialize review or planning completion.
- **[dream-task-visibility.md](dream-task-visibility.md)** — How auto-dream work becomes a UI-visible task without entering the normal model-facing notification path.
- **[task-output-persistence-and-streaming.md](task-output-persistence-and-streaming.md)** — The single output owner, session-stable task files, shared polling, and bounded readback model.
- **[session-artifacts-and-sharing.md](session-artifacts-and-sharing.md)** — The session files, snapshots, subagent transcripts, and shareable artifacts around resume.
- **[build-profiles.md](build-profiles.md)** — Feature gates and environment-specific capability envelopes.
- **[state-machines-and-failures.md](state-machines-and-failures.md)** — Turn, task, and runtime transition model with the main failure classes.
- **[review-path.md](review-path.md)** — End-to-end path for local review and remote ultrareview-style flows.
- **[resume-path.md](resume-path.md)** — End-to-end path for resuming local and teleported sessions.
