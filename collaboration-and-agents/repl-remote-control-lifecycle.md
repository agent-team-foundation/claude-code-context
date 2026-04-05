---
title: "REPL Remote-Control Lifecycle"
owners: []
soft_links: [/collaboration-and-agents/bridge-transport-and-remote-control-runtime.md, /collaboration-and-agents/remote-control-spawn-modes-and-session-resume.md, /integrations/clients/remote-setup-and-companion-bootstrap.md, /platform-services/interactive-startup-and-project-activation.md, /platform-services/auth-config-and-policy.md, /ui-and-experience/system-feedback-lines.md]
---

# REPL Remote-Control Lifecycle

Interactive Claude Code can keep Remote Control alive in the background for the lifetime of a local session. That behavior is not just a transport attachment. It has a desired-state flag, multiple startup sources, an explicit `/remote-control` command that can upgrade outbound-only mirror sessions into full bidirectional control, a failure fuse that stops broken sessions from thrashing, and disconnect rules that distinguish session-only shutdown from persistent opt-out.

## Scope boundary

This leaf covers:

- interactive REPL-side Remote Control enablement, disablement, and desired-versus-live bridge state
- startup sources such as explicit remote-control launch, config-driven startup enablement, assistant-mode forcing, and outbound-only mirror mode
- the `/remote-control` command path, first-use remote callout, and disconnect persistence rules
- the hook-managed bridge lifecycle inside an interactive session: init, teardown, state projection, failure fuse, and auto-disable behavior
- the interactive session metadata projected to companion clients once the bridge is connected

It intentionally does not re-document:

- standalone `claude remote-control` host startup, spawn-mode selection, and resume pointer behavior already captured in [remote-control-spawn-modes-and-session-resume.md](remote-control-spawn-modes-and-session-resume.md)
- low-level bridge transport, reconnect, dedup, and teardown internals already captured in [bridge-transport-and-remote-control-runtime.md](bridge-transport-and-remote-control-runtime.md)
- detailed companion-visible bridge state, `system/init` redaction, and inbound slash-command narrowing already captured in [bridge-session-state-projection-and-command-narrowing.md](bridge-session-state-projection-and-command-narrowing.md)
- companion pairing dialog rendering and install/bootstrap wrappers already captured in [remote-setup-and-companion-bootstrap.md](../integrations/clients/remote-setup-and-companion-bootstrap.md)

## Desired state and startup sources

Equivalent behavior should preserve:

- a split between desired bridge state and live bridge state, with one flag that says Remote Control should be running and separate fields for ready, active, reconnecting, failed, URL, and debug identity
- startup seeding the desired bridge state from explicit remote-control launch, the effective startup preference, or assistant-mode forcing, instead of making the hook rediscover those causes later
- startup-preference precedence of explicit user config over rollout-provided defaults over plain false, so a user opt-out beats background auto-connect
- outbound-only mirror mode being a separate startup posture that turns on only when full bidirectional Remote Control is absent
- explicit session naming being stored in app state before connect logic runs, so later init paths can reuse that name as the first bridge session title

## Explicit command activation and mirror upgrade

Equivalent behavior should preserve:

- explicit `--remote-control` entitlement checks running only after trust setup and auth-dependent startup work complete, so the flag can print a concrete warning instead of failing later inside bridge init
- `/remote-control` opening a disconnect or continue dialog when full bidirectional Remote Control is already active instead of registering a second bridge
- outbound-only mirror sessions not counting as "already connected" for that command, so `/remote-control` upgrades the session into full bidirectional control rather than trapping the user in mirror mode
- command preflight checking organization policy, bridge entitlement, the correct version floor for the v1 versus v2 path, assistant-mode forcing back to the non-env-less path, and token presence before desired state flips on
- a first-use remote callout being allowed to intercept the command, while still capturing the requested session name so the later consent handler can connect with the same intent
- explicit activation setting desired state plus "this was user-requested" metadata, clearing outbound-only posture, and leaving actual environment or session creation to the hook

## Hook-managed init, fuse, and teardown

Equivalent behavior should preserve:

- bridge init waiting for any prior teardown promise to finish before registering again, so a delayed deregister cannot tear down a freshly created replacement environment
- consecutive init failures being counted across reenables for the lifetime of the session and blowing a fuse after a small threshold, with restart-required disablement instead of infinite 401 churn
- ordinary init failures surfacing a notification, recording an error string, and auto-clearing desired bridge state after a short delay so the runtime stops retrying on its own
- outbound-only mirror mode suppressing those user-facing failure surfaces while still updating minimal connection truth for event forwarding
- successful init resetting the failure counter, preserving flushed historical UUIDs across reconnects, and advancing the write cursor so initial transcript events are not re-forwarded as live messages
- assistant mode marking the interactive bridge as perpetual, so clean restarts can preserve one long-lived remote session instead of starting a new bridge session each time
- cleanup clearing live bridge URLs, IDs, reconnect flags, permission callbacks, and message-forwarding cursors while leaving the fuse intact until a later successful init proves recovery

## Connected-session projection and bridge-safe surface

Detailed projection and narrowing rules live in [bridge-session-state-projection-and-command-narrowing.md](bridge-session-state-projection-and-command-narrowing.md). Lifecycle-wise, equivalent behavior should preserve:

- full bridge sessions and outbound-only mirror sessions projecting different depth into app state, because only the full bridge exposes URLs, permission callbacks, and status transcript rows
- inbound bridge callbacks applying model, thinking-budget, and permission-mode changes through the same centralized session state transitions used locally, rather than through a forked remote-only state path
- disconnect dialogs, footer pills, and transcript status rows reading the shared projected bridge state instead of recomputing connection truth independently

## Disconnect and persistence rules

Equivalent behavior should preserve:

- disconnecting from the command dialog or footer dialog clearing desired bridge state together with explicit and outbound-only markers in one coordinated transition
- a persistent startup opt-out being written only when the active bridge was explicitly user-enabled, not when the session was auto-connected by settings or rollout defaults
- continuing from the dialog leaving desired bridge state untouched and simply dismissing the overlay
- interactive status surfaces reading live app state instead of recomputing bridge truth independently, so ready, active, reconnecting, and failed states stay consistent across transcript rows, footer pills, and dialogs

## Failure modes

- **mirror trap**: outbound-only auto-connect blocks explicit `/remote-control` instead of allowing upgrade to full Remote Control
- **opt-out overreach**: a session-only disconnect writes a persistent startup opt-out and silently undoes config-driven or rollout-driven behavior
- **retry storm**: init failures can be re-armed forever by settings sync or repeated command toggles and hammer the register endpoint
- **state collapse**: desired enablement and live connection state are flattened into one bit, so reconnecting or failed sessions render as either fully off or falsely healthy
- **metadata leak**: companion bootstrap advertises local-only commands or full local tool or plugin inventories to remote clients
- **teardown race**: re-enable happens before a previous deregister completes and the stale teardown destroys the newly registered bridge
- **perpetual drift**: assistant sessions accidentally take the env-less ephemeral path and lose continuity across clean restarts
