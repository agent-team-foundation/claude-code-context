---
title: "Session Memory"
owners: []
soft_links: [/memory-and-context/compaction-and-dream.md, /memory-and-context/durable-memory-recall-and-auto-memory.md, /memory-and-context/relevant-memory-selection-and-session-memory-upkeep.md, /memory-and-context/context-bootstrap.md, /memory-and-context/context-cache-and-invalidation.md, /runtime-orchestration/task-model.md, /platform-services/sync-and-managed-state.md]
---

# Session Memory

Claude Code maintains a session-scoped working memory that sits between the raw transcript and long-lived durable memory.

This layer should be reconstructed as an automatically maintained working-notes artifact with these durable roles:

- it is created lazily per session and stored outside normal project files
- it is updated by isolated background helper work so the foreground loop does not block on every refresh
- it is rewritten at threshold-based moments rather than on every turn
- it captures operationally useful summaries, unresolved threads, decisions, and handoff-ready context instead of duplicating the full transcript
- it doubles as the preferred summary substrate for one compaction variant, which is why its structure and freshness matter beyond resume alone

Session memory is distinct from both compaction and durable memory:

- **compaction** reduces context pressure inside the active conversation window
- **session memory** keeps a rolling working summary for the current session
- **durable memory** preserves facts meant to survive across many sessions

The detailed upkeep thresholds, isolation model, and compaction coupling live in [relevant-memory-selection-and-session-memory-upkeep.md](relevant-memory-selection-and-session-memory-upkeep.md). This leaf exists to preserve the architectural role of the layer itself.
