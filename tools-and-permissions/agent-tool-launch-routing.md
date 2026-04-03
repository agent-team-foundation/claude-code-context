---
title: "Agent Tool Launch Routing"
owners: []
soft_links: [/collaboration-and-agents/worker-execution-boundaries.md, /runtime-orchestration/local-agent-task-lifecycle.md, /runtime-orchestration/remote-agent-restoration-and-polling.md]
---

# Agent Tool Launch Routing

The Agent tool is a launch router, not one execution primitive. It decides whether a request should create a teammate, start an inherited-context fork, run a named subagent, detach into background execution, isolate itself in a worktree, or jump to a remote environment. Reproducing Claude Code requires the same precedence rules, because later task and UI behavior depends on which branch was chosen up front.

## Route selection order

Equivalent behavior should preserve:

- team-execution feature gating before any teammate branch is considered valid
- resolution of team context from explicit `team_name` first and current team membership second
- teammate spawning only when both a resolved team name and an explicit teammate name are present
- ordinary subagent execution remaining available inside a team when the caller omits teammate naming
- refusal to let an already-running teammate create more teammates, keeping team membership flat
- refusal to let in-process teammates request background execution, whether that background intent comes from explicit input or from an agent definition that always backgrounds
- teammate launches returning a dedicated teammate-spawn result instead of pretending to be ordinary subagent completions
- explicit agent type taking precedence over experimental fork defaults, while omitted type can route into the inherited-context fork path when that experiment is enabled
- recursive fork protection so a forked child cannot create another fork and explode inherited context
- agent-definition permission filtering and deny-rule enforcement after route selection but before execution
- required MCP-server checks that wait for pending connections, then fail closed if the chosen agent still lacks authenticated tool-bearing servers

## Worker preparation rules

Equivalent behavior should preserve:

- normal subagents receiving their own tool pool assembled from worker permission context instead of inheriting the parent's narrowed tool restrictions
- fork-style children being the exception that reuse the parent's exact system-prompt prefix, exact tool array, and full conversation context for cache-stable inherited execution
- normal agents building their own system prompt, environment augmentation, and simple user-prompt envelope
- explicit isolation input overriding any isolation default baked into the chosen agent definition
- remote isolation short-circuiting the local run loop and worktree path entirely
- stable agent ID creation before worktree setup so isolated checkout names, metadata, and later message routing stay consistent
- optional worktree isolation creating a separate checkout for the worker and passing that override into later filesystem resolution
- an extra path-translation notice being appended when a forked child also runs inside a worktree, so inherited context does not keep pointing at stale parent paths
- explicit cwd override taking precedence over the worktree path when both could affect how the worker resolves the filesystem

## Async, background, and remote semantics

Equivalent behavior should preserve:

- remote launches performing eligibility checks, registering a remote task row, and returning a distinct remote-launch result without entering the normal local agent loop
- local async execution being forced not only by explicit background mode, but also by agent definitions that require background, coordinator mode, fork-experiment mode, assistant or daemon-style execution, and proactive execution
- global background-task disablement suppressing every async-forcing branch above
- async workers registering before execution starts, with an abort controller independent from the parent foreground turn
- name-to-agent routing entries for follow-up messaging being written only after async registration succeeds, so failed launches do not leave stale names behind
- teammate-originated subagents preserving lineage back to the team-lead session rather than pretending to belong to whichever teammate view is currently highlighted
- unchanged temporary worktrees being deleted on completion, while changed or hook-managed worktrees are intentionally preserved and surfaced as result metadata
- distinct result envelopes for teammate spawn, remote launch, async launch, and normal completion so callers can branch on structured state instead of parsing prose

## Failure modes

- **wrong-branch precedence**: a request that should create a teammate accidentally becomes a normal subagent or vice versa
- **fork context leak**: fresh subagents inherit parent context outside the explicit fork path
- **MCP dead-end**: an agent launches without the required authenticated tool servers and fails mid-task
- **background cancel leak**: pressing escape on the parent turn kills workers that were meant to keep running independently
- **worktree orphaning**: short-lived isolated checkouts are left behind or, worse, deleted even though the child produced changes
