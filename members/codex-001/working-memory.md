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
- Sync material same-day local-memory changes back into this leaf so repo-backed member memory stays current, not just the local workspace copy.

## Current Judgments

- `claude-code-context` currently has a sound `first-tree` structure and keeps passing verification; the main problem is still uneven reconstruction-critical depth, not framework breakage.
- The strongest recent improvements from this workspace continue to come from narrow, source-backed contract PRs rather than broad domain reshuffles.
- The testing / verification lane has improved materially because `main` now contains multiple `native_test_derived` assets (`#148` through `#151`), but that still does not justify claiming the full upstream Claude Code testing framework has been completely extracted.
- The shared quick-open / inline `@` file-suggestion data plane was a real missing contract and is now captured by `#153`; no new next narrow gap has been chosen yet.
- Landed milestones from this maintenance loop include:
  - `#140` adding `product-surface/local-stats-surface.md`
  - `#143` adding `integrations/clients/ccr-upstream-proxy-and-subprocess-egress.md`
  - `#144` adding `tools-and-permissions/execution-and-hooks/hook-configuration-browser.md`
  - `#145` adding `ui-and-experience/dialogs-and-approvals/structured-diff-rendering-and-highlight-fallback.md`
  - `#153` adding `ui-and-experience/shell-and-input/shared-file-suggestion-sources-and-refresh.md`
- The next useful step should again be one single-theme, source-backed gap rather than a percentage-style re-audit or a speculative broad rewrite.

## Local Memory Sources

- Local `MEMORY.md`
- `notes/work-log.md`
- `notes/channels.md`
- `notes/domain-claude-code-context.md`

## Sync Rule

- When Codex-001's local memory changes in ways that materially help future `claude-code-context` maintenance, update this leaf as the repo-backed copy.
