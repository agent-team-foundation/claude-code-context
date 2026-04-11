---
title: "Teammate Backend and Context Bootstrap"
owners: []
soft_links: [/collaboration-and-agents/worker-execution-boundaries.md, /runtime-orchestration/sessions/session-artifacts-and-sharing.md, /platform-services/bootstrap-and-service-failures.md]
---

# Teammate Backend and Context Bootstrap

Worker execution mode is decided early and then treated as session reality. Claude Code snapshots teammate-mode settings, detects the terminal environment carefully, bootstraps team context before first render, and makes spawned teammates inherit enough CLI and environment state to behave like the same session rather than a different product.

## Session-start mode snapshot

Equivalent behavior should preserve:

- teammate mode captured once at session startup from CLI override or config
- use of that captured mode for later teammate spawns instead of re-reading mutable runtime config
- explicit reset only when the user deliberately changes the setting through the supported control path

This snapshot prevents mid-session config churn from making half the swarm think it is in one backend mode and half in another.

## Environment detection rules

Backend detection depends on the original terminal environment, not whatever later subsystems rewrite.

A faithful rebuild should preserve:

- capture of the original `TMUX` value at module load so later shell setup cannot fake "inside tmux"
- capture of the original tmux pane ID so leader-pane targeting survives later pane switches
- "inside tmux" detection that trusts only the original environment flag, not a fallback command that could succeed merely because some tmux server exists elsewhere on the machine
- cached detection results because these answers should not change during one process lifetime

## iTerm and tmux availability probes

Availability checks must test real usability, not just binary presence.

Equivalent behavior should preserve:

- iTerm detection via terminal metadata and iTerm-specific environment markers
- an iTerm CLI probe that verifies it can actually talk to the native pane API
- tmux availability checks that verify the executable exists

A superficial version check is not enough if it can succeed while later pane-split commands still fail.

## Backend resolution and stickiness

Automatic mode resolves differently depending on environment.

Required behavior:

- non-interactive sessions force in-process execution
- explicit in-process mode always uses in-process execution
- explicit pane-backed mode suppresses automatic in-process preference
- automatic mode resolves to pane-backed execution when already inside tmux or a native iTerm-style environment, and otherwise resolves to in-process execution
- when a spawn attempt falls back to in-process because no pane backend is usable, that fallback becomes sticky for the rest of the session so later UI and spawns agree on reality
- backend executors and detection results are cached once chosen

## Team-context bootstrap

Swarm context has to exist before inbox polling, teammate heartbeats, or leader routing can work.

Equivalent behavior should preserve:

- synchronous computation of initial team context before first render when CLI launch context already identifies a team and teammate
- inclusion of team name, team-file path, lead-agent identity, self identity, and leader-versus-worker role in that bootstrap state
- resumed-session initialization that reconstructs the same team context from persisted team and agent names
- graceful degradation when the team file changed and the resumed member no longer exists

## Spawn inheritance rules

Spawned teammates need a controlled subset of parent session state.

Equivalent behavior should preserve:

- propagation of selected CLI settings such as model override, settings path, inline plugins, Chrome flag, and teammate-mode snapshot
- forwarding of critical environment variables for remote execution, proxies, certificate roots, and config-directory overrides when pane-backed teammates launch in fresh shells
- permission-mode inheritance that refuses to pass through dangerous bypass state when a teammate is explicitly required to stay in plan mode

## Backend-neutral executor surface

Callers should not need separate orchestration code for pane-backed and in-process workers.

The durable contract is:

- both paths expose one executor abstraction for spawn, send message, terminate, kill, and active-status checks
- in-process execution still strips parent conversation arrays before launch so the worker does not pin the leader's whole transcript in memory
- pane-backed execution still remembers enough backend metadata for later shutdown cleanup

## Failure modes

- **tmux mirage**: later shell initialization rewrites environment variables and tricks backend detection into thinking the session started inside tmux
- **false iTerm readiness**: native pane support is selected even though the real pane API is unavailable
- **session split-brain**: automatic fallback to in-process is not made sticky, so later spawns or UI paths believe pane mode still works
- **resume without team context**: a resumed teammate loses heartbeat, mailbox, or leader-routing behavior because team context was not reconstructed
- **unsafe inheritance**: a plan-required teammate inherits bypass-permissions mode from its parent

## Test Design

In the observed source, collaboration behavior is verified through protocol and state-machine regressions, bridge-aware integration coverage, and multi-agent or remote end-to-end scenarios.

Equivalent coverage should prove:

- agent lifecycle, routing, mailbox, subscription, and control-state transitions preserve the contracts documented in this leaf
- bridge transport, projection, permission forwarding, reconnect, and transcript continuity behave correctly with resettable peers and deterministic state seeds
- observable teamwork behavior remains correct when users drive the product through real teammate, pane, or remote-session surfaces
