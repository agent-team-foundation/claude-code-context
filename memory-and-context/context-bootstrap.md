---
title: "Context Bootstrap"
owners: []
soft_links: [/memory-and-context/instruction-sources-and-precedence.md, /memory-and-context/durable-memory-recall-and-auto-memory.md, /memory-and-context/relevant-memory-selection-and-session-memory-upkeep.md, /memory-and-context/session-memory.md, /integrations/clients/client-surfaces.md, /platform-services/interactive-startup-and-project-activation.md, /reconstruction-guardrails/source-boundary.md]
---

# Context Bootstrap

Claude Code does not build turn context from one raw prompt template. It assembles a cached bootstrap envelope whose exact contents vary by session mode, trust state, and client surface.

## Scope boundary

This leaf covers:

- the session-stable system and user context assembled before ordinary turns
- mode-specific narrowing for bare, simple, headless, and client-owned prompt flows
- how baseline instruction discovery, memory entrypoints, and stable repo facts enter bootstrap
- invalidation boundaries for cached bootstrap context

It does not re-document:

- detailed instruction precedence already covered in [instruction-sources-and-precedence.md](instruction-sources-and-precedence.md)
- durable-memory ranking and session-memory upkeep already covered in [relevant-memory-selection-and-session-memory-upkeep.md](relevant-memory-selection-and-session-memory-upkeep.md)
- full startup sequencing already covered in [../platform-services/interactive-startup-and-project-activation.md](../platform-services/interactive-startup-and-project-activation.md)
- per-turn nested file-targeted memory attachments

## Two cached context bands

Equivalent behavior should preserve two separately memoized bootstrap bands rather than one undifferentiated prefix blob.

- **system context** carries stable repo/runtime facts such as the startup git snapshot when enabled, plus any session-wide cache-break or debugging injection that should persist until explicitly cleared
- **user context** carries baseline instruction-bearing memory plus a current-date anchor
- these two bands should invalidate independently; changing one should not force full recomputation of the other unless the underlying discovery inputs overlap

One important invariant is that repo-status context is a point-in-time startup snapshot, not a live feed that silently refreshes during the conversation.

## Automatic instruction discovery is mode-sensitive

Equivalent behavior should preserve that not every surface gets the same eager memory discovery.

- ordinary interactive sessions eagerly discover managed, user, project, and local instruction layers plus durable-memory entrypoints that belong in baseline context
- bare/simple sessions suppress automatic cwd-upward instruction discovery and background memory extras, because those modes are meant to skip unrequested ambient context
- explicitly added instruction roots can still be honored in bare/simple-style sessions when the caller deliberately supplies them, because "minimal" means "do not auto-discover," not "discard requested context"
- client surfaces that replace the default system prompt should not silently retain persistent-memory mechanics unless they explicitly opt back into that contract

## Baseline memory entrypoints and working-note layers stay distinct

Equivalent behavior should preserve that several memory-bearing surfaces enter context in different ways.

- baseline instruction files and durable-memory entrypoints are part of the eager bootstrap envelope
- session memory is a separate working-note layer that can be injected or summarized without changing baseline instruction precedence
- selectively recalled durable memories are later turn attachments, not part of the unconditional bootstrap prefix
- team memory may travel through the same discovery machinery as other memory files, but it remains a typed shared-memory surface rather than just another project instruction file

## Stable project identity matters

Equivalent behavior should preserve that bootstrap discovery keys off the stable project identity, not only the current transient execution directory.

- worktrees of the same repository should share the same repo-scoped durable-memory root
- startup-time worktree switches that redefine the session's project root must invalidate cached context and rediscover instruction-bearing files from the new authority
- mid-session navigation helpers that temporarily change execution location should not silently rebase the whole bootstrap identity unless they intentionally become the new project root

## Invalidation boundaries

Equivalent behavior should preserve explicit cache clears when:

- the effective project root or original working directory changes
- baseline instruction files or includes are edited or resynchronized
- additional instruction directories are changed
- session-wide system-prompt injection changes
- compaction or reset paths replace the message window in ways that require fresh memory/context bookkeeping

## Failure modes

- **ambient-context leak**: bare/simple sessions still auto-load cwd instructions or durable-memory entrypoints the caller never asked for
- **explicit-context loss**: an explicitly added instruction directory is dropped just because automatic discovery is disabled
- **bootstrap flattening**: system context, user context, session memory, and later relevant-memory attachments collapse into one uncached blob
- **project-identity drift**: worktree or startup cwd changes leave bootstrap reading instructions from the wrong root
- **stale snapshot illusion**: startup git/runtime facts silently refresh mid-session and stop matching what the model originally saw

## Test Design

In the observed source, memory and context behavior is verified through deterministic transformation regressions, persistence-aware integration tests, and continuity-focused conversation scenarios.

Equivalent coverage should prove:

- selection, compaction, extraction, and invalidation rules preserve the invariants and bounded-resource behavior documented above
- cache state, memory layers, session persistence, and rehydration paths compose correctly across resume, compact, and recovery flows
- visible context continuity still matches the product contract when deterministic fixtures or replay replace live upstream variability
