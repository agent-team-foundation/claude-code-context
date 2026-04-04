---
title: "Background Main Session Lifecycle"
owners: []
soft_links: [/runtime-orchestration/task-model.md, /runtime-orchestration/task-registry-and-visibility.md, /runtime-orchestration/app-state-and-input-routing.md, /runtime-orchestration/session-reset-and-state-preservation.md, /runtime-orchestration/task-output-persistence-and-streaming.md, /runtime-orchestration/turn-attachments-and-sidechannels.md, /memory-and-context/context-lifecycle-and-failure-modes.md]
---

# Background Main Session Lifecycle

Claude Code can detach the main conversation itself into a background task. That path is not the same as spawning a helper agent: it keeps running the standard query loop, but under a task-scoped identity and transcript that can survive UI reset and session-clear flows.

Shared task registration, generic stop dispatch, `notified` barriers, terminal eviction rules, and SDK lifecycle bookends are captured in [shared-task-control-plane-and-lifecycle-events.md](shared-task-control-plane-and-lifecycle-events.md). This leaf focuses on what is special about backgrounding the main conversation itself.

## Specialized task identity

Equivalent behavior should preserve:

- a dedicated main-session task ID namespace distinct from normal subagent IDs
- task type compatibility with local-agent infrastructure, while still marking the task as `main-session` for UI and routing decisions
- registration in the shared local task registry as its own recognizable task flavor even when storage shape is reused from ordinary local-agent tasks
- reuse of the existing abort controller when a live foreground query is backgrounded, so later stop requests abort the real in-flight query rather than a detached copy

## Isolated transcript contract

Background main-session work must not keep writing to the primary session transcript.

A correct rebuild should:

- bind task output to an isolated per-task transcript path
- snapshot the pre-background conversation into that task transcript immediately so output inspection works from the start
- append later events incrementally so long-running background work remains inspectable while it runs
- tolerate session-ID resets or `/clear`-style relinks without losing where the background query is writing

Without that isolation, a backgrounded query can corrupt the fresh post-clear conversation.

## Handoff from the live foreground turn

When the current query is backgrounded, the runtime should preserve more than messages.

Required behavior:

- stop the foreground query with a dedicated backgrounding path instead of treating it as a user cancellation
- remove pending task notifications from the main queue before the fresh prompt returns
- forward those notifications into the background session's message stream after deduplicating anything already attached
- continue the background session with the same system prompt, tool policy, and contextual attachments that the foreground query had already assembled

## Agent-scoped continuation

The detached main-session query still needs its own agent-style scope.

Equivalent behavior should run it under task-specific agent context so that:

- invoked skills remain associated with the background task instead of the cleared main session
- task-scoped caches, permission callbacks, and other per-agent state survive concurrent foreground work
- `/clear` can preserve the background task's execution state while resetting the main conversation

## Progress model

Background main-session progress is approximate but live.

A faithful rebuild should preserve:

- rolling message accumulation for foreground re-entry
- rough token counting from assistant text
- a bounded list of recent tool activities
- task visibility derived from the shared registry and main-view foreground pointer rather than from task-local UI state
- no-op state updates when token count, tool count, and message list have not materially changed

## Foreground return path

The user can foreground a running background main-session task.

Equivalent behavior should preserve:

- a dedicated foregrounded-task pointer for the main view
- returning the task's accumulated messages so the visible transcript can be reconstructed immediately
- backgrounding of any previously foregrounded local-agent task when a new one is brought to the front
- keeping the separate viewed-worker steering pointer free to continue targeting teammates or named agents
- continued execution while foregrounded; this is a display change, not a restart

## Completion and notification rules

Completion handling depends on whether the task is still backgrounded.

The durable contract is:

- if the task finishes while still backgrounded, enqueue exactly one task notification with task ID, status, and output path
- if the user foregrounded it first, suppress the model-facing completion notification because the user is already watching the result
- even in the foregrounded case, mark the task notified and emit the SDK closing event so task lifecycle bookends remain balanced

## Abort and failure semantics

If an abort lands mid-stream before the normal completion path runs, the task still needs a clean terminal record.

Equivalent behavior should:

- atomically mark the task notified before returning from the aborted background loop
- emit a stopped event for SDK consumers when no ordinary completion notification will be sent
- evict in-memory output writers after terminal transition while keeping the persisted transcript readable

## Clear-session preservation

Main-session background tasks are intentionally preserved across conversation clears.

The runtime should:

- keep backgrounded main-session tasks alive across session cache resets
- kill only tasks that are explicitly still foreground-only
- preserve the background task's per-agent state when the primary conversation ID regenerates

## Failure modes

- **post-clear corruption**: background output keeps appending to the main transcript after the user cleared the session
- **lost notifications**: task notifications removed during handoff are never forwarded into the detached session
- **double completion**: a foregrounded task still emits a model-facing completion notification
- **scope leakage**: background task loses its agent-scoped caches or skill state during `/clear`
- **identity collapse**: main-session work is reconstructed as an ordinary subagent task and loses its distinct routing or notification behavior
