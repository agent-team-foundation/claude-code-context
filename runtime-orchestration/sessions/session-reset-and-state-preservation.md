---
title: "Session Reset and State Preservation"
owners: []
soft_links: [/runtime-orchestration/sessions/background-main-session-lifecycle.md, /runtime-orchestration/sessions/resume-path.md, /runtime-orchestration/sessions/worktree-session-lifecycle.md, /memory-and-context/context-cache-and-invalidation.md]
---

# Session Reset and State Preservation

Claude Code's session-reset path is not a blind wipe. It deliberately destroys some foreground-only state, preserves selected background work, regenerates session identity, and then relinks surviving artifacts so future resume and inspection still work.

## Reset envelope

Equivalent behavior should wrap reset in lifecycle hooks:

1. run bounded session-end hooks for the current session
2. clear the visible transcript
3. reset caches and transient runtime state
4. regenerate session identity
5. relink preserved task artifacts to the new session context
6. re-persist mode or worktree state that should describe the new post-reset session
7. run session-start hooks for the fresh session

This keeps reset observable and recoverable instead of behaving like process death.

## Preservation predicate

Reset uses a negative preservation rule, not a positive allowlist.

A faithful rebuild should preserve any task that is explicitly safe to survive reset, while killing only tasks that are still foreground-only. In practice this means:

- backgrounded local-agent work survives
- backgrounded main-conversation work survives
- foreground-only shell or agent work is aborted and removed
- preserved agent identities are collected before cache eviction so their per-agent state can survive the wipe

The preservation decision must be made before task cleanup starts.

## What gets cleared

Equivalent reset should clear at least these classes of state:

- visible conversation messages
- cwd-sensitive file-state caches
- discovered skill or nested-memory bookkeeping tied to the old session
- file-history snapshots and transient attribution state
- session-scoped metadata such as custom title, tag, and standalone identity badge
- plan-slug and similar per-session coordination helpers
- transient MCP runtime connections and registries that should be rebuilt

The important contract is that reset returns the foreground session to a clean conversational baseline.

## Identity regeneration and artifact relinking

Reset must create a new session identity without orphaning preserved background work.

Equivalent behavior should preserve:

- generation of a fresh session ID, with lineage back to the prior one for analytics or continuity features
- reset of the main transcript pointer to the new session artifact location
- relinking of preserved running task-output handles so continued writes land in the live post-reset location rather than a frozen pre-reset snapshot
- continued readability of old persisted task transcripts even after live writers are evicted

Without relinking, preserved background work appears to survive reset while actually writing into dead files.

## Mode and worktree continuity

Reset clears session metadata caches, but it does not necessarily change the process's execution envelope.

Equivalent behavior should therefore re-persist:

- the current interaction mode when that mode influences later resume behavior
- the current worktree state when the session is still operating inside an alternate worktree
- the already-chosen worktree posture rather than normalizing it, because startup `--worktree` and mid-session `EnterWorktree` do not grant the stable project root to the worktree in the same way

This is how later resume can understand the fresh post-reset session correctly.

## Failure modes

- **over-clearing**: safe background tasks are killed during reset
- **under-clearing**: old transcript metadata, file history, or MCP runtime state bleeds into the fresh session
- **dangling output**: preserved tasks keep writing to pre-reset transcript paths
- **resume drift**: the regenerated session loses mode or worktree context that future resume depends on
