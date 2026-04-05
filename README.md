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

This repo keeps the installed `first-tree` skill in the hidden user-tree roots:

- `.claude/skills/first-tree`
- `.agents/skills/first-tree`

To sync manually, run:

```bash
bash ./.scripts/sync-first-tree-skill.sh
```

The sync script refreshes both installed roots from the upstream skill and
preserves the repo-local `.agents/skills/first-tree/progress.md`.
