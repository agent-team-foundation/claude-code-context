---
title: "Task Stop and Output Legacy Compatibility"
owners: []
soft_links: [/tools-and-permissions/agent-and-task-control/task-and-team-control-tool-contracts.md, /runtime-orchestration/tasks/shared-task-control-plane-and-lifecycle-events.md, /tools-and-permissions/permissions/permission-rule-loading-and-persistence.md]
---

# Task Stop and Output Legacy Compatibility

Claude Code treats task stop and task output as canonical task-family controls, but it still accepts older tool names, older parameter names, and a separate SDK control request shape. Reproducing the behavior requires preserving those compatibility bridges without confusing them with the modern contract.

## Scope boundary

This leaf covers:

- the compatibility matrix for stopping tasks through tool and SDK surfaces
- the compatibility matrix for reading task output through renamed legacy tools
- the shared stop core and the intentionally narrow responsibilities it owns
- legacy permission-rule and settings normalization for renamed tools
- the notification and SDK-closeout side effects that make these surfaces more than plain CRUD

It intentionally does not re-document:

- the broader task creation and update contracts already captured in [task-and-team-control-tool-contracts.md](task-and-team-control-tool-contracts.md)
- generic task registration, status, and lifecycle event routing already captured in [shared-task-control-plane-and-lifecycle-events.md](../runtime-orchestration/tasks/shared-task-control-plane-and-lifecycle-events.md)

## Stop-task compatibility matrix

Equivalent behavior should preserve:

- one canonical stop tool named `TaskStop`
- one legacy tool alias named `KillShell` that still resolves to the same stop behavior
- acceptance of deprecated `shell_id` input alongside canonical `task_id`, with `task_id` winning when both are present
- stop-tool validation and execution using the same compatibility lookup for either field, rather than accepting the alias name but then refusing the old parameter
- tool results still reporting canonical task information such as task ID, task type, and human-readable command or description

The compatibility contract is about renamed control surfaces, not about supporting two different stop implementations.

## Shared stop core is intentionally narrow

Equivalent behavior should preserve one shared stop helper that does only the common minimum:

- look up the task by ID
- verify the task exists and is actively running
- find the registered task-family implementation
- dispatch the family-specific kill operation
- perform narrowly scoped notification cleanup needed to prevent duplicate shell closeouts

It should not absorb every family-specific summary, terminal message, or closeout rule. Those still belong to the task family or to the transcript and SDK event pipeline around it.

## SDK `stop_task` request is a sibling surface, not a clone of the tool

Equivalent behavior should preserve:

- a separate SDK control request subtype named `stop_task`
- SDK input accepting only canonical `task_id`, not deprecated `shell_id`
- SDK stop requests reusing the same shared stop helper as the tool path
- SDK control responses remaining minimal and control-oriented, rather than returning the richer human-facing tool payload that `TaskStop` emits

This keeps the stopping semantics unified while still letting the SDK wire protocol stay lean.

## Output-tool compatibility matrix

Equivalent behavior should preserve:

- one canonical output tool named `TaskOutput`
- two legacy aliases, `AgentOutputTool` and `BashOutputTool`
- normalization of old parameter names such as `agentId`, `bash_id`, and `wait_up_to` into canonical `task_id` and millisecond `timeout`
- legacy blocking semantics surviving the normalization, including the default behavior of waiting unless explicitly told not to
- support for reading output from shell tasks, agent tasks, and remote-style tasks through the same canonical surface

The important contract is that renamed tools and parameters still converge on one output behavior before validation or execution.

## Deprecated toward `Read`, but not a pure read

`TaskOutput` is explicitly deprecated in favor of reading the task output file path directly.

Equivalent behavior should still preserve:

- deprecation messaging that steers callers toward `Read` on the output file path
- successful terminal retrieval marking the task as `notified`, so later notification logic knows the result was already surfaced
- the difference between non-blocking inspection of a still-running task and terminal retrieval of a finished one
- timeout responses that can return either `null` or partial task state depending on whether the task record is still available and whether it finished in time

So although the tool is classified as read-like for concurrency and safety purposes, it still has notification-state side effects and should not be rebuilt as a pure filesystem read wrapper.

## Permission and settings normalization keep old names alive

Equivalent behavior should preserve:

- permission-rule parsing that rewrites legacy tool names such as `KillShell`, `AgentOutputTool`, and `BashOutputTool` to their canonical modern names
- settings persistence checks doing the same normalization when comparing stored permission entries
- hooks, policy, and saved allow or deny lists matching canonical task-control tools even when older transcripts or configs still mention the deprecated names

Without this bridge, renamed tools would appear to work in conversation history but silently fail permission matching.

## SDK closeout ownership and shell-notification suppression

Equivalent behavior should preserve:

- normal terminal closeout for SDK consumers being driven by the usual parsed task-notification path when a task emits a terminal status
- `killed`-style terminal task states being normalized into the SDK-facing `stopped` vocabulary
- a direct SDK termination event being emitted only when the normal shell-notification path was intentionally suppressed, so SDK consumers still receive one final closeout
- the shared stop helper staying careful about when it claims closeout ownership, rather than assuming every kill path can safely emit a second terminal event

A clean-room rebuild should preserve the observable rule of "exactly one SDK terminal closeout when normal parsing is bypassed" without depending on one fragile internal ordering inside a particular shell-task implementation.

## Failure modes

- **alias split**: `TaskStop` and `KillShell` accept different IDs or run different validation paths
- **wire drift**: SDK `stop_task` starts accepting deprecated inputs or returning the tool's richer payload and breaks protocol expectations
- **read-only misconception**: `TaskOutput` is rebuilt as a side-effect-free file read and stops marking tasks as notified
- **permission mismatch**: old saved rules mention legacy tool names that no longer normalize to the canonical task-control tools
- **double closeout**: shell-stop suppression and direct SDK termination both fire, producing two terminal task events for the same stop
