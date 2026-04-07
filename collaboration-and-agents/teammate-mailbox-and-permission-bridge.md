---
title: "Teammate Mailbox and Permission Bridge"
owners: []
soft_links: [/collaboration-and-agents/worker-execution-boundaries.md, /collaboration-and-agents/in-process-teammate-lifecycle.md, /collaboration-and-agents/peer-addressing-discovery-and-routing.md, /tools-and-permissions/permissions/permission-model.md, /tools-and-permissions/filesystem-and-shell/shell-command-parsing-and-classifier-flow.md, /ui-and-experience/feedback-and-notifications/interaction-feedback.md]
---

# Teammate Mailbox and Permission Bridge

Claude Code uses a shared mailbox protocol so teammates can talk to each other without sharing one mutable conversation buffer. That same transport also carries permission requests, sandbox approvals, plan-approval responses, shutdown control traffic, and mode changes. In-process workers add a direct bridge into the leader's UI when both sides live in the same process, but the mailbox contract remains the compatibility fallback.

This leaf is intentionally limited to the team-local swarm mailbox plane. Same-process local-agent follow-up, direct session-to-session delivery, and Remote Control peer delivery are separate routing paths captured in [peer-addressing-discovery-and-routing.md](peer-addressing-discovery-and-routing.md).

## Mailbox transport contract

Equivalent behavior should preserve:

- one inbox file per teammate name within a team, rooted under the teams directory and derived from sanitized team and agent path components
- lazy directory creation for the per-team inbox folder plus lazy inbox-file creation on first write, without accidentally creating files during clear or read-only paths
- append-only mailbox writes protected by locking plus retry backoff so concurrent senders do not trample each other
- re-reading inbox contents after acquiring the write lock, then appending the new message to that fresh snapshot before rewriting the file
- explicit read markers rather than destructive dequeue on read
- a mailbox record shape that always carries sender name, raw text payload, timestamp, read bit, and optional color or short summary metadata for UI use
- missing inbox files reading as an empty mailbox rather than a hard failure
- lock-protected read-mark operations for mark-one-by-index, mark-all, and predicate-based partial acknowledgement
- the same logical transport for pane-backed and in-process teammates so control flows behave the same across backends

Mailbox routing is by teammate name and team, not by ephemeral process identity, local session socket, or Remote Control session identifier.

## Structured versus conversational traffic

Not every mailbox item is meant to become model context.

The durable rule is:

- raw teammate messages may be rendered as teammate-message XML with optional color and summary
- structured protocol messages must be intercepted by the inbox poller before attachment generation
- protocol traffic should never be bundled into generic teammate-message attachments just because it traveled through the same inbox file
- structured control payloads remain team-local; cross-session peer routes accept plain text only

Important structured message families include:

- tool-permission requests and responses
- sandbox network-permission requests and responses
- plan-approval requests and responses
- shutdown requests and shutdown-approved replies
- team-wide permission updates
- leader-driven permission-mode changes

Equivalent behavior should also preserve:

- a narrower attachment-exclusion protocol set than “all structured JSON,” so idle notifications, task assignments, shutdown rejections, task-completed payloads, and teammate-termination notices can still reach later UI filters or summary logic
- mailbox attachment generation marking only non-protocol messages as read, leaving the intercepted protocol subset unread until the inbox poller handles it
- raw teammate-message XML formatting preserving color and summary metadata in wrapper attributes instead of flattening everything into text
- mixed parser strictness across mailbox families: plan approval, shutdown, and mode-set control use schema-validated parsing, while permission, sandbox, idle, task-assignment, and team-permission payloads rely primarily on `type`-based JSON detection

## Direct leader permission bridge

When an in-process worker and the leader share one process, permission requests should use the leader's normal approval UI rather than a degraded side channel.

Equivalent behavior should preserve:

- registration of the leader's live permission queue and permission-context setter into module-level bridge state
- worker permission prompts that reuse the same tool-specific approval UI the leader sees, including worker identity badges
- bash classifier auto-approval before asking the leader when classifier confidence is sufficient
- unresolved shell asks forwarding only after that speculative local classifier path has had a chance to win, so the leader is not bothered for requests that could already have been auto-approved safely
- propagation of accepted permission updates back into the leader's shared permission context
- preservation of the leader's own mode when applying those updates, so a worker's transformed context cannot overwrite coordinator or leader mode

## Mailbox fallback and compatibility layer

The bridge is preferred, but the mailbox path remains necessary.

A faithful rebuild should preserve:

- worker-side callback registration keyed by permission request ID
- mailbox-based permission requests when the live leader bridge is unavailable
- mailbox-based permission responses that resolve the matching worker callback
- permission-request payload fields staying aligned with SDK control-plane naming, including snake_case request and tool-use identifiers
- permission-response payloads mirroring control success-versus-error structure instead of inventing a separate ad hoc response shape
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
- plan-approval request payloads carrying requester identity, request id, plan file path, plan body, and timestamp as first-class structured fields
- plan-approval responses carrying an approval boolean, request id, optional feedback, timestamp, and optional inherited permission mode
- the returned permission mode should inherit the leader's current external mode
- if the leader is itself in plan mode, the inherited worker mode should normalize back to an ordinary execution mode rather than trapping the worker in plan forever
- separate UI state such as "awaiting plan approval" should be cleared without conflating it with the worker's permission-mode update

## Sandbox network approvals

Sandbox host approvals use the same overall pattern as tool permissions but need their own request and callback namespace.

Equivalent behavior should preserve:

- unique sandbox request IDs
- worker-to-leader requests that carry host identity in a nested host-pattern object plus worker id, worker name, optional worker color, and creation time
- leader-to-worker responses that resolve the matching pending sandbox callback
- no cross-talk between tool-permission and sandbox-permission registries

## Shutdown and mode-control traffic

Mailbox control traffic also governs teammate lifecycle and steering.

Equivalent behavior should preserve:

- shutdown-request payloads using deterministic request ids per target and inheriting sender identity from the current agent context or reserved leader identity
- shutdown requests that remain visible to the teammate model or UI for approval or rejection
- shutdown-approved messages that let the leader finish backend-specific cleanup and may also carry optional pane or backend metadata for that cleanup step
- shutdown-rejected messages remaining visible coordination traffic rather than being hidden inside the attachment-exclusion protocol subset
- mode-set messages that let the leader cycle a worker's permission mode without editing its prompt history
- team permission update broadcasts that carry shared allow rules to workers

## Failure modes

- **over-broad protocol filter**: every structured JSON mailbox item is treated as control-plane traffic and idle, assignment, or rejection updates never reach the UI layer
- **protocol leak**: shutdown or permission JSON is surfaced as ordinary teammate text and never reaches its handler
- **write race**: concurrent mailbox senders overwrite one another because the writer does not re-read after acquiring the lock
- **mode bleed-back**: worker permission updates overwrite the leader's actual mode
- **stale approval**: a callback from an older request fires after session reset and resolves the wrong permission prompt
- **registry collision**: sandbox and tool-permission responses share identifiers or handlers and unblock the wrong waiter
- **transport split-brain**: mailbox IPC and legacy file-based polling disagree about which request is canonical
