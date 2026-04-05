---
title: "Session Discovery and Lite Indexing"
owners: []
soft_links: [/runtime-orchestration/resume-path.md, /runtime-orchestration/session-artifacts-and-sharing.md, /product-surface/session-utility-commands.md, /integrations/clients/structured-io-and-headless-session-loop.md, /collaboration-and-agents/peer-addressing-discovery-and-routing.md]
---

# Session Discovery and Lite Indexing

Resume and SDK session listing do not begin by loading every full transcript. Claude Code uses a lightweight discovery layer that resolves project scope, extracts only cheap summary metadata, filters out subordinate transcripts, and upgrades to full state only after a concrete session has been chosen.

This leaf is about resumable transcript discovery, not live peer discovery for cross-session messaging. Current reachability, direct local ingress, and Remote Control peer aliases are published through a separate live-session registry captured in [peer-addressing-discovery-and-routing.md](../collaboration-and-agents/peer-addressing-discovery-and-routing.md).

## Discovery scope and project resolution

Equivalent behavior should preserve:

- canonicalizing a requested directory before lookup so symlinked paths and Unicode-normalization differences still resolve to one logical project bucket
- mapping project directories into cross-platform-safe storage paths, with truncation plus a hash suffix for very long paths
- tolerating hash-strategy mismatches for long paths by falling back from exact directory lookup to prefix-based discovery instead of acting like the project has no sessions
- dir-scoped listing being able to include sibling git worktrees while still remembering which real checkout each candidate belongs to
- whole-installation listing scanning every project bucket when no directory is specified

This scope logic matters because session identity is repo-aware, but the storage layer still has to survive different runtimes, path lengths, and worktree layouts.

## Cheap metadata extraction instead of full transcript reads

Equivalent behavior should preserve:

- a light-read path that opens one JSONL file, stats it, and reads only bounded head and tail windows
- extracting summary metadata from those windows rather than parsing the entire transcript
- filtering subordinate or non-resumable records early, especially sidechain-style transcripts and metadata-only files with no user-facing summary
- user-authored titles winning over generated titles, with recent prompt summaries and first meaningful prompts filling the fallback chain
- first-prompt extraction skipping synthetic metadata, compact summaries, tool results, and slash-command wrappers so discovery reflects what the user was actually trying to do
- bash-style first prompts being summarized as shell intent rather than raw XML-like payload wrappers
- creation time coming from transcript timestamps when possible instead of relying on filesystem birth-time behavior

The clean-room point is that discovery metadata is intentionally lossy but still semantically curated.

## Pagination and sorting strategy

Equivalent behavior should preserve:

- two execution modes: read-all-then-sort when no pagination is requested, and stat-first selection when `limit` or `offset` is present
- paginated listing sorting cheap candidates by most-recent modification before doing expensive metadata reads
- reading only enough sorted candidates to produce the requested visible page after filtering
- deduplicating after full metadata filtering rather than before it, so a newer unreadable or non-visible copy does not hide an older valid session
- stable ordering by descending modification time with a deterministic secondary key for ties

Without this split, either pagination becomes too expensive or correctness regresses when filters remove candidates after sorting.

## Resume and SDK upgrade path

Equivalent behavior should preserve:

- direct session-ID lookup resolving one concrete file before any transcript load, first in the requested project, then in sibling worktrees, then across all projects when needed
- zero-byte or truncated session files being treated as missing so lookup can continue to another viable copy
- discovery surfaces upgrading only the chosen session from lite metadata into the full transcript and snapshot chain
- the portable lookup and metadata rules being shared across interactive resume and automation-facing session APIs, even when individual surfaces apply different placeholder labels or visibility filters afterward
- current-session exclusion, cross-project guarding, and explicit disambiguation living above the discovery layer rather than being baked into raw storage traversal

This separation is load-bearing: the same session store supports fast browsing, exact lookup, and full resume, but those consumers should not all pay the cost of full transcript loading.

## Failure modes

- **hash blind spot**: long-path projects disappear because discovery assumes every runtime hashed the storage directory name identically
- **sidechain leak**: subordinate worker transcripts show up as first-class resumable sessions
- **pagination starvation**: a paginated reader stops after `limit` raw files instead of `limit` visible sessions, producing sparse or empty pages
- **title precedence drift**: generated titles overwrite explicit user titles in discovery surfaces
- **cross-worktree confusion**: the runtime finds a session file but loses which checkout it belongs to, so resume retargets the wrong repo
