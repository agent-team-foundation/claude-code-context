---
title: "Session Artifacts and Sharing"
owners: []
soft_links: [/runtime-orchestration/resume-path.md, /runtime-orchestration/session-discovery-and-lite-indexing.md, /runtime-orchestration/session-reset-and-state-preservation.md, /runtime-orchestration/worktree-session-lifecycle.md, /product-surface/session-utility-commands.md, /memory-and-context/context-lifecycle-and-failure-modes.md, /collaboration-and-agents/remote-handoff-path.md]
---

# Session Artifacts and Sharing

Resume and handoff depend on a richer session artifact set than a plain chat log.

Artifacts that matter for reconstruction:

- a primary per-session transcript stored as an append-oriented artifact
- lightweight index entries that can be listed quickly and upgraded to full logs on demand
- snapshots attached to the session timeline for things like mode, file-history state, attribution state, worktree state, and similar restore-critical context
- worktree-state entries following a last-wins contract so resume can tell whether the session most recently entered or exited its alternate checkout
- lineage metadata that explains when a fresh session ID replaced an older one during a structured reset
- live output bindings for preserved background tasks that may need relinking after reset
- subordinate transcripts for subagents or teammates that ran beside the main session, without promoting them automatically to top-level resumable sessions
- optional user-facing metadata such as custom titles, tags, branch hints, remote identity, and PR-related associations

Reconstruction requirements:

- Session discovery should be fast enough to drive a picker or search flow without loading every full transcript eagerly.
- Full recovery must be able to rebuild a resumable conversation from indexed artifacts plus the underlying transcript and snapshot chain.
- Same-repo worktrees should participate in session discovery, but cross-project resume must be explicit and guarded.
- Reset and resume need enough artifact structure to preserve background-task continuity without letting cleared foreground transcripts bleed forward.
- Shareable artifacts should be treated as a separate export path, not as a synonym for ordinary resume. Consent, redaction, size limits, and inclusion of subagent material all matter.
- In builds where a direct `/share`-style command is hidden, stubbed, or feature-gated, the topology should still preserve the concept of session sharing as an optional capability rather than a guaranteed baseline surface.

The key clean-room insight is that session continuity comes from a bundle of artifacts. Transcript text alone is not enough to recreate the user-visible state of a prior Claude Code session.
