---
title: "Codex-003 Working Memory"
owners: [bingran-you]
soft_links:
  - /members/NODE.md
  - /reconstruction-guardrails/rebuild-phasing.md
  - /memory-and-context/NODE.md
  - /runtime-orchestration/tasks/task-model.md
---

# Codex-003 Working Memory

This leaf is the repo-backed snapshot of Codex-003's workspace memory. It is kept here so later sessions can reload member-specific context directly from the tree instead of depending on one local checkout.

## Stable Operating Context

- Use Slock task ownership as the default coordination primitive; do not duplicate work on already claimed tasks.
- Treat `claude-code-context`, the `first-tree` skill/repo, and the local `claude-code-main` snapshot as the three baseline sources for rewrite-readiness work.
- Keep the current phase scoped to tree/spec maintenance and validation-asset extraction, not early Python rewrite implementation.
- Prefer Claude Code's native test design, fixtures, seams, and behavior contracts as the primary oracle for future reconstruction validation.
- Keep `first-tree init` and default onboarding credential-free; any model-backed PR review or key setup should remain an explicit follow-up path.

## Current Judgments

- `claude-code-context` is good enough to act as the reconstruction skeleton, but not yet explicit enough to serve as an executable verification spec or TCK.
- Shared rewrite work should be driven by capability matrices, provenance fields, and native-test-derived acceptance assets rather than coverage-looking prose alone.
- The local Claude Code snapshot exposes useful testing seams and schema contracts, but it does not yet present an obvious directly runnable full upstream test suite entrypoint.
- Generic `first-tree init` and `first-tree upgrade` flows can overwrite custom shared-tree integrations; preserve bespoke bindings when a workspace depends on a repo-subpath tree layout.

## Active Collaboration Rules

- Keep PRs narrow and single-purpose, with source mapping, coverage delta, `first-tree verify`, and open-risk notes whenever applicable.
- Report progress in the owning task thread; for non-owned domains, stick to analysis, coverage, or verification unless a side task is explicitly split out.
- When local `MEMORY.md` or notes change in ways that matter to future shared work, sync the durable parts into this leaf.

## Recent Cross-Workspace State

- `first-tree` now keeps core init and onboarding credential-free; model-backed review flows remain follow-up work rather than default bootstrap behavior.
- The `kael-frontend` integration depends on a custom `first-tree-context/kael` binding, so future refreshes there should preserve the custom source and workspace contract instead of blindly rerunning generic install flows.
