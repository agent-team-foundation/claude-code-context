---
title: "Session State and Breakpoints"
owners: []
soft_links: [/runtime-orchestration/state-machines-and-failures.md, /runtime-orchestration/session-reset-and-state-preservation.md, /tools-and-permissions/permission-mode-transitions-and-gates.md, /collaboration-and-agents/remote-session-live-control-loop.md, /ui-and-experience/feedback-state-machine.md]
---

# Session State and Breakpoints

From the user's perspective, Claude Code behaves like one session moving through a series of recognizable phases.

## User-visible session states

1. Startup.
   The process validates environment, loads settings, and decides which surface is active.
2. Ready.
   Commands, modes, and prompt input are available.
3. Active turn.
   The user prompt is being processed, tools may run, and output is streaming.
4. Deferred work active.
   Background agents or tasks keep progressing while the foreground session stays usable.
5. Awaiting decision.
   The system pauses for a permission response, auth step, selection, or user clarification.
6. Reset or recovered continuation.
   A prior session, branch, compacted transcript, remote turn, or fresh post-clear session is resumed or reconstructed.
7. Terminal end.
   The session exits, hands off, archives, or becomes remote-view only.

One important user-visible invariant is that "which transcript is shown" and "which target receives new input" can diverge temporarily. Foregrounding a background task or viewing a worker should not silently rewrite the rest of the session state machine.

## Breakpoints that matter

- entering or leaving plan mode
- switching permission posture or auto-approval availability
- switching to worktree or delegated execution
- foregrounding a background transcript or steering a viewed worker
- clearing the session while preserving background work
- transitioning into remote or bridge-controlled operation
- resuming after compaction, reconnect, or session restore
- dropping from rich local control to narrower remote-safe command sets

## Failure paths

- **Startup degradation**: optional services fail, but the session should still reach a usable ready state.
- **Mode mismatch**: a command appears available in one surface but is blocked in another.
- **Resume mismatch**: recovered history does not match repo, branch, or session identity expectations.
- **Interaction dead-end**: the product asks for a decision but lacks a viable UI path for the current client.
- **Handoff ambiguity**: users cannot tell whether work is local, remote, background, or merely queued.
- **Routing mismatch**: the session shows one transcript while input or approval actions still target a stale recipient.
