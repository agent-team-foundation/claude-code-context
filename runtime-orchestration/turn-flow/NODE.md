---
title: "Turn Flow"
owners: []
---

# Turn Flow

This subdomain captures what happens inside one active model turn: request shaping, queue draining, tool/result integration, and recovery when the turn goes wrong.

Relevant leaves:

- **[query-loop.md](query-loop.md)** — The streaming turn engine and its recovery paths.
- **[api-request-assembly-retry-and-prompt-cache-stability.md](api-request-assembly-retry-and-prompt-cache-stability.md)** — How one turn becomes one or more model requests, including tool filtering, retry/fallback policy, and prompt-cache break control.
- **[query-recovery-and-continuation.md](query-recovery-and-continuation.md)** — The recovery ladder for compaction, overflow, truncation, and continuation.
- **[turn-assembly-and-recovery.md](turn-assembly-and-recovery.md)** — The full turn envelope from context assembly through tool batches, recovery branches, and persistence.
- **[turn-attachments-and-sidechannels.md](turn-attachments-and-sidechannels.md)** — The post-tool attachment drain, queued prompts, memory/skill sidechannels, and recursion control signals.
- **[unified-command-queue-and-drain.md](unified-command-queue-and-drain.md)** — How the shared command queue mediates busy input, between-turn draining, mid-turn attachments, headless batching, and agent-scoped delivery.
- **[queued-command-projection-and-replay.md](queued-command-projection-and-replay.md)** — How one queued item becomes preview rows, transcript attachments, replayed user events, remote delivery state, and non-rewindable synthetic prompt history.
- **[stop-hook-orchestration-and-turn-end-bookkeeping.md](stop-hook-orchestration-and-turn-end-bookkeeping.md)** — Stop-hook execution outcomes, API-error stop-failure fallback, and the turn-end sidework that runs around hook evaluation.
