---
title: "SDK Hook Event Transport"
owners: []
soft_links: [/integrations/clients/sdk-control-protocol.md, /tools-and-permissions/tool-hook-control-plane.md, /ui-and-experience/hook-execution-feedback.md]
---

# SDK Hook Event Transport

Claude Code separates hook execution from hook event delivery. The runtime may execute many hook types, but clients and SDK hosts see a narrower, transport-shaped event stream with explicit opt-in, bounded replay, and low-noise defaults.

## Scope boundary

This leaf covers:

- SDK/session initialization of hook callbacks and hook-event delivery
- always-emitted low-noise hook events versus broader opt-in delivery
- late-subscriber replay from a bounded pending buffer
- started/progress/response payload shape and ordering

It does not re-document:

- how hooks are discovered, merged, or matched for execution
- stop-hook or permission-hook semantics already covered in the runtime/tool leaves
- ordinary transcript rendering of hook effects

## Initialize-time callback registration is first-class

Equivalent behavior should preserve:

- SDK-style session initialization being able to register hook callback matchers keyed by named hook events
- those callback definitions remaining transport/session scoped rather than becoming durable user settings
- hook event delivery being attachable after process start without reinitializing hook execution itself
- richer remote/headless clients being able to ask for broader hook event delivery without changing which hooks actually run

The clean-room requirement is that clients subscribe to hook signals; they do not own hook execution.

## Low-noise default, opt-in expansion

Equivalent behavior should preserve two delivery bands:

- a tiny always-emitted low-noise band for compatibility-safe lifecycle hooks such as session-start/setup style events
- a larger allowlisted hook-event band that is delivered only when the client explicitly enables richer hook visibility

Important invariants:

- unsupported or unknown hook-event names should not leak through the SDK stream just because internal hook execution used them
- enabling richer delivery expands visibility, but should not alter hook ordering or outcomes
- remote/headless surfaces can opt into the broader band without rewriting the main transcript channel

## Event phases and payloads

Equivalent behavior should preserve at least three client-visible phases:

- **started** with hook identity and hook-event name
- **progress** with incremental stdout/stderr/output snapshots
- **response** with terminal output plus an explicit outcome such as success, error, or cancelled

The important product behavior is that progress is a side channel, not a transcript diff. Hosts can render it as status rows, debug panels, or SDK messages without pretending hook output was assistant text.

## Late-subscriber replay is bounded and ordered

Equivalent behavior should preserve:

- buffering recent hook events when no handler is currently attached
- replaying buffered events in original order when a handler later registers
- a hard cap on pending buffered events, with oldest-first eviction on overflow rather than unbounded memory growth

This matters because SDK and remote clients can attach after startup hooks have already begun.

## Separation from transcript and debug logging

Equivalent behavior should preserve:

- hook events being transport-side signals distinct from the ordinary transcript stream
- terminal hook responses still being logged for debug/verbose inspection even when the client did not subscribe to that event family
- clients being free to transform hook events into their own local UX without forcing the core runtime to render them as assistant messages

## Failure modes

- **event-noise flood**: every hook event is forwarded by default and swamps low-noise clients
- **late-subscriber loss**: startup or setup hook events vanish because the handler registered after execution began
- **unbounded buffer**: missing subscribers cause hook-event retention to grow without limit
- **execution/transport coupling**: subscribing to hook events changes hook execution behavior instead of only delivery
- **transcript confusion**: hook progress is mixed into ordinary conversation output and loses its structured meaning
