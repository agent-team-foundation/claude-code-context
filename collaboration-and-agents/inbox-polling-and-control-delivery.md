---
title: "Inbox Polling and Control Delivery"
owners: []
soft_links: [/collaboration-and-agents/teammate-mailbox-and-permission-bridge.md, /collaboration-and-agents/peer-addressing-discovery-and-routing.md, /runtime-orchestration/turn-flow/turn-attachments-and-sidechannels.md, /ui-and-experience/feedback-and-notifications/interaction-feedback.md]
---

# Inbox Polling and Control Delivery

Pane-backed teammates and leaders rely on inbox polling as the compatibility layer between mailbox files and live runtime state. The inbox path must be able to turn unread mailbox entries into either control actions or model-visible teammate messages without dropping, duplicating, or misclassifying traffic.

This poller covers swarm mailbox ingress only. Cross-session peer messages arrive through a separate queued-prompt path and should not be reconstructed as mailbox attachments or teammate control cards.

## Poll eligibility and identity

Equivalent behavior should preserve:

- polling for process-backed teammates under their own agent name
- polling for the leader under the lead agent name inside the active team, with a stable fallback to the reserved lead name when team metadata is incomplete
- no inbox-poller usage for in-process teammates, because they share one React tree and need a different handoff path
- eligibility being re-derived from current app state on each poll rather than captured once, so role changes and swarm teardown stop polling cleanly
- an initial poll at startup plus continued 1-second polling while a leader or pane-backed teammate is active

If the in-process path and the pane-backed path share the same poller, message routing will eventually cross wires.

## Protocol interception before model delivery

Not every unread mailbox item is normal conversation.

A faithful rebuild should preserve:

- classification of unread messages into permission requests, permission responses, sandbox permission traffic, shutdown control, plan approvals, mode changes, team-wide permission updates, and ordinary teammate messages
- a worker-side pre-scan for plan-approval responses before the main bucketing pass, so plan mode can be exited promptly even if later transcript delivery is deferred
- interception of structured control messages before XML teammate-message wrapping happens
- classification asymmetry: plan-approval requests, shutdown requests, and shutdown approvals get their own buckets, while shutdown rejections and plan-approval responses still fall through to ordinary teammate delivery after any side effects run
- rejection of malformed control payloads instead of crashing or blindly passing them through as model context, including unknown permission-request tools and malformed nested sandbox or team-permission fields
- security checks on who is allowed to trigger privileged state changes, especially plan-mode exit and leader-driven mode changes

Mailbox transport is shared, but model context and control-plane traffic are not interchangeable.

## Leader-side control handling

Equivalent behavior should preserve:

- tool-permission requests routed into the same approval UI queue the leader uses for foreground tool prompts
- worker identity badges on those reused approval prompts and per-request deduplication by tool-use id so a read-marker failure does not enqueue the same permission request twice
- sandbox host approvals handled in a separate queue and callback namespace from ordinary tool permissions
- desktop-style notifications for newly surfaced worker approval prompts when the leader is not already focused on another decision dialog
- sandbox approval queue entries carrying worker identity, optional worker color, host, and original creation time rather than only a host string
- automatic approval of teammate plan requests using the leader's current external permission mode, normalized so a leader already in plan mode does not trap workers in plan forever
- auto-approved plan requests still remaining visible as regular teammate context after the approval side effect has already been sent, so the leader transcript and model keep the teammate's planning context
- in-process teammate plan state being updated immediately when the auto-approved request maps back to a live in-process teammate task
- shutdown approvals attempting backend-specific pane cleanup when pane metadata exists, without blocking the rest of reconciliation on that kill finishing first
- shutdown approvals then removing the worker from the durable team file and live team state, unassigning its unfinished shared tasks with a shutdown reason, and appending a synthetic termination notice into the leader inbox
- shutdown approval handling also completing the lingering teammate task row so swarm-running indicators stop claiming the teammate is still active
- shutdown approvals still being passed through as regular teammate context after reconciliation, even though downstream renderers may later hide the visible row

## Worker-side control handling

Equivalent behavior should preserve:

- permission and sandbox responses that resolve only the matching pending callback if one is still registered
- plan approval responses accepted only from the team lead before leaving plan-required mode
- approved plan responses inheriting the leader-provided mode when present and otherwise falling back to the default execution mode
- rejected plan responses leaving plan-required mode intact while still remaining eligible for transcript delivery
- application of team-wide permission updates into the worker's session-scoped permission context
- leader-driven mode changes applied only when the sender is the team lead, with the new mode mirrored back into team metadata so the leader can see the worker's live mode
- shutdown requests surfaced to the worker model or worker UI rather than silently killing the process on receipt

## Delivery and acknowledgement semantics

Regular teammate messages still need reliable turn delivery.

Equivalent behavior should preserve:

- immediate submission of regular unread messages when the session is idle and no blocking dialog is open
- durable queueing into app state when the session is busy or when immediate submission is rejected
- a shared XML formatting path for immediate submission and later replay, preserving teammate identity plus optional color and summary metadata
- mailbox read markers written only after messages were either submitted successfully or stored in the local inbox queue
- control-only poll cycles still marking mailbox messages as read after their handlers run, even when no regular teammate message survives to create a transcript turn
- replay of queued messages when the session becomes idle again
- queued inbox entries carrying generated ids and explicit `pending` status so later replay can remove only the messages actually submitted
- cleanup of already-processed queued messages after they were consumed as mid-turn attachments, with `processed` acting as an attachment-delivered-but-not-yet-garbage-collected state
- pending replay clearing only the specific messages that were successfully submitted, while rejected replay attempts leave them queued

This ordering is load-bearing. Marking messages read before successful submit or queueing would turn a transient busy state into permanent message loss.

## Shutdown and task-state reconciliation

When a worker exits, the inbox path is responsible for more than text display.

A correct rebuild should preserve:

- removal of the teammate from the leader's live team roster on confirmed shutdown
- unassignment of the worker's unfinished shared tasks back to the pending pool
- insertion of a system-style notification into the leader inbox so the leader learns what was reassigned
- completion of any lingering worker task rows that otherwise would keep the spinner tree claiming the teammate is still running
- reconciliation happening even when pane-kill metadata is missing, so logical shutdown completion does not depend on backend cleanup support

## Failure modes

- **control leak**: permission or shutdown payloads fall through and become ordinary teammate prose
- **stale callback**: a delayed approval response resolves a request that no longer exists
- **lost unread message**: mailbox items are marked read before submit or queueing succeeds
- **double approval prompt**: duplicate unread permission requests re-enter the leader queue after read-marker failure
- **authority spoof**: non-leader messages are allowed to change plan state or permission mode
- **processed-queue leak**: messages already surfaced mid-turn never leave the local inbox queue and keep reappearing as if they were new
- **shutdown half-reconcile**: the backend pane dies, but team membership, shared-task ownership, or running-task state is left behind

## Test Design

In the observed source, collaboration behavior is verified through protocol and state-machine regressions, bridge-aware integration coverage, and multi-agent or remote end-to-end scenarios.

Equivalent coverage should prove:

- agent lifecycle, routing, mailbox, subscription, and control-state transitions preserve the contracts documented in this leaf
- bridge transport, projection, permission forwarding, reconnect, and transcript continuity behave correctly with resettable peers and deterministic state seeds
- observable teamwork behavior remains correct when users drive the product through real teammate, pane, or remote-session surfaces
