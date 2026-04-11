---
title: "Team Formation and Spawn Contract"
owners: []
soft_links: [/collaboration-and-agents/teammate-backend-and-context-bootstrap.md, /runtime-orchestration/tasks/shared-task-list-contract.md, /tools-and-permissions/agent-and-task-control/control-plane-tools.md]
---

# Team Formation and Spawn Contract

Claude Code treats team creation as durable runtime setup, not a cosmetic naming step. A faithful rebuild needs one contract for how a leader establishes a team, how teammates join that team, and how the whole structure is torn down without leaving orphaned panes, task directories, or routing state behind.

## Team creation contract

Equivalent behavior should preserve:

- a leader being allowed to manage only one active team at a time within one session
- reuse of the requested team name when it is unused, but automatic minting of a different unique name when that team name already exists on disk
- a deterministic leader agent ID derived from the fixed lead identity plus the final team name
- creation of a team file seeded with the leader member, leader session identity, creation timestamp, current working directory, current resolved model, and any explicit lead role override
- immediate registration for session-end cleanup as soon as the team file is written, so abandoned teams do not accumulate forever
- creation or reset of a shared team task-list directory keyed from the sanitized team identity
- an explicit leader-side task-list binding so the leader and all teammates resolve the same shared queue instead of splitting work across session-local and team-local directories
- insertion of the leader into app state with a stable color and roster entry even though the leader has no pane backing
- storage of lead identity in team context rather than teammate environment variables, so leader-only logic still recognizes the leader as special instead of mistaking it for a worker

## Teammate spawn contract

Equivalent behavior should preserve:

- activation of teammate spawning only when a resolved team name and an explicit teammate name are both present
- team-name resolution that prefers an explicit tool input but can inherit the current team context when the caller omits it
- a flat roster: teammates may spawn ordinary subagents, but they may not create nested teammates inside the same team
- duplicate teammate names being disambiguated inside the team before final ID generation, while final agent IDs remain deterministic from sanitized name plus team
- assignment of a stable teammate color before the worker is exposed in any roster, task row, or pane chrome
- pane-backed and in-process spawns both writing a member record to the team file and mirroring that member into leader app state with model, prompt, cwd, backend, and pane metadata
- pane-backed spawns creating the pane first, then launching the CLI with explicit teammate identity, team identity, parent-session lineage, optional role, optional plan-mode requirement, and inherited CLI or environment state
- delivery of the first prompt to pane-backed teammates only after the process is alive, using the mailbox path that later follow-up messages also use
- in-process spawns starting the worker loop directly, stripping parent conversation arrays before handoff, and avoiding mailbox delivery of the same first prompt
- automatic insertion of a synthetic leader roster entry when an in-process spawn needs team routing but no prior team bootstrap has populated the leader yet
- automatic backend mode falling back from pane-backed spawn to in-process spawn when no usable pane backend exists, with that fallback becoming sticky for the rest of the session
- plan-required teammates inheriting normal session settings without inheriting dangerous bypass-permission posture from the leader
- enough metadata in each member record to rediscover status later without live executor objects, including backend type, pane identity, color, current mode, hidden membership, cwd or worktree path, and model

## Shared visibility and task binding

Team membership is also a visibility contract.

A correct rebuild should preserve:

- pane-backed teammates appearing in task and progress UI even though they run in separate processes
- kill or cleanup paths being able to bridge from a logical teammate row back to the pane backend that created it
- shared task ownership using the team-scoped list identity rather than the leader session ID once the team exists
- leader-side status surfaces being able to rebuild the roster from disk, not just from currently live React state

## Team teardown contract

Equivalent behavior should preserve:

- teardown acting on the leader's current team context rather than arbitrarily deleting any on-disk team by name
- refusal to clean up while any non-lead member still appears active
- allowance for idle or already-dead non-lead members to be swept without blocking teardown forever
- removal of team directories, related shared task state, and other swarm-scoped disk artifacts on successful teardown
- unregistering the team from session-end cleanup once explicit teardown succeeds
- clearing teammate color allocation and leader task-list binding so the next team starts from clean runtime state
- clearing team context and queued inbox entries from app state so later turns do not inherit stale swarm routing data
- restoration of plain leader semantics after teardown, with no leftover team-affiliated identity or shared queue binding

## Failure modes

- **lead identity leak**: the leader is marked as a teammate and later worker-only routing or polling logic misfires
- **split task list**: the leader and workers resolve different task-list IDs and silently stop sharing work
- **double first prompt**: an in-process teammate receives its initial instructions both directly and through the mailbox
- **orphaned team state**: the team file is deleted or cleared in memory while panes or task rows keep running
- **unsafe teardown**: cleanup removes a team whose non-lead members still appear active, leaving live workers with no durable coordination state

## Test Design

In the observed source, collaboration behavior is verified through protocol and state-machine regressions, bridge-aware integration coverage, and multi-agent or remote end-to-end scenarios.

Equivalent coverage should prove:

- agent lifecycle, routing, mailbox, subscription, and control-state transitions preserve the contracts documented in this leaf
- bridge transport, projection, permission forwarding, reconnect, and transcript continuity behave correctly with resettable peers and deterministic state seeds
- observable teamwork behavior remains correct when users drive the product through real teammate, pane, or remote-session surfaces
