---
title: "Tool Families"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /runtime-orchestration/tasks/task-model.md, /tools-and-permissions/agent-and-task-control/control-plane-tools.md, /tools-and-permissions/agent-and-task-control/task-and-team-control-tool-contracts.md, /tools-and-permissions/permissions/config-permission-and-sandbox-admin-surfaces.md, /reconstruction-guardrails/verification-and-native-test-oracles/test-seams-reset-hooks-and-injected-dependencies.md]
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

Helper or test-only tools can still exist in the catalog, but they should be treated as admission- and posture-sensitive helper surfaces rather than as a separate public product family.

## Test Design

In the observed source, tool-catalog behavior is verified through deterministic assembly regressions, cache-aware integration coverage, and availability-oriented surface checks.

Equivalent coverage should prove:

- discovery, precedence, filtering, and ordering logic preserve the catalog contracts described in this leaf
- deferred loading, refresh, and contributions from built-ins, agents, plugins, and MCP sources behave correctly with resettable caches and registries
- visible tool availability and ordering stay stable enough for prompt caching, search, and client expectations to remain consistent across sessions
