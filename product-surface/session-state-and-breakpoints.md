---
title: "Session State and Breakpoints"
owners: []
soft_links: [/runtime-orchestration/state/state-machines-and-failures.md, /runtime-orchestration/sessions/session-reset-and-state-preservation.md, /runtime-orchestration/state/app-state-and-input-routing.md, /tools-and-permissions/permissions/permission-mode-transitions-and-gates.md, /collaboration-and-agents/remote-session-live-control-loop.md, /ui-and-experience/dialogs-and-approvals/focused-dialog-and-overlay-arbitration.md]
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

One important user-visible invariant is that "which transcript is shown" and "which target receives new input" are different axes. Claude Code can temporarily show one transcript while steering input somewhere else, and a clean-room rebuild needs to preserve that split instead of folding everything into one active-session pointer.

## Transcript view and input target are separate state

Equivalent behavior should preserve at least three distinct user-visible routing cases:

- the default leader view, where the leader transcript is shown and new input goes to the leader
- a foregrounded background-session transcript, where the main pane is showing a background task's history without necessarily changing worker-routing rules
- a viewed worker transcript, where a teammate or named local agent becomes both visible and steerable through a separate viewed-target pointer

Important invariants:

- the main transcript-view pointer and the viewed-worker pointer are different state, because the product supports showing a background task without pretending it is the same thing as viewing a steerable worker
- viewed-worker routing degrades safely back to the leader if the referenced task disappears or no longer matches a steerable worker shape
- switching who is viewed must not require re-registering the task or inventing a second transcript identity

Without this split, background-session viewing, teammate steering, and recovery after worker exit all become visibly wrong.

## Viewing a worker changes retention semantics

Equivalent behavior should preserve that entering and leaving worker view changes more than the header label.

That includes:

- retaining the viewed local-agent transcript in memory while it is actively viewed
- releasing it back to a lighter stub form when the user leaves that view
- giving terminal viewed workers a short grace window before eviction instead of deleting them the instant the user navigates away
- immediately dismissing a terminal viewed worker when the user explicitly closes that row

The product contract is that "viewing" is a stateful hold on transcript material, not just a cursor position.

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
- **view-state collapse**: foregrounded background transcripts and steerable worker views are merged into one pointer and break resume or release behavior.

## Test Design

In the observed source, product-surface behavior is verified through command-focused integration tests and CLI-visible end-to-end checks.

Equivalent coverage should prove:

- parsing, dispatch, flag composition, and mode selection preserve the public contract for this surface
- downstream runtime, tool, and session services receive the correct shaping when this surface is used from interactive and headless entrypoints
- user-visible output, exit behavior, and help or error routing remain correct through the packaged CLI path rather than only direct module calls
