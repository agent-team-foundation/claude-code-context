---
title: "Filesystem and Shell"
owners: []
---

# Filesystem and Shell

This subdomain captures the shared contracts for local file access, notebook mutation, path safety, and shell execution.

Relevant leaves:

- **[path-and-filesystem-safety.md](path-and-filesystem-safety.md)** — Working-directory boundaries, protected files, internal harness paths, and shell path validators.
- **[file-read-write-edit-and-notebook-consistency.md](file-read-write-edit-and-notebook-consistency.md)** — Shared read-state invariants, native media/notebook branches, atomic text edits, full-file writes, and notebook-cell mutation rules.
- **[shell-execution-and-backgrounding.md](shell-execution-and-backgrounding.md)** — How shell tools stream, background, reuse tasks, and stay responsive in assistant mode.
- **[shell-command-parsing-and-classifier-flow.md](shell-command-parsing-and-classifier-flow.md)** — How trustworthy shell structure, fallback parsing, compound-command suggestions, and speculative Bash auto-approval interact before execution.
- **[shell-rule-grammar-and-matching.md](shell-rule-grammar-and-matching.md)** — The shared exact/prefix/wildcard rule grammar and the Bash/PowerShell normalization rules around it.
- **[sed-command-validation-contracts.md](sed-command-validation-contracts.md)** — Testable contracts for sed command validation (allowlist/denylist patterns), with acceptance criteria for Python reconstruction.
