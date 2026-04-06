---
title: "Peer Addressing, Discovery, and Routing"
owners: []
soft_links: [/collaboration-and-agents/teammate-mailbox-and-permission-bridge.md, /collaboration-and-agents/bridge-transport-and-remote-control-runtime.md, /collaboration-and-agents/bridge-session-state-projection-and-command-narrowing.md, /runtime-orchestration/tasks/local-agent-task-lifecycle.md, /runtime-orchestration/sessions/session-discovery-and-lite-indexing.md, /tools-and-permissions/agent-and-task-control/control-plane-tools.md, /integrations/clients/sdk-control-protocol.md]
---

# Peer Addressing, Discovery, and Routing

Claude Code has more than one message plane. Team-local swarm mailboxes are only one of them. Plain-text follow-up can also target same-process local agents, other live local sessions on the same machine, and Remote Control sessions that are currently acting as addressable peers.

## Scope boundary

This leaf covers:

- address namespaces and reply-address parsing
- live peer discovery distinct from resume/session discovery
- routing order across local agents, team mailboxes, direct local peers, and Remote Control peers
- the trust and delivery boundaries around cross-session messaging

It intentionally does not re-document:

- team-local mailbox transport and structured swarm control payloads, which stay in [teammate-mailbox-and-permission-bridge.md](teammate-mailbox-and-permission-bridge.md)
- transcript-based resume discovery, which stays in [session-discovery-and-lite-indexing.md](../runtime-orchestration/sessions/session-discovery-and-lite-indexing.md)
- low-level Remote Control reconnect/auth mechanics, which stay in [bridge-transport-and-remote-control-runtime.md](bridge-transport-and-remote-control-runtime.md)

## Address namespaces and identity split

Equivalent behavior should preserve:

- bare teammate-style names as the team-local namespace
- explicit `uds:` addresses for direct local-session delivery over a Unix-socket route
- explicit `bridge:` addresses for Remote Control peers
- `*` broadcast meaning "all teammates in the current team" only, never "all peers everywhere"
- legacy bare socket-path reply addresses continuing to resolve as local-session peers so older senders remain replyable
- local agent IDs, teammate names, local session IDs, Remote Control session IDs, environment/pairing IDs, and reply addresses staying distinct even when one send surface can reach all of them

The load-bearing rule is that a user-visible reply target is not always the same thing as the session's canonical resume identity.

## Routing order for plain-text follow-up

Equivalent behavior should preserve:

- plain-text sends to a bare name resolving against same-process local-agent identity before any team-mailbox fallback
- running local agents receiving follow-up through their per-task prompt queue and consuming it on the next eligible tool/attachment round
- stopped or evicted local agents being resumed from transcript state under the same agent identity when possible, instead of silently dropping or retargeting the follow-up
- bare-name routing falling back to team-local mailbox delivery only when no same-process local-agent match exists
- structured control payloads staying team-local rather than taking these local-agent or cross-session routes
- cross-session routes accepting plain text only, never structured control JSON

This keeps one send surface convenient without flattening away the very different semantics behind each target family.

## Live peer discovery versus resume discovery

Equivalent behavior should preserve:

- a live-session registry for messaging peers that is separate from resumable transcript discovery
- publication of top-level live sessions only, intentionally excluding swarm teammates and subordinate subagents so concurrent-session discovery does not get polluted with internal worker noise
- live records carrying enough routing context to target safely: session identity, working context, session kind, optional user-facing name, and direct local ingress when available
- Remote Control-backed sessions publishing an additional bridge-session alias so discovery can deduplicate "same logical session reachable locally and remotely"
- preference for the direct local route when both a local socket and a Remote Control alias reach the same live session
- rename, session-switch, activity-state, bridge attach, and bridge teardown updating that live registry rather than leaving stale aliases behind

The exact peer-listing presentation is only partially recoverable from this snapshot. The durable requirement is the identity and route-preference model, not one specific row layout.

## Startup gating and metadata publication

Equivalent behavior should preserve:

- local direct-peer capability existing only when the session starts a local messaging server
- bare/scripted sessions skipping that server by default, while an explicit socket-path request can opt them back into direct local messaging
- startup binding the local messaging server before hooks or attached clients snapshot environment/process metadata, so spawned children and trusted clients learn a stable reply target
- trusted/internal `system/init` consumers being allowed to receive hidden peer-targeting metadata such as a local messaging socket path without making that field part of the public SDK contract
- explicit local-socket opt-in being able to change whether peer-injected prompts are replayed onto structured output streams, while auto-created passive sockets need not reshape every headless stream by default

## Cross-session delivery and receive semantics

Equivalent behavior should preserve:

- direct local-session sends enqueueing work at the receiver and draining on the receiver's next eligible round instead of first probing a busy/idle state
- Remote Control peer sends requiring a live full bridge session, not an outbound-only mirror attachment
- cross-machine `bridge:` sends passing an explicit user-consent gate even when normal teammate traffic does not
- incoming cross-session messages arriving as a dedicated `cross-session-message` envelope rather than as teammate mailbox content
- the displayed `from` address being the exact reply token the receiver should copy back into the next `to`, including `uds:`/`bridge:` prefixes or legacy bare socket paths
- cross-session ingress bypassing local slash-command parsing and exit-word shortcuts so peer text is treated as plain queued prompt content

This is a different plane from swarm mailbox control traffic: queueable prompt ingress with exact reply-address preservation.

## Failure modes

- **identity collapse**: teammate names, local agent IDs, local socket paths, and Remote Control session IDs are treated as one interchangeable identifier
- **fallback misroute**: a stopped local agent follow-up drops into team mailbox delivery instead of transcript-backed resume
- **peer duplication**: one live session appears as two separate targets because local and bridge reachability are not deduplicated
- **mirror send hole**: an outbound-only mirror session is exposed as an addressable `bridge:` peer even though it cannot safely receive prompt injection
- **protocol bleed**: structured team-control payloads are allowed onto cross-session routes and become meaningless or dangerous prompt text
- **reply breakage**: the UI normalizes or prettifies the sender address and destroys the exact token needed for a correct reply
- **startup race**: the local peer address is published only after hooks or attached clients already snapshotted environment state
