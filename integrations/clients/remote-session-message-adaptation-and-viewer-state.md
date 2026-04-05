---
title: "Remote Session Message Adaptation and Viewer State"
owners: []
soft_links: [/integrations/clients/assistant-viewer-attach-and-history-paging.md, /integrations/clients/surface-adapter-contract.md, /collaboration-and-agents/remote-session-contract.md, /collaboration-and-agents/remote-session-live-control-loop.md, /integrations/clients/sdk-control-protocol.md]
---

# Remote Session Message Adaptation and Viewer State

Claude Code's remote-capable clients do not render remote SDK traffic verbatim. They adapt remote protocol messages into local REPL message types, keep a small amount of viewer-specific app state in sync, bridge remote permissions into local approval UX, and treat history replay differently from live traffic so the transcript stays legible without duplicating user content.

## Scope boundary

This leaf covers:

- the local adapter that converts remote SDK messages into REPL messages, stream events, and ignored classes
- the viewer-specific app-state projection for connection status, remote task count, loading state, and transcript echo suppression
- the history replay and upward paging path used by viewer-only assistant attach
- the transport-specific normalization shared by WebSocket CCR sessions, direct-connect sessions, and SSH-backed sessions

It intentionally does not re-document:

- remote session transport ownership, permission request semantics, and reconnect categories already covered in [remote-session-contract.md](../../collaboration-and-agents/remote-session-contract.md) and [remote-session-live-control-loop.md](../../collaboration-and-agents/remote-session-live-control-loop.md)
- viewer attach entry, chooser behavior, and viewport paging UX already covered in [assistant-viewer-attach-and-history-paging.md](assistant-viewer-attach-and-history-paging.md)
- remote bootstrap and environment selection already covered in other client leaves

## Adapter layer versus raw SDK traffic

Equivalent behavior should preserve:

- one explicit adapter layer between inbound remote SDK messages and local REPL rendering instead of letting each client reinterpret protocol payloads ad hoc
- assistant SDK messages mapping directly into local assistant transcript messages
- streaming partial assistant payloads mapping into the local stream-event model rather than being rendered as finished messages
- remote status, tool-progress, compact-boundary, and error-result messages being translated into local system-style feedback so existing REPL rendering paths can reuse them
- success result messages, auth-status messages, tool-use summaries, rate-limit events, and unknown future SDK-only classes being non-fatal and normally hidden from the transcript
- compact-boundary messages preserving structured compact metadata instead of flattening compaction into plain text only

## User-message handling and duplicate suppression

Equivalent behavior should preserve:

- live remote user text normally being ignored because the local REPL already appended the user message before sending it upstream
- viewer-only history replay enabling explicit conversion of historical user text into local user messages, because those messages were never locally appended in the first place
- tool-result-shaped remote user messages being converted when the local client must render remote tool results, especially in viewer-only or direct-connect style sessions
- detecting tool-result messages by inspecting content blocks rather than by relying on a parent-tool-use pointer that may be normalized away upstream
- a bounded UUID echo filter for locally posted user messages, because one outbound post can echo back multiple times on the remote event stream and a delete-on-first-match set would leak the later duplicates into the transcript
- the echo filter acting only on locally sent messages, not on full history replay, so attach-time history and live traffic do not collapse into one lossy deduper

## Viewer-state projection into local app state

Equivalent behavior should preserve:

- a small remote-viewer state slice in app state rather than pretending remote activity can be reconstructed from ordinary local task state
- explicit connection statuses of `connecting`, `connected`, `reconnecting`, and `disconnected`
- a remote background-task counter driven by remote lifecycle events because the viewer process does not own the remote daemon's local task registry
- local `AppState.tasks` remaining empty in viewer mode while the separate remote background-task count still feeds footer and spinner surfaces
- connection-state updates avoiding no-op rewrites so the viewer does not churn renders on repeated identical status transitions
- reconnect and disconnect clearing derived remote task-count and in-progress-tool state that may have drifted during a websocket gap

## Remote task, tool, and loading adaptation

Equivalent behavior should preserve:

- `task_started` and terminal task-notification SDK events updating the remote background-task counter but not rendering as ordinary transcript messages
- task-progress SDK events being treated as state-only noise for this viewer layer rather than as transcript content
- assistant messages with tool-use blocks adding those tool-use IDs to the local "in progress" set so remote tools show the same spinner posture as local tools
- incoming tool-result blocks clearing those in-progress tool-use IDs even when the converted transcript message itself would otherwise be ignored
- complete converted messages clearing any temporary streaming-tool-use placeholders, because the final assistant message supersedes partial streaming state
- session-end result messages clearing local loading state even if the transcript does not show a visible success row

## Permission bridge and viewer ownership boundaries

Equivalent behavior should preserve:

- remote permission requests being turned into synthetic local assistant/tool-confirm rows using stable request IDs
- tool lookup preferring the local tool registry but falling back to a stub tool shape when the remote server names a tool the local client does not know
- allow, deny, abort, and server-cancel actions traveling back over the remote control channel rather than being emulated as local transcript input
- local loading pausing while the user is answering a remote permission challenge and resuming after approval or remote cancellation
- viewer-only clients remaining able to answer permissions but not to claim ownership of other remote-only controls such as session-title mutation or interrupts

## Viewer-only history replay and paging

Equivalent behavior should preserve:

- viewer-only assistant attach preparing one reusable authenticated history context and then paging remote events over HTTP separately from the live websocket stream
- newest history loading first via an anchor-to-latest call, with older pages fetched only when the user scrolls near the top
- history pages staying chronological within each page and using the oldest loaded event as the next `before_id` cursor
- history conversion reusing the same SDK-message adapter options as viewer live mode so user text and tool results render consistently across replay and live traffic
- sentinel transcript rows for `loading`, retryable history-fetch failure, and true start-of-session, with one stable sentinel identity so the transcript does not flicker through remove-and-reinsert churn
- prepending older history with scroll anchoring and unseen-divider compensation so the viewport remains stable
- chaining a bounded number of older-page loads on first paint until the transcript actually overflows the viewport instead of forcing the user to scroll an empty-looking viewer

## Transport-specific normalization

Equivalent behavior should preserve:

- the general CCR websocket viewer path accepting repeated streamed init or status traffic while still extracting slash-command metadata and connection truth from the remote session
- direct-connect and SSH-backed remote sessions deduplicating repeated `system/init` messages because those transports can emit an init payload on every turn
- that repeated-init dedup applying to the lean streamed `system/init` surface, not to the richer one-time `initialize` control-response catalog used during host bootstrap
- direct-connect and SSH paths still converting remote tool results for local rendering even though they do not use the full viewer-only history mode
- non-viewer remote sessions being allowed to update the remote session title after the first successful outbound user message when the session was created without an initial prompt
- viewer-only sessions never mutating the remote title and never sending interrupt on local cancel, because the remote agent remains the owner of the session lifecycle
- non-viewer CCR sessions running an unresponsive-session timeout with a longer window during compaction, while viewer-only sessions skip that watchdog because a sleeping or respawning assistant may legitimately stay quiet for longer
- SSH reconnect attempts surfacing an explicit transcript warning row, while permanent disconnect still terminates the local process with a clear final message

## Failure modes

- **double-print replay**: live echoes and history replay both render the same user-originated text because no local echo suppression boundary exists
- **blank brief replies**: viewer mode ignores remote tool-result-shaped user messages, so assistant brief-channel output appears empty
- **phantom tasks**: the viewer reconstructs remote background work from local task state and shows tasks that do not exist in the local process
- **stale spinner drift**: reconnect or disconnect leaves old remote tool-use IDs marked in progress forever
- **permission desync**: remote permission cancellation does not remove the local approval row, leaving the viewer with an answerable prompt the server no longer wants
- **init spam**: direct-connect or SSH surfaces print a fresh "session initialized" row every turn because repeated init payloads are not deduplicated
- **viewer takeover**: a viewer-only client is allowed to rename or interrupt the remotely owned session
