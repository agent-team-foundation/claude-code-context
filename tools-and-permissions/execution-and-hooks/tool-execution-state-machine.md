---
title: "Tool Execution State Machine"
owners: []
soft_links: [/tools-and-permissions/permissions/permission-model.md, /runtime-orchestration/state/state-machines-and-failures.md]
---

# Tool Execution State Machine

Tool use is a controlled lifecycle, not a direct function call.

## States

1. Candidate.
   The model proposes a tool.
2. Resolved.
   The runtime maps the request to a concrete built-in, MCP, or extension tool.
3. Permission evaluation.
   Policy, mode, path, and safety checks are applied.
4. Awaiting approval.
   Used when human confirmation or interactive elicitation is required.
5. Running.
6. Producing progress.
7. Result integrated.
   The tool output becomes part of the same turn.
8. Denied or failed.

## Key transitions

- A candidate tool can be rejected before execution if the current surface, mode, or permission context forbids it.
- Running tools may emit progress repeatedly before yielding a final result.
- Some failures should return structured errors to the model so the turn can continue productively.
- Background agents may skip the approval state and use precomputed deny or allow rules instead.

## Failure modes

- **Blanket deny**: the tool is unavailable due to policy or explicit deny rules.
- **Promptable but unpromptable**: approval is needed, but the current execution context cannot ask the user.
- **Path escape or destructive intent**: command semantics force rejection or input rewriting.
- **Stale tool pool**: the runtime and current integrations disagree on which tools exist.
- **Collapsed visibility**: a tool runs, but the UI does not surface enough progress or output for the user to trust it.
