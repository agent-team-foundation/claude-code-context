---
title: "Local Scheduled Prompt Tool Contracts"
owners: []
soft_links: [/runtime-orchestration/automation/scheduled-prompts-and-cron-lifecycle.md, /tools-and-permissions/agent-and-task-control/control-plane-tools.md, /tools-and-permissions/agent-and-task-control/task-and-team-control-tool-contracts.md]
---

# Local Scheduled Prompt Tool Contracts

Claude Code exposes local scheduling as a first-class control-plane tool surface, not just a background runtime timer. A faithful rebuild needs a user- and model-facing contract for creating, listing, and deleting scheduled prompts that is distinct from remote trigger management.

## Local scheduling stays separate from remote triggers

Equivalent behavior should preserve:

- a local scheduling surface that targets the current machine and current session context rather than a cloud trigger service
- local schedules using local-calendar cron semantics rather than delegating timing interpretation to a remote backend
- remote trigger creation remaining a separate tool family with different auth, policy, and ownership rules

## Creation semantics

Equivalent behavior should preserve:

- support for both recurring and one-shot schedules
- session-only scheduling by default, with durable persistence only when the caller explicitly asks for survival across restarts
- durable scheduling remaining subject to a feature gate or kill switch without changing the visible schema shape mid-session
- when durable persistence is temporarily disabled, requests that ask for durability still succeeding but being downgraded to session-only scheduling instead of failing schema validation
- rejection of malformed cron expressions and schedules that cannot produce a next fire time
- a bounded total job count so scheduling cannot grow without limit

## Ownership and durability boundaries

Equivalent behavior should preserve:

- durable schedules being rejected for ephemeral worker identities that are not expected to survive process restarts
- scheduling state carrying enough identity to re-enqueue prompts for the correct session or agent family later
- turning scheduling on in the current session as part of successful creation, so a newly created local schedule can actually fire without waiting for restart
- worker-scoped scheduling views staying owner-filtered: teammate contexts list only their own schedules, while leader contexts can view the full local inventory
- delete operations enforcing the same ownership boundary, so teammates cannot cancel schedules owned by another agent identity

## Persistence boundary

Equivalent behavior should preserve:

- a distinction between session-only schedules held only for the life of the current process and durable schedules stored under a hidden local state path
- user-facing result text that makes that distinction explicit, so "fires later" does not imply "survives restart"
- delete and list surfaces operating over the same combined local schedule inventory even if some entries are session-only and others are durable, with owner filtering applied where the caller is a teammate context

## Failure modes

- **local-remote conflation**: a local schedule is created through the remote trigger service or inherits remote auth and policy requirements
- **durability surprise**: schedules silently persist across restarts when the caller expected session-only behavior, or silently disappear when the caller explicitly asked for durability
- **orphaned worker schedule**: a durable schedule is allowed for a non-persistent worker identity and later cannot route back to a valid target
- **dead scheduler flag**: schedule creation succeeds but never enables the local watcher loop that actually fires tasks
- **ownership leak**: teammate-scoped list or delete paths can view or mutate another agent's scheduled jobs
- **gate-mismatch failure**: disabling durable persistence turns valid durable requests into hard validation errors instead of runtime downgrade to session-only
