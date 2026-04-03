---
title: "Context Bootstrap"
owners: []
soft_links: [/integrations/clients/client-surfaces.md, /reconstruction-guardrails/source-boundary.md]
---

# Context Bootstrap

Before the model sees a user turn, the runtime assembles both system context and user context.

Important context sources include:

- repository identity and git state
- current date and time anchors
- session-start hooks and injected tree context
- discovered project memory files such as `CLAUDE.md`-style instructions
- settings, policy, and model capability context needed to interpret the session correctly

The bootstrap layer should cache stable context within a session, but it must also expose explicit invalidation paths when settings, injected instructions, or working directories change.
