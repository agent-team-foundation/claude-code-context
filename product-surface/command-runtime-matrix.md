---
title: "Command Runtime Matrix"
owners: []
soft_links: [/product-surface/command-surface.md, /runtime-orchestration/state-machines-and-failures.md, /tools-and-permissions/tool-families.md]
---

# Command Runtime Matrix

The command surface is best understood as a thin set of affordances over a smaller set of runtime subsystems.

| Command family | Primary runtime anchor | Typical tool or task dependency | Surface-specific constraints | Main failure classes |
| --- | --- | --- | --- | --- |
| Session and bootstrap | startup pipeline, session store, auth, migrations | usually no direct tool use; may invoke session restore or remote bootstrap flows | must work before the full interactive loop is warm | auth unavailable, stale local state, repo or resume mismatch |
| Workspace and context | current cwd, git context, transcript state, query loop | filesystem, search, shell, diff, file presentation tools | interactive CLI can expose richer flows than remote-safe surfaces | path restrictions, missing git root, context assembly drift |
| Model and behavior controls | session-scoped config and mode toggles | mostly config mutation; some commands trigger compaction or re-render | some controls are local-only because they assume Ink dialogs or full TUI state | unsupported model or mode, policy deny, state restoration bugs |
| Collaboration and review | task manager, agent orchestration, branch and review helpers | agent tools, task tools, shell tools, remote-agent tasks | bridge and remote clients need narrower command allowlists | background orphaning, task visibility gaps, permission split-brain |
| Integration management | registries for MCP, plugins, skills, IDE, bridge, remote setup | MCP tools, skill loading, plugin loaders, transport setup tasks | command availability depends on build gates, trust, and auth posture | config parse failures, transport setup failure, disabled integrations |
| Governance and commercial controls | policy layer, entitlement checks, usage accounting, privacy state | config and reporting tools rather than heavy execution | must degrade cleanly when optional backends fail | hidden entitlement misses, stale usage data, policy/config disagreement |

## Additional mapping rules

- Prompt-like commands should expand into the same core query loop rather than creating an independent execution engine.
- Local JSX commands may be valid in the full terminal UI but unsafe over remote-control or bridge surfaces.
- Some command families narrow in remote mode; only commands that avoid local filesystem, shell, IDE, or terminal-only assumptions should survive that filter.
- Commands that mutate integrations should update registry state in one place so tool listings, skill indexes, and UI menus all observe the same refresh.
