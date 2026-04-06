---
title: "Tools and Permissions"
owners: []
soft_links: [/runtime-orchestration, /collaboration-and-agents]
---

# Tools and Permissions

This domain captures the tool contract that powers agentic work and the permission system that keeps it safe.

Subdomains:

- **[tool-catalog/](tool-catalog/NODE.md)** — Tool families, pool assembly, deferred discovery, and how agent definitions enter the active catalog.
- **[execution-and-hooks/](execution-and-hooks/NODE.md)** — Tool execution, batching, hook integration, and final tool shaping for a launched worker.
- **[permissions/](permissions/NODE.md)** — Permission posture, rule lifecycle, decision routing, sandbox selection, and admin mutation surfaces.
- **[filesystem-and-shell/](filesystem-and-shell/NODE.md)** — File, notebook, path, and shell execution contracts shared by the core local tool surfaces.
- **[agent-and-task-control/](agent-and-task-control/NODE.md)** — Control-plane tools that mutate runtime state, create work, or launch delegated/remote execution paths.
- **[specialized-tools/](specialized-tools/NODE.md)** — Ask-user, browser/desktop control, and public web-access contracts that stay distinct from the generic tool core.
