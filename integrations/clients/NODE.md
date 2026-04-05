---
title: "Client Surfaces"
owners: []
soft_links: [/collaboration-and-agents/remote-and-bridge-flows.md, /ui-and-experience]
---

# Client Surfaces

The core runtime is surfaced through multiple clients and transports.

Relevant leaves:

- **[client-surfaces.md](client-surfaces.md)** — What each surface must preserve from the core runtime.
- **[surface-adapter-contract.md](surface-adapter-contract.md)** — How each client wraps the same runtime without forking semantics.
- **[sdk-control-protocol.md](sdk-control-protocol.md)** — The structured control channel used by SDK and automation-facing clients.
- **[structured-io-and-headless-session-loop.md](structured-io-and-headless-session-loop.md)** — How NDJSON transport, pending control requests, headless run-state, replay, and remote transport glue preserve one live session.
- **[sdk-hook-event-transport.md](sdk-hook-event-transport.md)** — SDK/session hook callback registration, low-noise versus opt-in event delivery, and bounded late-subscriber replay.
- **[remote-and-managed-client-envelopes.md](remote-and-managed-client-envelopes.md)** — Remote-capable clients, managed wrappers, and environment-selection envelopes.
- **[direct-connect-session-bootstrap-and-environment-selection.md](direct-connect-session-bootstrap-and-environment-selection.md)** — How direct-connect, bridge resume, and remote session creation choose environments and seed remote sessions with repo, model, and permission context.
- **[ssh-remote-session-and-auth-proxy.md](ssh-remote-session-and-auth-proxy.md)** — How `claude ssh` keeps UI local, runs execution remotely, bridges permission prompts back into the local REPL, and scopes the auth proxy to Anthropic API traffic only.
- **[remote-setup-and-companion-bootstrap.md](remote-setup-and-companion-bootstrap.md)** — Local bootstrap flows for web, desktop, mobile, browser, and bridge companion surfaces.
- **[remote-session-message-adaptation-and-viewer-state.md](remote-session-message-adaptation-and-viewer-state.md)** — How remote SDK traffic becomes local transcript, viewer state, and permission UX without replay duplication.
- **[assistant-viewer-attach-and-history-paging.md](assistant-viewer-attach-and-history-paging.md)** — How `claude assistant` discovers a running assistant session, attaches as a viewer-skewed client, and pages remote history without taking over session ownership.
- **[ide-connectivity-and-diff-review.md](ide-connectivity-and-diff-review.md)** — IDE discovery, auto-connect and install bootstrap, live `/ide` selection, and IDE-backed diff approval loops.
