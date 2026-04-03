---
title: "Remote Session Contract"
owners: []
soft_links: [/collaboration-and-agents/remote-and-bridge-flows.md, /integrations/clients/client-surfaces.md, /tools-and-permissions/permission-model.md]
---

# Remote Session Contract

Remote sessions are not just transports. They split responsibility between a remote executor and a local or companion client.

## Ownership boundary

- The remote runtime owns turn execution, streaming events, and remote task progress.
- The client owns rendering, user-facing session controls, and permission response UX unless the remote surface explicitly handles those itself.
- Session identity, repository identity, and handoff metadata must remain stable across reconnects and resumes.

## Lifecycle

1. Remote session configured.
2. Transport connected.
3. Remote execution active.
4. Permission challenge or user-decision branch.
5. Reconnecting or viewer-only degraded mode.
6. Resumed, handed off, or terminated.

## Contract requirements

- inbound messages must preserve enough structure to render tool progress, compaction events, and assistant output correctly
- outbound user messages must carry stable session identity
- permission requests must be cancellable and must fail closed if the client disappears
- reconnect paths must distinguish transient network loss from expired or invalid sessions

## Failure boundaries

- **session not reachable**: network or transport failure before the session is established
- **session expired or invalid**: the client must fetch a fresh session or fail explicitly
- **permission request stranded**: remote work cannot proceed because approval cannot be delivered
- **resume mismatch**: remote state no longer matches local repo, branch, or session expectations
