---
title: "Structured I/O and Headless Session Loop"
owners: []
soft_links: [/integrations/clients/sdk-control-protocol.md, /integrations/clients/sdk-hook-event-transport.md, /runtime-orchestration/unified-command-queue-and-drain.md, /collaboration-and-agents/bridge-contract.md, /product-surface/session-state-and-breakpoints.md]
---

# Structured I/O and Headless Session Loop

Claude Code's SDK and remote clients do not screen-scrape the terminal. They drive a line-oriented control channel that is paired with a headless session loop, a pending-request registry, optional remote transports, and typed event replay rules. A faithful rebuild needs that full execution layer, not only the public message schemas.

## Scope boundary

This leaf covers:

- the structured stdin and stdout transport used by headless and SDK-style sessions
- how request and response pairing, cancellation, replay, and duplicate suppression work
- how headless sessions initialize, stream output, and decide what becomes the final result
- how permission prompts, hook callbacks, elicitation, MCP messages, and sandbox asks are externalized through the same transport
- how remote transports and CCR-style state reporting extend the same control loop

It intentionally does not re-document:

- the abstract control schema catalog already captured in [sdk-control-protocol.md](sdk-control-protocol.md)
- queue priority and drain internals already captured in [unified-command-queue-and-drain.md](../../runtime-orchestration/unified-command-queue-and-drain.md)
- remote pairing, bridge trust, or managed-environment policy envelopes beyond the points where they touch this transport loop

## Structured transport as the session boundary

Equivalent behavior should preserve:

- one line-oriented NDJSON transport where user messages, control requests, control responses, keep-alives, and a small set of auxiliary records all share the same framing
- one structured reader that normalizes inbound control-message keys before type-routing, so compatibility shims happen before the runtime decides how to interpret a line
- an outbound stream object that serializes SDK-facing emissions from one place, preventing control requests from overtaking queued stream events
- the ability to prepend synthetic user messages into the input stream before or during iteration, so resumed agents, init-defined agents, and startup hooks can inject a first turn without forking the transport
- a strict user-role expectation for inbound prompt messages, with malformed lines treated as fatal protocol errors rather than silently downgraded transcript text
- keep-alive frames being transport health signals rather than conversation content
- environment-variable update messages being applied directly to process state when the transport is allowed to mutate runtime auth or environment inputs

## Pending request registry and cancellation contract

Equivalent behavior should preserve:

- every outbound control request receiving a request ID, a stored resolver pair, and an optional schema that validates the eventual response payload before it is accepted
- input-stream closure rejecting all still-pending requests so permission prompts, hook callbacks, or MCP round-trips do not hang forever after the host disconnects
- caller-driven aborts emitting a control-cancel request immediately while also rejecting the local promise without waiting for host acknowledgment
- cancellation bookkeeping removing the pending entry exactly once regardless of whether the abort, the response, or stream shutdown wins the race
- response handling supporting both success and error payloads, with parse failures staying local to the waiting promise instead of corrupting later protocol state
- control responses being optionally replayable to hosts that requested a full echo stream, but otherwise being consumed as protocol state rather than transcript output

## Duplicate suppression and orphan recovery

Equivalent behavior should preserve:

- resolved tool-use identifiers being tracked in a bounded set so duplicate late permission responses from reconnecting transports do not execute the same tool a second time
- unmatched control responses first being checked against that resolved set before they are treated as orphans
- an unexpected-response callback path that can recover orphaned permission approvals by finding the unresolved tool use in transcript state and re-enqueueing it for execution
- duplicate user-message UUIDs being filtered against both persisted session history and an in-memory recent set, so reconnects can acknowledge already-seen messages without re-running them
- replay mode still closing lifecycle state for duplicate historical messages even when execution is skipped, preventing client-side async-message rows from staying open forever

## Externalized permission, hook, and elicitation flows

Equivalent behavior should preserve:

- host-rendered permission prompts using the same structured control request family as the core SDK transport rather than a second bespoke approval API
- permission prompts carrying enough structured detail for the host to show the blocked action, raw tool input, request identity, and any precomputed suggestions
- permission-request hooks racing against the host-visible permission prompt instead of blocking it, with whichever side decides first canceling or overshadowing the loser
- session state moving into a requires-action phase with structured pending-action details whenever the runtime is waiting on an external permission answer
- bridge-origin permission answers being injectable into the same pending request registry, while also canceling the stale host-side request so the losing prompt does not hang
- hook callbacks, MCP elicitation, sandbox network asks, and MCP JSON-RPC round-trips all reusing the same pending-request machinery instead of inventing separate transport layers
- sandbox network access being modeled as a synthetic tool permission request so hosts can reuse their normal approval UI and policy flow

## Headless bootstrap and initialization

Equivalent behavior should preserve:

- headless startup selecting StructuredIO or RemoteIO from one factory based on whether the session is local stdio or attached to a remote stream URL
- non-interactive startup subscribing directly to settings hot-reload because there is no React tree to host the usual settings hook
- remote-only policy and trust checks, sandbox setup, and other preflight gates running before the first streamed output so hosts never see a partially initialized session pretending to be ready
- resume, rewind, agent restore, and hook-injected initial-user-message paths being able to alter the first headless turn before the main run loop begins
- initialize requests being the one place where stdin-provided system prompts, appended prompts, JSON schemas, hooks, and SDK-defined agents are merged into the live runtime configuration
- initialize responses returning the currently invocable command catalog, agent catalog, output styles, model list, account snapshot, process identity, and fast-mode state from the actual live runtime rather than from a static SDK manifest
- agent-defined initial prompts still entering through the structured input path, even when the host is streaming JSON rather than passing a single prompt string

## Headless run loop and streamed output

Equivalent behavior should preserve:

- two cooperating loops in headless mode: one that reads structured input and one that drains queued executable work until the session is genuinely idle
- command draining and background-task waiting sharing one mutexed run loop so a host cannot accidentally create overlapping turns by sending prompts too quickly
- task-progress SDK events being drained before queued command work so clients see progress updates before later completion or notification events
- result messages being temporarily held back while certain background agents are still alive, so clients do not interpret the session as complete before deferred follow-up output has surfaced
- the runtime transitioning to idle only after pending internal-event flushes have completed, then draining any late SDK state or task bookend events before truly going quiescent
- non-stream output modes retaining only the final user-visible result, while verbose stream-json mode can emit the full typed event stream
- optional output transforms being able to replace the raw assistant stream with streamlined summaries or prompt suggestions without changing underlying session semantics

## Replay, partial output, and client-visible lifecycle

Equivalent behavior should preserve:

- replay mode being able to echo assistant messages, acknowledged user messages, control responses, and other selected protocol traffic back to the host when the host asked for a mirrored event stream
- replay acknowledgments existing even for merged prompt batches or duplicate inbound messages so async client footers can close every submitted UUID
- prompt suggestions being emitted only after the corresponding result is safely deliverable, preventing a host from receiving a "next prompt" hint for a turn whose result is still intentionally withheld
- partial assistant streaming remaining optional so low-noise consumers can wait for coarser events while richer hosts opt into incremental output
- session-state changes such as running, idle, or requires-action being mirrored into typed SDK system events and remote metadata channels from one shared state source

## Remote transport and CCR-style extensions

Equivalent behavior should preserve:

- remote transport setup choosing the concrete wire protocol from the stream URL while still feeding all inbound data back through the same StructuredIO reader
- auth and environment-runner headers being refreshed on reconnect instead of being frozen to whatever token existed at process start
- transport close ending the local input stream so the headless session shuts down through the same cleanup path as a local EOF
- bridge mode being able to echo outbound control requests, and optionally all outbound traffic in debug mode, so an upstream bridge parent can mirror or intercept approvals
- CCR-style remote mode restoring worker-side external metadata before headless message loading, letting resumed sessions recover permission mode, pending action, model, and other session metadata from remote state
- CCR v2 integration registering internal-event writers and readers, delivery reporters, and state or metadata reporters before the transport connects, so early inbound events cannot outrun their acknowledgment wiring
- bridge-only keep-alive frames being emitted on a configurable timer to keep otherwise idle remote-control sessions from being reaped by intermediaries, while remaining invisible to normal conversation consumers

## Failure modes

- **protocol deadlock**: a pending permission or hook request never resolves after the host disconnects because stream closure does not reject waiting promises
- **duplicate execution**: reconnect-delivered control responses or user messages re-run work that the session already completed
- **replay confusion**: mirrored acknowledgments, control responses, or suggestions arrive in an order that causes the host to think a turn is complete when it is still being held back
- **requires-action blind spot**: a permission prompt is externalized, but no structured pending-action state is emitted, leaving remote clients unable to explain what the session is waiting on
- **transport drift**: RemoteIO and local StructuredIO stop sharing the same request registry, so one surface learns behaviors the other cannot reproduce
- **remote resume amnesia**: worker external metadata is not restored before initial message loading, so resumed remote sessions lose model, permission, or pending-action context
- **idle timeout breakage**: keep-alive signaling is missing or leaks into the visible message stream instead of staying a transport-only health frame
