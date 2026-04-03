---
title: "Session Memory"
owners: []
soft_links: [/memory-and-context/compaction-and-dream.md, /runtime-orchestration/task-model.md, /platform-services/sync-and-managed-state.md]
---

# Session Memory

Claude Code maintains a session-scoped working memory that sits between the raw transcript and long-lived durable memory.

This layer should be reconstructed as an automatically maintained notes artifact with the following qualities:

- It is created lazily for a session and stored in a path that is isolated from normal project files.
- It is updated by background agent work so the main conversation loop does not block on every summary refresh.
- Updates are threshold-based. The system should wait for enough new context, enough tool activity, or a natural pause before rewriting the notes.
- The update path should avoid racing with active tool-heavy turns and should prefer stable boundaries where the extracted notes will remain coherent.
- The file should capture operationally useful summaries, unresolved threads, decisions, and handoff-ready context rather than duplicating the full transcript.

Session memory is distinct from both compaction and durable memory:

- **compaction** reduces context pressure inside the active conversation window
- **session memory** keeps a rolling working summary for the current session
- **durable memory** preserves facts meant to survive across many sessions

Without this middle layer, resume flows, review flows, and long-running collaborative sessions become much harder to recover cleanly.
