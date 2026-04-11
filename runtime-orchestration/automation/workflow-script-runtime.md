---
title: "Workflow Script Runtime"
owners: []
soft_links: [/product-surface/command-dispatch-and-composition.md, /runtime-orchestration/tasks/task-model.md, /runtime-orchestration/tasks/task-registry-and-visibility.md, /ui-and-experience/background-and-teamwork/background-task-detail-dialogs.md, /ui-and-experience/background-and-teamwork/background-task-row-and-progress-semantics.md, /tools-and-permissions/agent-and-task-control/task-and-team-control-tool-contracts.md]
---

# Workflow Script Runtime

Workflow scripts are not just fancy slash-command expansions. They are a gated subsystem that loads workflow definitions from the same markdown-config world as commands and skills, exposes them as badged commands, executes them through a dedicated workflow tool, and tracks them as first-class background tasks with their own progress tree, control surface, and cleanup rules.

## Definition discovery and command surfacing

Equivalent behavior should preserve:

- a dedicated workflows directory participating in the same layered markdown-config discovery used for other user- and repo-defined extensibility surfaces
- expensive workflow-definition loading being memoized per working directory alongside other command sources instead of rescanning disk on every command refresh
- workflow-backed commands joining the unified command catalog rather than living behind a separate menu or separate slash namespace
- that catalog position being stable relative to bundled skills, directory skills, plugins, and built-ins so naming and precedence do not drift across refreshes
- workflow-backed commands carrying explicit metadata that lets typeahead and help badge them as workflows instead of making them indistinguishable from ordinary prompt commands
- non-workflow builds omitting both the workflow-management command surface and the workflow-backed command loader, not merely hiding them cosmetically

This keeps workflows feeling like native commands while still allowing builds without the feature to tree-shake the whole subsystem away.

## Tool bootstrap and permission boundaries

Equivalent behavior should preserve:

- bundled workflows being initialized before the workflow tool is exposed, so built-in workflow definitions are ready even before user directories are scanned
- workflow execution going through a dedicated tool and permission surface rather than pretending to be generic shell or agent work
- a specialized workflow permission renderer being used when the build ships one, with safe fallback to the generic permission card when it does not
- classifier-style fast paths being allowed to treat workflow orchestration as metadata-safe, while the concrete downstream agent and tool calls inside the workflow still go through their own normal permission checks
- async subagents being prevented from recursively invoking the workflow tool, so a workflow cannot spawn an agent that launches another workflow tool chain indefinitely

The important contract is that orchestration is centralized, but concrete side effects still stay permissioned at the leaves.

## Background task identity and turn interaction

Equivalent behavior should preserve:

- a dedicated `local_workflow` task family with its own durable ID namespace rather than reusing plain local-agent IDs
- workflow task registration emitting the same started and terminated lifecycle signals as other tasks, but with workflow-specific metadata such as workflow name and originating prompt when available
- workflow tasks appearing in the shared app-state task registry while retaining their own distinct type for routing, labeling, and detail dispatch
- the CLI and headless output loop treating running background workflows like running background agents: final turn results can be held back until those background workflow tasks settle instead of claiming the turn is over too early
- workflow progress being owned by the workflow task itself, not reconstructed afterward from generic transcript text
- remote viewers using task-start and task-close signals to maintain background-count awareness of workflows while ignoring workflow-progress deltas for count math

## Phase progress and operator controls

Equivalent behavior should preserve:

- progress updates being emitted as delta batches that clients can upsert into a phase tree, rather than retransmitting the full workflow state snapshot on every tick
- workflow rows in task summaries preferring workflow metadata over raw prompt text, with a fallback order that keeps user-facing names stable even when one field is missing
- running workflow rows surfacing agent-count progress, while completed rows fall back to ordinary terminal status plus unread semantics
- background-task dialogs giving workflows their own section, their own detail renderer, and their own completion grace period so users can inspect the final state before eviction
- workflow detail exposing whole-workflow stop plus per-agent skip and retry actions while the workflow is still live
- detail dispatch and keyboard affordances remaining feature-gated so non-workflow builds do not carry dead UI branches

## Ephemeral worktrees and cleanup

Equivalent behavior should preserve:

- workflow-created throwaway worktrees using a workflow-specific slug pattern distinct from user-named worktrees
- that slug including a run-scoped discriminator plus per-workflow index so sibling worktrees from one workflow do not collide
- stale workflow worktrees participating in the same aged cleanup sweep as leaked agent and bridge worktrees
- cleanup being fail-closed: only known ephemeral patterns are eligible, current-session worktrees are skipped, tracked changes block deletion, and unreached commits prevent cleanup

Without this cleanup discipline, killed workflows accumulate orphaned worktrees that look user-owned and become unsafe to reap later.

## Failure modes

- **workflow invisibility**: workflow definitions load, but commands do not join the unified catalog or lose their workflow badge, so users cannot distinguish them from ordinary prompt commands
- **recursive orchestration**: subagents are allowed to call the workflow tool again and create unbounded nested workflow trees
- **early turn completion**: headless or bridge output emits the final result before background workflow tasks finish, so SDK or remote consumers think the turn is fully done when workflow work is still active
- **progress snapshot thrash**: clients receive full workflow-state blobs instead of delta batches and cannot stably rebuild phase progress
- **control loss**: workflow detail forgets skip or retry controls for individual agents and turns a recoverable multi-agent workflow into a kill-only task
- **worktree leak**: workflow crash paths leave behind throwaway worktrees that no longer match cleanup rules and accumulate indefinitely

## Test Design

In the observed source, automation behavior is verified through deterministic scheduler regressions, stateful integration coverage, and public-surface workflow scenarios.

Equivalent coverage should prove:

- due-time calculation, jitter, speculation, and recovery logic remain deterministic under test posture and explicit clock control
- durable task state, ownership locks, prompt injection, and cross-session coordination compose correctly with the task and session subsystems
- user-visible cron, review, proactive, and remote-planning behavior works through the real automation surfaces instead of a bypass harness
