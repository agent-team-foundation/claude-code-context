---
title: "Permission Resolution Races and Forwarding"
owners: []
soft_links: [/tools-and-permissions/permissions/permission-decision-pipeline.md, /tools-and-permissions/execution-and-hooks/tool-execution-state-machine.md, /collaboration-and-agents/teammate-mailbox-and-permission-bridge.md, /integrations/mcp/channel-servers-and-permission-relay.md]
---

# Permission Resolution Races and Forwarding

When a permission decision reaches `ask`, multiple async responders may compete to resolve it. The contract is not "one dialog"; it is "one winner across several channels."

## Single-winner resolution primitive

Equivalent behavior should preserve an atomic claim-or-resolve guard:

- only the first resolver can commit a final decision
- late responses become no-ops
- claim must happen before awaited work when callbacks include async steps

This prevents double-apply bugs where one approval path races another.

## Competing resolution channels

A pending permission can be resolved by several channels:

- local interactive dialog (allow, reject, abort)
- remote bridge response (when remote control surfaces are active)
- channel-permission relay response (when enabled and supported)
- permission hooks
- classifier auto-approval
- explicit recheck after config/mode changes
- abort signal cancellation

All of these must converge through the same single-winner guard.

## Forwarding contracts

Equivalent behavior should preserve distinct forwarding paths:

- bridge forwarding to remote control clients with request, response, and explicit cancel
- swarm worker forwarding to leader mailbox with callback registration before send (to avoid early-response races)
- optional channel relay forwarding via MCP servers with request IDs and structured allow/deny replies

Each path should support teardown when another channel wins.

## Cleanup invariants after any winner

Once any resolver wins, the runtime should:

- clear pending queue UI state
- unsubscribe pending response handlers
- cancel sibling remote prompts where supported
- clear classifier in-progress indicators
- clear worker pending-request markers

Without this, stale prompts or stale listeners can leak into later tool calls.

## Stale and unknown response behavior

Late responses for unknown request IDs should be safely ignored. This includes mailbox replies, bridge replies, and channel relay replies that arrive after local resolution.

## Failure modes

- **double resolution**: two channels both commit and mutate state
- **listener leak**: stale handlers remain attached and react to future requests
- **stale remote UI**: remote prompt stays open after local approval already executed
- **worker dead-wait**: worker callback registers after sending request and misses fast leader reply
- **abort desync**: abort path resolves locally but leaves forwarded requests active
