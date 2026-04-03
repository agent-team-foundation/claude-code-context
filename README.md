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
