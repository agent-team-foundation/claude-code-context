---
title: "Remote-Control Spawn Modes and Session Resume"
owners: []
soft_links: [/collaboration-and-agents/bridge-contract.md, /collaboration-and-agents/bridge-transport-and-remote-control-runtime.md, /runtime-orchestration/sessions/worktree-session-lifecycle.md, /platform-services/workspace-trust-dialog-and-persistence.md, /platform-services/interactive-startup-and-project-activation.md]
---

# Remote-Control Spawn Modes and Session Resume

`claude remote-control` does more than attach a bridge. It decides whether the process is a single resumable session or a persistent multi-session host, whether future sessions share one checkout or fan out into isolated worktrees, whether an older bridge environment can be reclaimed, and which project-scoped preference wins when flags, saved config, runtime toggles, and resume state disagree.

## Scope boundary

This leaf covers:

- the standalone `claude remote-control` or `rc` entry path rather than the in-REPL `/remote-control` command
- startup-time gating, trust, consent, and preference resolution that decide whether the host can start and what spawn posture it uses
- resume-target lookup, crash-pointer hygiene, environment reuse, and fresh-session fallback
- pre-created home sessions, on-demand session placement, and live toggling between shared-directory and worktree isolation
- the headless daemonized remote-control worker only where it intentionally reuses the same spawn-mode contract without the interactive prompts

It intentionally does not re-document:

- bridge attach, transport, reconnect, dedup, and teardown internals already captured in [bridge-transport-and-remote-control-runtime.md](bridge-transport-and-remote-control-runtime.md)
- generic remote-session ownership, permission routing, and reconnect semantics already captured in [remote-session-contract.md](remote-session-contract.md)
- main-session worktree posture and exit semantics already captured in [worktree-session-lifecycle.md](../runtime-orchestration/sessions/worktree-session-lifecycle.md)

## Startup eligibility and trust prerequisites

Equivalent behavior should preserve:

- CLI parsing that treats `session`, `same-dir`, and `worktree` as distinct spawn postures, rejects duplicate spawn or capacity flags, and refuses impossible combinations before any network attach begins
- `--capacity` being valid only for multi-session hosting, while `--session-id` and `--continue` remain mutually exclusive with each other and with every spawn-shaping flag because resume always targets one already-existing session on its original environment
- multi-session-specific flags being denied by an async feature gate instead of silently degrading, so rollout withdrawal cannot be bypassed by stale local config
- standalone startup enabling config reads, sink initialization, and cwd bootstrap state explicitly because this command bypasses the normal interactive startup path
- prior workspace trust being mandatory before remote-control startup, because this path cannot surface the interactive trust dialog itself
- valid claude.ai auth and a secure bridge base URL being required before bridge registration proceeds
- one first-use remote-access consent dialog being stored in global config and skipped on later launches
- worktree availability being determined up front from either real git support or hook-backed worktree creation, because that answer drives both startup defaults and runtime toggles

## Resume target discovery and pointer hygiene

Equivalent behavior should preserve:

- `--continue` looking for the freshest bridge pointer in the current directory first and only then across sibling worktrees, so a repo-root restart can still find a session whose pointer was last written from a worktree
- pointer freshness being based on file modification time with a rolling TTL, allowing periodic rewrites to keep long-lived sessions resumable without introducing a second embedded timestamp contract
- invalid, stale, or schema-broken pointers being deleted eagerly instead of re-triggering dead resume prompts forever
- the directory that supplied the resume pointer being remembered so deterministic resume failures clear the correct file even when it lives in another worktree
- fresh launches that are not resuming clearing any leftover pointer early, so an old crashed single-session bridge cannot mislead a later same-dir or worktree host
- explicit `--session-id` validation rejecting malformed IDs before reconnect work begins, while leaving unrelated pointer files alone unless the failed attempt actually came from `--continue`
- resume startup fetching the target session metadata first and refusing to continue when the session is gone or no longer bound to an environment

## Spawn-mode resolution and preference precedence

Equivalent behavior should preserve:

- per-project saved spawn-mode preferences being loaded only while the multi-session entitlement is still active, so a gate rollback truly restores legacy single-session behavior
- saved `worktree` preferences being cleared when the directory no longer supports worktrees, instead of warning forever while keeping invalid state on disk
- the first-run spawn-mode chooser appearing only when the user is on a TTY, worktree mode is actually available, no explicit `--spawn` was passed, and the command is not resuming a prior session
- precedence of `resume` over explicit flags, explicit flags over saved project preference, and saved project preference over gate defaults
- gate defaults resolving to `same-dir` when multi-session hosting is enabled and to `single-session` when it is not
- capacity staying fixed at one in single-session mode and otherwise defaulting to a bounded multi-session fan-out
- session precreation in the launch directory defaulting to on, while still remaining an explicit opt-out for users who want every session to be on-demand

## Environment reuse and fresh-session fallback

Equivalent behavior should preserve:

- resume startup re-registering the backend-issued environment attached to the target session instead of inventing a brand-new environment and hoping the session can follow it
- a backend environment mismatch being treated as proof the original environment expired, producing a warning and falling back to a fresh session on the newly registered environment rather than attempting an impossible reconnect
- successful resume force-stopping stale workers for the target session and re-queueing that session onto the revived environment before the main poll loop begins
- reconnect attempts trying both the session's compat-style ID and infrastructure-style ID when needed, because rollout-era servers may expect either lookup key
- fatal reconnect failures clearing the resume pointer, but transient reconnect failures preserving it so rerunning the same command is still a valid retry path
- fresh-session fallback reusing the same bridge host startup after resume failure instead of forcing the operator to restart everything manually

## Session placement and runtime mode switching

Equivalent behavior should preserve:

- the pre-created initial session always starting in the launch directory so the operator immediately lands in the repo they invoked `claude remote-control` from
- `worktree` mode isolating only on-demand sessions into dedicated worktrees, while `same-dir` and `single-session` keep every session in the launch directory
- each dispatched session latching the spawn mode that was active at assignment time, so a concurrent runtime toggle changes only later sessions instead of half-mutating one already being started
- runtime `w` toggling being available only for multi-session hosts that actually support worktrees, never for single-session resume flows
- toggling persisting the per-project preference and live status display so future launches and the current operator surface agree on how the next sessions will be placed
- the headless remote-control worker reusing the same spawn-mode and worktree-availability contract even though the supervisor, not the human operator, provides the resolved config

## Shutdown and resumability contract

Equivalent behavior should preserve:

- crash-recovery pointers being written immediately after the initial session exists and refreshed periodically so a later crash can still resume a long-lived single-session bridge
- pointer writing being limited to `single-session` mode, because multi-session hosts do not have one canonical session to resume and would otherwise leave misleading breadcrumbs
- successful single-session shutdown avoiding session archive and environment deregistration when the exit was nonfatal, so `--continue` still finds a live server-side session within the backend TTL window
- multi-session or fatal exits following normal archive and deregistration cleanup instead of pretending they are resumable
- resume hints, pointer retention, and cleanup policy staying consistent with one another rather than printing a recoverability message after destroying the underlying environment

## Failure modes

- **resume-precedence drift**: explicit or saved spawn configuration overrides a requested resume and reconnects the user into the wrong lifecycle
- **gate bypass**: stale project config re-enables same-dir or worktree hosting after the entitlement gate has been turned off
- **dead-pointer loop**: invalid or fatal-resume pointers are not cleared and `--continue` keeps targeting an unrecoverable session
- **expired-environment reuse**: the runtime keeps trying to reconnect a session to an environment the backend has already replaced
- **misplaced first session**: worktree mode incorrectly isolates the initial session, breaking the expected "launch here, type here" workflow
- **orphaned resume breadcrumbs**: multi-session mode writes pointers that do not map to one resumable session and later mislead recovery
- **interactive-headless drift**: daemon workers stop enforcing the same spawn-mode or worktree prerequisites as the interactive command

## Test Design

In the observed source, collaboration behavior is verified through protocol and state-machine regressions, bridge-aware integration coverage, and multi-agent or remote end-to-end scenarios.

Equivalent coverage should prove:

- agent lifecycle, routing, mailbox, subscription, and control-state transitions preserve the contracts documented in this leaf
- bridge transport, projection, permission forwarding, reconnect, and transcript continuity behave correctly with resettable peers and deterministic state seeds
- observable teamwork behavior remains correct when users drive the product through real teammate, pane, or remote-session surfaces
