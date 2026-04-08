---
title: "Codex-001 Working Memory"
owners: [bingran-you]
soft_links:
  - /members/NODE.md
  - /reconstruction-guardrails/rebuild-standard.md
  - /product-surface/NODE.md
  - /platform-services/NODE.md
  - /runtime-orchestration/NODE.md
  - /members/codex-001/NODE.md
---

# Codex-001 Working Memory

This leaf is the repo-backed snapshot of Codex-001's local workspace memory. It is kept here so later sessions can recover member-specific context directly from the tree instead of depending on one local checkout.

## Stable Operating Context

- Treat `claude-code-context`, the latest `first-tree` skill/repo, and the local `claude-code-main` snapshot as the three baseline sources for reconstruction work.
- Keep the tree clean-room: capture behavioral contracts, boundaries, and cross-domain relationships, but do not mirror source layout or copy implementation detail that only matters inside the original codebase.
- Prefer one narrow, source-backed gap per PR over broad mixed refactors; rebase onto latest `origin/main` before opening or merging each PR.
- Re-run `node ../first-tree/dist/cli.js verify` after tree edits and before merge.
- Use concise Chinese thread updates in Slock for in-flight progress on the long-running `claude-code-context` task.
- Respect task ownership and avoid overlapping with other agents' active PR slices.

## Current Judgments

- `claude-code-context` currently has a sound `first-tree` structure; the main problem is uneven reconstruction-critical depth, not framework breakage.
- The strongest recent improvements from this workspace have been narrow product-surface and workflow-alignment PRs rather than broad domain reshuffles.
- Landed milestones from this maintenance loop include:
  - `#133` aligning tree-instruction and source-snapshot handling with the current `first-tree` workflow
  - `#134` adding `product-surface/auxiliary-local-command-surfaces.md`
  - `#138` adding `product-surface/agent-management-surface.md`
  - `#140` adding `product-surface/local-stats-surface.md`
- The next useful step should again be a single-theme, source-backed gap rather than a percentage-style re-audit or a speculative broad rewrite.

## Local Memory Sources

- Local `MEMORY.md`
- `notes/work-log.md`
- `notes/channels.md`
- `notes/domain-claude-code-context.md`

## Sync Rule

- When Codex-001's local memory changes in ways that materially help future `claude-code-context` maintenance, update this leaf as the repo-backed copy.
