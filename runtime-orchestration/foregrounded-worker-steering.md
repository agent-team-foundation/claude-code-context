---
title: "Foregrounded Worker Steering"
owners: []
soft_links: [/runtime-orchestration/local-agent-task-lifecycle.md, /runtime-orchestration/turn-attachments-and-sidechannels.md, /ui-and-experience/teammate-surfaces-and-navigation.md, /collaboration-and-agents/inbox-polling-and-control-delivery.md]
---

# Foregrounded Worker Steering

Foregrounding a worker in Claude Code changes more than the visible transcript. It temporarily redirects prompt submission, permission-mode controls, transcript bootstrap, mailbox attachment targeting, and parts of the leader-only prompt UX. A faithful rebuild needs one contract for that view-slot behavior so the UI does not imply one steering target while the runtime still sends input or attachments somewhere else.

## View-slot and leader-UX overrides

Equivalent behavior should preserve:

- one global `viewingAgentTaskId` that can point at either an in-process teammate or a named local background agent
- teammate lookup that narrows only when the viewed task is actually an in-process teammate, while the same view slot can still represent a local-agent transcript through a separate branch
- prompt suggestions and speculation acceptance remaining leader-only behavior and therefore being suppressed while any worker transcript is foregrounded
- brief-mode layout giving up its special prompt gap and compact user-message styling while a worker transcript is foregrounded, so transcript view falls back to the ordinary spinner and prompt framing
- permission-mode chrome treating a viewed teammate's current mode as the effective mode for footer display and cycle actions instead of blindly showing the leader's mode
- leader-only first-time auto-mode warnings staying disabled while steering a foregrounded worker
- direct `@name` teammate messages still being attempted before normal prompt routing, but falling through to ordinary prompt submission if team context is missing or the recipient name is unknown

## Worker-directed prompt submission

Equivalent behavior should preserve:

- prompt submission consulting the active-view selector before normal leader submit, after direct-message parsing and suggestion handling
- local background-agent input being appended to the visible transcript immediately even before the worker consumes it
- running local background agents receiving new input through a queued-message path rather than a full relaunch
- non-running local background agents being resumed on demand with a fresh tool-use context instead of silently discarding the user's follow-up
- in-process teammates receiving injected user messages directly into their pending queue and UI transcript mirror, without any separate resume step
- worker-directed submissions clearing the visible prompt buffer and cursor state the same way leader submissions do
- failed local-agent resume attempts surfacing an explicit notification instead of leaving the user with a swallowed message

## Transcript bootstrap and retention boundary

Equivalent behavior should preserve:

- disk bootstrap only for retained local-agent transcript views that have not yet loaded their historical sidecar transcript
- asynchronous loading of the stored transcript followed by UUID-based merging against whatever live stream messages already arrived
- ordering where disk-only prefix messages are prepended ahead of live stream suffix messages, rather than replacing the live view wholesale
- rechecking that the viewed task is still the same retained local agent before applying the bootstrap result, so a stale async read cannot overwrite newer state
- marking the local-agent transcript as disk-loaded after the merge so later renders do not repeat the bootstrap
- no equivalent disk bootstrap for in-process teammate transcript views, because their live task state is already the source of truth for the transcript mirror

## Mailbox attachment retargeting

Equivalent behavior should preserve:

- swarm mailbox attachments running only when the swarm feature and build gating for that path are both active
- mailbox target resolution that prefers the foregrounded teammate's name, otherwise falls back to runtime agent identity, and finally derives the leader identity from team context when acting as the team lead
- leader transcript view reading the leader-facing inbox, but a foregrounded teammate view reading that teammate's own mailbox instead
- structured protocol messages being filtered out before mailbox messages are turned into model-visible attachments, leaving those control payloads unread for the inbox poller to route correctly
- leader-side pending inbox messages from app state being shown only while viewing the leader, never while viewing a teammate or running as an in-process teammate
- deduplication across file-backed unread messages and app-state pending messages so races between attachment generation and inbox polling do not surface the same human message twice
- collapsing repeated idle notifications per agent down to the latest one before attachment delivery
- mark-as-read or mark-as-processed steps happening only after the attachment payload has been built, so transient failures do not lose unread messages
- shutdown approvals discovered through the attachment path still triggering team-file cleanup, task unassignment, and in-memory roster pruning in non-interactive contexts where the normal inbox poller is not running

## Failure modes

- **wrong steering target**: the UI foregrounds a worker but the runtime still submits the next prompt to the leader
- **stale bootstrap overwrite**: an async transcript load clobbers newer live messages after the user has already switched views
- **leader inbox leak**: leader-only pending messages appear inside a teammate transcript view and confuse the worker context
- **control-message leak**: permission or shutdown protocol payloads are bundled as ordinary model attachments
- **lost passive cleanup**: shutdown approvals received in non-interactive mode never remove teammates from the roster or return their tasks to the queue
