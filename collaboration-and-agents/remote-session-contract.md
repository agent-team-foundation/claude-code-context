---
title: "Remote Session Contract"
owners: []
soft_links: [/collaboration-and-agents/remote-and-bridge-flows.md, /collaboration-and-agents/remote-session-live-control-loop.md, /runtime-orchestration/app-state-and-input-routing.md, /integrations/clients/client-surfaces.md, /integrations/clients/structured-io-and-headless-session-loop.md, /tools-and-permissions/permission-model.md]
---

# Remote Session Contract

Remote sessions are not just transports. They split responsibility between a remote executor and a local or companion client.

## Ownership boundary

- The remote runtime owns turn execution, streaming events, and remote task progress.
- The client owns rendering, user-facing session controls, and permission response UX unless the remote surface explicitly handles those itself.
- Session identity, repository identity, and handoff metadata must remain stable across reconnects and resumes.
- Permission posture projected into remote metadata should expose only externally meaningful states, not worker-internal transition details.

## Lifecycle

1. Remote session configured.
2. Transport connected.
3. Remote execution active.
4. Permission challenge or user-decision branch.
5. Reconnecting or viewer-only degraded mode.
6. Resumed, handed off, or terminated.

## Transport and adaptation

- inbound messages must preserve enough structure to render tool progress, compaction events, and assistant output correctly
- outbound user messages and control responses must carry stable session identity over a separate send path
- remote event streams need an adaptation layer so replayed history, live partials, tool progress, and status events are rendered correctly without double-printing user content

## Permission and interrupt bridge

- permission requests must be tracked by stable request ID
- permission requests must be cancellable and must fail closed if the client disappears
- interrupt or stop requests must travel over an explicit control path instead of masquerading as ordinary chat input

## Reconnect and degradation

- reconnect paths must distinguish transient network loss from expired or invalid sessions
- some server-side "not found" states may merit a small retry budget because remote handoff and compaction can create short staleness windows
- viewer-only degraded mode should remain legible instead of pretending full remote control still works

## Failure boundaries

- **session not reachable**: network or transport failure before the session is established
- **session expired or invalid**: the client must fetch a fresh session or fail explicitly
- **permission request stranded**: remote work cannot proceed because approval cannot be delivered
- **resume mismatch**: remote state no longer matches local repo, branch, or session expectations
- **replay duplication**: history replay and live adaptation both render the same user-originated content
