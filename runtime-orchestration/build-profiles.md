---
title: "Build Profiles"
owners: []
soft_links: [/integrations/clients/client-surfaces.md, /reconstruction-guardrails/source-boundary.md]
---

# Build Profiles

The codebase is designed around a baseline runtime plus many gated capabilities.

Reconstruction should therefore assume:

- One core product exists across all builds.
- Optional capabilities are enabled by compile-time or runtime gates.
- Internal, experimental, or enterprise features may exist without defining the baseline architecture.
- Capability registration must be modular so advanced features can be added or removed without destabilizing the core loop.

Examples of gated capability classes include advanced multi-agent coordination, persistent assistants, browser automation, scheduled triggers, workflow execution, and specialized internal tools.

Public reconstruction should model the gates and extension seams, not preserve any internal naming or hidden rollout metadata.
