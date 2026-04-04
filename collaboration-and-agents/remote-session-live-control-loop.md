---
title: "Remote Session Live Control Loop"
owners: []
soft_links: [/collaboration-and-agents/remote-session-contract.md, /collaboration-and-agents/remote-session-subscription-auth-and-reconnect.md, /collaboration-and-agents/bridge-transport-and-remote-control-runtime.md, /tools-and-permissions/permission-decision-pipeline.md, /integrations/clients/sdk-control-protocol.md, /integrations/clients/structured-io-and-headless-session-loop.md]
---

# Remote Session Live Control Loop

Claude Code's remote-session support is not just transcript polling. Live control uses a bidirectional loop: WebSocket subscription for inbound events, HTTP-style submission for outbound user messages, and a structured control channel for permission and interrupt actions.

For the exact CCR subscribe-socket auth path, pending-request map semantics, and close-code reconnect ladder this loop relies on, see [remote-session-subscription-auth-and-reconnect.md](remote-session-subscription-auth-and-reconnect.md).

## Transport split

Equivalent behavior should preserve two transport roles:

- a subscription channel for inbound session events and control messages
- a send path for outbound user messages

The send path and the subscribe path fail differently and must be recoverable independently.

## Inbound message classes

The live loop needs to distinguish at least three inbound classes:

- ordinary SDK-style session messages
- control requests that require local decision handling, especially permission requests
- control-cancel messages that retract a previously pending request

Acknowledgment-style control responses may also arrive, but they should not be rendered as ordinary transcript content.

## Local adaptation

Inbound remote messages are not rendered raw.

Equivalent behavior should preserve an adapter layer that:

- converts remote assistant messages into local assistant transcript events
- converts streaming partials into the local stream-event model
- maps compaction boundaries, status messages, and tool-progress events into local system-style feedback
- ignores remote event types that are meaningful only to SDK consumers or auth plumbing
- treats historical replay differently from live streaming, because some user messages must be shown during replay but not duplicated during live mode

Without this adaptation layer, direct rendering will either miss important status context or duplicate user-originated content.

## Permission and interrupt bridge

Remote execution can still require local approval.

Equivalent behavior should preserve:

- storage of pending remote permission requests by stable request ID
- forwarding of permission prompts into the local approval UX
- explicit removal of pending requests when the server cancels them
- structured success or deny responses back to the remote session
- a dedicated interrupt control request for cancelling the active remote turn

This is the live-control equivalent of the local permission bridge used for workers.

## Reconnect model

A faithful rebuild should preserve a bounded reconnect ladder:

- permanent server-side rejection codes stop reconnect attempts immediately
- some "session not found" closes get a small retry budget because they can be transient during remote compaction or handoff
- ordinary transient disconnects get a fixed reconnect budget with backoff scheduling
- keepalive or ping logic continues only while the subscription is live

The important contract is that reconnect behavior distinguishes recoverable transport churn from definitive session death.

## Failure modes

- **request orphaning**: a cancelled permission request remains pending locally and blocks future responses
- **double rendering**: remote replay and live-mode adaptation both render the same user message
- **false permanence**: a transient remote-staleness close is treated as a hard terminal failure
- **infinite reconnect**: the client never gives up after definitive session closure
