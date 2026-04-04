---
title: "Context Bootstrap"
owners: []
soft_links: [/memory-and-context/instruction-sources-and-precedence.md, /memory-and-context/durable-memory-recall-and-auto-memory.md, /memory-and-context/session-memory.md, /integrations/clients/client-surfaces.md, /reconstruction-guardrails/source-boundary.md]
---

# Context Bootstrap

Before the model sees a user turn, the runtime assembles both system context and user context.

Important context sources include:

- repository identity and git state
- current date and time anchors
- session-start hooks and injected tree context
- discovered project memory files such as `CLAUDE.md`-style instructions
- session memory and selectively recalled durable memories
- settings, policy, and model capability context needed to interpret the session correctly

## Bootstrap phases

Equivalent behavior should stage context assembly rather than concatenating one monolithic prompt:

1. gather stable environment and repository facts
2. discover and order baseline instruction-bearing memory
3. attach session memory and a small relevant set of durable-memory recalls
4. inject settings, policy, and model-capability context
5. apply session-start hooks or turn-scoped attachments that depend on the current surface

The bootstrap layer should cache stable context within a session, but it must also expose explicit invalidation paths when settings, injected instructions, recalled memory, or working directories change.
