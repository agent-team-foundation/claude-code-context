---
title: "Bridge Contract"
owners: []
soft_links: [/collaboration-and-agents/remote-and-bridge-flows.md, /product-surface/command-execution-archetypes.md, /integrations/clients/client-surfaces.md]
---

# Bridge Contract

Bridge mode lets a constrained client control or observe an existing session without receiving the full local terminal surface.

## Distinguishing property

Bridge is a control channel into a session that already exists or is locally anchored. It is not the same thing as remote execution.

## Command boundary

- Prompt-style commands are generally safe because they expand into text for the existing model loop.
- Local JSX commands are not bridge-safe because they assume an interactive terminal UI.
- A narrow allowlist is needed for local commands that can safely stream textual results back to the companion client.
- The concrete REPL projection, `system/init` redaction, and slash-command narrowing rules are captured in [bridge-session-state-projection-and-command-narrowing.md](bridge-session-state-projection-and-command-narrowing.md).

## Lifecycle

1. Bridge environment registered.
2. Session paired with the bridge transport.
3. Polling or ingress channel active.
4. Companion client sends input or control requests.
5. Reconnect, heartbeat recovery, or environment expiry handling.
6. Teardown and archive.

## Failure boundaries

- **unsafe command ingress**: a companion client requests a command that the bridge must block
- **heartbeat expiry**: the bridge loses its authority to keep the session alive
- **sequence drift or duplicate delivery**: replayed messages confuse the transcript
- **token expiry**: bridge auth remains valid long enough for recovery, or the session must be re-registered

Bridge implementations should optimize for safe narrowing rather than feature parity with the local TUI.
