---
title: "Tool Families"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /runtime-orchestration/task-model.md, /tools-and-permissions/control-plane-tools.md, /tools-and-permissions/task-and-team-control-tool-contracts.md, /tools-and-permissions/config-discovery-and-trigger-tool-contracts.md]
---

# Tool Families

Claude Code is fundamentally a tool-using agent runtime. Equivalent implementations need a coherent registry of first-class tool families.

Core families:

- Filesystem and search: read, write, edit, glob, grep, notebook editing.
- Shell execution: bash, PowerShell, REPL, and other execution environments.
- Web access: fetch, search, and optional interactive browser control.
- Coordination and control: agent spawning, task creation and updates, team management, messaging, and mode transitions.
- Context and planning: ask-user flows, brief or summary tools, todo or task planning, plan mode transitions.
- Integration tools: MCP connection and resource access, skill loading, config mutation, remote triggers, scheduling.
- Configuration and retry surfaces: narrow settings discovery or mutation, permission browsing, denied-command retry, and sandbox admin actions.

Across all families, tools should share a common contract:

- machine-readable input schema
- consistent progress reporting
- permission gating before execution
- optional UI rendering while running
- results that can be stitched back into the same conversation turn

The important reconstruction point is that not all tools act on the outside world. Some mutate the runtime's own work graph, settings, or approval posture, and those families still need the same schema, observability, and safety guarantees.
