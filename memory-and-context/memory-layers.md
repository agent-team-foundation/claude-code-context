---
title: "Memory Layers"
owners: []
soft_links: [/memory-and-context/instruction-sources-and-precedence.md, /memory-and-context/durable-memory-recall-and-auto-memory.md, /memory-and-context/relevant-memory-selection-and-session-memory-upkeep.md, /memory-and-context/session-memory.md, /memory-and-context/compaction-and-dream.md, /platform-services/sync-and-managed-state.md, /tools-and-permissions/agent-definition-loading-and-precedence.md]
---

# Memory Layers

Claude Code does not have one memory system. It has several layers with different scope, loading time, and persistence rules. A faithful rebuild needs those layers to stay distinct so the model sees the right information at the right time.

## Layer families

- baseline instruction layers and path-conditioned rules discovered from managed, user, project, and local sources
- the live transcript plus tool results for the current conversation window
- session memory, which is a rolling working note for one session
- compaction summaries or other condensed conversation replacements
- repo-scoped durable memory, which survives across sessions and is recalled selectively
- shared team memory, which rides alongside durable memory but has collaboration-specific sync and safety rules
- agent-scoped persistent memory roots for specialists that should search or update a narrower memory surface than the general repo memory

## Scope and roots are load-bearing

Equivalent behavior should preserve that these layers do not all live in the same filesystem namespace.

- repo-scoped durable memory should key off stable project identity so worktrees of one repository share the same memory root
- team memory should live under that same durable-memory root while still remaining a distinct synchronized surface
- agent-scoped memory should support separate user, project, and local roots rather than one hard-coded location
- local agent memory may live on a remote/session-specific mount while still preserving project scoping
- user-scoped agent memory can be initialized from a project snapshot and later carry a pending-update marker without ceasing to be user-owned memory
- session memory should stay in isolated session storage rather than inside normal project files

## Loading model differs by layer

Equivalent behavior should preserve different loading times and budgets for each layer.

- baseline instruction layers and durable-memory entrypoints are eager bootstrap context
- selectively recalled durable memories are late turn attachments chosen from headers, not unconditional prompt baggage
- session memory is maintained in the background and reused only when thresholds and safe boundaries permit
- compaction summaries replace old transcript context, but they do not rewrite durable-memory files or instruction precedence
- team memory and agent-specific memory can narrow recall/injection scope without becoming new global defaults for every turn

## Mode and client gating

Equivalent behavior should preserve:

- bare/simple sessions suppressing automatic instruction discovery and background memory upkeep
- explicitly supplied instruction roots or custom memory directories still being able to participate when the caller opts in
- client surfaces that replace the default system prompt having to opt back into memory mechanics explicitly if they still want persistent-memory behavior

## Failure modes

- **flat-history rebuild**: session memory, durable memory, and compaction all collapse into one transcript-summary mechanism
- **scope bleed**: team or specialist agent memory is injected into ordinary turns as if it were global repo guidance
- **worktree divergence**: two worktrees of the same repo accumulate separate repo-scoped durable memories
- **snapshot clobber**: project-provided agent-memory snapshots silently overwrite user-owned memory instead of becoming an explicit initialization or update flow
- **mode leak**: bare/simple sessions keep auto-loading ambient memory surfaces that those modes were meant to suppress
