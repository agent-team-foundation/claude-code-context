---
title: "Worker Execution Boundaries"
owners: []
soft_links: [/collaboration-and-agents/multi-agent-topology.md, /collaboration-and-agents/collaboration-state-machine.md, /tools-and-permissions/delegation-modes.md]
---

# Worker Execution Boundaries

Claude Code workers are not just "the same agent in another thread." They have explicit boundaries around authority, context inheritance, execution backend, and permission posture.

## Coordinator authority versus worker authority

Coordinator mode is a behavioral contract, not just a boolean flag.

When coordinator behavior is active:

- the foreground agent becomes responsible for planning, synthesis, and user communication
- workers are used for bounded research, implementation, or verification
- worker completions arrive as structured task notifications, not as normal conversation turns
- resumed sessions must restore the same coordinator-versus-normal mode or the session semantics change

The authoritative conversation with the user stays with the coordinator even while workers are active.

## Fresh workers do not inherit the conversation

The default worker contract is zero inherited conversational context.

Equivalent behavior should preserve these rules:

- a fresh worker needs a self-contained prompt
- "fix the thing we discussed" is invalid because the worker cannot see the prior dialogue
- the coordinator must synthesize findings before assigning follow-up work
- workers should not be used as proxies for reading another worker's state

This boundary is central to how Claude Code keeps multi-agent work legible.

## Forks are a distinct path

The product also supports a separate fork-style subagent path that can inherit the parent context. That path should stay distinct from ordinary worker spawning.

If a rebuild erases the distinction between fresh workers and inherited-context forks, it will either over-share noisy context or under-brief workers that actually start fresh.

## Unified executor, multiple backends

Worker spawning targets a common executor abstraction even though the actual execution substrate varies.

The important backend families are:

- **pane-backed workers** using tmux or native iTerm2 panes
- **in-process workers** running in the same process with isolated runtime state

Both styles should support the same high-level operations:

- spawn
- send a follow-up message
- terminate or kill
- check active status

This keeps orchestration logic separate from terminal-specific mechanics.

## Backend resolution rules

Automatic teammate mode should resolve by environment, not by arbitrary preference.

Important rules:

- non-interactive sessions should resolve to in-process execution
- explicit in-process mode should force in-process execution
- explicit tmux mode should force pane-backed execution
- auto mode should prefer pane-backed execution when already inside tmux or a native pane-capable iTerm2 environment
- iTerm2 without native pane support should fall back to tmux if available
- when no pane backend is usable and the runtime falls back to in-process, that fallback should stay sticky for the rest of the session so the UI and future spawns agree on reality

This is why backend detection belongs to session state, not to each spawn call independently.

## Identity, lineage, and isolation

Each worker needs more than a name.

Important identity fields include:

- a stable logical agent ID
- team affiliation
- parent session identity for lineage and task ownership
- optional worktree path for filesystem isolation
- optional plan-mode or permission constraints

These fields let the system route messages, attribute work, resume tasks, and clean up worker state safely.

## Message transport and history

Workers should communicate through explicit task notifications and mailbox-style follow-up messages, not through shared mutable conversation state.

Important consequences:

- pane-backed workers can be launched as separate CLI processes while still receiving follow-up messages through a shared transport
- in-process workers should maintain their own accumulating history and compaction path instead of pinning the leader's full conversation forever
- leader and worker transcripts are related by lineage, not by one shared message array

This is how the product gets parallelism without collapsing back into a single prompt buffer.

## Tool and permission boundaries

Workers need their own tool posture.

A correct rebuild should support:

- narrowed worker tool allowlists
- optional permission-prompt suppression for unlisted tools
- a small set of coordination-essential tools that remain available so workers can report back or shut down cleanly
- optional shared scratchpad or worktree structures for cross-worker coordination without granting full shared prompt state

The key invariant is that orchestration boundaries are enforced by runtime capability boundaries, not just by polite prompting.

## Failure modes

- **authority leak**: workers start behaving like coordinators and the user can no longer tell who is in charge
- **context leak**: fresh workers accidentally inherit the leader's whole conversation
- **backend split-brain**: UI believes workers are pane-backed while the runtime already fell back to in-process
- **orphaned lineage**: follow-up messages or resumes lose the parent session and cannot route correctly
- **tool dead-end**: a worker's tool restrictions prevent it from reporting status or responding to shutdown
