---
title: "Session Artifacts and Sharing"
owners: []
soft_links: [/runtime-orchestration/resume-path.md, /memory-and-context/context-lifecycle-and-failure-modes.md, /collaboration-and-agents/remote-handoff-path.md]
---

# Session Artifacts and Sharing

Resume and handoff depend on a richer session artifact set than a plain chat log.

Artifacts that matter for reconstruction:

- a primary per-session transcript stored as an append-oriented artifact
- lightweight index entries that can be listed quickly and upgraded to full logs on demand
- snapshots attached to the session timeline for things like mode, file-history state, attribution state, worktree state, and similar restore-critical context
- subordinate transcripts for subagents or teammates that ran beside the main session
- optional user-facing metadata such as custom titles, tags, branch hints, and PR-related associations

Reconstruction requirements:

- Session discovery should be fast enough to drive a picker or search flow without loading every full transcript eagerly.
- Full recovery must be able to rebuild a resumable conversation from indexed artifacts plus the underlying transcript and snapshot chain.
- Same-repo worktrees should participate in session discovery, but cross-project resume must be explicit and guarded.
- Shareable artifacts should be treated as a separate export path, not as a synonym for ordinary resume. Consent, redaction, size limits, and inclusion of subagent material all matter.
- In builds where a direct `/share`-style command is hidden, stubbed, or feature-gated, the topology should still preserve the concept of session sharing as an optional capability rather than a guaranteed baseline surface.

The key clean-room insight is that session continuity comes from a bundle of artifacts. Transcript text alone is not enough to recreate the user-visible state of a prior Claude Code session.
