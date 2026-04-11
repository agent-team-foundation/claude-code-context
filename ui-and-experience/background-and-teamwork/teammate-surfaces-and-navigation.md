---
title: "Teammate Surfaces and Navigation"
owners: []
soft_links: [/collaboration-and-agents/in-process-teammate-lifecycle.md, /collaboration-and-agents/pane-backed-teammate-layout-and-control.md, /runtime-orchestration/tasks/shared-task-list-contract.md, /ui-and-experience/shell-and-input/terminal-ui.md]
---

# Teammate Surfaces and Navigation

Claude Code makes swarm work legible by projecting the same teammate state into multiple terminal surfaces at once: footer status, spinner tree, team dialog, background-task dialog, transcript view, and prompt routing. A faithful rebuild needs these surfaces to agree on who is running, who is foregrounded, what actions are legal, and where typed input should go.

## Roster and control surfaces

Equivalent behavior should preserve:

- footer teammate count derived from live team context without filesystem reads, and hidden entirely when no non-lead teammates exist
- a team dialog that refreshes disk-backed teammate status on an interval and treats the team file as the durable source of truth for running versus idle, hidden membership, backend type, current mode, cwd or worktree path, model, and prompt summary
- teammate list rows that exclude the lead from teammate counts while still treating the lead as the control authority behind every action
- consistent team-dialog actions for focus, hard kill, graceful shutdown request, backend-gated hide or show, hide or show all, prune-idle cleanup, and permission-mode cycling
- permission-mode changes being optimistic: metadata is updated immediately for UI coherence and a mailbox control message is also sent so the worker updates its live permission context
- teammate detail surfaces joining runtime progress with shared task-list ownership, including compatibility with tasks owned by either logical teammate name or stable agent ID
- detail views that prefer worktree path over cwd when showing the worker's effective working location, and that expose prompt, recent activity, and terminal error state without requiring the pane to be focused

## Transcript-view state and input routing

Equivalent behavior should preserve:

- one global `viewingAgentTaskId` deciding whether the user is steering the leader, an in-process teammate, or a named local background agent
- input routing that prefers a viewed in-process teammate first, falls back to a viewed named local agent second, and otherwise submits to the leader
- prompt submission checking that routing decision before normal leader submit so the same prompt bar can steer whichever worker is foregrounded
- local-agent transcript viewing using explicit retain or release semantics so disk-loaded transcript stubs are kept alive only while viewed
- switching between local-agent transcript views releasing the old retained agent back to stub form instead of pinning every viewed transcript forever
- terminal local-agent rows lingering briefly after release before eviction, while explicit dismiss forces immediate hiding
- in-process teammate transcript views avoiding that retain-and-evict path because their live task state already contains the relevant transcript mirror
- automatic exit from a viewed teammate only when it is killed, failed, errored, or disappears from task state; completed teammates remain viewable for inspection
- escape while viewing a running in-process teammate aborting only its current turn, not the whole teammate lifecycle, and escape on a non-running viewed teammate returning to the leader

## Navigation and selection contracts

Equivalent behavior should preserve:

- one shared alphabetical ordering of running in-process teammates across the spinner tree, footer selection, and keyboard navigation so selection indexes never drift between surfaces
- shift-up or shift-down entering teammate selection when teammates exist, but opening the general background-task dialog instead when only non-teammate background work exists
- selection wrapping across leader, running teammates, and a final hide row that collapses the teammate tree
- Enter mirroring that structure by returning to leader view, foregrounding a selected teammate transcript, or collapsing the tree when the hide row is selected
- teammate kill from selection applying only to running in-process teammates, while leaving selection mode never aborts leader work
- teammate-count changes clamping or resetting the selection index so removed workers do not leave the selector pointing at dead rows
- a background-task dialog that auto-skips list view when opened for a specific task or when exactly one background task exists, but falls back to list view once multiple items are present
- background-task dialog teammate rows being suppressed whenever the spinner tree is already expanded, preventing duplicate teammate control surfaces
- injection of a synthetic leader row into background-task dialog teammate groups so users can foreground back to the main thread from the same selection model
- teammate detail dialogs exposing close, stop, back, and foreground actions while terminal teammate records remain inspectable instead of disappearing immediately

## Spinner tree, banner, and idle semantics

Equivalent behavior should preserve:

- the main spinner being able to foreground either the leader or a viewed teammate while the tree still shows a leader row for orientation and return
- a static idle display replacing the animated spinner whenever the leader is idle but teammates are still working, or whenever the foregrounded teammate is idle
- an all-idle swarm freezing each teammate row into a past-tense worked-for display instead of letting idle timers drift forever
- row-level hints and token or tool stats appearing only when width and selection state allow, so narrow terminals still keep the activity text readable
- optional preview lines being drawn from the newest user or assistant content, including condensed descriptions of recent tool use rather than only raw prose
- a swarm banner that switches among external attach guidance, foregrounded teammate badge, named local-agent badge, standalone-agent badge, and CLI-agent badge according to backend reality and the current viewing slot

## Failure modes

- **selection-order drift**: two surfaces sort teammates differently and the highlight targets the wrong worker
- **lost steering target**: the prompt bar sends text to the leader while the UI still implies a worker is foregrounded
- **premature view eviction**: a transcript disappears before the user can review the finished worker output
- **duplicate teammate surfaces**: the background-task dialog and spinner tree both expose the same teammate controls at once
- **false stall feedback**: the UI keeps animating a spinner for an idle leader or idle teammate and incorrectly suggests work is stuck

## Test Design

In the observed source, background and teamwork UI behavior is verified through state-to-view regressions, live-update integration tests, and multi-agent interaction scenarios.

Equivalent coverage should prove:

- row, detail, summary, and status-derivation logic render the same meaning from task and teammate state snapshots
- polling, mailbox updates, progress streaming, and navigation state stay coherent across live runtime changes and reset hooks between cases
- users can still follow work, inspect details, and switch teammate context through the real interactive surfaces without stale or duplicated UI state
