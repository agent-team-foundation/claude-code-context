---
title: "Interaction Modes"
owners: []
soft_links: [/runtime-orchestration/query-loop.md, /tools-and-permissions/delegation-modes.md]
---

# Interaction Modes

Claude Code is a terminal-first coding agent, but it is not just a chat REPL.

The product surface should support at least these operating modes:

- Interactive REPL for day-to-day coding work, with streaming output and tool progress.
- Non-interactive and structured-output entry paths for automation, scripts, and SDK consumers.
- Session continuation flows such as resume, export, share, and branch-aware recovery.
- Behavior toggles that change how the agent works without changing the core runtime, such as model selection, effort level, fast mode, output style, and compactness.
- Focused task modes, including planning-oriented turns, worktree-isolated work, reviews, context inspection, and memory-focused operations.

The important design choice is that one runtime serves many surfaces. New modes should reuse the same conversation, tool, and state machinery rather than fork entirely separate implementations.
