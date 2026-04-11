---
title: "Client Surfaces"
owners: []
soft_links: [/runtime-orchestration/turn-flow/query-loop.md, /ui-and-experience/feedback-and-notifications/interaction-feedback.md]
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

## Test Design

In the observed source, client-integration behavior is verified through adapter regressions, transport-aware integration tests, and public-surface end-to-end flows.

Equivalent coverage should prove:

- message shaping, history or state projection, and surface-specific envelope rules stay stable across the client contracts described here
- auth proxying, environment selection, reconnect, and remote-session coordination behave correctly at the real process or transport boundary
- packaged client entrypoints still expose the same visible behavior as direct source invocation, especially for structured I/O and remote viewers
