---
title: "Agent Runtime Context and Tool Shaping"
owners: []
soft_links: [/tools-and-permissions/tool-catalog/agent-definition-loading-and-precedence.md, /tools-and-permissions/agent-and-task-control/agent-tool-launch-routing.md, /collaboration-and-agents/worker-execution-boundaries.md, /integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md, /integrations/plugins/plugin-and-skill-model.md, /integrations/plugins/skill-loading-contract.md]
---

# Agent Runtime Context and Tool Shaping

Selecting an agent definition and a launch route is only the start of worker execution. Claude Code then runs a second shaping phase that decides what the worker can see, which tools it actually gets, how permission prompts behave, which skills or hooks are activated, and whether agent-scoped MCP servers join the session. A faithful rebuild needs this phase as its own contract, because the selected definition alone does not explain the worker's real authority.

## Scope boundary

This leaf covers:

- the post-selection runtime shaping that happens before the worker query loop starts
- how normal workers differ from inherited-context fork children
- which parts of `ToolUseContext` are isolated, cloned, shared, or overridden per worker
- how agent-scoped skills, hooks, and MCP servers attach to one worker lifecycle

It intentionally does not re-document:

- how agent definitions are discovered and deduplicated, already covered in [agent-definition-loading-and-precedence.md](agent-definition-loading-and-precedence.md)
- how the Agent tool chooses teammate, fork, background, worktree, or remote launch branches, already covered in [agent-tool-launch-routing.md](agent-tool-launch-routing.md)
- the longer-lived task registration, backgrounding, and notification lifecycle, already covered in [../runtime-orchestration/tasks/local-agent-task-lifecycle.md](../runtime-orchestration/tasks/local-agent-task-lifecycle.md)

## Normal workers rebuild their tool posture; exact forks reuse it

Equivalent behavior should preserve two distinct paths:

- ordinary workers receiving a fresh worker tool pool assembled for the worker's own permission posture instead of inheriting the parent's currently narrowed session rules
- that worker tool pool defaulting to an edit-capable posture when the selected agent does not name a stricter permission mode
- ordinary workers then resolving that pool through agent-specific tool shaping, not by blindly accepting every assembled tool
- inherited-context fork children being the exception: they reuse the parent's exact tool definitions byte-for-byte so the child request can share the same prompt-cache prefix as the parent
- exact-tool forks also inheriting the parent's thinking configuration and non-interactive posture, while ordinary workers disable thinking and independently decide whether they are interactive

## Tool filtering is layered, not one allowlist

Equivalent behavior should preserve this shaping order for normal workers:

- MCP tools surviving the generic agent filter regardless of other tool restrictions
- a global agent disallow list being enforced for every agent
- an extra disallow layer applying only to non-built-in agents
- async workers being narrowed again to an async-safe allowlist
- plan-mode workers still retaining the explicit way to leave plan mode
- in-process teammates getting a small set of extra coordination tools, including the ability to spawn synchronous subagents when the swarming path is active
- agent-level `disallowedTools` subtracting from the remaining pool after the generic filters run
- agent-level `tools` behaving as an allowlist only after the remaining pool is known
- missing `tools` or a wildcard meaning "all remaining tools", not "inherit the parent session allow rules"
- invalid tool specs being tracked as invalid rather than silently widening the worker's authority
- Agent tool specs being able to carry a restricted set of allowed child agent types, even when the Agent tool itself is not available to ordinary subagents

The important invariant is that runtime authority comes from the filtered result, not from whichever tool names happened to exist in the definition file.

## Permission posture is recomputed per worker

Equivalent behavior should preserve:

- worker execution wrapping app-state access so the worker sees a derived permission posture without mutating the parent's live session state
- agent frontmatter `permissionMode` overriding the inherited mode only when the parent is not already in a stronger or more centralized control mode such as bypass, accept-edits, or transcript-classifier-driven auto mode
- the edit-capable default used to assemble a fresh worker tool pool staying separate from approval-mode inheritance, so an unspecified agent can get an edit-capable surface without forcibly switching the worker into `acceptEdits`
- async workers that cannot surface dialogs marking permission prompts as unavailable so approvals fail closed instead of hanging on invisible UI
- async workers that can surface dialogs still waiting for automated checks before interrupting the user with a prompt
- bubble-style permission behavior staying interactive even when the worker itself is async
- explicit worker `allowedTools` replacing inherited session-level allow rules so the parent's ad hoc approvals do not leak through
- CLI or SDK allow rules remaining in force even when session-level rules are replaced, because those are consumer-specified global permissions rather than incidental session history
- per-agent effort overrides being applied through the same derived app-state view instead of mutating global settings

## Context inheritance is selective and branch-sensitive

Equivalent behavior should preserve:

- fresh workers starting from the explicit prompt envelope only, with no inherited conversation by default
- fork children prepending inherited parent messages before the new prompt
- inherited message history being filtered to remove assistant tool calls that do not yet have matching tool results, preventing malformed replay of incomplete tool-use blocks
- normal workers starting with a fresh bounded read-file cache
- fork children cloning the parent's read-file cache so previously read files remain visible without forcing the child to reread them immediately
- agent metadata and initial messages being written to a sidechain transcript before the worker loop begins so resume and task surfaces can reconstruct the correct agent identity
- some read-only agent types being allowed to omit bulky checked-in instruction context and stale repository-status context when that inherited information would only waste tokens and the coordinator is expected to interpret the result
- subagent-start hooks being able to attach additional context as explicit user-visible attachments rather than silently mutating the worker's system prompt

## Subagent context isolation is selective, not absolute

Equivalent behavior should preserve:

- cloned read-state and cloned content-replacement state by default, so workers do not trample the parent's mutable caches
- fresh per-worker collections for nested-memory triggers, dynamic skill discovery, surfaced skill names, and denial tracking
- a distinct agent ID and incremented lineage depth for every worker context
- sync workers being allowed to share the parent's state-update callback when they need to participate in live interactive state changes
- async workers getting no-op local state mutation callbacks by default, while task-registration writes still flow to the root app-state store so background subtasks, shell tasks, and cleanup remain visible and stoppable
- response-length and API-metrics callbacks being sharable even when most other UI callbacks are intentionally absent
- async workers receiving an abort controller that can outlive cancellation of the parent foreground turn, while sync workers may share the parent's controller
- explicit overrides being able to opt back into sharing selected callbacks for special interactive subagent paths

The result is deliberate partial isolation: enough sharing to keep coordination working, but not so much that a worker accidentally becomes another view of the parent.

## Skills, hooks, and MCP are attached at worker start

Equivalent behavior should preserve:

- agent frontmatter hooks registering only when customization policy allows that source to contribute hooks
- admin-trusted built-in, plugin, or managed-policy agent sources being able to keep their approved hook surface even when user-controlled hook customization is locked down
- agent-scoped stop-style hooks being rewritten to the subagent-specific lifecycle event rather than pretending the worker is the main session
- registered agent hooks being cleared when that worker finishes
- agent frontmatter skills resolving late against the current local prompt-command catalog by exact match first, then plugin-qualified fallback, then suffix matching for plugin-namespaced skills
- missing skills or non-prompt skills degrading with warnings instead of blocking the worker entirely
- that preload path in this snapshot not consulting the live MCP-skill overlay, so agent-declared preloads behave as local prompt selections rather than arbitrary MCP-skill lookups
- preloaded skills entering the worker transcript as explicit meta user messages with loading metadata, not as invisible prompt concatenation
- preloaded skill bodies being expanded before the final worker context exists, using the parent or session context rather than the worker's eventual worktree override or agent-scoped MCP additions
- agent-scoped MCP servers being additive to the parent's MCP client set rather than replacing it
- named MCP references reusing shared clients, while inline MCP definitions create worker-owned dynamic clients
- plugin-only MCP policy blocking user-controlled frontmatter MCP additions while still allowing admin-trusted agent sources to contribute approved MCP servers
- worker-owned inline MCP clients being cleaned up when the worker exits, while shared named clients remain alive for the rest of the session
- tools fetched from agent-scoped MCP clients being merged with the worker's shaped tool set by tool identity rather than simply appended with duplicates

## Query-loop preparation and cleanup are part of the contract

Equivalent behavior should preserve:

- the worker's final system prompt being built only after tool shaping is complete, because tool availability influences environment augmentation
- cache-safe parameters being exposed after prompt, context, and tool shaping so background summarizers and other forks can reuse the same request prefix
- only recordable transcript message types being persisted to the sidechain transcript; stream deltas should inform liveness but not become durable history
- worker teardown always cleaning up agent-scoped MCP connections, agent-scoped hooks, cloned file-state caches, transcript-subdirectory mappings, prompt-cache bookkeeping, and worker-owned shell or monitor tasks

## Failure modes

- **permission leak**: parent session approvals or live tool restrictions bleed into the worker in the wrong direction, changing what the worker can actually do
- **cache-break fork**: an inherited-context child recomputes tools, thinking, or system prompt bytes and loses the parent's cache-stable prefix
- **hidden-prompt deadlock**: a background worker waits on a permission dialog it has no path to display
- **tool-mode conflation**: rebuilds treat the fresh worker tool-pool default as a forced runtime approval-mode switch and change prompt UX the agent never requested
- **preload context drift**: agent-declared skill preloads resolve against the wrong catalog or the final worker-local MCP or worktree context, so the loaded guidance differs from the observed product
- **extension trust inversion**: user-controlled agents gain hooks or MCP authority that should be reserved for admin-trusted sources, or trusted plugin agents lose approved capabilities
- **context bloat**: read-only workers inherit bulky instruction or repository-status context that they cannot act on, wasting tokens and obscuring the bounded-worker model
