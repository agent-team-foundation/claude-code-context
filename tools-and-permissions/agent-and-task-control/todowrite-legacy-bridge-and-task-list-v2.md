---
title: "TodoWrite Legacy Bridge and Task List V2"
owners: []
soft_links: [/tools-and-permissions/agent-and-task-control/task-and-team-control-tool-contracts.md, /runtime-orchestration/tasks/shared-task-list-contract.md, /ui-and-experience/background-and-teamwork/background-task-status-surfaces.md, /collaboration-and-agents/team-formation-and-spawn-contract.md]
---

# TodoWrite Legacy Bridge and Task List V2

Claude Code currently preserves two progress-tracking systems: the older session-local `TodoWrite` checklist and the newer file-backed task-list tools. They are not interchangeable, but they are intentionally bridged so agents, teammates, reminders, verification nudges, and UI surfaces do not regress during the migration. A clean-room rebuild needs that bridge, not just one side of it.

## Scope boundary

This leaf covers:

- when the runtime exposes legacy `TodoWrite` versus Task V2 tools
- how each system stores and projects progress state
- reminder and verification behaviors that span the migration boundary
- team and watcher behavior that turn Task V2 into a shared work queue

It intentionally does not re-document:

- generic task CRUD semantics already covered in [task-and-team-control-tool-contracts.md](task-and-team-control-tool-contracts.md)
- deeper task-runtime visibility already covered in [../runtime-orchestration/tasks/shared-task-list-contract.md](../runtime-orchestration/tasks/shared-task-list-contract.md)

## Version gate: only one primary progress toolset at a time

Equivalent behavior should preserve a gate between:

- legacy `TodoWrite`
- Task V2 tools such as create, get, list, and update

Task V2 is the normal interactive-session path. Legacy `TodoWrite` remains the active progress tool when Task V2 is not enabled, with an explicit force-enable escape hatch for environments that need the newer task system outside the default interactive path.

The clean-room requirement is "one primary progress model," not "both always visible."

## Legacy TodoWrite is session-local and agent-local

Equivalent behavior should preserve `TodoWrite` as in-memory state keyed by:

- the main session when running on the primary thread
- the current agent ID when running inside a subagent

When every todo item is completed, the stored list collapses back to empty instead of lingering forever as completed clutter.

## Legacy TodoWrite is intentionally quiet in the transcript

Equivalent behavior should preserve the legacy tool not rendering its own prominent user-facing tool row. It acts as a side channel for structured progress state first, transcript decoration second.

## Legacy reminders are turn-based, not time-based

Equivalent behavior should preserve the "you have not used TodoWrite recently" reminder as a turn-count rule:

- count assistant turns since the last `TodoWrite`
- count assistant turns since the last reminder attachment
- do not count thinking-only messages
- suppress the reminder if the TodoWrite tool is not actually available
- suppress the reminder when another structured user-messaging channel already owns the workflow

This reminder is attached context, not a timer popup.

## Legacy verification nudge fires at list closeout

Equivalent behavior should preserve a verification nudge when:

- the main-thread agent just closed out a substantial todo list
- all items became completed
- none of those items was a verification step
- the verification-agent feature is active

The nudge belongs to the closeout moment, not to arbitrary background auditing.

## Subagent cleanup must clear legacy todo residue

Equivalent behavior should preserve teardown that removes a finished agent's legacy todo entry from shared app state. Otherwise long sessions that spawn many helpers accumulate empty per-agent todo keys forever.

## Task V2 is file-backed and shared

Equivalent behavior should preserve Task V2 as a file-backed task list under the user's Claude config home, with:

- one task file per task
- a high-water mark to prevent ID reuse after resets
- lock-guarded mutation so multiple agents or processes can share one list safely
- structured fields for subject, description, active form, owner, status, blockers, and metadata

Task V2 is designed to survive across cooperating processes, not just one REPL instance.

## Task-list identity depends on team and session context

Equivalent behavior should preserve task-list ID resolution in this order:

1. explicit task-list override from environment
2. in-process teammate team name
3. process-based teammate team name
4. leader-created team name
5. session ID fallback

This is what makes a team-created shared queue and a standalone session-local queue use the same underlying task system without special-case storage code.

## Task mutations carry workflow behavior

Equivalent behavior should preserve:

- task-creation hooks that can veto creation and roll back the just-created task
- task-completion hooks that can block a completion transition
- automatic expansion of the task view when tasks are created or updated
- teammate auto-claim behavior when a worker marks a task `in_progress` without explicitly naming an owner
- metadata merge semantics where `null` deletes a key

Task V2 is not just persistent storage. It is a workflow control plane.

## Task V2 mirrors the verification nudge

Equivalent behavior should preserve the verification nudge on Task V2 closeout too, so migrating from legacy todos to file-backed tasks does not silently remove the "verify before final summary" workflow steer.

## Shared UI projection uses one watcher store

Equivalent behavior should preserve the visible Task V2 UI through one shared watcher/store layer that:

- reuses one `fs.watch` subscription instead of one watcher per UI consumer
- debounces bursts of file events
- falls back to periodic polling while incomplete tasks exist
- filters internal-only tasks from the visible list
- hides the visible list after a short delay once all tasks are completed
- resets the underlying list after that hide delay so future work starts cleanly

This is a persistence-and-projection bridge, not a mere React convenience.

## Tasks mode turns Task V2 into an execution queue

Equivalent behavior should preserve a watcher mode that:

- watches a chosen task list directory
- claims pending unowned unblocked tasks
- formats the chosen task into a prompt
- submits it to Claude automatically
- releases the claim if submission fails
- avoids re-claiming while already busy with another task

That path is what lets Task V2 act as a work queue for teammates or external producers.

## Teams bind directly onto Task V2

Equivalent behavior should preserve team creation establishing a 1:1 relation between:

- the team identity
- its shared task-list identity
- leader and teammate routing

The migration is incomplete if teams still coordinate elsewhere while task tools mutate a different queue.

## Failure modes

- **split progress model**: both TodoWrite and Task V2 are exposed as primary progress tools in the same session and the model updates the wrong one
- **reminder drift**: TodoWrite reminders still fire in sessions where the legacy tool is not even available
- **verification regression**: migrating to Task V2 removes the closeout verification nudge that existed under TodoWrite
- **orphaned task queue**: leader and teammates resolve different task-list IDs and stop coordinating through one shared queue
- **watcher storm**: every UI surface opens its own filesystem watcher and task visibility becomes flaky or expensive
- **ghost todos**: finished subagents leave empty TodoWrite keys behind and slowly leak app-state memory
