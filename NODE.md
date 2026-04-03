---
title: "Claude Code Context"
owners: [bingran-you]
---

# Claude Code Context

The living source of truth for a clean-room reconstruction of Claude Code.

This tree was derived from analysis of a local source snapshot, but it intentionally records only the decision-critical abstractions needed to rebuild an equivalent product: user journeys, subsystem boundaries, interaction contracts, operating constraints, and cross-domain relationships.

The tree must remain a reconstruction spec, not a source mirror. If a detail is only useful for execution in the original codebase, or if reproducing it would amount to copying proprietary expression, it does not belong here.

---

## Domains

- **[reconstruction-guardrails/](reconstruction-guardrails/NODE.md)** — Copyright-safe extraction rules, scope, provenance, and rebuild standards.
- **[product-surface/](product-surface/NODE.md)** — User-facing operating modes, command families, and top-level product shape.
- **[runtime-orchestration/](runtime-orchestration/NODE.md)** — Main loop, task model, feature gating, and session orchestration.
- **[tools-and-permissions/](tools-and-permissions/NODE.md)** — Tool contracts, sandboxing, permissions, and delegation modes.
- **[memory-and-context/](memory-and-context/NODE.md)** — Context injection, memory layers, compaction, and durable consolidation.
- **[collaboration-and-agents/](collaboration-and-agents/NODE.md)** — Multi-agent coordination, remote execution, bridge flows, and teamwork primitives.
- **[integrations/](integrations/NODE.md)** — MCP, plugins, skills, and surface-specific client integrations.
- **[platform-services/](platform-services/NODE.md)** — Auth, configuration, policy, usage, telemetry, updates, and migrations.
- **[ui-and-experience/](ui-and-experience/NODE.md)** — Terminal UI composition, feedback patterns, and interaction ergonomics.
- **[members/](members/NODE.md)** — Team member definitions and responsibilities.

---

## Working with the Tree

See [AGENT.md](AGENT.md) for agent instructions — the before/during/after workflow, ownership model, and tree maintenance.

See [about.md](about.md) for background — the mission of this repo and the clean-room boundary it enforces.

See the framework documentation in `.context-tree/`:
- [principles.md](.context-tree/principles.md) — core principles with examples
- [ownership-and-naming.md](.context-tree/ownership-and-naming.md) — node naming and ownership model
