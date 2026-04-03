---
title: "Tool Families"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /runtime-orchestration/task-model.md]
---

# Tool Families

Claude Code is fundamentally a tool-using agent runtime. Equivalent implementations need a coherent registry of first-class tool families.

Core families:

- Filesystem and search: read, write, edit, glob, grep, notebook editing.
- Shell execution: bash, PowerShell, REPL, and other execution environments.
- Web access: fetch, search, and optional interactive browser control.
- Coordination: agent spawning, task creation and inspection, team management, messaging.
- Context and planning: ask-user flows, brief or summary tools, todo or task planning, plan mode transitions.
- Integration tools: MCP connection and resource access, skill loading, config mutation, remote triggers, scheduling.

Across all families, tools should share a common contract:

- machine-readable input schema
- consistent progress reporting
- permission gating before execution
- optional UI rendering while running
- results that can be stitched back into the same conversation turn
