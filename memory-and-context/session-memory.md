---
title: "Session Memory"
owners: []
soft_links: [/memory-and-context/compaction-and-dream.md, /memory-and-context/durable-memory-recall-and-auto-memory.md, /memory-and-context/context-bootstrap.md, /memory-and-context/context-cache-and-invalidation.md, /runtime-orchestration/task-model.md, /platform-services/sync-and-managed-state.md]
---

# Session Memory

Claude Code maintains a session-scoped working memory that sits between the raw transcript and long-lived durable memory.

This layer should be reconstructed as an automatically maintained notes artifact with the following qualities:

- It is created lazily for a session and stored in a path that is isolated from normal project files.
- It is updated by background agent work so the main conversation loop does not block on every summary refresh.
- Updates are threshold-based. The system should wait for enough new context, enough tool activity, or a natural pause before rewriting the notes.
- The update path should avoid racing with active tool-heavy turns and should prefer stable boundaries where the extracted notes will remain coherent.
- The file should capture operationally useful summaries, unresolved threads, decisions, and handoff-ready context rather than duplicating the full transcript.

## Isolation model

A faithful rebuild should preserve strong isolation for the updater:

- upkeep runs in a forked or otherwise isolated helper so the main conversation loop stays responsive
- that helper should be allowed to edit only the exact session-memory artifact, not arbitrary project files
- the session-memory refresh should surface as maintenance work that can be observed or deferred without looking like ordinary foreground assistant output

## Output contract

Equivalent behavior should preserve:

- bounded rewrite frequency based on thresholds rather than on every turn
- durable placement in session-specific storage so reset and resume can find the latest working note
- enough structure to support later handoff, review, or resume without pretending to be a full transcript

Session memory is distinct from both compaction and durable memory:

- **compaction** reduces context pressure inside the active conversation window
- **session memory** keeps a rolling working summary for the current session
- **durable memory** preserves facts meant to survive across many sessions

Without this middle layer, resume flows, review flows, and long-running collaborative sessions become much harder to recover cleanly.
