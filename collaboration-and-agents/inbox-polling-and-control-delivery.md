---
title: "Inbox Polling and Control Delivery"
owners: []
soft_links: [/collaboration-and-agents/teammate-mailbox-and-permission-bridge.md, /runtime-orchestration/turn-attachments-and-sidechannels.md, /ui-and-experience/interaction-feedback.md]
---

# Inbox Polling and Control Delivery

Pane-backed teammates and leaders rely on inbox polling as the compatibility layer between mailbox files and live runtime state. The inbox path must be able to turn unread mailbox entries into either control actions or model-visible teammate messages without dropping, duplicating, or misclassifying traffic.

## Poll eligibility and identity

Equivalent behavior should preserve:

- polling for process-backed teammates under their own agent name
- polling for the leader under the lead agent name inside the active team
- no inbox-poller usage for in-process teammates, because they share one React tree and need a different handoff path
- an initial poll at startup plus continued short-interval polling while a leader or pane-backed teammate is active

If the in-process path and the pane-backed path share the same poller, message routing will eventually cross wires.

## Protocol interception before model delivery

Not every unread mailbox item is normal conversation.

A faithful rebuild should preserve:

- classification of unread messages into permission requests, permission responses, sandbox permission traffic, shutdown control, plan approvals, mode changes, team-wide permission updates, and ordinary teammate messages
- interception of structured control messages before XML teammate-message wrapping happens
- rejection of malformed control payloads instead of crashing or passing them through as ordinary model context
- security checks on who is allowed to trigger privileged state changes

Mailbox transport is shared, but model context and control-plane traffic are not interchangeable.

## Leader-side control handling

Equivalent behavior should preserve:

- tool-permission requests routed into the same approval UI queue the leader uses for foreground tool prompts
- worker identity badges and per-request deduplication so a read-marker failure does not enqueue the same permission request twice
- sandbox host approvals handled in a separate queue and callback namespace from ordinary tool permissions
- desktop-style notifications for newly surfaced worker approval prompts when the leader is not already focused on another decision dialog
- automatic approval of teammate plan requests using the leader's current external permission mode, normalized so a leader already in plan mode does not trap workers in plan forever
- shutdown approvals that trigger backend cleanup when pane metadata exists, then remove the worker from team state and release its unfinished shared tasks

## Worker-side control handling

Equivalent behavior should preserve:

- permission and sandbox responses that resolve only the matching pending callback if one is still registered
- plan approval responses accepted only from the team lead before leaving plan-required mode
- application of team-wide permission updates into the worker's session-scoped permission context
- leader-driven mode changes applied only when the sender is the team lead, with the new mode mirrored back into team metadata
- shutdown requests surfaced to the worker model or worker UI rather than silently killing the process on receipt

## Delivery and acknowledgement semantics

Regular teammate messages still need reliable turn delivery.

Equivalent behavior should preserve:

- immediate submission of regular unread messages when the session is idle and no blocking dialog is open
- durable queueing into app state when the session is busy or when immediate submission is rejected
- mailbox read markers written only after messages were either submitted successfully or stored in the local inbox queue
- replay of queued messages when the session becomes idle again
- cleanup of already-processed queued messages after they were consumed as mid-turn attachments
- one formatting path for regular teammate messages that preserves color and summary metadata

This ordering is load-bearing. Marking messages read before successful submit or queueing would turn a transient busy state into permanent message loss.

## Shutdown and task-state reconciliation

When a worker exits, the inbox path is responsible for more than text display.

A correct rebuild should preserve:

- removal of the teammate from the leader's live team roster on confirmed shutdown
- unassignment of the worker's unfinished shared tasks back to the pending pool
- insertion of a system-style notification into the leader inbox so the leader learns what was reassigned
- completion of any lingering worker task rows that otherwise would keep the spinner tree claiming the teammate is still running

## Failure modes

- **control leak**: permission or shutdown payloads fall through and become ordinary teammate prose
- **stale callback**: a delayed approval response resolves a request that no longer exists
- **lost unread message**: mailbox items are marked read before submit or queueing succeeds
- **double approval prompt**: duplicate unread permission requests re-enter the leader queue after read-marker failure
- **authority spoof**: non-leader messages are allowed to change plan state or permission mode
