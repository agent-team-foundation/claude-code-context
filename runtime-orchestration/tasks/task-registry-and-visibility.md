---
title: "Task Registry and Visibility"
owners: []
soft_links: [/runtime-orchestration/tasks/task-model.md, /runtime-orchestration/tasks/shared-task-control-plane-and-lifecycle-events.md, /runtime-orchestration/tasks/monitor-task-families-and-watch-lifecycle.md, /runtime-orchestration/state/app-state-and-input-routing.md, /runtime-orchestration/sessions/background-main-session-lifecycle.md, /runtime-orchestration/sessions/remote-agent-restoration-and-polling.md, /ui-and-experience/background-and-teamwork/background-task-status-surfaces.md]
---

# Task Registry and Visibility

Claude Code keeps one shared in-memory registry for locally owned tasks, then derives many different user-visible surfaces from that registry. Reconstructing the product requires both halves: the canonical task records and the rules that decide which tasks appear where.

Registration, replacement, generic stop dispatch, and SDK task-lifecycle bookends are shared runtime mechanics captured in [shared-task-control-plane-and-lifecycle-events.md](shared-task-control-plane-and-lifecycle-events.md). This leaf focuses on record shape and on the derived surfaces built from those records.

## Canonical task record

Every locally owned task should have a stable record containing at least:

- a durable task ID from a family-specific namespace
- a task family or type
- user-facing description or prompt summary
- non-terminal versus terminal status
- start time and optional end time
- an output location or transcript binding
- optional progress payload such as tool counts, token estimates, or recent activity
- cleanup and abort handles while the task is live

Terminal tasks must become immutable from the runtime's point of view even if the UI keeps them visible for a short linger window.

## Task identity families

Equivalent behavior should distinguish at least these identity classes:

- ordinary background tasks
- monitor-style shell tasks that reuse shell storage shape while changing notification and labeling semantics
- dedicated monitor-MCP watch tasks that need their own namespace and dialog slot
- local subagent-style tasks
- backgrounded main-conversation tasks that reuse local-agent infrastructure but still need their own recognizable flavor
- remote shadow tasks that represent work owned elsewhere
- UI-visible maintenance tasks such as durable-memory consolidation

The important clean-room point is that task family cannot always be inferred from one coarse top-level type field. Some task flavors intentionally reuse the same storage shape while changing routing, notification, and transcript semantics.

## Visibility is derived, not stored once

The canonical registry is not the same thing as the visible task list.

Equivalent behavior should preserve:

- derived filters for different surfaces such as generic footer summaries, coordinator-style panels, teammate strips, and detail dialogs
- separate pointers for "which task transcript is foregrounded in the main view" versus "which worker should receive routed input"
- support for terminal-task linger without reopening terminal tasks for mutation
- explicit dismissal or expiry paths that remove a task from one surface without rewriting the task family's meaning

This is why one task can still exist for inspection while no longer appearing in the compact footer summary.

## Local versus remote work accounting

Remote viewer state must not be synthesized from the local registry.

A faithful rebuild should keep separate:

- locally owned tasks that have in-process state and local output handles
- remotely owned background-work counts that arrive as transport events
- reconnect, disconnected, or degraded remote state that affects rendering even when no local task exists

If these are merged, a viewer-only client will either show phantom local tasks or lose awareness of remote work entirely.

## Failure modes

- **identity collapse**: two task families share one storage shape and the rebuild loses the behavioral distinction between them
- **visibility drift**: one surface hides or shows a task based on stale data while another surface still treats it as active
- **mutable terminal tasks**: finished tasks keep accepting progress writes and the UI cannot trust their history
- **remote-local confusion**: remote background work is incorrectly reconstructed from local task records

## Test Design

In the observed source, task behavior is verified through lifecycle regressions, registry-backed integration tests, and concurrency-sensitive foreground or background scenarios.

Equivalent coverage should prove:

- state transitions for launch, running, streaming, cancellation, completion, and failure remain deterministic and resettable between cases
- task registries, monitor families, shared-control events, and persisted output compose correctly across main-session and worker contexts
- users can still observe, foreground, stop, and inspect task output through the same surfaces they use in normal interactive or automated runs
