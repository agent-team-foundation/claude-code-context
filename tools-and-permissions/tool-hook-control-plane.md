---
title: "Tool Hook Control Plane"
owners: []
soft_links: [/tools-and-permissions/tool-execution-state-machine.md, /tools-and-permissions/permission-resolution-races-and-forwarding.md, /runtime-orchestration/turn-attachments-and-sidechannels.md, /memory-and-context/compact-path.md]
---

# Tool Hook Control Plane

Tool hooks are a control plane, not just logging callbacks. They can modify input, inject context, block execution, or stop continuation after execution.

## Hook source merge and admission

Equivalent behavior should preserve merged hook sources:

- persisted settings hooks
- registered runtime hooks
- session-derived hooks
- plugin and skill hook sources

This merge still passes through global gating (for example, trust and managed-policy restrictions) before execution.

## Matching and dedup semantics

Hook matching should preserve:

- event-specific matcher keys (tool names, session source, trigger types, etc.)
- hook-level conditional matching for tool events
- dedup keys that include source context, so identical templates from different plugins do not collapse incorrectly

The runtime should also support lightweight existence checks on hot paths so unconfigured events are cheap.

## Execution model

Equivalent behavior should preserve parallel hook execution with per-hook timeout and abort control.

Hook types can include command, callback, prompt, agent, function, and HTTP forms, but all should emit into one normalized result stream.

## Structured output protocol

Hook outputs should support structured control fields, including:

- continuation stop signals
- permission decisions
- updated tool input
- additional context
- event-specific outputs (for example, MCP output rewrites or elicitation decisions)

For permission behavior, aggregate precedence should remain `deny` over `ask` over `allow`.

## Tool lifecycle integration points

The hook control plane must integrate at least:

- pre-tool phase
- permission-request and permission-denied phases
- post-tool success phase
- post-tool failure phase

Pre-tool allow decisions still flow through rule checks; hooks do not become an unconditional bypass.

## Out-of-band hook runs

Some hook events run outside normal REPL message exposure. Equivalent behavior should preserve these out-of-band runs without leaking their diagnostics directly into model-visible turns unless explicitly attached.

## Failure modes

- **policy bypass**: hook allow skips downstream deny/ask rule checks
- **priority inversion**: aggregate permission behavior allows despite a deny from another hook
- **context loss**: additional context or rewritten input is dropped between hook layer and executor
- **orphaned async hook**: background hook survives without lifecycle tracking and cleanup
- **execution stall**: one broken hook blocks unrelated hook execution or deadlocks hot paths
