---
title: "Durable Memory Recall and Auto-Memory"
owners: []
soft_links: [/memory-and-context/memory-layers.md, /memory-and-context/instruction-sources-and-precedence.md, /memory-and-context/relevant-memory-selection-and-session-memory-upkeep.md, /platform-services/sync-and-managed-state.md]
---

# Durable Memory Recall and Auto-Memory

Claude Code has a durable, file-based memory system that is separate from both checked-in instruction files and session-scoped summaries. Reconstructing it requires both the storage model and the selective recall path that decides which memories become turn context.

## Storage model

Equivalent behavior should preserve a project-scoped durable memory directory with these properties:

- one canonical memory root per repository, shared across worktrees of the same repo
- optional trusted overrides for the full memory directory path
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

- **worktree fragmentation**: the same repository accumulates separate durable memories per worktree
- **index overload**: the entrypoint grows into a full memory dump instead of a compact recall index
- **recall repetition**: the selector keeps resurfacing the same files within one transcript window
- **tool-doc noise**: relevance ranking keeps surfacing reference docs for tools the agent is already actively using
