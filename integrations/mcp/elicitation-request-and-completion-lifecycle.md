---
title: "Elicitation Request and Completion Lifecycle"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /integrations/mcp/connection-and-recovery-contract.md, /tools-and-permissions/tool-hook-control-plane.md, /ui-and-experience/ask-user-question-and-plan-interview-ui.md]
---

# Elicitation Request and Completion Lifecycle

MCP elicitation support is a full lifecycle: request intake, optional hook auto-resolution, interactive collection, post-response hook mediation, and (for URL mode) explicit completion signaling.

## Handler registration boundary

Elicitation handlers should only register for MCP clients that negotiated elicitation capability. Capability-missing clients should continue operating without elicitation surfaces rather than failing connection setup.

## Request intake and queueing

Each elicitation request should be materialized as a queue event with:

- server identity
- per-request ID from the connection
- request payload and mode (`form` or `url`)
- cancellation signal
- a response callback that resolves the underlying protocol request

If the request signal is already aborted, the lifecycle should return a cancel action immediately.

## Pre-response hooks

Before showing UI, elicitation hooks may:

- auto-accept with content
- auto-decline
- provide no decision and let the interactive path proceed

Hook failures should degrade safely to interactive handling, not crash the MCP session.

## Interactive response contract

Equivalent behavior should preserve:

- explicit user response actions (`accept`, `decline`, `cancel`)
- telemetry and observability for shown and returned actions
- abort-to-cancel behavior while dialogs are open

URL mode should include a waiting phase after opening the browser, with explicit dismissal/retry/cancel actions.

## Completion signaling for URL mode

URL-mode elicitations require a second signal: server completion notification keyed by elicitation ID.

Equivalent behavior should preserve:

- queue lookup by server plus elicitation ID
- queue-event mutation to mark completion
- auto-dismiss behavior in the waiting dialog when completion arrives
- safe ignore of unknown/stale completion IDs

## Post-response hook mediation

After user choice is collected, elicitation-result hooks may override action/content or block with decline. Notification hooks should still observe the final action for auditability.

## SDK control-plane bridge

Headless/SDK surfaces should use a structured control request-response contract for elicitation:

- control request carries server name, message, mode, optional URL, optional schema, optional elicitation ID
- control response returns `accept`/`decline`/`cancel` plus optional content

This keeps terminal and SDK behavior aligned without inventing a separate business flow.

## Failure modes

- **capability mismatch**: elicitation handlers register on clients that never negotiated elicitation
- **lost cancellation**: aborted requests remain stuck in queue and never resolve
- **URL dead-wait**: completion notifications do not clear waiting-state UI
- **stale completion match**: completion from one request resolves a different pending elicitation
- **hook bypass**: post-response hooks are skipped, breaking policy or audit workflows
