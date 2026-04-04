---
title: "Remote Session Subscription Auth and Reconnect"
owners: []
soft_links: [/collaboration-and-agents/remote-session-contract.md, /collaboration-and-agents/remote-session-live-control-loop.md, /integrations/clients/remote-session-message-adaptation-and-viewer-state.md, /integrations/clients/sdk-control-protocol.md]
---

# Remote Session Subscription Auth and Reconnect

Claude Code's CCR-style remote sessions rely on a dedicated subscription channel that is narrower than the full remote-session concept. It owns WebSocket auth, message parsing tolerance, control-message demultiplexing, close-code-specific reconnect behavior, and keepalive management. A faithful rebuild needs these exact semantics or remote sessions will either die too eagerly or reconnect forever in the wrong situations.

## Scope boundary

This leaf covers:

- the CCR session subscription socket and its header-authenticated connect path
- message parsing, forward-compatible type acceptance, and control-message demultiplexing
- pending permission-request bookkeeping at the remote-session manager layer
- close-code-specific reconnect ladders, forced reconnect, and ping lifecycle

It intentionally does not re-document:

- remote message rendering and viewer-state projection already covered in [remote-session-message-adaptation-and-viewer-state.md](../integrations/clients/remote-session-message-adaptation-and-viewer-state.md)
- higher-level remote ownership and permission semantics already covered in [remote-session-contract.md](remote-session-contract.md)
- bridge-specific transport behavior already covered elsewhere

## Subscription channel and auth model

Equivalent behavior should preserve:

- one dedicated subscribe socket per remote session, addressed by session ID and organization identity rather than a generic shared event bus
- the subscribe URL being derived from the OAuth API base URL and converted to a WebSocket endpoint for the session subscribe route
- authentication happening in connection headers on every socket attempt instead of through a post-open auth message
- every connect or reconnect attempt fetching a fresh bearer token rather than reusing whatever token existed when the manager was first constructed
- the remote-session manager owning socket creation and lifecycle while keeping outbound user-message submission on a separate send path
- direct disconnect clearing both the live socket reference and any pending permission-request state so a future reconnect starts from a clean manager state

## Message acceptance and demultiplexing

Equivalent behavior should preserve:

- parsing incoming payloads as JSON and dropping malformed frames without crashing the session
- treating any object with a string `type` as a valid inbound envelope, so newly introduced backend message types are not silently discarded by a stale client-side allowlist
- leaving unknown SDK message classes to downstream render or adapter code instead of rejecting them at the socket boundary
- demultiplexing control requests, control-cancel requests, control responses, and ordinary SDK messages before any viewer rendering logic runs
- acknowledgment-style control responses being treated as protocol noise for this layer rather than as transcript content
- unsupported control-request subtypes returning an explicit protocol error response so the server does not hang forever waiting for a reply the client never intends to send

## Pending permission-request bookkeeping

Equivalent behavior should preserve:

- `can_use_tool` control requests being stored by stable request ID before the local approval UI is asked to render them
- control-cancel messages looking up the original pending request and forwarding its tool-use ID, when known, so the local prompt queue can remove the correct synthetic approval row
- successful allow or deny responses deleting the pending request before sending the structured control response back over the socket
- unknown request IDs on local response being treated as an error instead of fabricating a best-effort reply against stale state
- interrupt remaining a separate control request subtype sent over the socket rather than a fake user message on the ordinary remote send path

## Close-code-specific reconnect ladder

Equivalent behavior should preserve:

- a hard distinction between permanent server-side rejection and transient transport churn
- unauthorized closes being treated as permanent and not retried automatically
- session-not-found closes getting a small special retry budget because remote compaction or handoff can make the session briefly look stale
- that session-not-found budget being separate from the ordinary reconnect-attempt counter
- session-not-found retries using a short increasing delay rather than an immediate tight loop
- ordinary transient reconnect attempts only being scheduled after the socket had previously reached the connected state, so "never connected" failures do not loop forever
- a fixed ordinary reconnect budget with a short retry delay and an explicit terminal close once the budget is exhausted
- successful reconnect resetting both the ordinary reconnect counter and the session-not-found retry counter
- the `onReconnecting` callback firing when a retry is actually scheduled, while the terminal `onClose` callback fires only when the runtime has given up

## Keepalive, cleanup, and forced reconnect

Equivalent behavior should preserve:

- a ping keepalive timer running only while the subscription is connected
- ping failures being ignored locally and left to the normal close handler rather than treated as a separate fatal path
- both the ping timer and any scheduled reconnect timer being cleared on explicit close or replacement
- forced reconnect resetting retry counters, closing the current socket, and scheduling one fresh reconnect attempt after a small delay
- this forced reconnect path being usable by higher layers when a subscription appears stale even though the remote session itself may still be alive
- reconnect and close paths nulling or replacing the active socket reference before new work begins, so stale timers or late events cannot accidentally operate on a superseded connection

## Send-path separation

Equivalent behavior should preserve:

- ordinary remote user messages traveling over the remote HTTP-style event-submission API rather than being pushed through the WebSocket subscribe channel
- control responses and interrupts traveling over the WebSocket only when the subscription is actively connected
- failed send attempts surfacing as explicit errors instead of being silently swallowed
- subscription recovery and outbound message submission failing independently, because a healthy send path does not prove that the live subscribe stream is still usable

## Failure modes

- **stale-token reconnect**: reconnect keeps reusing the first token and fails after auth rotation even though a fresh token would have worked
- **future-type blackhole**: a hardcoded inbound allowlist drops newly introduced backend message types before the adapter can decide what to do
- **permission orphan**: a cancel or local answer leaves the pending permission request in the map and blocks later responses or queue cleanup
- **compaction false death**: a transient session-not-found close during compaction is treated as permanent and the viewer gives up too early
- **pre-connect loop**: a socket that never authenticated successfully still retries forever because reconnect logic ignores whether the session was ever connected
- **split-path confusion**: outbound user messages are sent over the subscribe socket or interrupts are sent as chat input, breaking protocol expectations
