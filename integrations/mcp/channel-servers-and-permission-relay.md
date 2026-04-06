---
title: "Channel Servers and Permission Relay"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /integrations/mcp/config-layering-policy-and-dedup.md, /tools-and-permissions/permissions/permission-resolution-races-and-forwarding.md, /ui-and-experience/feedback-and-notifications/status-line-and-footer-notification-stack.md]
---

# Channel Servers and Permission Relay

Channel support treats a subset of MCP servers as inbound message transports, then optionally lets those same servers relay binary permission decisions.

## Channel server admission gates

A server is only treated as a channel when all of these checks pass in order:

- it declares the channel capability
- runtime channel feature gates are enabled
- the session is authenticated on the required first-party auth path
- org policy allows channels for managed subscriptions
- the server is explicitly listed in session channel intent
- plugin channel entries pass marketplace identity checks and approved-channel allowlists (or a development bypass)

If any gate fails, the MCP connection can still stay alive for normal tools; only channel notification handlers are skipped.

## Session-scoped trust declaration

Equivalent behavior should preserve two separate user intent forms:

- explicit plugin channel entries (plugin name plus expected marketplace)
- explicit raw server entries

Plugin entries carry a stronger trust check because runtime names are namespaced and do not by themselves prove marketplace provenance.

## Inbound message injection contract

Accepted channel notifications should be converted into structured conversation attachments rather than plain text passthrough.

Important invariants:

- channel metadata keys are sanitized before being projected into structured attributes
- inbound messages are wrapped with source identity so the model can attribute origin
- channel prompts are queued as high-priority meta input so they can wake idle loops quickly without being mistaken for local slash commands

## Permission relay is a second capability

Permission relay is not implied by channel messaging alone.

Equivalent behavior should preserve:

- a separate runtime gate for permission relay enablement
- a separate server capability for permission reply events
- app-state wiring that exposes relay callbacks only when relay is enabled

That split allows channels to ship without auto-enabling remote approval surfaces.

## Permission relay protocol

Relay behavior should preserve a request-response map keyed by short request IDs:

- outbound relay request includes tool identity and a truncated preview payload
- inbound relay response is structured (`allow` or `deny`) plus request ID
- responses are matched only against pending IDs; unknown or stale IDs are ignored

Relay responses race with local/bridge/hook/classifier paths; winning resolution is handled by the permission race arbiter.

## Handler teardown and demotion

When channel gating changes mid-session (for example, auth or policy transitions), notification handlers should be removed idempotently. A gate result of "skip" must not leave previously-registered channel handlers active.

## Failure modes

- **gate drift**: channel handlers remain active after auth or policy demotion
- **provenance mismatch**: user-intended marketplace and installed plugin source are not cross-checked
- **capability confusion**: ordinary channel servers accidentally become permission surfaces
- **stale-approval replay**: old relay replies can still resolve new permission requests
- **payload flood**: inbound channel messages bypass structured queue controls and overwhelm local input flow
