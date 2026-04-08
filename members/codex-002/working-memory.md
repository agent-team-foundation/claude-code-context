---
title: "Codex-002 Working Memory"
owners: [bingran-you]
soft_links:
  - /members/NODE.md
  - /reconstruction-guardrails/rebuild-standard.md
  - /integrations/NODE.md
  - /collaboration-and-agents/NODE.md
  - /ui-and-experience/NODE.md
  - /memory-and-context/NODE.md
---

# Codex-002 Working Memory

This leaf is the repo-backed snapshot of Codex-002's local workspace memory. It is kept here so later sessions can recover member-specific context directly from the tree instead of depending on one local checkout.

## Stable Operating Context

- Treat `claude-code-context`, the `first-tree` skill/repo, and the local `claude-code-main` snapshot as the three baseline sources for reconstruction work.
- Prefer source-grounded audits over filename heuristics or memory-based guesses; when coverage is unclear, inspect the relevant source files directly.
- Keep the current phase scoped to tree/spec maintenance, member-memory sync, and validation design, not early Python rewrite implementation.
- Re-run `first-tree verify` after tree edits and use PR-based, narrowly scoped changes instead of broad mixed updates.
- Respect Slock task ownership; if another agent already owns a task or domain change, contribute analysis or verification rather than overlapping edits.

## Current Judgments

- `claude-code-context` currently has a valid `first-tree` structure and passes `first-tree verify`, so the main gaps are content-depth gaps rather than framework breakage.
- The strongest confirmed missing reconstruction contract is the CCR/container-side `upstreamproxy` path, which is distinct from the existing SSH auth-proxy leaf.
- Two likely under-specified areas for full behavioral reconstruction are quick-open/file-index semantics and structured diff renderer semantics.
- Several apparent gaps do not currently need duplicate leaves because the tree already covers them at the domain level, including voice, Vim mode, companion/buddy behavior, coordinator topology, and onboarding.
- Future validation design should prefer Claude Code's native test seams, fixtures, and behavior contracts as the primary oracle rather than demo-only parity claims.

## Local Memory Sources

- Local `MEMORY.md`
- `notes/context-tree.md`
- `notes/work-log.md`
- `notes/channels.md`

## Sync Rule

- When Codex-002's local memory changes in ways that matter to future tree-guided work, update this leaf as the repo-backed copy.
