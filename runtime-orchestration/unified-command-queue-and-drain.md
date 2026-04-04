---
title: "Unified Command Queue and Drain"
owners: []
soft_links: [/ui-and-experience/prompt-composer-and-queued-command-shell.md, /runtime-orchestration/turn-attachments-and-sidechannels.md, /runtime-orchestration/background-shell-task-lifecycle.md, /runtime-orchestration/scheduled-prompts-and-cron-lifecycle.md, /runtime-orchestration/local-agent-task-lifecycle.md]
---

# Unified Command Queue and Drain

Claude Code does not hand prompt submission directly to one execution function. It routes human prompts, background notifications, cron work, bridge or SDK input, channel traffic, orphaned permissions, and command-generated follow-ups through one shared queue that doubles as the runtime's async boundary.

## Scope boundary

This leaf covers:

- the queue data model shared across interactive and headless runtimes
- how priorities, batching, and wakeups decide when queued work becomes executable
- how direct input and queued input converge into one execution loop
- how mid-turn drains, headless drains, and agent-scoped drains divide responsibility
- how lifecycle state, provenance, pasted payloads, and workload tags survive the queue boundary

It intentionally does not re-document:

- prompt editing, recovery, and footer behavior already captured in [prompt-composer-and-queued-command-shell.md](../ui-and-experience/prompt-composer-and-queued-command-shell.md)
- the full post-tool attachment ladder already captured in [turn-attachments-and-sidechannels.md](turn-attachments-and-sidechannels.md)
- task-specific notification payload content already captured in the task lifecycle leaves

## One queue, many producers

Equivalent behavior should preserve:

- one module-level command queue shared by the REPL, the headless printer loop, and in-process agents instead of separate per-surface pending lists
- a React-safe frozen snapshot for UI subscribers, alongside direct read helpers for non-React code that drains the live queue
- queue mutations emitting one shared change signal so prompt preview, idle drain, and headless wakeups all observe the same source of truth
- queue operation logging being recorded as session metadata so enqueue, dequeue, remove, and bulk-pop behavior can be reconstructed later
- each queued item being able to carry the executable value, mode, priority, UUID, raw pasted payloads, pre-expansion text, slash-command routing flags, provenance, hidden-versus-visible intent, workload tag, agent target, and orphaned-permission context

## Priority classes and enqueue defaults

Equivalent behavior should preserve:

- three urgency classes: an interrupting class, a normal between-turn class, and a deferred class
- dequeue choosing the best available priority first, while preserving FIFO behavior within that priority class
- ordinary user submissions and orphaned-permission recoveries entering the normal execution class unless a caller explicitly overrides them
- task notifications defaulting to the deferred class so system chatter does not starve human input
- selected producers being able to promote notifications to the normal between-turn class when they are intended to wake the model promptly, such as channel traffic or shell-task stall and completion notices
- scheduled prompts and proactive ticks entering as hidden deferred prompts rather than bypassing the queue and writing directly into the transcript
- priority governing when work becomes eligible, not promising that every queued prompt gets its own separate turn once the runtime starts collapsing backlog

## Submission normalization and busy-state queueing

Equivalent behavior should preserve:

- direct prompt submission first normalizing into the same queued-command shape used by later drains, even when the input will execute immediately
- pasted-text references being expanded before queueing or dispatch so deferred execution sees the text that existed at submit time
- raw pasted image payloads staying attached separately to the queued command so image resizing and attachment building still happen at execution time
- immediate local terminal dialogs for selected slash commands still being allowed to open while a turn is busy, instead of always waiting behind the queue
- ordinary prompt and bash submissions queueing whenever a query or other external loading path is active
- busy-state queueing preserving pre-expansion text, pasted payloads, UUIDs, and slash-command routing flags across the async boundary
- interruptible in-flight tools being abortable before the follow-up command is queued, so submit can act like an interrupt-and-replace action when the active tool allows it
- the busy-path user submission gate accepting only prompt and bash mode input, leaving notification and permission queue entries to system producers

## Query guard and interactive idle drain

Equivalent behavior should preserve:

- one synchronous query guard with idle, dispatching, and running states so the runtime can reserve the gap between dequeue and the first awaited work
- the interactive queue processor subscribing to both the query guard and the queue snapshot, and only draining when the session is idle and no local JSX surface is actively owning focus
- interactive draining considering only unscoped main-thread commands, leaving subagent-targeted notifications to other consumers
- slash commands and bash-mode commands being executed one at a time so they keep their own command-processing semantics and error boundaries
- non-slash commands being greedily drained in same-mode groups once they become the head class, favoring backlog collapse over replaying every pending prompt as its own separate idle turn
- reservation cleanup living in the shared execution path, with explicit release on no-message local commands and a finally-path safety net for thrown errors
- command-generated follow-up input re-entering the same queue contract when it should auto-submit, instead of inventing a second follow-up channel

## Shared execution loop for direct and queued input

Equivalent behavior should preserve:

- both immediate submissions and drained queued work flowing through one common execution loop after normalization
- the first command in a batched execution pass receiving turn-level extras such as IDE selection, prompt-local pasted contents, and the visible "processing input" placeholder
- later commands in that same execution pass intentionally skipping those turn-level extras so attachments, diffs, and pasted images are not duplicated across one logical follow-up chain
- workload attribution only being hoisted when every batched command agrees on the same non-empty workload tag, preventing hidden cron work from contaminating mixed human turns
- local slash commands that do not emit transcript messages still releasing the guard, clearing temporary JSX state, and resetting abort bookkeeping cleanly
- follow-up input requested by a command being able either to refill the prompt buffer or enqueue another prompt automatically, depending on the command's own chaining intent

## Mid-turn drain inside the query loop

Equivalent behavior should preserve:

- after tool results settle, but before later enrichments are attached, the query loop taking a snapshot of eligible queued work and treating it as same-turn follow-up context
- the mid-turn drain threshold normally including normal-priority items, but expanding to include deferred notifications after the turn has explicitly yielded time to background work
- slash commands being excluded from this path so they still route through the explicit command processor after the turn ends
- the attachment builder only converting prompt and task-notification entries into model-visible queued-command attachments, leaving other queue modes for explicit execution paths
- main-thread turns draining only unscoped entries, while subagent turns drain only task notifications addressed to that exact agent identity
- subagents never consuming the ordinary human prompt stream, even though they share the same underlying queue object
- consumed queued entries being removed only after they were actually turned into attachments, and their lifecycle state advancing when that consumption happens
- hidden queue entries preserving provenance, UUIDs, and image payload references when they cross this attachment boundary

## Headless and SDK drain behavior

Equivalent behavior should preserve:

- the headless runtime running its own mutexed drain loop because there is no React subscriber to wake idle processing
- direct queue wakeups from structured input, bridge callbacks, cron callbacks, and UDS inbox callbacks all funneling back into that same run loop
- headless draining limiting itself to unscoped main-thread commands, with subagent-targeted notifications staying for subagent-side consumption
- prompt-mode headless batches merging only when neighboring queued prompts agree on workload and hidden-versus-visible intent, so merged asks keep correct attribution and transcript visibility
- non-prompt queue modes such as task notifications or orphaned-permission recoveries executing singly because they carry side effects or unresolved execution context
- any interrupt-priority arrival aborting the active headless request as soon as the queue listener notices it
- a final post-mutex recheck of the queue so messages that arrived in the last idle transition gap do not become stranded forever
- duplicate inbound UUIDs from reconnect or replay paths being filtered before enqueue, and explicit cancel-by-UUID requests being able to remove queued-but-unstarted work

## Agent scoping and producer responsibilities

Equivalent behavior should preserve:

- one process-global queue shared by the coordinator and in-process subagents, with scoping handled by metadata rather than separate storage
- `agentId` controlling notification delivery scope rather than redefining where normal human prompts go
- background task completions, shell-task stall pings, async hook blocking errors, bridge or SDK prompts, headless teammate mailbox injections, channel messages, orphaned permissions, and command-generated follow-ups all entering through the same queue contract
- producers being responsible for annotating urgency, provenance, hidden-versus-visible intent, and target agent, while consumers remain responsible for deciding when and how those entries execute

## Failure modes

- **lost wakeup**: a message arrives between the last dequeue and the idle transition, and no consumer rechecks the queue
- **cross-agent bleed**: a subagent notification leaks into the coordinator turn or the coordinator drains input that was meant for a worker
- **busy-path drift**: direct submit and queued submit stop sharing the same normalization rules, so pasted content or slash-command routing changes depending on timing
- **workload leakage**: deferred cron work leaves its low-priority workload tag active for later human turns
- **lifecycle skew**: merged or mid-turn-consumed commands are marked started but never completed, or duplicate deliveries close the wrong UUID
- **sleep churn**: deferred notifications are filtered incorrectly and either never wake a waiting turn or keep waking it immediately in a loop
- **orphan replay duplication**: duplicate permission or reconnect messages re-enqueue unresolved work that already executed once
