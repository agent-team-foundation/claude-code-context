---
title: "Runtime Orchestration"
owners: []
soft_links: [/tools-and-permissions, /memory-and-context]
---

# Runtime Orchestration

This domain captures the core assembly logic that turns a prompt, a tool registry, and session state into an agentic coding loop.

Relevant leaves:

- **[query-loop.md](query-loop.md)** — The streaming turn engine and its recovery paths.
- **[api-request-assembly-retry-and-prompt-cache-stability.md](api-request-assembly-retry-and-prompt-cache-stability.md)** — How one turn becomes one or more model requests, including tool filtering, beta/header latching, retry or fallback policy, and prompt-cache break control.
- **[query-recovery-and-continuation.md](query-recovery-and-continuation.md)** — The precise recovery ladder for compaction, overflow, truncation, and continuation.
- **[turn-assembly-and-recovery.md](turn-assembly-and-recovery.md)** — The full turn envelope from context assembly through tool batches, recovery branches, and persistence.
- **[turn-attachments-and-sidechannels.md](turn-attachments-and-sidechannels.md)** — The post-tool attachment drain, queued prompts, memory/skill sidechannels, and recursion control signals.
- **[unified-command-queue-and-drain.md](unified-command-queue-and-drain.md)** — How the shared command queue mediates busy input, between-turn draining, mid-turn attachments, headless batching, and agent-scoped delivery.
- **[queued-command-projection-and-replay.md](queued-command-projection-and-replay.md)** — How one queued item becomes preview rows, transcript attachments, replayed user events, remote delivery state, and non-rewindable synthetic prompt history.
- **[proactive-assistant-loop-and-brief-mode.md](proactive-assistant-loop-and-brief-mode.md)** — How assistant mode, proactive ticks, BriefTool, and startup team bootstrap create a persistent autonomous posture.
- **[task-model.md](task-model.md)** — Background work and long-running task lifecycle.
- **[shared-task-control-plane-and-lifecycle-events.md](shared-task-control-plane-and-lifecycle-events.md)** — Shared task IDs, registration and replacement rules, generic stop or poll or eviction behavior, and SDK lifecycle bookends across task families.
- **[workflow-script-runtime.md](workflow-script-runtime.md)** — How workflow definitions become badged commands, bootstrap bundled flows, run as background workflow tasks, emit phase progress, and clean up workflow worktrees.
- **[app-state-and-input-routing.md](app-state-and-input-routing.md)** — Central app-state partitions, routed input targeting, metadata projection, and write-through side effects.
- **[task-registry-and-visibility.md](task-registry-and-visibility.md)** — Canonical local task records, family-specific identity, and the derived surfaces that make work visible.
- **[scheduled-prompts-and-cron-lifecycle.md](scheduled-prompts-and-cron-lifecycle.md)** — How local scheduled prompts, `/loop`, cron persistence, jitter, multi-session ownership, and missed-task catch-up behave as one runtime subsystem.
- **[remote-scheduled-agents-and-trigger-management.md](remote-scheduled-agents-and-trigger-management.md)** — How cloud-side scheduled agents, trigger APIs, `/schedule`, environment selection, and connector setup stay distinct from local cron.
- **[shared-task-list-contract.md](shared-task-list-contract.md)** — File-backed task-list storage, claiming, watcher pickup, and the user-facing summary model for team work queues.
- **[background-shell-task-lifecycle.md](background-shell-task-lifecycle.md)** — How shell tasks register, background in place, notify exactly once, and stop safely.
- **[monitor-task-families-and-watch-lifecycle.md](monitor-task-families-and-watch-lifecycle.md)** — How monitor-style shell tasks and monitor-MCP tasks diverge in entry guards, notification urgency, teardown, and UI partitioning.
- **[local-agent-task-lifecycle.md](local-agent-task-lifecycle.md)** — How local subagents register early, background in place, retain transcript state, and notify without duplicate starts.
- **[foregrounded-worker-steering.md](foregrounded-worker-steering.md)** — How viewed workers redirect prompt input, bootstrap transcripts, and retarget mailbox attachments.
- **[prompt-suggestion-and-speculation.md](prompt-suggestion-and-speculation.md)** — How leader-only next-input suggestions are generated, filtered, optionally pre-executed in overlays, and accepted or aborted.
- **[background-main-session-lifecycle.md](background-main-session-lifecycle.md)** — How the main query detaches into a task-scoped transcript that survives clear and can be foregrounded later.
- **[session-reset-and-state-preservation.md](session-reset-and-state-preservation.md)** — Structured reset, preserved background work, fresh session identity, and artifact relinking.
- **[session-discovery-and-lite-indexing.md](session-discovery-and-lite-indexing.md)** — How resume and SDK session listing discover sessions cheaply, across worktrees, before upgrading a chosen candidate into full transcript state.
- **[remote-agent-restoration-and-polling.md](remote-agent-restoration-and-polling.md)** — How remote sessions persist restore metadata, poll safely, and specialize review or planning completion.
- **[dream-task-visibility.md](dream-task-visibility.md)** — How auto-dream work becomes a UI-visible task without entering the normal model-facing notification path.
- **[task-output-persistence-and-streaming.md](task-output-persistence-and-streaming.md)** — The single output owner, session-stable task files, shared polling, and bounded readback model.
- **[session-artifacts-and-sharing.md](session-artifacts-and-sharing.md)** — The session files, snapshots, subagent transcripts, and shareable artifacts around resume.
- **[worktree-session-lifecycle.md](worktree-session-lifecycle.md)** — How startup and mid-session worktree entry differ, how worktree posture persists across reset and resume, and how exit/removal safely restore the main session.
- **[conversation-branching-and-forked-session-state.md](conversation-branching-and-forked-session-state.md)** — `/branch` session forking, transcript cloning, title collision handling, content-replacement preservation, and immediate handoff into the fork.
- **[build-profiles.md](build-profiles.md)** — Feature gates and environment-specific capability envelopes.
- **[state-machines-and-failures.md](state-machines-and-failures.md)** — Turn, task, and runtime transition model with the main failure classes.
- **[remote-planning-session-loop.md](remote-planning-session-loop.md)** — How the gated remote-planning flow launches a remote plan-mode session, polls approval artifacts, and splits into remote execution or local handoff.
- **[review-path.md](review-path.md)** — End-to-end path for local review and remote ultrareview-style flows.
- **[resume-path.md](resume-path.md)** — End-to-end path for resuming local and teleported sessions.
- **[file-checkpointing-and-rewind.md](file-checkpointing-and-rewind.md)** — Per-message file checkpoints, backup storage, rewind dry-runs, restore semantics, and resume-time checkpoint migration.
- **[stop-hook-orchestration-and-turn-end-bookkeeping.md](stop-hook-orchestration-and-turn-end-bookkeeping.md)** — Stop-hook execution outcomes, API-error stop-failure fallback, and the turn-end sidework that runs around hook evaluation.
