---
title: "Command Execution Archetypes"
owners: []
soft_links: [/product-surface/command-surface.md, /product-surface/command-dispatch-and-composition.md, /runtime-orchestration/automation/review-path.md, /runtime-orchestration/sessions/resume-path.md, /memory-and-context/compact-path.md, /collaboration-and-agents/remote-handoff-path.md]
---

# Command Execution Archetypes

Claude Code exposes many slash commands, but they are not many independent runtimes. A faithful rebuild needs a small set of reusable execution chains that commands enter after lookup. If a rebuild gives each command family bespoke orchestration, remote narrowing, and recovery semantics drift apart.

## Scope boundary

This leaf covers:

- the small set of execution chains command records are allowed to enter after dispatch
- which runtime subsystems each chain depends on
- where local, headless, bridge, and remote surfaces narrow those chains

It intentionally does not re-document:

- command record kinds, loading order, and lookup rules already covered in [command-dispatch-and-composition.md](command-dispatch-and-composition.md)
- surface-specific inventory shaping already covered in [command-surface.md](command-surface.md)
- deep behavior of review, resume, compaction, and remote handoff already covered in the linked runtime leaves

## Commands collapse onto a few reusable chains

Equivalent behavior should preserve a command model where slash names are entrypoints into a small number of runtime archetypes:

### 1. Bootstrap and restore chain

- startup-routing commands, `/resume`, continue flags, direct-connect attach, and some remote-control entrypoints run before the ordinary steady-state prompt loop or temporarily suspend it
- these paths depend on session discovery, repo identity, auth or policy checks, cwd or worktree placement, and sometimes transport attachment
- the important invariant is that restore commands recover an existing session state machine instead of simulating a new prompt turn that merely replays old text

### 2. Local control and modal UI chain

- help, picker, config, plugin-management, diff, export, and similar local commands execute local logic or open terminal UI without sending a model query
- these commands may still mutate shared session or settings state, queue follow-up input, or emit transcript-visible status messages
- bridge and companion clients must narrow this chain aggressively because local JSX and local filesystem assumptions do not survive remote-control surfaces

### 3. Prompt re-entry chain

- prompt-backed commands expand into structured instructions and re-enter the ordinary query loop instead of inventing a second execution engine
- per-command metadata may narrow tools, choose a model, install hooks, request forked execution, or hide direct user invocation, but the chain still lands in the same turn assembly, permission, tool, and compaction systems as freeform user text
- local review, setup, memory, and many skill-like commands live here

### 4. Delegated and background chain

- some commands package work for a worker, remote task, or remote session instead of doing the work inline
- the local session must keep ownership, status, and result-foldback semantics even when execution moved elsewhere
- remote review, remote planning, and handoff-oriented flows are orchestration variants over the same task and session spine, not separate products

### 5. Registry-mutation and refresh chain

- commands that change plugins, MCP state, permissions, or settings mutate a source of record first, then rebuild live runtime state through explicit cache-clear, reload, reconnect, or needs-refresh steps
- they must not rely on one-off in-memory patches that other surfaces would miss
- this is why integration-management commands feel administrative: their real work is propagating state into the shared runtime safely

## One command record can change surface, not architecture

Equivalent behavior should preserve:

- the same underlying command being invocable from a local TUI, a headless SDK path, or a narrowed bridge surface while still entering one of the same archetypes above
- surface differences mostly affecting admission, narrowing, and result presentation rather than inventing new command-specific orchestration trees
- feature gates, auth posture, and policy being allowed to steer a command from one archetype to another in limited cases, such as local review versus delegated remote review

## Failure modes

- **bespoke-command runtime**: each command family grows its own orchestration stack instead of reusing the query, task, restore, or reload spines
- **restore-as-prompt**: resume or attach flows are rebuilt as ordinary prompt commands and lose session-state recovery guarantees
- **UI leak across surfaces**: local modal commands remain reachable from bridge or remote clients that cannot satisfy their UI assumptions
- **hidden live-state patches**: integration-management commands tweak process memory without going through shared refresh or reconnect paths
- **delegation split-brain**: background or remote command variants stop folding status and results back into the owning local session
