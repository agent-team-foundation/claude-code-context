---
title: "Product Surface"
owners: []
soft_links: [/runtime-orchestration, /ui-and-experience]
---

# Product Surface

This domain captures how Claude Code presents itself to users: entry modes, command families, and the high-level capability map visible from the terminal.

Relevant leaves:

- **[interaction-modes.md](interaction-modes.md)** — How startup surface, autonomy posture, execution locality, and input targeting compose across local, headless, remote, and worker-steered sessions.
- **[command-surface.md](command-surface.md)** — How the admitted command record set is projected differently across `/help`, `/skills`, init payloads, SDK picker metadata, and narrowed bridge-facing inventories.
- **[startup-entrypoint-routing-and-session-handoff.md](startup-entrypoint-routing-and-session-handoff.md)** — How direct-connect URLs, `assistant`, `ssh`, and hidden handoff commands are intercepted before ordinary subcommand dispatch and routed back into the main REPL or headless runner.
- **[model-and-behavior-controls.md](model-and-behavior-controls.md)** — How `/model`, `/effort`, `/fast`, `/theme`, `/color`, and `/output-style` together control runtime model choice, effort, premium speed paths, and behavior styling.
- **[command-dispatch-and-composition.md](command-dispatch-and-composition.md)** — How the local command catalog, late dynamic skills, and session-scoped MCP overlay compose into one ordered slash surface.
- **[prompt-command-and-skill-execution.md](prompt-command-and-skill-execution.md)** — How prompt-backed slash commands and SkillTool calls divide inline query re-entry, worker-backed fork execution, coordinator summaries, and turn-scoped permission or model overrides.
- **[auxiliary-local-command-surfaces.md](auxiliary-local-command-surfaces.md)** — How local-only or feature-gated slash surfaces such as quick side-question flows and celebratory recap experiences stay outside the ordinary transcript-turn contract while still behaving like first-class product commands.
- **[agent-management-surface.md](agent-management-surface.md)** — How `/agents` exposes source-aware browsing, guided creation, structured editing, and override visibility for the live agent catalog without collapsing back into raw config files.
- **[review-and-pr-automation-commands.md](review-and-pr-automation-commands.md)** — How `/review`, `/ultrareview`, `/commit-push-pr`, `/pr-comments`, `/security-review`, and the hidden `autofix-pr` stub divide local prompt expansion, remote review launch, plugin fallback, and GitHub automation behavior.
- **[feedback-and-issue-commands.md](feedback-and-issue-commands.md)** — How `/feedback`, `/issue`, `/good-claude`, and reserved auto-run escalation paths divide public product feedback from narrower model-diagnostics flows.
- **[session-utility-commands.md](session-utility-commands.md)** — How rename, profile-gated tag, copy, export, remote-only session inspection, and resume-adjacent commands expose session metadata, transcript extraction, and guarded continuation.
- **[session-state-and-breakpoints.md](session-state-and-breakpoints.md)** — User-visible session phases, mode transitions, and where interaction can fail or be deferred.
- **[command-execution-archetypes.md](command-execution-archetypes.md)** — The small set of reusable execution chains slash commands enter after dispatch, including restore, local UI, prompt re-entry, delegation, and reload flows.
- **[init-command-and-claude-md-setup.md](init-command-and-claude-md-setup.md)** — The `/init` prompt-command contract, staged setup flow, and CLAUDE.md/CLAUDE.local.md loading and trust boundaries.
