---
title: "Turn Attachments and Sidechannels"
owners: []
soft_links: [/memory-and-context/memory-layers.md, /collaboration-and-agents/worker-execution-boundaries.md, /runtime-orchestration/tasks/task-model.md]
---

# Turn Attachments and Sidechannels

Claude Code does more than alternate between assistant text and tool results. Between recursive turn iterations it injects structured sidechannels, and their ordering changes what the model sees next.

## Attachment boundary

Regular attachments are added only after the tool phase finishes.

That boundary is required because the transcript format must not interleave ordinary user-side attachments with unresolved tool-result traffic. A rebuild that injects attachments too early will produce an invalid or behaviorally different trajectory.

## Post-tool attachment order

After tool results are integrated, the runtime should process sidechannels in this order:

1. queued prompt and task-notification attachments
2. relevant-memory attachments whose prefetch has already finished
3. prefetched skill-discovery attachments
4. any tool-pool refresh needed for the next iteration
5. turn-control attachments such as max-turn notices

This order ensures that new human or worker input outranks opportunistic enrichment.

## Queue-backed prompt injection

The runtime maintains a shared command queue that can inject mid-turn input.

Important routing rules:

- the main thread drains ordinary user prompts and unscoped task notifications
- subagents only drain task notifications addressed to their own agent identity
- slash-command entries are excluded from this path and must be handled by the explicit command processor
- queued entries are removed only after they were actually converted into attachments

Lifecycle tracking belongs to this same path. Consumed queued commands are marked as started when attached and completed when the whole turn exits normally.

## Wait-sensitive notification draining

Notification urgency is affected by whether the turn already executed a wait-style tool.

Equivalent behavior should support one class of notifications that can be drained immediately on the next iteration and another class that can remain deferred when the turn has already explicitly yielded time to background work.

## Relevant-memory sidechannel

Relevant-memory search is started once per user turn and allowed to run in the background while the model streams and tools execute.

When that prefetch has settled, the next iteration may attach its results, but only if:

- the prefetch was not already consumed earlier in the same turn
- the candidate memories are not duplicates of files the model already read, edited, or wrote during the live session

This makes memory surfacing opportunistic rather than blocking, while still preventing the same memory file from being reattached pointlessly.

## Skill-discovery sidechannel

Skill discovery is similarly prefetched in parallel with the main iteration and attached after tool execution.

Important behavior:

- discovery is tied to the current turn trajectory, especially write-oriented work
- collection happens after tools so the next request benefits from the discovery without delaying the current response
- attached skill discoveries become part of the next recursive request, not a separate conversation

## Deferred summaries

Not every sidechannel is an attachment block.

Two important deferred outputs should still be reconstructed:

- a tool-use summary that is generated asynchronously after a tool batch and emitted at the start of the next iteration
- a periodic top-level task summary for long-running foreground sessions

The first is turn-local and user-visible. The second is operational metadata for background-task visibility.

## Continuation-stop signals

Some sidechannels are control messages rather than ordinary context.

Equivalent behavior should support structured outputs that:

- stop recursive continuation after the tool phase
- announce that the turn exceeded its max-turn ceiling
- carry mode-transition reminders or other runtime state notices into later iterations

These are part of the turn control plane, not just decoration.

## Dynamic tool refresh

The tool pool may change between iterations.

If integrations connect or reconnect during a turn, the runtime refreshes the available tool set before recursing so the next model call sees the updated surface. This refresh happens after the current tool results are settled and before the next request is assembled.

## Failure modes

- **interleaving breakage**: ordinary attachments are injected before tool results settle
- **queue misrouting**: subagents accidentally consume main-thread prompts or vice versa
- **duplicate memory surfacing**: already-read memory files keep reappearing because cumulative file state is ignored
- **discovery lag**: skill or memory prefetch completes, but the next iteration never consumes it
- **stale tool surface**: integrations connect mid-turn, but the next recursive request still uses the old tool pool
