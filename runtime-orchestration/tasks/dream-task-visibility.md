---
title: "Dream Task Visibility"
owners: []
soft_links: [/runtime-orchestration/tasks/task-model.md, /memory-and-context/compaction-and-dream.md]
---

# Dream Task Visibility

Automatic memory consolidation is surfaced as a task even though the underlying forked agent is otherwise invisible to the main conversation. This task is primarily a UI and lifecycle shim: it makes consolidation progress inspectable, killable, and recoverable as task state without turning the dream worker into a normal model-facing background agent.

## Purpose and scope

Equivalent behavior should preserve:

- a dedicated `dream` task type for automatic consolidation work
- visibility in background-task UI and detail dialogs even though no ordinary task notification is sent back into the model loop
- enough state to explain what the dream worker is currently doing without exposing the entire raw fork transcript

## State model

A faithful rebuild should preserve at least:

- task status plus start and end timestamps
- a coarse dream phase that begins in startup mode and flips once observed edits begin
- how many sessions the dream pass is reviewing
- a bounded list of recent dream turns for live display
- a best-effort set of touched files
- an abort controller for user kill
- the prior consolidation-lock timestamp needed for rollback

## Progress inference

Dream-task progress is intentionally approximate.

Equivalent behavior should preserve:

- assistant text as the human-readable progress surface
- tool uses collapsed to a count rather than reproduced in full
- phase transition based on observed file-edit or file-write actions, without pretending to reconstruct the dream prompt's full internal stages
- touched-file tracking as a lower bound only; writes performed indirectly through shell commands may not be visible here
- suppression of empty updates so pure no-op turns do not trigger re-render churn

## Completion contract

Dream tasks are terminal as soon as consolidation finishes, but they do not generate a normal task-notification attachment.

The durable rule is:

- mark dream tasks notified immediately on terminal transition because their user surface is UI-only plus any inline memory-saved note
- clear the abort controller on terminal transition
- keep only recent turn summaries in task state rather than an unbounded transcript

## Lock rollback semantics

The dream task carries lock-rollback state because stop and failure handling must reopen the door for future consolidation passes.

Equivalent behavior should preserve:

- kill aborts the active dream worker and rewinds the consolidation lock timestamp
- ordinary failure also rewinds that lock
- once kill has already handled rollback, later aborted cleanup paths should not roll it back a second time

## Inline completion surfacing

Automatic consolidation may still leave a lightweight trace in the main session.

Equivalent behavior should allow:

- a concise inline completion note when the dream pass actually touched durable memory files
- no completion note when nothing durable changed

## Failure modes

- **silent dream**: consolidation runs in the background with no inspectable task record
- **false precision**: touched-file state is treated as exhaustive even though shell-mediated writes can be missed
- **lock wedged**: a killed or failed dream run does not rewind the consolidation lock and future runs never retry
- **double rollback**: both the kill path and the outer failure path rewind the lock for the same aborted run
