---
title: "Command Surface"
owners: []
soft_links: [/integrations, /platform-services/auth-config-and-policy.md]
---

# Command Surface

The command surface is broad and should be organized into coherent families rather than treated as a flat list.

Primary command families:

- Session and bootstrap: initialization, onboarding, help, status, login, logout, resume, upgrade, doctor.
- Workspace and context: add directories, inspect context, browse files, diff, rewind, rename, clear, copy, export, session management.
- Model and behavior controls: model, effort, fast mode, compact behavior, output style, theme, color, keybindings, vim, voice.
- Collaboration and review: agents, tasks, review, branch helpers, PR comment helpers, issue flows, commit or push orchestration.
- Integration management: MCP, plugins, skills, IDE connectivity, desktop or mobile handoff, browser or Chrome surfaces, remote setup, remote environment, bridge workflows.
- Governance and commercial controls: permissions, sandbox mode, privacy settings, rate limits, usage, stats, passes, feature eligibility.

Each command should behave like a discoverable affordance over deeper subsystems. A command should reveal and configure capabilities; it should not duplicate the subsystem architecture internally.
