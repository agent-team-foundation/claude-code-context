---
title: "Remote-Control Entrypoints and Startup Preferences"
owners: []
soft_links: [/collaboration-and-agents/repl-remote-control-lifecycle.md, /collaboration-and-agents/remote-control-spawn-modes-and-session-resume.md, /platform-services/interactive-startup-and-project-activation.md, /platform-services/auth-config-and-policy.md]
---

# Remote-Control Entrypoints and Startup Preferences

Remote Control is exposed through three different entry surfaces that look similar from the outside but serve different jobs: a standalone bootstrap command that hosts remote sessions, root startup flags that pre-enable Remote Control inside the normal interactive REPL, and an in-session slash command that flips the current REPL into bridge mode. A clean-room rebuild should keep those surfaces distinct.

## Scope boundary

This leaf covers:

- the separate entrypoint contracts for standalone bootstrap, root startup flags, and in-REPL slash command
- the fast-path ordering for standalone remote-control bootstrap
- persisted startup preference resolution for interactive sessions
- migration from the leaked persisted key to the newer user-facing key
- the distinction between persisted config names and live in-memory app-state names

It intentionally does not re-document:

- interactive bridge lifecycle, mirror upgrade, fuse behavior, and disconnect rules already captured in [repl-remote-control-lifecycle.md](repl-remote-control-lifecycle.md)
- standalone spawn-mode, resume, and worktree placement rules already captured in [remote-control-spawn-modes-and-session-resume.md](remote-control-spawn-modes-and-session-resume.md)

## Three entry surfaces must stay separate

Equivalent behavior should preserve three distinct surfaces:

- a standalone bootstrap subcommand entered as `remote-control` or `rc`
- hidden root startup flags `--remote-control` and `--rc` that launch the normal interactive REPL with Remote Control already desired
- an in-REPL slash command named `remote-control` with alias `rc`

They may all lead to Remote Control, but they do not share the same parsing layer, startup order, or responsibility boundary.

## Standalone bootstrap command and legacy aliases

Equivalent behavior should preserve:

- the standalone bootstrap subcommand accepting `remote-control` and `rc`
- continued acceptance of legacy spellings `remote`, `sync`, and `bridge` as compatibility aliases for the same fast-path host startup
- the bootstrap path handing off to the dedicated remote-control host entry rather than falling through the normal interactive startup path
- the main interactive command table still containing a fallback `remote-control` subcommand definition only as a compatibility shell, not as the primary implementation path

The compatibility aliases belong to the standalone host launcher, not to the interactive slash-command surface.

## Standalone bootstrap fast-path ordering

Equivalent behavior should preserve this high-level order before the host actually starts:

1. enable config access needed by the bootstrap path
2. verify authenticated access first
3. evaluate feature or gate enablement, organization policy, and minimum-version eligibility
4. hand control to the bridge host main entrypoint

The ordering matters because gate evaluation depends on authenticated user context, and the host should fail with a concrete policy or version reason before deeper startup begins.

## Root startup flags are interactive-session preferences

Equivalent behavior should preserve:

- hidden root flags `--remote-control` and `--rc` on the main interactive CLI
- optional session naming on those flags, so the interactive bridge session can start with a preselected title
- those flags affecting the desired startup posture of the REPL session rather than invoking the standalone host command path
- root-flag activation happening early enough that later REPL lifecycle hooks can treat Remote Control as an intended startup state rather than a retroactive toggle

This surface is best thought of as "launch the regular REPL already wanting Remote Control," not "run the standalone remote-control host subcommand."

## In-REPL slash command stays a third surface

Equivalent behavior should preserve:

- one slash command named `remote-control`
- one slash-command alias `rc`
- slash-command activation staying inside the live REPL lifecycle, with the current session deciding whether to connect, upgrade from mirror-only mode, or show disconnect UI
- slash-command behavior reusing the interactive bridge lifecycle rules instead of the standalone bootstrap flow

Conflating the slash command with the standalone host launcher would erase important REPL-specific behavior.

## Persisted startup preference versus rollout defaults

Equivalent behavior should preserve:

- one persisted config key named `remoteControlAtStartup`
- precedence of explicit user config over rollout-provided auto-connect defaults over plain false
- user opt-out always winning over rollout-driven default enablement
- interactive startup reading the effective startup preference as an input to desired bridge state, not as proof that a live session is already connected

This keeps a stable distinction between "should try to start" and "is currently connected."

## Migration from leaked key to user-facing key

Equivalent behavior should preserve:

- migration from legacy persisted key `replBridgeEnabled` to `remoteControlAtStartup`
- that migration running inside the version-gated main interactive migration flow, not inside the standalone bootstrap fast-path
- migration copying the old value only when the new key is absent
- migration deleting the old key only in the branch where it actually performs the copy

One subtle compatibility consequence also matters:

- if `remoteControlAtStartup` already exists, migration exits early and leaves the old `replBridgeEnabled` key on disk unchanged

So a rebuild should not assume that absence of cleanup means the migration never ran.

## Persisted config names are not live app-state names

Equivalent behavior should preserve a deliberate naming split:

- persisted configuration uses the user-facing key `remoteControlAtStartup`
- live session state still uses `replBridgeEnabled` and related `replBridge*` fields for desired and live bridge posture inside app state

That means documentation and tooling should distinguish persisted preferences from runtime state instead of assuming one rename propagated everywhere.

## Failure modes

- **surface conflation**: standalone host boot, root startup flags, and slash-command activation are merged into one path and lose their different prerequisites
- **auth-before-gate drift**: bootstrap checks rollout or policy before auth and produces stale or misleading refusal reasons
- **migration mirage**: the runtime assumes the old key must disappear once the new key exists, breaking compatibility with partially migrated config files
- **preference collapse**: persisted startup desire is treated as proof of live connection, so reconnecting or failed sessions render incorrectly
- **alias leakage**: legacy bootstrap aliases start being accepted as slash-command names or root flags and muddy the command surface
