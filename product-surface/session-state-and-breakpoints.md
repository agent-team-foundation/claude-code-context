---
title: "Session State and Breakpoints"
owners: []
soft_links: [/runtime-orchestration/state-machines-and-failures.md, /ui-and-experience/feedback-state-machine.md]
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
6. Recovered continuation.
   A prior session, branch, compacted transcript, or remote turn is resumed.
7. Terminal end.
   The session exits, hands off, archives, or becomes remote-view only.

## Breakpoints that matter

- entering or leaving plan mode
- switching to worktree or delegated execution
- transitioning into remote or bridge-controlled operation
- resuming after compaction, reconnect, or session restore
- dropping from rich local control to narrower remote-safe command sets

## Failure paths

- **Startup degradation**: optional services fail, but the session should still reach a usable ready state.
- **Mode mismatch**: a command appears available in one surface but is blocked in another.
- **Resume mismatch**: recovered history does not match repo, branch, or session identity expectations.
- **Interaction dead-end**: the product asks for a decision but lacks a viable UI path for the current client.
- **Handoff ambiguity**: users cannot tell whether work is local, remote, background, or merely queued.
