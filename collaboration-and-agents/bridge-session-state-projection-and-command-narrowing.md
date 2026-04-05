---
title: "Bridge Session State Projection and Command Narrowing"
owners: []
soft_links: [/collaboration-and-agents/repl-remote-control-lifecycle.md, /collaboration-and-agents/bridge-contract.md, /collaboration-and-agents/peer-addressing-discovery-and-routing.md, /product-surface/command-runtime-matrix.md, /runtime-orchestration/unified-command-queue-and-drain.md, /integrations/clients/remote-setup-and-companion-bootstrap.md]
---

# Bridge Session State Projection and Command Narrowing

Remote Control does not expose the full local REPL to companion clients. It projects a narrowed session snapshot into app state and into companion-facing `system/init` metadata, and it routes inbound prompts through a bridge-specific command gate so remote clients can use skills and a few benign local commands without opening local-only UI or leaking local integration wiring.

## Scope boundary

This leaf covers:

- the app-state fields that represent desired bridge posture, live phase, URLs, IDs, error state, and explicit versus mirror intent
- startup seeding and hook-driven projection of `ready`, `connected`, `reconnecting`, `failed`, and outbound-only mirror states
- the REPL `system/init` payload published to companion clients and how it differs from the full SDK or QueryEngine init surface
- bridge-safe slash-command classification, routing, and user-visible rejection behavior for unsafe commands

It intentionally does not re-document:

- bridge enablement, desired-state toggles, failure fuse, and disconnect persistence already covered in [repl-remote-control-lifecycle.md](repl-remote-control-lifecycle.md)
- transport auth, reconnect, dedup, and teardown internals already covered in [bridge-transport-and-remote-control-runtime.md](bridge-transport-and-remote-control-runtime.md)
- pairing dialog and bootstrap UX already covered in [remote-setup-and-companion-bootstrap.md](../integrations/clients/remote-setup-and-companion-bootstrap.md)

## Projected app-state contract

Equivalent behavior should preserve:

- startup seeding desired enablement from full Remote Control or mirror posture, seeding explicit-user-request origin separately from settings-driven origin, seeding outbound-only posture separately from full bidirectional posture, clearing stale live URLs or IDs or errors, and storing any requested session name before connect logic starts
- app state keeping separate fields for desired enablement, explicit-versus-settings origin, outbound-only posture, ready versus session-active versus reconnecting phase, connect URL, session URL, environment ID, session ID, and last error so dialogs, footers, and transcript status surfaces can read one source of truth
- `ready` meaning the bridge runtime has created or recovered a session and can show a pairing URL even though no active companion attachment exists yet, while `connected` means the live ingress stream is open and `reconnecting` means recovery is in progress rather than idle or disabled
- outbound-only mirror mode exposing only the minimum projection needed for outbound forwarding, typically connected truth plus session identity, without publishing the full connect or session URL pair or full bidirectional callbacks
- full bidirectional mode registering bridge permission callbacks in app state so local approval UI can race, answer, or cancel companion-side tool requests using stable request IDs
- full bridge init appending a bridge-status transcript message with the session URL, while mirror mode stays quiet and lightweight because it is not the primary user-facing control surface
- direct session-first bridge sessions allowing a session URL without an environment-backed connect URL, because that path has no resumable environment pairing page

## Companion-visible `system/init` surface

Equivalent behavior should preserve:

- REPL bridge sending a `system/init` message on connect because interactive REPL queries bypass the normal QueryEngine SDK init path
- that streamed `system/init` surface being a lean attach-time snapshot, not the richer control-plane `initialize` response used by headless and SDK bootstrap
- using the same base init schema as SDK or headless flows so companion clients still receive cwd, session ID, version, API-key source, output style, betas, agent list, skills, and fast-mode state in a recognizable shape
- REPL bridge populating model, permission mode, active agents, and user-invocable skill names from current local state at connect time rather than inventing a bridge-only metadata format
- local transcript session ID, Remote Control session ID, and environment/pairing ID remaining distinct in projected state and metadata, because companion navigation, reconnect, and peer reply addresses do not all refer to the same identity
- slash commands in that payload being filtered down to bridge-safe commands only, so companion clients surface only actions that the local REPL will actually honor
- tool list, MCP server list, and plugin list being intentionally redacted to empty collections for REPL bridge sessions, because revealing local integration names or plugin paths would leak local environment wiring and filesystem context to companion clients
- the shared init helper still filtering out non-user-invocable commands and skills before names are emitted, even after the bridge-specific narrowing pass
- trusted internal clients being allowed to learn additional hidden peer-targeting metadata, such as a local messaging socket path, without expanding the public companion catalog or exposing full local integration inventories
- outbound-only or narrow bridge surfaces still replying successfully to server `initialize` requests, but with minimal capability claims rather than pretending the companion owns the full local command or model catalog

## Inbound command gate and slash-command routing

Equivalent behavior should preserve:

- inbound bridge prompts entering the unified command queue with preserved UUIDs, `skipSlashCommands=true`, and `bridgeOrigin=true`, so ordinary bridge text cannot accidentally trip local immediate-command or exit-word paths
- bridge-specific command override resolving slash commands only when `bridgeOrigin` is set and reopening the slash path only for commands that pass the bridge-safe predicate
- predicate rules of prompt commands being allowed by construction, `local-jsx` commands always being blocked, and `local` commands needing an explicit allowlist
- the bridge-safe local allowlist staying narrow and intentional rather than aiming for full parity with the local terminal; it covers only benign text-returning commands such as compaction, clear, cost, summary, release notes, and tracked-file listing
- known-but-unsafe commands being short-circuited locally with a friendly "isn't available over Remote Control" result wrapped as local-command output, while still preserving the original user message in transcript state instead of letting the model reinterpret the raw slash command
- unknown or unparsable slash-like text falling back to plain prompt text instead of producing a local unknown-command error, so companion users are not punished for typing `/foo` text the local registry does not recognize
- `system/init` advertising only commands that this gate would later permit, so companion UI menus and runtime enforcement stay aligned rather than teasing actions that fail after selection

## Failure modes

- **surface drift**: UI surfaces reconstruct bridge phase independently instead of reading the projected app-state fields, so `ready`, `connected`, `reconnecting`, and `failed` indicators disagree
- **metadata overshare**: REPL bridge emits full tools, MCP servers, or plugin paths into `system/init`, leaking local environment wiring to companion clients
- **menu/runtime mismatch**: `system/init` advertises commands that the inbound bridge gate later blocks, producing false affordances on mobile or web
- **slash-command escape**: bridge inbound text bypasses `skipSlashCommands` or `bridgeOrigin` checks and opens local-only immediate commands or terminal UI
- **mirror overprojection**: outbound-only mirror mode publishes full control URLs or mutable callbacks, making a passive observer session look interactive
- **unknown-command regression**: unrecognized `/foo` text is rejected locally instead of falling through to the model as ordinary prompt content
