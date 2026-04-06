---
title: "Durable Memory Recall and Auto-Memory"
owners: []
soft_links: [/memory-and-context/memory-layers.md, /memory-and-context/instruction-sources-and-precedence.md, /memory-and-context/relevant-memory-selection-and-session-memory-upkeep.md, /tools-and-permissions/tool-catalog/agent-definition-loading-and-precedence.md, /platform-services/sync-and-managed-state.md]
---

# Durable Memory Recall and Auto-Memory

Claude Code has a durable, file-based memory family that is separate from both checked-in instruction files and session-scoped summaries. Reconstructing it requires the storage roots, the write styles, and the selective recall path that decides which memories become turn context.

## Scope boundary

This leaf covers:

- repo-scoped durable memory roots and trusted path overrides
- index/topic-file versus daily-log durable write styles
- specialist agent memory roots and snapshot seeding behavior
- the way durable memory is surfaced back into turns

It does not re-document:

- detailed selector thresholds and upkeep timing already covered in [relevant-memory-selection-and-session-memory-upkeep.md](relevant-memory-selection-and-session-memory-upkeep.md)
- team-memory sync conflict and secret-safety internals
- session-memory mechanics, which remain a separate current-session layer

## Persistent roots and path resolution

Equivalent behavior should preserve a repo-scoped durable memory root with these properties:

- one canonical memory root per repository, shared across worktrees of the same repo via stable repo identity rather than per-worktree cwd
- an ordered resolution model where an explicit trusted full-path override wins over trusted user/local/policy settings, and only then does the runtime fall back to a default repo-scoped location under the user's memory base
- checked-in project settings not being allowed to redirect the durable-memory root, because that would grant arbitrary write reach to a repository-controlled file
- a stable entrypoint index file named `MEMORY.md`
- additional topic files under the same directory
- optional team-memory substructure layered under the durable memory root rather than bolted on as a separate unrelated system

The important contract is that this memory survives across conversations and worktrees.

## Write styles

Durable memory does not have one write pattern.

Equivalent behavior should preserve both of these styles:

- an index-plus-topic-file model where `MEMORY.md` acts as a concise pointer file into richer topic documents
- a long-lived assistant-mode daily-log path where new memories append to date-based log files and a later consolidation process distills them back into the durable index and topic files

This distinction matters because the assistant may accumulate memory continuously without rewriting the durable index on every turn.

## Agent-scoped persistent memory is parallel, not decorative

Equivalent behavior should preserve that specialized agents can own dedicated durable-memory roots separate from the general repo memory.

- agent memory should support at least user, project, and local scopes
- those scopes should change both where memory is stored and what kind of knowledge belongs there
- `@`-mentioning a specialist should narrow relevant-memory search to that agent's memory root instead of mixing general repo memory back in
- user-scoped agent memory can initialize from a project-provided snapshot when empty
- once local user memory exists, newer project snapshots should surface as an explicit update decision rather than silently replacing the current contents

This matters because specialist memory is part of agent behavior, not just a cosmetic folder path.

## Recall selection

Relevant durable memory is selected, not dumped wholesale.

Equivalent behavior should preserve:

- header-based scanning across available durable memory files
- exclusion of the entrypoint index from relevance ranking because it is already handled separately
- a small capped selection budget
- filtering of already-surfaced files before ranking so the budget is spent on fresh recall
- threading of file freshness metadata through the recall path
- suppression of tool-reference memories when the agent is already actively using that tool, while still allowing warnings or gotchas about the same tool

The key design choice is selectivity: durable memory is valuable because it stays sparse at turn time.

## Injection shape

Selected memories should enter the conversation as explicit recall attachments, not as silent prompt concatenation.

Equivalent behavior should preserve:

- path and freshness metadata alongside recalled content
- truncation notes instead of silently dropping oversized files
- reset of surfaced-memory dedup after compaction, because old recall attachments are no longer present in the compacted transcript
- agent-specific memory isolation when the user explicitly addresses a specialized agent and its own memory directory should be searched instead of the general durable memory root

## Failure modes

- **redirected-root escape**: repo-controlled configuration can point durable memory at arbitrary user paths
- **worktree fragmentation**: the same repository accumulates separate durable memories per worktree
- **index overload**: the entrypoint grows into a full memory dump instead of a compact recall index
- **recall repetition**: the selector keeps resurfacing the same files within one transcript window
- **tool-doc noise**: relevance ranking keeps surfacing reference docs for tools the agent is already actively using
- **snapshot clobber**: project-seeded specialist memory silently overwrites user-owned agent memory instead of becoming an initialize-or-update choice
