---
title: "Session Utility Commands"
owners: []
soft_links: [/runtime-orchestration/resume-path.md, /runtime-orchestration/session-artifacts-and-sharing.md, /memory-and-context/session-memory.md]
---

# Session Utility Commands

Claude Code exposes a cluster of commands that do not primarily advance code execution. They inspect, rename, tag, export, or lightly recover session state. These commands matter for reconstruction because they reveal which session artifacts are first-class to the product.

## Metadata commands

Equivalent behavior should preserve a set of commands that act on current-session metadata rather than on project files:

- renaming the current session title
- tagging the current session for later discovery
- showing session-connection information for remote mode

Important contracts:

- rename is blocked for subordinate swarm members whose identity is owned by the team leader
- renaming updates both durable session metadata and the current session badge shown in the UI
- retagging with the same value behaves like an explicit remove path rather than a duplicate add
- tag input is sanitized before persistence
- remote-session inspection is read-only and still useful even when optional decoration such as QR rendering fails

## Recovery and discovery helpers

Resume is its own deeper runtime path, but the user-facing session utility surface still sets important expectations:

- the current live session is excluded from ordinary resume pickers
- subordinate sidechain transcripts are not treated as top-level resumable sessions
- cross-project resume is explicit rather than silently retargeting the current process
- exact identifiers and exact title matches can bypass the picker when unambiguous

This is part of the product surface, not just storage internals.

## Copy and export surfaces

Equivalent behavior should treat transcript extraction as a deliberate UX surface rather than "just open the transcript file."

Important requirements:

- copy works over recent assistant-visible text rather than arbitrary raw transcript blocks
- tool-only turns and API-error turns are skipped when assembling copy candidates
- when a response contains code blocks, the user can choose whole-response versus one-block extraction
- clipboard copy is best-effort and paired with a file fallback
- export renders the conversation into plain text before writing, instead of dumping raw structured transcript artifacts
- default export filenames derive from the first user prompt when possible and fall back to timestamped generic names otherwise

## Failure modes

- **identity confusion**: rename updates one session artifact but not the in-session badge or remote mirror
- **tag duplication**: repeated tagging creates duplicates instead of toggling or replacing
- **raw-transcript leakage**: export or copy surfaces expose internal transcript structure instead of user-facing content
- **cross-project surprise**: resume silently jumps into an unrelated repository
