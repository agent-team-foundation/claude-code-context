---
title: "Client Surfaces"
owners: []
soft_links: [/runtime-orchestration/query-loop.md, /ui-and-experience/interaction-feedback.md]
---

# Client Surfaces

Equivalent implementations should expect one shared runtime to appear through several wrappers:

- interactive CLI
- structured SDK or automation entrypoints
- IDE-connected flows
- desktop or mobile companion surfaces
- browser-mediated approval or review surfaces
- voice or other specialized input modes

The transport and rendering may vary by surface, but the following must stay aligned:

- tool semantics
- task visibility
- session identity and resume behavior
- permission and trust decisions
- user-understandable feedback for progress, errors, and approvals
