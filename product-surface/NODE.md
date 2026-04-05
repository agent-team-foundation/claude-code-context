---
title: "Product Surface"
owners: []
soft_links: [/runtime-orchestration, /ui-and-experience]
---

# Product Surface

This domain captures how Claude Code presents itself to users: entry modes, command families, and the high-level capability map visible from the terminal.

Relevant leaves:

- **[interaction-modes.md](interaction-modes.md)** — The major ways a user can operate the product.
- **[command-surface.md](command-surface.md)** — How the shared command catalog is presented, narrowed, and made discoverable across help, init payloads, and related user-facing inventories.
- **[special-entrypoint-argv-rewrite-and-fullscreen-handoff.md](special-entrypoint-argv-rewrite-and-fullscreen-handoff.md)** — How direct-connect URLs, `assistant`, `ssh`, and hidden handoff commands are intercepted before ordinary subcommand dispatch and routed back into the main REPL or headless runner.
- **[model-and-behavior-controls.md](model-and-behavior-controls.md)** — How `/model`, `/effort`, `/fast`, `/theme`, `/color`, and `/output-style` together control runtime model choice, effort, premium speed paths, and behavior styling.
- **[command-dispatch-and-composition.md](command-dispatch-and-composition.md)** — How one command registry composes built-ins, skills, plugins, workflows, and gated command variants into one surface.
- **[prompt-command-and-skill-execution.md](prompt-command-and-skill-execution.md)** — How prompt-backed slash commands and SkillTool calls divide inline query re-entry, worker-backed fork execution, coordinator summaries, and turn-scoped permission or model overrides.
- **[review-and-pr-automation-commands.md](review-and-pr-automation-commands.md)** — How `/review`, `/ultrareview`, `/commit-push-pr`, `/pr-comments`, `/security-review`, and the hidden `autofix-pr` stub divide local prompt expansion, remote review launch, plugin fallback, and GitHub automation behavior.
- **[feedback-and-issue-commands.md](feedback-and-issue-commands.md)** — How `/feedback`, `/issue`, `/good-claude`, and reserved auto-run escalation paths divide public product feedback from narrower model-diagnostics flows.
- **[session-utility-commands.md](session-utility-commands.md)** — How rename, tag, copy, export, remote session inspection, and resume-adjacent commands expose session metadata, transcript extraction, and guarded continuation.
- **[session-state-and-breakpoints.md](session-state-and-breakpoints.md)** — User-visible session phases, mode transitions, and where interaction can fail or be deferred.
- **[command-runtime-matrix.md](command-runtime-matrix.md)** — How command families map onto runtime subsystems, tool families, and task types.
- **[end-to-end-scenario-graphs.md](end-to-end-scenario-graphs.md)** — Concrete user journey to command to runtime to tool or task to state-transition flows.
- **[init-command-and-claude-md-setup.md](init-command-and-claude-md-setup.md)** — The `/init` prompt-command contract, staged setup flow, and CLAUDE.md/CLAUDE.local.md loading and trust boundaries.
