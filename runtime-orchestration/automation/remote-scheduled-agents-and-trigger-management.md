---
title: "Remote Scheduled Agents and Trigger Management"
owners: []
soft_links: [/runtime-orchestration/automation/scheduled-prompts-and-cron-lifecycle.md, /tools-and-permissions/agent-and-task-control/remote-trigger-control-tool-contracts.md, /collaboration-and-agents/remote-session-contract.md, /integrations/mcp/server-contract.md]
---

# Remote Scheduled Agents and Trigger Management

Claude Code has two different recurring-work surfaces. Local scheduled prompts live inside the local runtime and are covered by [scheduled-prompts-and-cron-lifecycle.md](scheduled-prompts-and-cron-lifecycle.md). Remote scheduled agents are different: they are cloud-owned triggers that launch fully remote Claude sessions on a schedule. Rebuilding them faithfully means not pretending they are just another frontend for the local cron subsystem.

## Scope boundary

This leaf covers:

- the low-level remote trigger control-plane tool
- the bundled `/schedule` skill that interviews the user and drives that tool
- remote-specific environment, connector, timezone, and deletion rules

It intentionally does not re-document:

- local cron scheduling already covered in [scheduled-prompts-and-cron-lifecycle.md](scheduled-prompts-and-cron-lifecycle.md)
- generic remote-session lifecycle after a remote session is already running, already covered in [../collaboration-and-agents/remote-session-contract.md](../collaboration-and-agents/remote-session-contract.md)

## The low-level tool is a thin proxy to a cloud trigger API

Equivalent behavior should preserve:

- a dedicated remote-trigger control-plane tool rather than reuse of local cron tools
- feature and policy gating before the tool is even visible
- Claude.ai OAuth plus organization identity being required before any remote-trigger operation can proceed
- the tool being deferred and concurrency-safe, with only `list` and `get` treated as read-only actions
- the low-level action set being exactly:
  - `list`
  - `get`
  - `create`
  - `update`
  - `run`
- no low-level delete action in the tool contract
- the client acting mostly as a thin authenticated proxy and leaving most schedule-body validation to the cloud service rather than re-implementing every server rule locally

## `/schedule` is a guided wrapper, not a second scheduler

Equivalent behavior should preserve:

- `/schedule` being a bundled skill layered on top of the remote-trigger tool instead of being an independent runtime subsystem
- the skill only needing the remote-trigger tool plus ask-user-question support
- a no-argument invocation opening with one ask-user-question step that offers create, list, update, or run
- an argument-bearing invocation skipping that initial question but still surfacing any setup warnings in the prompt body
- the skill interviewing the user about goal, schedule, environment, repo sources, and connectors before attempting creation or update

## Remote scheduled agents are remote Claude sessions, not local jobs

Equivalent behavior should preserve:

- each trigger launching a fully remote session with its own environment, repo sources, tool allowlist, and optional MCP connectors
- trigger creation carrying at least:
  - a human-facing name
  - a UTC cron expression
  - enabled or disabled state
  - a remote environment id
  - session-context fields such as model, repo sources, and allowed tools
  - an initial user event that carries the scheduled prompt body
- the prompt for a remote scheduled agent needing to be self-contained because the remote session starts with none of the local machine's implicit context
- remote scheduled agents not being able to access local files, local environment variables, or local services just because the user launched them from a local CLI session

## Environment and connector setup is advisory but structured

Equivalent behavior should preserve:

- the client fetching available remote environments before guiding the user through trigger creation
- automatic creation of a default remote environment when none exist, with a graceful failure message if that bootstrap also fails
- soft setup checks rather than hard blocking for:
  - not currently being inside a git repo
  - missing GitHub access for the current repo
  - no Claude.ai-connected MCP connectors
- repo-less triggers remaining valid when the user's task does not actually need a code checkout
- connector discovery being limited to Claude.ai-connected MCP proxies instead of assuming every local MCP server is remotely attachable
- connector names being sanitized to a restricted identifier format before inclusion in trigger config
- the skill inferring needed connectors from the user's stated task and warning when the necessary services are not connected

## Time semantics differ from local cron

Equivalent behavior should preserve:

- the user speaking in local time while the stored remote trigger uses UTC cron
- the assistant confirming the local-time to UTC conversion rather than silently rewriting the user's intent
- minimum scheduling granularity being approximately one hour for this remote surface
- this cloud-owned schedule contract remaining separate from the more permissive or differently tuned local cron parser

## Delete stays out of band

Equivalent behavior should preserve:

- delete being intentionally absent from both the low-level tool action set and the guided `/schedule` workflow
- users being redirected to the cloud scheduled-agents UI for deletion instead of the CLI pretending to own the full lifecycle

## Failure modes

- **local-remote collapse**: `/schedule` is rebuilt as a wrapper over the local cron file instead of a cloud trigger API
- **false locality**: remote scheduled agents inherit local files, env vars, or machine assumptions that should have stayed local-only
- **connector drift**: arbitrary local MCP servers are treated as remotely attachable even though the remote surface only knows how to reuse specific cloud-connected connectors
- **timezone ambiguity**: the system stores UTC cron without confirming the user's local-time intent
- **fake delete**: the CLI pretends to support deletion even though the observed surface keeps deletion in the web control plane

## Test Design

In the observed source, automation behavior is verified through deterministic scheduler regressions, stateful integration coverage, and public-surface workflow scenarios.

Equivalent coverage should prove:

- due-time calculation, jitter, speculation, and recovery logic remain deterministic under test posture and explicit clock control
- durable task state, ownership locks, prompt injection, and cross-session coordination compose correctly with the task and session subsystems
- user-visible cron, review, proactive, and remote-planning behavior works through the real automation surfaces instead of a bypass harness
