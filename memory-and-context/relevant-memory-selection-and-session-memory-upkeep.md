---
title: "Relevant Memory Selection and Session Memory Upkeep"
owners: []
soft_links: [/memory-and-context/durable-memory-recall-and-auto-memory.md, /memory-and-context/session-memory.md, /memory-and-context/compact-path.md, /memory-and-context/context-lifecycle-and-failure-modes.md]
---

# Relevant Memory Selection and Session Memory Upkeep

Durable recall and session memory are separate layers, but the runtime treats both as selective, low-latency maintenance systems that must stay isolated from the foreground conversation loop and must survive compaction correctly. A faithful rebuild needs the exact selector and upkeep contracts, not just the fact that these features exist.

## Scope boundary

This leaf covers:

- turn-time relevant-memory prefetch, ranking inputs, dedup, surfacing limits, and agent-memory scoping
- background session-memory maintenance, thresholds, file setup, and updater isolation
- the boundary state shared with compaction

It intentionally does not re-document:

- the durable memory storage layout already covered in [durable-memory-recall-and-auto-memory.md](durable-memory-recall-and-auto-memory.md)
- the general role of session memory already covered in [session-memory.md](session-memory.md)
- full compaction summary generation already covered in [compact-path.md](compact-path.md)

## Relevant-memory prefetch gate

Equivalent behavior should preserve:

- relevant-memory recall starting once per real user turn, not once per loop iteration, so the same prompt is not re-ranked repeatedly
- the selector running only when auto-memory is enabled, the relevant-memory gate is on, a last real user message exists, and that message has enough lexical context to rank against; single-word prompts are skipped
- prefetch staying non-blocking: the turn loop consumes the result only if it has already settled, otherwise it skips with zero wait and retries later in the same turn
- a cumulative per-session recall budget of about 60 KB based on bytes already surfaced in prior relevant-memory attachments; once exhausted, no new prefetch runs until compaction removes those attachments from the live transcript

## Selector inputs, scoping, and ranking

Equivalent behavior should preserve:

- default search against the auto-memory directory, but if the user explicitly `@`-mentions specialized agents, search narrowing to only those agents' memory directories rather than mixing them with general durable memory
- candidate discovery by scanning markdown memory files except the durable entrypoint, reading only the opening metadata, sorting newest-first, and capping the candidate pool to the newest roughly 200 files
- filtering already-surfaced paths before ranking so the selector spends its limited budget on fresh files instead of returning files the caller will discard anyway
- ranking based on the raw user query plus recently successful tools from the current turn window, with instructions to suppress tool usage references or API docs for tools that are already working while still allowing warnings, gotchas, or known issues for those same tools
- recent-tool suppression depending on successful tool use only; tools that errored or have not resolved yet stay eligible because reference material may still be needed
- a hard post-rank cap of five surfaced memories total, even when multiple memory directories contribute candidates
- filename validation against the scanned manifest so the ranking step cannot invent nonexistent files

## Surfacing and dedup contract

Equivalent behavior should preserve:

- a second dedup pass after ranking that filters against both cumulative file-read state and already-surfaced paths, because multi-directory results and later tool reads can reintroduce duplicates after the selector runs
- reading selected files with both line and byte caps, roughly 200 lines and 4 KB per file, and adding an explicit truncation note instead of dropping an otherwise relevant file entirely
- surfacing freshness metadata and absolute-path identity alongside the memory content so the model sees both what the memory says and how stale it is
- marking surfaced memories in file-read state only after duplicate filtering, so the prefetch does not suppress itself by writing its own candidates into the dedup cache too early
- dedup reset after compaction coming from transcript reality rather than from a separate persistent ledger: once old relevant-memory attachments disappear from the compacted transcript, those files become eligible to surface again

## Session-memory upkeep gate and thresholds

Equivalent behavior should preserve:

- session-memory upkeep being a local maintenance hook, disabled in remote mode and not even registered unless automatic compaction is enabled
- the feature gate and numeric config loading lazily and non-blockingly from cached experimentation values when the hook runs, using defaults whenever remote values are unset or non-positive
- default upkeep thresholds of about 10,000 total context tokens to initialize, 5,000 tokens of context growth between rewrites, and three tool calls between rewrite opportunities
- upkeep running only on the main REPL thread, not in subagents, teammate flows, or other forked query sources
- initialization waiting until the total live-context token estimate crosses the threshold, using the same token-counting basis as auto-compact rather than cumulative API spend
- subsequent updates always requiring token growth since the last extraction; tool-call volume alone is never enough to force another rewrite
- automatic extraction firing when the token-growth threshold is met and either enough tool calls have accumulated or the latest assistant turn contains no tool calls, so rewrites happen at both tool-heavy milestones and natural conversational pauses
- the update path being serialized so overlapping extractions do not race each other

## Session-memory file setup and updater isolation

Equivalent behavior should preserve:

- one session-memory artifact per session under session-scoped internal storage rather than inside normal project files
- secure filesystem setup with an owner-only directory and owner-only file, created lazily when upkeep first needs the artifact
- a stable session-memory path ending in `session-memory/summary.md`
- seeding a newly created file from a fixed template while allowing per-user prompt and template overrides from the Claude config home
- reading the file through normal read tooling after clearing cached read state, so the updater sees actual current content rather than a deduplicated "unchanged" stub
- building the updater as a forked isolated agent context and constraining that helper to edit exactly the session-memory file, with all other tool use denied
- an update prompt that preserves a fixed section structure, prioritizes current state, and reminds the updater to keep each section within a bounded size and the whole note within a bounded total budget so later compaction can still use it
- manual extraction using the same isolated edit-only path but bypassing the automatic threshold checks

## Boundary tracking and compaction coupling

Equivalent behavior should preserve:

- a distinction between the extraction-frequency boundary and the compaction-safe summary boundary
- tool-call counting for future upkeep windows advancing when an extraction fires, even if the newest assistant turn is not yet safe to treat as a compaction cutoff
- the compaction-safe boundary advancing only when the latest assistant turn has no tool calls, preventing later compaction from keeping tool results whose matching tool uses were already summarized away
- session-memory compaction waiting briefly for any in-flight extraction to finish, then falling back to legacy compaction when no session-memory file exists, the file is still just the template, or the recorded summary boundary no longer exists in the current transcript
- successful compaction resetting the saved summary boundary afterward, because the old message UUIDs are no longer valid once the transcript has been pruned and rewritten

## Failure modes

- **selector budget waste**: already-surfaced memories are filtered only after ranking, so fresh candidates never get a slot
- **tool-doc spam**: the selector keeps surfacing reference docs for tools that are already working instead of surfacing only warnings or novel constraints
- **self-dedup starvation**: prefetch marks files as read before post-rank filtering and ends up dropping every selected memory
- **agent-memory bleed**: an `@`-mentioned specialist gets general project memories mixed into its recall set instead of searching its own memory directory in isolation
- **rewrite thrash**: session memory updates on tool-call count alone and rewrites too often during long tool-heavy turns
- **unsafe cutoff**: session memory records a summarized boundary after a tool-using assistant turn and later compaction leaves orphaned tool results
- **file-scope escape**: the upkeep helper can edit arbitrary files instead of only the session-memory artifact
- **stale summary dependency**: compaction trusts a missing or template-only session-memory file and drops transcript context without a valid working summary
