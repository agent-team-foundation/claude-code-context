---
title: "claude-code-context"
owners: [bingran-you]
soft_links: [/NODE.md, /reconstruction-guardrails]
---

# claude-code-context

Context Tree for reconstructing Claude Code from capability, architecture, and behavior specifications without mirroring source code.

Start with [NODE.md](NODE.md). This repository intentionally stores:

- product behavior and user-visible capability boundaries
- runtime, tool, memory, integration, and collaboration contracts
- reconstruction guidance for building an equivalent system from scratch

This repository intentionally does not store:

- source files, source snippets, or prompt bodies copied from the analyzed codebase
- proprietary strings, secrets, internal codenames, or implementation-only detail
- repo-by-repo file inventories that would turn the tree into a source mirror

Local analysis-only inputs such as raw source snapshots should live under hidden paths like `.analysis/` so `context-tree verify` continues to validate the tree itself rather than auxiliary research material.

## Installed skill

This repo keeps the canonical installed `first-tree` skill at:

- `skills/first-tree`

Compatibility mirrors are also kept in sync for local agent tooling:

- `.claude/skills/first-tree`
- `.agents/skills/first-tree`

To sync manually, run:

```bash
bash ./.scripts/sync-first-tree-skill.sh
```

The sync script refreshes `skills/first-tree/` from the upstream skill and then updates the compatibility mirrors without clobbering the repo-local `skills/first-tree/progress.md`.

GitHub Actions also runs `.github/workflows/sync-first-tree-skill.yml` on a schedule and supports manual triggering.
