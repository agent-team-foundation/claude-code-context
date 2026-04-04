---
title: "Queued Command Projection and Replay"
owners: []
soft_links: [/runtime-orchestration/unified-command-queue-and-drain.md, /runtime-orchestration/turn-attachments-and-sidechannels.md, /ui-and-experience/prompt-composer-and-queued-command-shell.md, /collaboration-and-agents/bridge-session-state-projection-and-command-narrowing.md]
---

# Queued Command Projection and Replay

One queued command does not stay in one representation. As it moves through Claude Code, the same logical item can appear as a prompt-preview row, a transcript attachment, a synthetic user replay for SDK consumers, and a remote-delivery event for companion sessions. A clean-room rebuild has to preserve the identity and visibility rules across all four surfaces.

## Scope boundary

This leaf covers:

- how one queued item fans out into preview, transcript, replay, and remote-delivery projections
- which visibility decisions belong only to prompt editing versus transcript or API replay
- how queued-command identity survives attachment creation and replay
- lifecycle transitions for queued work after it is consumed, deduplicated, replayed, or cleaned up
- rewind and restore rules for queued-command rows that look user-like but are not raw user messages

It intentionally does not re-document:

- queue priority, wakeup, and drain mechanics already captured in [unified-command-queue-and-drain.md](unified-command-queue-and-drain.md)
- generic post-tool attachment ordering already captured in [turn-attachments-and-sidechannels.md](turn-attachments-and-sidechannels.md)
- prompt-buffer editing affordances already captured in [prompt-composer-and-queued-command-shell.md](../ui-and-experience/prompt-composer-and-queued-command-shell.md)

## One logical item, four projections

Equivalent behavior should preserve four distinct projections of the same queued item:

- a prompt-area preview row that helps the local operator see pending work before execution
- a `queued_command` attachment row in the transcript when the queue item is drained into turn context
- a synthetic user replay event for SDK consumers when replay mode asks for user-side reconstruction
- a remote-delivery lifecycle event so companion clients can mirror queued work without inventing their own IDs

These projections are related but not identical. A rebuild should not collapse them into one universal message type.

## Preview visibility is not transcript visibility

Equivalent behavior should preserve:

- one preview-specific visibility helper that answers only whether an item should appear in the pending-input shell under the prompt
- preview visibility being a superset of editability, so some system-originated items can be visible without becoming editable prompt text
- transcript and API hiddenness being decided separately from preview visibility, primarily from the queued item's origin metadata plus its `isMeta` intent
- channel-style or control-style items being allowed to appear in preview for awareness while still remaining non-editable or non-replayable
- task-notification and other meta-style items staying outside normal editable restore flows even when the runtime still needs to project them elsewhere

The key contract is that `isQueuedCommandVisible` is a UI-preview rule, not the master truth for every later surface.

## Identity propagation and UUID ownership

Equivalent behavior should preserve:

- the original queued-command UUID, when present, staying attached to the logical work item across later projections
- the queued-command UUID flowing into the transcript attachment as `source_uuid`
- synthetic SDK user replays reusing that `source_uuid` when available, instead of minting a brand-new replay identity
- the transcript attachment row keeping its own message UUID in addition to the carried `source_uuid`, because the attachment is still a real transcript record
- replay consumers falling back to the attachment row UUID only when the queued item never had its own UUID

This double-identity contract matters because transcript storage and replay correlation solve different problems.

## Lifecycle state and remote-delivery mapping

Equivalent behavior should preserve:

- queued work becoming `started` only when it is actually consumed into execution or attachment flow, not merely when it is enqueued
- queued work becoming `completed` after normal turn completion once the runtime has fully processed that consumed item
- duplicate-cleanup and orphan-cleanup paths being allowed to close queued items without replaying them a second time
- remote-delivery reporting mapping local queued-command lifecycle into remote-friendly states such as `processing` and `processed`
- lifecycle listeners being driven from the shared queued-command identity so remote viewers can correlate delivery state with the original inbound work

The important boundary is that queue lifecycle reflects real consumption, not mere presence in the pending list.

## Rewind, selection, and auto-restore limits

Queued-command attachments can look like user prompts in the transcript, but they are not rewind anchors.

Equivalent behavior should preserve:

- rewind and message-selector flows targeting only raw selectable user messages, not queued-command attachment rows
- sticky-prompt or transcript rendering being allowed to make queued-command rows read like prompts without granting them full user-message semantics
- auto-restore after an interrupted turn only restoring a raw user message when no later queued commands remain, so the runtime does not resurrect stale input after the operator already queued new work
- rewind-file operations continuing to require real user-message UUIDs rather than queued-command attachment UUIDs

The contract is intentionally asymmetric: queued commands may look conversational, but only true user messages own rewindable history.

## Duplicate suppression across replay surfaces

Equivalent behavior should preserve duplicate prevention in several independent places:

- inbound queue admission rejecting repeated UUIDs from reconnect or replay paths before they become pending work
- task-notification transcript insertion deduplicating by prompt text when the producer omitted a UUID
- replay and reconnect logic deduplicating by replay UUID so synthetic user messages do not multiply after transport churn
- remote viewers filtering echoed deliveries so locally originated queued commands are not reflected back as a second visible submission

No single dedupe pass is sufficient. The runtime expects different producers to fail in different ways.

## Failure modes

- **surface collapse**: preview, transcript, SDK replay, and remote delivery are treated as one shared representation and lose their different visibility rules
- **uuid drift**: the original queued-command ID is dropped, so replay consumers cannot correlate the item that was originally queued
- **false rewind target**: queued-command attachment rows become selectable restore anchors and corrupt prompt history or file rewind behavior
- **premature completion**: queued work is marked finished when it is dequeued, even though the turn later aborts or replays it differently
- **echo duplication**: reconnect, companion replay, or task notifications reinsert the same queued work because only one dedupe path was preserved
