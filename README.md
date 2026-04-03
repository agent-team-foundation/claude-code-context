---
title: "claude-code-context"
owners: []
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

## Synced skill

This repo mirrors the `first-tree-cli-framework` skill from the upstream `agent-team-foundation/first-tree` repository into:

- `skills/first-tree-cli-framework`
- `.claude/skills/first-tree-cli-framework`
- `.agents/skills/first-tree-cli-framework`

To sync manually, run:

```bash
bash ./scripts/sync-first-tree-skill.sh
```

GitHub Actions also runs `.github/workflows/sync-first-tree-skill.yml` on a schedule and supports manual triggering.
