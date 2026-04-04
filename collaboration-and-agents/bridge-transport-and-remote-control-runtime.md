---
title: "Bridge Transport and Remote-Control Runtime"
owners: []
soft_links: [/collaboration-and-agents/bridge-contract.md, /collaboration-and-agents/remote-session-contract.md, /integrations/clients/structured-io-and-headless-session-loop.md, /runtime-orchestration/state-machines-and-failures.md]
---

# Bridge Transport and Remote-Control Runtime

The bridge contract only explains what a constrained companion client is allowed to do. The runtime underneath it is more specific: Claude Code has to pick the right bootstrap path, create or reattach the right session identity, choose the correct auth shape for each transport generation, preserve message ordering through reconnects, and fail over without duplicating prompts or stranding permissions.

## Scope boundary

This leaf covers:

- how REPL-side remote control chooses between the environment-backed bridge path and the env-less direct bridge path
- how bridge sessions are created, titled, tagged, archived, and resumed across compat and infrastructure session IDs
- how bridge transports authenticate, flush initial history, gate live writes, deduplicate replay, and route inbound control traffic
- how outbound-only or mirror attachments narrow the control surface while still satisfying the server handshake
- how reconnect, token refresh, environment recovery, keep-alive, and teardown behavior preserve session continuity

It intentionally does not re-document:

- the high-level product contract for bridge-safe commands already captured in [bridge-contract.md](bridge-contract.md)
- the generic structured host I/O loop already captured in [structured-io-and-headless-session-loop.md](../integrations/clients/structured-io-and-headless-session-loop.md)
- the standalone multi-session spawn loop behind `claude remote-control` beyond the shared bridge-runtime primitives it reuses

## Bootstrap path selection and session identity

Equivalent behavior should preserve:

- bridge startup refusing to proceed unless remote control is feature-enabled, the client is signed into claude.ai, organization policy allows remote control, the organization UUID is available, and the running build satisfies the minimum version gate for the selected bridge path
- a strict distinction between transport generation and bootstrap generation: the environment-backed bridge can still use the newer CCR v2 wire protocol, while the env-less bridge removes the environment register or poll layer entirely and talks directly to session-ingress-compatible code-session endpoints
- title derivation precedence of explicit remote-control name, stored renamed title, latest meaningful human-authored user text, then a generated slug fallback
- automatic title improvement continuing after attach until the runtime has either seen an explicit rename or derived enough early prompts, including an early placeholder and a later richer regeneration from a wider conversation slice
- bridge session creation carrying repository identity and model context for the companion surface instead of creating an anonymous session card
- session identity being treated as one logical session with multiple tag encodings, so equality checks compare the underlying UUID while individual endpoints still receive the tag form they require
- crash-recovery or perpetual-session pointers recording both the bridge environment identity and the current session identity, with later reconnect code deciding whether that pointer is still reusable
- trusted-device headers remaining part of the bridge auth surface when elevated-auth enforcement is enabled, while enrollment and secure-storage failures stay best-effort rather than blocking attach

The important reconstruction rule is that bridge identity is not just a URL. It is a tuple of session ID, environment or worker authority, title state, auth context, and repo metadata that must survive reconnect logic without drifting.

## Environment-backed versus env-less attach flow

Equivalent behavior should preserve:

- the environment-backed path registering a bridge environment first, then either reconnecting an existing session in place or creating a new bridge session on that environment before polling for work dispatch
- perpetual-mode startup attempting to reuse the prior environment and session instead of always creating a fresh session, but falling back to fresh creation when the old environment cannot be resurrected
- the env-less path always creating a fresh code session first, then exchanging OAuth credentials for worker credentials through a bridge-specific handshake that also returns the API base URL and worker epoch
- the env-less path treating each credential refresh as a new worker registration event, because the credential exchange itself bumps server-side epoch and therefore invalidates older workers
- the bridge transport abstraction hiding whether reads come from HybridTransport or SSE while writes go to Session-Ingress or CCR worker endpoints, so higher-level bridge code can share one callback and teardown model
- v1 Session-Ingress traffic preferring OAuth tokens for writes and reconnects, while CCR v2 worker endpoints require worker credentials that are scoped to one session and cannot be replaced with ordinary OAuth
- multi-session-safe callers being able to provide per-instance auth closures so one bridge session does not overwrite another session's auth token in process-global environment state
- outbound-only attachments still building the write path and heartbeat path even when the inbound SSE read stream is intentionally skipped

## Initial history flush, message eligibility, and duplicate suppression

Equivalent behavior should preserve:

- only user messages, assistant messages, and local-command system events being forwarded into the bridge transcript, with virtual or display-only internal chatter excluded
- the initial history flush being capped to a configurable recent window, because the bridge transcript is for companion visibility and recovery rather than full model replay
- initial history being written only after transport connect, while a flush gate temporarily queues newer live messages so the server sees `[history..., live...]` instead of interleaved ordering
- the environment-backed reused-session path remembering which initial UUIDs were already flushed into the same remote session so reconnects do not poison the server with duplicate UUIDs
- the env-less fresh-session path skipping that cross-session flushed-UUID filter, because each attach creates a new remote session and stale local suppression would otherwise erase history on re-enable
- one bounded recent-posted UUID set suppressing echoes of locally forwarded events, plus a second bounded recent-inbound UUID set suppressing replayed inbound prompts after sequence-cursor loss or transport rebuild
- initial flush UUIDs seeding the outbound dedup state so the first server echo of flushed history is recognized as our own traffic
- user-message scanning for title derivation happening before flush-gate queueing, so queued prompts can still improve session naming
- mid-turn attach recognizing whether the last eligible historical message represents a running prompt and pushing running state immediately instead of leaving the remote session visually idle until the next explicit user event

## Inbound routing and server control handling

Equivalent behavior should preserve:

- every inbound frame being normalized through compatibility key rewriting before the runtime decides whether it is a control response, control request, ordinary SDK message, or ignorable noise
- control responses being routed to the permission or pending-request layer instead of being mistaken for transcript events
- server-initiated control requests receiving a prompt response even when the bridge surface is narrow, because silence causes the server to kill the connection
- `initialize` returning a minimal success payload that proves the bridge is alive without pretending the companion owns the full REPL command or model catalog
- `set_model`, `set_max_thinking_tokens`, `interrupt`, and permission-mode changes delegating to local callbacks when that context actually supports them
- unsupported or unknown control-request subtypes returning structured errors instead of hanging
- outbound-only mode still replying successfully to `initialize`, but returning explicit errors for all other mutable requests so the companion does not show false success for actions that the local session will not honor
- permission-mode changes requiring a verdict callback that can reject unsupported modes or policy-forbidden transitions without corrupting the local permission invariant
- inbound bridge permission answers reusing the same control-response shape as the rest of the runtime and transitioning the visible session state out of `requires_action` once the answer wins

## Reconnect, refresh, and transport rebuild

Equivalent behavior should preserve:

- the environment-backed path keeping a background work-poll loop alive even while a transport is connected, so the server can redispatch work with a fresh token after restart, token expiry, or worker loss
- heartbeat-auth failures immediately tearing down the current work attachment and waking the poll loop, instead of waiting for long reconnect budgets while the server stops forwarding prompts
- environment-loss recovery first trying to re-register the same environment and reconnect the same session in place, then archiving the orphaned session and creating a fresh replacement only if in-place recovery fails
- reconnect-in-place preserving the user-facing session identity and previously flushed history, while fresh-session fallback resets replay cursors and rewrites the crash-recovery pointer to the new session
- the env-less path scheduling proactive credential refresh before expiry and also supporting reactive recovery after a `401`, with both paths fetching fresh bridge credentials and rebuilding the entire transport rather than swapping a token in place
- only one auth-recovery path being allowed to claim a refresh window at a time, because multiple overlapping bridge-credential fetches would each bump worker epoch and make the earlier rebuild stale immediately
- transport rebuild carrying forward the last observed SSE sequence number when the logical session stays the same, so the new read stream resumes after the last processed event instead of replaying the whole history from zero
- sequence carryover being reset when a genuinely fresh session is created, because reusing an old cursor against a new session would silently skip valid events
- v2 handshake generations being monotonic so stale async registrations cannot overwrite a newer transport that carries the correct worker epoch
- reconnect-time writes being gated or dropped intentionally rather than half-sent through a transport whose epoch has already been superseded
- connect deadlines and explicit close-code handling distinguishing recoverable auth loss from permanent transport failure, so the runtime can choose rebuild, environment recovery, or teardown appropriately

## Shared reporting, keep-alive, and teardown rules

Equivalent behavior should preserve:

- one transport interface that exposes write, batch write, close, connect callbacks, sequence introspection, drop detection, state reporting, metadata reporting, delivery reporting, and flush semantics even when some of those operations are no-ops on the legacy path
- CCR-style delivery reporting acknowledging received and processed events quickly enough that reconnects do not cause the server to redeliver already-handled prompts forever
- session-state pushes reflecting real runtime waits, especially `running`, `idle`, and `requires_action`, so companion surfaces can explain whether the bridge is working, waiting for approval, or quiescent
- silent `keep_alive` frames being emitted on a timer for bridge sessions that might otherwise look idle long enough for intermediaries or server layers to reap them
- keep-alive traffic remaining transport-only health signaling and never leaking into visible transcript or UI message loops
- teardown writing a final result marker before archive and close, because closing first can strand the final result in a client-side buffer that never drains
- environment-backed teardown stopping active work and archiving the session before deregistering the environment, while env-less teardown archives the session and then closes the transport without any environment deregistration step
- teardown retrying archive once after an auth refresh when archive fails with authorization expiry, but still completing cleanup if that retry cannot be performed
- perpetual-mode teardown being intentionally local-only: stop polling, preserve the pointer, and leave the remote session alive so a later restart can reattach instead of signaling normal termination to the server
- cleanup being idempotent so repeated shutdown signals, reconnect races, or debug fault injections do not archive or deregister the same runtime twice

## Failure modes

- **epoch split-brain**: two overlapping bridge-credential fetches both bump worker epoch, and the runtime installs the stale transport instead of the newest one
- **history interleaving**: live writes bypass the flush gate and arrive before or between historical messages, corrupting companion-side transcript ordering
- **replay storm**: sequence carryover is lost on same-session reconnect, or applied to the wrong session, so inbound prompts are endlessly replayed or silently skipped
- **false-success control replies**: outbound-only or unsupported contexts acknowledge mutable control requests as successful even though no local state changed
- **stranded work lease**: heartbeat or auth failure leaves the runtime at capacity without re-queueing work, so the server stops delivering prompts while the client appears connected
- **echo re-execution**: outbound or inbound UUID dedup is missing, causing the runtime to re-inject its own traffic or duplicate replayed prompts
- **teardown loss**: archive or result delivery is attempted after close, so the session never records a clean terminal event and may linger as stale remote work
- **pointer drift**: reconnect or periodic pointer refresh writes the wrong session or environment pair, making the next resume attach to an archived session or the wrong environment
