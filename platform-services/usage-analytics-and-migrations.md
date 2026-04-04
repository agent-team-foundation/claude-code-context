---
title: "Usage, Analytics, and Migrations"
owners: []
soft_links: [/product-surface/interaction-modes.md, /runtime-orchestration/build-profiles.md]
---

# Usage, Analytics, and Migrations

The product includes substantial non-core support systems that still shape architecture.

Expected responsibilities:

- bootstrap and entitlement prefetch at startup
- usage tracking, rate or quota awareness, and plan-specific behaviors
- the dedicated Claude.ai subscriber limit-state contract documented in [claude-ai-limits-and-extra-usage-state.md](claude-ai-limits-and-extra-usage-state.md)
- analytics and diagnostic pipelines with opt-out and sink controls
- release notes and update flows
- local migrations that evolve stored settings and defaults over time

These services must be non-blocking where possible. Startup work should be parallelized or prefetched so the interactive product stays responsive.
