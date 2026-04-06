---
title: "Interaction Modes"
owners: []
soft_links: [/runtime-orchestration/turn-flow/query-loop.md, /runtime-orchestration/state/app-state-and-input-routing.md, /runtime-orchestration/automation/proactive-assistant-loop-and-brief-mode.md, /runtime-orchestration/sessions/worktree-session-lifecycle.md, /tools-and-permissions/agent-and-task-control/delegation-modes.md, /tools-and-permissions/permissions/permission-mode-transitions-and-gates.md, /integrations/clients/structured-io-and-headless-session-loop.md, /collaboration-and-agents/remote-and-bridge-flows.md]
---

# Interaction Modes

Claude Code does not have one monolithic "mode" switch. It keeps one core agent runtime and composes several user-visible axes around it: how the session is surfaced, where the agent is running, who is allowed to initiate the next turn, and which transcript currently owns keyboard focus.

## Scope boundary

This leaf covers:

- the top-level interaction axes that differentiate local REPL, headless automation, remote-attached viewing, assistant autonomy, and worker-steered sessions
- which entrypoints reuse the same session runtime versus dispatching to separate CLI subcommands
- user-visible invariants when transcript view, input target, and initiative posture stop lining up one-to-one

It intentionally does not re-document:

- headless wire-protocol details already covered in [../integrations/clients/structured-io-and-headless-session-loop.md](../integrations/clients/structured-io-and-headless-session-loop.md)
- remote transport, bridge, and handoff mechanics already covered in [../collaboration-and-agents/remote-and-bridge-flows.md](../collaboration-and-agents/remote-and-bridge-flows.md)
- assistant tick scheduling and brief-mode semantics already covered in [../runtime-orchestration/automation/proactive-assistant-loop-and-brief-mode.md](../runtime-orchestration/automation/proactive-assistant-loop-and-brief-mode.md)
- worktree, delegation, and permission-mode internals beyond how they shape the visible session posture

## Startup chooses a surface first, then reuses one core runtime

Equivalent behavior should preserve:

- the default top-level action starting an interactive terminal session, not a one-shot request runner
- `--print` switching startup into a non-interactive or headless session loop instead of registering or dispatching ordinary CLI subcommands
- special entrypoints such as direct-connect URLs, assistant attach, and SSH remote attach rewriting back into the main startup path so they still land in the normal REPL or headless runner rather than bespoke mini-clients
- SDK stream callers being able to imply headless posture and stream-oriented defaults automatically, while still failing closed when callers request incompatible input or output combinations
- startup-only flags such as no-persistence, partial streaming, or structured-output shaping being valid only on the headless surface

## Interaction posture is a composition of independent axes, not a flat enum

Equivalent behavior should preserve these independent axes:

- surface style: interactive terminal REPL, headless structured runner, or remote-attached viewer or control client
- initiative posture: ordinary request or response, brief-only assistant communication, or proactive autonomous ticking
- execution locality: leader session, same-process or teammate worker, worktree-scoped shell context, or remote-backed runtime
- input target: leader transcript, foregrounded background task, or explicitly viewed worker
- permission posture: an overlay that changes approval semantics without becoming its own separate client surface

The load-bearing product rule is that these axes can combine. A remote session can still be brief-only, a leader session can temporarily steer a worker transcript, and a worktree-scoped session can stay interactive instead of becoming a separate product.

## Transcript view, input focus, and waiting state can diverge on purpose

Equivalent behavior should preserve:

- showing one transcript while routing new input somewhere else only through explicit view or worker-steering state, never by mutating the underlying session identity
- local JSX slash surfaces acting as local UI overlays that temporarily own the keyboard and move the session into a visible waiting posture without becoming model turns
- remote-session loading, background-task foregrounding, and local query execution all feeding one shared busy-or-waiting status model even though they do not all use the same query guard
- fullscreen interaction rendering local command dialogs as modal overlays while non-fullscreen interaction can still leave command traces in scrollback

## Assistant, remote, and worker surfaces reuse the shared session shell

Equivalent behavior should preserve:

- assistant attach using the ordinary REPL chrome as a viewer or controller for an already running remote session, with the agentic loop staying remote
- remote-control and related bridge postures narrowing commands and mirroring session metadata inside the same app-state model instead of spawning a separate conversation product
- assistant activation changing initiative and communication defaults, but still running on the same session and runtime foundation as ordinary interactive use
- worker-targeted input resuming a paused local agent or injecting mail to a teammate without rewriting the leader transcript into a new top-level session

## Failure modes

- **flattened mode enum**: local, headless, remote, assistant, and worker-targeted postures are rebuilt as one mutually exclusive switch and valid combinations disappear
- **surface fork drift**: assistant attach, direct-connect, or remote viewer paths become bespoke clients and stop matching REPL behavior
- **focus confusion**: the visible transcript changes, but input still targets a stale worker or remote session
- **headless incompatibility leak**: stream-json or no-persistence flags appear to work outside headless mode and silently degrade
- **overlay deadlock**: local dialog surfaces leave command keybindings or prompt focus active underneath the modal
