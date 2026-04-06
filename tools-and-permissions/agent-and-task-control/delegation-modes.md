---
title: "Delegation Modes"
owners: []
soft_links: [/collaboration-and-agents/multi-agent-topology.md, /runtime-orchestration/tasks/task-model.md]
---

# Delegation Modes

Claude Code distinguishes between doing work directly and setting up safer execution contexts for work.

Important modes:

- Plan mode emphasizes analysis, scoping, and user alignment before edits.
- Worktree mode creates isolation for changes that should not share a mutable checkout.
- Delegated agent work runs through explicit worker or team constructs with narrower tool availability and different prompt expectations.

These modes are not separate products. They are overlays on the same runtime and should preserve the same message, tool, and permission semantics.
