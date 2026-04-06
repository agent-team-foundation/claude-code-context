---
title: "Task and Team Control Tool Contracts"
owners: []
soft_links: [/tools-and-permissions/agent-and-task-control/control-plane-tools.md, /runtime-orchestration/tasks/shared-task-list-contract.md, /collaboration-and-agents/team-formation-and-spawn-contract.md]
---

# Task and Team Control Tool Contracts

Task and team tools are not thin wrappers over files. They are structured control-plane contracts that mutate the work graph, notify other agents, and keep UI state aligned.

## Task creation

Equivalent task-creation behavior should preserve:

- creation of a pending task in the active task list
- optional metadata and activity-summary fields at creation time
- a deferred, concurrency-safe execution model so task creation can coexist with other turn work
- post-create hooks that may veto the creation
- rollback by deleting the just-created task when a blocking hook fails
- automatic expansion of the task surface so the created task becomes visible immediately

The important contract is that a failed create hook leaves no half-created task behind.

## Task updates

Equivalent task-update behavior should preserve a structured patch model rather than text editing of task files.

Important operations include:

- partial updates of subject, description, activity phrasing, status, owner, and metadata
- metadata merge semantics where null deletes a key
- a delete action represented as a special status transition
- dependency-edge creation in both directions
- completion hooks that can block status change before a task is marked complete
- optional automatic owner assignment when swarm workers claim work by moving a task into progress
- notification of newly assigned owners through the teammate mailbox

The task-update result channel should distinguish domain failures such as missing task or blocked completion from transport or runtime failures, so the broader tool executor can keep running.

## Verification nudges

Task updates also participate in workflow steering.

Equivalent behavior should support a late verification nudge when:

- the main agent closes out a sufficiently large task list
- no explicit verification step exists in that list

This is not required for every build, but the contract should allow task tools to add workflow-level guidance instead of acting as dumb CRUD.

## Team creation

Equivalent team-creation behavior should preserve:

- one actively led team per leader session
- collision-safe team naming that can recover instead of only failing
- creation of a durable team artifact describing the leader, team identity, and member roster
- reset or fresh initialization of the team's shared task-list directory
- binding of the leader's task-list identity to that team so leader and teammates operate on the same queue
- immediate update of in-memory team context for UI and routing
- session-end cleanup registration for teams that should not live forever by accident

The leader's identity should remain distinct from subordinate teammate identity even though both belong to the same team context.

## Failure modes

- **partial create**: a task is visible even though a create hook blocked it
- **non-atomic completion**: a task is marked complete before completion hooks finish
- **assignment drift**: owner changes do not notify the new owner, so swarm routing falls out of sync
- **split team queues**: leader and teammates accidentally write to different task lists
- **multi-team leader**: one leader session silently controls more than one active team
