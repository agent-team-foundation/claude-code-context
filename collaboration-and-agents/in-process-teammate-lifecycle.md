---
title: "In-Process Teammate Lifecycle"
owners: []
soft_links: [/collaboration-and-agents/worker-execution-boundaries.md, /runtime-orchestration/task-model.md, /runtime-orchestration/local-agent-task-lifecycle.md]
---

# In-Process Teammate Lifecycle

In-process teammates are not one-shot subagents. They are long-lived workers that stay inside the same Node.js process, keep their own ongoing history, go idle between assignments, and can later accept new prompts, task-list work, or shutdown requests.

## Identity and spawn contract

Equivalent behavior should preserve:

- a distinction between the logical teammate ID (`name@team`) and the task ID used in local task state
- teammate identity fields that include team affiliation, color, plan-mode requirement, and parent session lineage
- an independent lifecycle abort controller for the teammate itself rather than linking worker lifetime to the leader's current foreground request
- task registration with stable UI metadata such as spinner verbs, initial permission mode, and an empty transcript mirror ready for immediate viewing

Leader interruption should not implicitly kill a teammate that was meant to continue working.

## Continuous teammate loop

Unlike ordinary background agents, an in-process teammate runs a repeated prompt loop over its own accumulated history.

A faithful rebuild should preserve:

- an initial prompt that is wrapped into teammate-message format for transcript clarity
- an internal `allMessages` history that survives across multiple prompts
- repeated `runAgent` turns rather than one spawn per prompt
- use of the teammate's current permission mode at the start of each turn, allowing the leader to change that mode between turns
- a separate content-replacement and compaction path so long-lived teammate history stays cache-friendly without pinning the leader's full conversation forever

## Two abort scopes

The teammate needs two different stop levers.

Equivalent behavior should preserve:

- a lifecycle abort that kills the whole teammate
- a per-turn abort that stops only the current unit of work and returns the teammate to idle
- storage of the per-turn controller in task state so the UI can interrupt current work without destroying the worker

If these scopes collapse into one, simple "stop what you're doing" actions become full teammate termination.

## UI transcript mirror and memory bounds

The task state's transcript is only a UI mirror.

Required behavior:

- keep the full durable conversation in the internal history and transcript storage, not in AppState alone
- cap the UI-facing message buffer to a small recent window
- append user-injected prompts to that UI mirror immediately while separately queueing them for actual delivery
- track currently running tool-use IDs so teammate transcript views and spinners can show active work
- accumulate permission-wait time separately from productive work time so teammate duration displays remain honest

## Idle-state semantics

Finishing one prompt does not mean the teammate is done forever.

The durable contract is:

- after a turn completes or is interrupted, mark the teammate idle rather than terminal
- resolve any registered idle callbacks so leader-side waiters can unblock without polling
- send one idle notification on the transition into idle, not on every pass through the idle loop
- do not automatically forward the teammate's whole response to the leader; explicit teammate messaging remains the communication channel

## Follow-up work and queue priority

An idle teammate waits for the next assignment through several channels.

Equivalent behavior should preserve this priority order:

1. in-memory user messages injected from the transcript-view UI
2. shutdown requests
3. unread leader messages
4. other unread peer messages
5. newly available unclaimed task-list items

That ordering is load-bearing because leader intent and shutdown must not be starved behind lower-priority chatter.

## Task-list claiming

In-process teammates may self-assign from the team's shared task list.

A correct rebuild should:

- detect only pending, unowned, unblocked tasks as claimable
- claim ownership before announcing the task to the teammate loop
- move the claimed task to in-progress quickly enough that the shared UI reflects the assignment

## Graceful terminate versus force kill

Two exit paths must remain distinct.

Equivalent behavior should preserve:

- graceful termination by sending a shutdown request and marking `shutdownRequested`, letting the teammate decide whether to approve or reject shutdown
- force kill by aborting the lifecycle controller immediately
- cleanup of pending idle callbacks, current-work controllers, queued prompts, and in-progress tool markers on force kill
- direct SDK closeout for killed teammates without sending a normal task notification

## Terminal collapse

When the lifetime loop truly exits, the teammate task should collapse into a compact terminal record.

A faithful rebuild should preserve:

- terminal completion or failure only when the whole teammate loop exits
- retention of only the last visible message in terminal task state
- eager output eviction after terminal transition
- removal of task-local runtime handles such as abort controllers and cleanup callbacks

## Failure modes

- **leader-cancel bleed-through**: interrupting the foreground leader turn kills teammates that were supposed to keep running
- **output authority leak**: teammate output is auto-forwarded to the leader and collapses the worker boundary
- **priority inversion**: peer chatter prevents shutdown or leader instructions from being handled promptly
- **UI memory balloon**: the AppState mirror stores the teammate's full history instead of a capped recent slice
- **abort conflation**: stopping current work destroys the whole teammate instead of returning it to idle
