---
title: "Product Surface"
owners: []
soft_links: [/runtime-orchestration, /ui-and-experience]
---

# Product Surface

This domain captures how Claude Code presents itself to users: entry modes, command families, and the high-level capability map visible from the terminal.

Relevant leaves:

- **[interaction-modes.md](interaction-modes.md)** — The major ways a user can operate the product.
- **[command-surface.md](command-surface.md)** — How commands are grouped and what each group must expose.
- **[model-and-behavior-controls.md](model-and-behavior-controls.md)** — How `/model`, `/effort`, `/fast`, `/theme`, `/color`, and `/output-style` together control runtime model choice, effort, premium speed paths, and behavior styling.
- **[command-dispatch-and-composition.md](command-dispatch-and-composition.md)** — How one command registry composes built-ins, skills, plugins, workflows, and gated command variants into one surface.
- **[review-and-pr-automation-commands.md](review-and-pr-automation-commands.md)** — How `/review`, `/ultrareview`, `/commit-push-pr`, `/pr-comments`, `/security-review`, and the hidden `autofix-pr` stub divide local prompt expansion, remote review launch, plugin fallback, and GitHub automation behavior.
- **[session-utility-commands.md](session-utility-commands.md)** — Rename, tag, resume-adjacent, copy, export, and session-inspection commands that operate on session artifacts.
- **[session-state-and-breakpoints.md](session-state-and-breakpoints.md)** — User-visible session phases, mode transitions, and where interaction can fail or be deferred.
- **[command-runtime-matrix.md](command-runtime-matrix.md)** — How command families map onto runtime subsystems, tool families, and task types.
- **[end-to-end-scenario-graphs.md](end-to-end-scenario-graphs.md)** — Concrete user journey to command to runtime to tool or task to state-transition flows.
- **[init-command-and-claude-md-setup.md](init-command-and-claude-md-setup.md)** — The `/init` prompt-command contract, staged setup flow, and CLAUDE.md/CLAUDE.local.md loading and trust boundaries.
