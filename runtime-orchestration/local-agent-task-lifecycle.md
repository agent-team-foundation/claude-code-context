---
title: "Local Agent Task Lifecycle"
owners: []
soft_links: [/runtime-orchestration/task-model.md, /runtime-orchestration/turn-attachments-and-sidechannels.md, /collaboration-and-agents/multi-agent-topology.md, /collaboration-and-agents/peer-addressing-discovery-and-routing.md, /tools-and-permissions/delegation-modes.md]
---

# Local Agent Task Lifecycle

Local subagents are explicit task records, not disposable helper calls. The same agent may begin inline, switch to background execution, be viewed in a coordinator panel, receive follow-up messages, survive a resume path, and later re-surface after compaction.

Shared task registration, replacement semantics, `notified` barriers, terminal eviction rules, and SDK lifecycle bookends are captured in [shared-task-control-plane-and-lifecycle-events.md](shared-task-control-plane-and-lifecycle-events.md). This leaf focuses on the agent-specific foreground, background, transcript-retention, and prompt-injection behavior layered on top.

## Stable identity and transcript binding

Equivalent behavior should preserve:

- one agent ID across spawn, task state, transcript file, task-output path, SendMessage routing, and resume handling
- task output as a view of the agent transcript rather than as a second competing log
- in-session task replacement paths that reuse the existing task identity and avoid a duplicate `task_started` emission

## Foreground-first registration

Foreground-capable agents should still be registered as tasks before the user backgrounds them.

That contract matters because:

- manual backgrounding must be able to target a running agent at any point
- auto-background timers need a task record to flip in place
- coordinator and SDK surfaces need a stable handle before the agent leaves the main turn

Showing the "background this agent" hint later is presentation logic, not the moment the task starts existing.

## Foreground-to-background handoff

Equivalent behavior should preserve this transition:

1. start the agent in a foreground task record with `isBackgrounded = false`
2. wait on a one-shot background signal triggered by user action or an auto-background timer
3. when backgrounding fires, flip the existing task in place instead of registering a second task
4. close the foreground iterator quickly so session hooks, MCP resources, and other cleanup logic run
5. resume the agent in background mode under the same task ID and abort controller

If the agent finishes without ever backgrounding, the task should be removed rather than left behind as a fake background artifact. SDK consumers may still need a closing bookend even though the main model loop does not.

## Progress and summarization

Local-agent progress is richer than "still running."

Required behavior:

- track latest input tokens and cumulative output tokens separately so repeated API input counts are not double-counted
- count tool uses, but omit internal synthetic-output tools from the visible activity feed
- keep a bounded recent-activity list with precomputed read/search classification when available
- allow a background summarizer to store a short status summary without having later progress updates erase that summary
- emit optional SDK progress summaries from the same task state rather than from a parallel state machine

## Transcript retention and panel lifecycle

Panel-managed agent tasks need a split between runtime ownership and UI retention.

Equivalent behavior should preserve:

- a `retain` state that blocks eviction and enables live in-memory transcript append while the user is holding the task open
- a one-shot disk bootstrap marker so the transcript is loaded from disk once per retain cycle and then extended live in memory
- release back to a stub form when the user switches away: drop retained messages, clear the bootstrap marker, and schedule terminal tasks for delayed eviction
- immediate dismiss for terminal tasks without waiting for the grace period

If a task is re-registered during an in-session resume path, retained transcript state, pending injected messages, and panel ordering metadata should survive that replacement.

## Mid-run prompt injection

A local agent can receive follow-up user input while still running.

Equivalent behavior should preserve:

- plain-text follow-up targeting resolving by registered agent name or stable agent ID before any teammate-mailbox fallback is attempted
- per-task queued messages that are routed to the agent's next request, not injected into the transcript immediately
- a separate UI append path so the user can see the prompt appear in the viewed transcript without lying about when the model actually consumed it
- draining of queued messages only at defined attachment or tool-round boundaries
- running agents consuming those queued messages on their next eligible round without requiring a second task registration

## Completion, kill, and notification ordering

A faithful rebuild should:

- transition the task to terminal state before slow post-processing such as worktree cleanup or handoff classification
- evict in-memory output writers after terminal transition while leaving the transcript readable
- use an atomic notified barrier before enqueueing completed, failed, or killed task notifications
- allow bulk-stop flows to mark tasks as already notified when one aggregate shutdown message replaces many per-agent notifications
- abort speculative follow-up generation when task state changes, because speculated output can reference stale background results

Killed tasks should prefer partial user-visible output over silence when a meaningful partial result exists.

## Recovery and compaction expectations

Long-running or finished-but-not-yet-consumed local agents still need to remain visible to later turns.

The durable contract is:

- compaction and recovery paths should keep enough task metadata to stop the model from spawning a duplicate worker
- pending results should remain attachable until the runtime considers them consumed
- resume paths should reconstruct the running agent from transcript plus task state rather than treat it as an unrelated new worker
- a targeted follow-up to a stopped or evicted local agent should prefer transcript-backed background resume under the same agent identity, and fail explicitly if no resumable transcript remains

## Failure modes

- **ghost background task**: a foreground-only agent completes normally but is left behind as if it had been backgrounded
- **double start**: a background transition or resume path emits a second task-start event for the same agent
- **summary clobber**: a later progress update erases the background summary text
- **transcript reset**: retained messages or queued prompts disappear during in-session task replacement
- **blocked readback**: terminal state waits on slow cleanup work and leaves task output readers hanging
