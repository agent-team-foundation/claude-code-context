---
title: "Source Boundary"
owners: []
soft_links: [/memory-and-context/context-bootstrap.md, /runtime-orchestration/build-profiles.md]
---

# Source Boundary

This tree may be informed by source analysis, but it may not become a derivative source archive.

Allowed forms of knowledge:

- capability descriptions
- subsystem boundaries
- state machines and lifecycle descriptions
- failure modes, invariants, and safety constraints
- user-visible command and tool surfaces
- implementation-neutral architecture notes

Disallowed forms of knowledge:

- source files or source snippets
- prompt bodies or long proprietary strings
- copied comments or unique prose from the analyzed code
- secrets, tokens, credentials, or internal service endpoints
- internal codenames and other identifiers that are not necessary to describe public behavior
- low-level execution detail whose only use is to reproduce the original implementation line by line

When a fact can be expressed either as source-shaped detail or as behavior, prefer behavior.
