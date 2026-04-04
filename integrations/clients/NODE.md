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
- **[hooks-and-event-surface.md](hooks-and-event-surface.md)** — Hook registration, event delivery, and client-visible lifecycle signals.
- **[remote-and-managed-client-envelopes.md](remote-and-managed-client-envelopes.md)** — Remote-capable clients, managed wrappers, and environment-selection envelopes.
- **[direct-connect-session-bootstrap-and-environment-selection.md](direct-connect-session-bootstrap-and-environment-selection.md)** — How direct-connect, bridge resume, and remote session creation choose environments and seed remote sessions with repo, model, and permission context.
- **[remote-setup-and-companion-bootstrap.md](remote-setup-and-companion-bootstrap.md)** — Local bootstrap flows for web, desktop, mobile, browser, and bridge companion surfaces.
- **[ide-connectivity-and-diff-review.md](ide-connectivity-and-diff-review.md)** — IDE discovery, auto-connect and install bootstrap, live `/ide` selection, and IDE-backed diff approval loops.
