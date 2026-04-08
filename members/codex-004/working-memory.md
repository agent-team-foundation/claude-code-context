---
title: "Codex-004 Working Memory"
owners: [bingran-you]
soft_links:
  - /members/NODE.md
  - /reconstruction-guardrails/rebuild-phasing.md
  - /tools-and-permissions/NODE.md
  - /memory-and-context/NODE.md
---

# Codex-004 Working Memory

This leaf is the repo-backed snapshot of Codex-004's workspace memory. It is kept here so later sessions can load member-specific context directly from the tree instead of depending on one local checkout.

## Stable Operating Context

- Use Slock task ownership as the default coordination primitive; avoid duplicating work on already claimed tasks.
- Treat `claude-code-context`, the `first-tree` skill/repo, and the local `claude-code-main` snapshot as the three baseline sources for rewrite-readiness work.
- Keep the current phase scoped to tree/spec maintenance and validation design, not early Python rewrite implementation.
- Prefer Claude Code's native test design, fixtures, seams, and behavior contracts as the primary oracle for future reconstruction validation.

## Current Judgments

- `claude-code-context` already has broad domain coverage and working first-tree structure, so it can act as the reconstruction skeleton.
- The tree is not yet an executable verification spec; capability matrices, acceptance rules, provenance fields, and native-test-derived validation assets still need to be made explicit.
- The local `claude-code-main` snapshot exposes useful testing seams such as `TestingPermissionTool`, protocol schemas, and reset helpers, but does not currently present an obvious complete runnable upstream test suite entrypoint.
- Broad Python implementation work should wait until the tree can express go/no-go validation gates in a reusable, reviewable way.

## Active Collaboration Rules

- Keep `claude-code-context` changes narrow, PR-based, and consistent with the shared merge-train protocol.
- For non-owned work, prefer analysis, coverage, and verification over overlapping tree edits.
- The verification lane should keep using explicit provenance such as `test_asset_origin` and `native_ref` when test assets are reused from or derived from native/upstream tests.

## Sync Rule

- When Codex-004's local `MEMORY.md` changes in ways that matter to future tree-guided work, update this leaf as the repo-backed copy.
