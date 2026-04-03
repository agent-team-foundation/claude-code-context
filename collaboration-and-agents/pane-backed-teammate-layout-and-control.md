---
title: "Pane-Backed Teammate Layout and Control"
owners: []
soft_links: [/collaboration-and-agents/worker-execution-boundaries.md, /collaboration-and-agents/teammate-backend-and-context-bootstrap.md, /ui-and-experience/terminal-ui.md]
---

# Pane-Backed Teammate Layout and Control

Pane-backed teammates are real worker sessions with their own terminal surfaces, not decorative mirrors of the leader. A faithful rebuild needs one contract for spawning, laying out, focusing, hiding, and cleaning up these pane-based workers even though tmux and native iTerm-style backends behave differently.

## Spawn and tracking contract

Equivalent behavior should preserve:

- pane creation before the worker begins its first turn
- a stable mapping from logical teammate ID to pane ID and backend type so later focus, hide, kill, and cleanup operations hit the right target
- session-stable teammate colors reused across pane chrome, task state, and team status UI
- launch of the same CLI entrypoint with explicit teammate identity, team identity, parent-session lineage, working directory, and inherited runtime flags or environment
- mailbox delivery of the initial worker prompt after the pane process is alive, so pane-backed workers and in-process workers share one follow-up protocol
- leader-exit cleanup that kills any pane-backed workers still tracked by the executor

Pane-backed workers must feel like extensions of the same swarm session, not unrelated shell tabs.

## tmux layout rules

The tmux path needs deterministic layout behavior.

Equivalent behavior should preserve:

- serialized pane creation so concurrent spawns do not split against stale layout snapshots
- leader-inside-tmux layout where the first worker splits off the leader pane and later workers split only within the teammate region
- rebalancing that keeps the leader anchored while teammate panes are redistributed beside it
- leader-outside-tmux layout that creates a dedicated swarm session and window on an isolated tmux socket
- reuse of the seed pane for the first external teammate rather than spawning an extra placeholder pane
- command routing through the user's tmux session when workers share that session, but through the isolated swarm socket when the swarm lives outside the user's tmux
- a short shell-readiness pause after pane creation so the injected launch command is not lost during shell startup

Using the wrong tmux server or wrong pane anchor is enough to make the whole collaboration surface look haunted.

## Native iTerm-style backend rules

Equivalent behavior should preserve:

- first split targeted from the leader's original session when that session identity is known
- later splits targeted from the most recent live teammate session so the teammate stack grows in a predictable place
- pruning and retry when a stored split target has died, instead of letting stale session IDs poison future spawns
- lighter pane cosmetics than tmux when native-pane API calls would materially slow worker creation
- forced pane close on kill so shutdown does not depend on interactive terminal confirmation dialogs
- explicit lack of hide or show support when the native pane backend cannot faithfully emulate tmux-style pane parking

## Focus, hide, and cleanup semantics

Pane-backed teammate control is more than spawn and kill.

A correct rebuild should preserve:

- direct focus of a teammate's pane or session from the team UI
- tmux-only hide by moving a live pane into a detached hidden session rather than killing it
- tmux-only show by rejoining that pane into the main swarm layout and reapplying the expected geometry
- persistence of hidden-pane membership in team state so the UI can reconstruct which teammates are merely parked
- backend capability checks before offering per-pane or hide-all controls
- cleanup that removes pane-backed teammates from the team file and hidden-pane set, unassigns their unfinished shared tasks, and emits a leader-visible system notice

## Team-state reflection

The team file is the durable bridge between pane state and UI state.

Equivalent behavior should preserve:

- teammate records that include pane identity, backend type, working path, model, current mode, and visible-versus-hidden status
- status discovery that can rebuild the visible team roster from disk without holding live executor objects
- enough backend metadata to kill orphan panes during session cleanup even if the normal shutdown path did not finish

## Failure modes

- **layout race**: parallel spawns split the wrong pane or rebalance against an outdated pane count
- **wrong-server control**: focus or kill commands target the default tmux server instead of the isolated external swarm session
- **dead-anchor drift**: native pane creation keeps targeting a stale session and stops being able to spawn new workers
- **orphaned pane**: team metadata is deleted but the actual pane keeps running after leader shutdown
- **capability lie**: UI exposes hide or show actions on a backend that cannot actually park panes safely
