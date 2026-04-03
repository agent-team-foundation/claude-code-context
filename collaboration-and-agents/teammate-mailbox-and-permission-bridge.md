---
title: "Teammate Mailbox and Permission Bridge"
owners: []
soft_links: [/collaboration-and-agents/worker-execution-boundaries.md, /collaboration-and-agents/in-process-teammate-lifecycle.md, /tools-and-permissions/permission-model.md, /ui-and-experience/interaction-feedback.md]
---

# Teammate Mailbox and Permission Bridge

Claude Code uses a shared mailbox protocol so teammates can talk to each other without sharing one mutable conversation buffer. That same transport also carries permission requests, sandbox approvals, plan-approval responses, shutdown control traffic, and mode changes. In-process workers add a direct bridge into the leader's UI when both sides live in the same process, but the mailbox contract remains the compatibility fallback.

## Mailbox transport contract

Equivalent behavior should preserve:

- one inbox per teammate name within a team
- append-only mailbox writes protected by locking so concurrent senders do not trample each other
- explicit read markers rather than destructive dequeue on read
- the same logical transport for pane-backed and in-process teammates so control flows behave the same across backends

Mailbox routing is by teammate name and team, not by ephemeral process identity.

## Structured versus conversational traffic

Not every mailbox item is meant to become model context.

The durable rule is:

- raw teammate messages may be rendered as teammate-message XML with optional color and summary
- structured protocol messages must be intercepted by the inbox poller before attachment generation
- protocol traffic should never be bundled into generic teammate-message attachments just because it traveled through the same inbox file

Important structured message families include:

- idle notifications
- tool-permission requests and responses
- sandbox network-permission requests and responses
- plan-approval requests and responses
- shutdown requests plus shutdown-approved or shutdown-rejected replies
- team-wide permission updates
- leader-driven permission-mode changes

## Direct leader permission bridge

When an in-process worker and the leader share one process, permission requests should use the leader's normal approval UI rather than a degraded side channel.

Equivalent behavior should preserve:

- registration of the leader's live permission queue and permission-context setter into module-level bridge state
- worker permission prompts that reuse the same tool-specific approval UI the leader sees, including worker identity badges
- bash classifier auto-approval before asking the leader when classifier confidence is sufficient
- propagation of accepted permission updates back into the leader's shared permission context
- preservation of the leader's own mode when applying those updates, so a worker's transformed context cannot overwrite coordinator or leader mode

## Mailbox fallback and compatibility layer

The bridge is preferred, but the mailbox path remains necessary.

A faithful rebuild should preserve:

- worker-side callback registration keyed by permission request ID
- mailbox-based permission requests when the live leader bridge is unavailable
- mailbox-based permission responses that resolve the matching worker callback
- compatibility with older file-based pending or resolved permission flows while newer mailbox IPC is taking over
- cleanup of resolved artifacts and callbacks after a response is consumed

Malformed external permission updates should be dropped instead of being applied blindly.

## Session-clear hygiene

Permission callbacks outlive a single render tree, so they need explicit reset.

Equivalent behavior should:

- clear pending permission and sandbox callback registries on session reset
- avoid delivering stale approvals into unrelated future requests after `/clear`

## Plan-approval and mode inheritance

Teammate plan approval is another mailbox-mediated control flow.

Required behavior:

- leader-side inbox handling may auto-approve teammate plan requests
- the returned permission mode should inherit the leader's current external mode
- if the leader is itself in plan mode, the inherited worker mode should normalize back to an ordinary execution mode rather than trapping the worker in plan forever
- separate UI state such as "awaiting plan approval" should be cleared without conflating it with the worker's permission-mode update

## Sandbox network approvals

Sandbox host approvals use the same overall pattern as tool permissions but need their own request and callback namespace.

Equivalent behavior should preserve:

- unique sandbox request IDs
- worker-to-leader requests that carry host identity plus worker identity
- leader-to-worker responses that resolve the matching pending sandbox callback
- no cross-talk between tool-permission and sandbox-permission registries

## Shutdown and mode-control traffic

Mailbox control traffic also governs teammate lifecycle and steering.

Equivalent behavior should preserve:

- shutdown requests that remain visible to the teammate model or UI for approval or rejection
- shutdown-approved messages that let the leader finish backend-specific cleanup
- mode-set messages that let the leader cycle a worker's permission mode without editing its prompt history
- team permission update broadcasts that carry shared allow rules to workers

## Failure modes

- **protocol leak**: shutdown or permission JSON is surfaced as ordinary teammate text and never reaches its handler
- **mode bleed-back**: worker permission updates overwrite the leader's actual mode
- **stale approval**: a callback from an older request fires after session reset and resolves the wrong permission prompt
- **registry collision**: sandbox and tool-permission responses share identifiers or handlers and unblock the wrong waiter
- **transport split-brain**: mailbox IPC and legacy file-based polling disagree about which request is canonical
