---
title: "SDK Control Protocol"
owners: []
soft_links: [/runtime-orchestration/query-loop.md, /runtime-orchestration/shared-task-control-plane-and-lifecycle-events.md, /tools-and-permissions/permission-model.md, /ui-and-experience/feedback-state-machine.md]
---

# SDK Control Protocol

Claude Code is not only an interactive terminal app. It also exposes a structured control surface so IDEs, wrappers, and SDK consumers can drive the same runtime without screen-scraping terminal output.

The protocol should be modeled as two layers:

- **core serializable types** for models, usage, permissions, MCP status, hook payloads, agents, and output formats
- **control messages** for session initialization, interruption, permission handling, runtime configuration changes, and live inspection

Reconstruction requirements:

- Session initialization must return a discoverable catalog of commands, agents, models, output styles, and account or entitlement context.
- Clients must be able to interrupt a running turn, switch models or reasoning behavior, and query runtime state such as context usage or MCP connection health.
- Permission requests must be externalizable. A host client should be able to receive a structured approval request, present it in its own UI, and send back the resulting mode or decision without changing core safety semantics.
- The runtime must emit typed lifecycle events rather than raw log text. Important event families include session start and end, tool execution, permission prompts and denials, subagent lifecycle, compaction, task lifecycle, worktree lifecycle, config changes, and file or instruction updates. Task lifecycle in particular should follow the shared task control-plane contract rather than ad hoc terminal parsing.
- Schemas and generated types should stay aligned so SDK builders can validate payloads at runtime while also generating stable client libraries.

The key design constraint is semantic parity: the SDK surface should not be a second implementation of Claude Code. It should be another transport over the same command model, permission model, task model, and memory lifecycle.
