---
title: "Terminal UI"
owners: []
soft_links: [/product-surface/interaction-modes.md, /collaboration-and-agents/multi-agent-topology.md]
---

# Terminal UI

Claude Code uses a rich terminal UI rather than a bare prompt and plain text dump.

The UI layer should provide:

- prompt input and conversation rendering
- dialogs and onboarding flows
- status lines, progress indicators, and agent activity displays
- diff and file-change visualization
- settings, help, and trust or security prompts
- reusable component primitives that keep the interface consistent across commands and tools

The key requirement is composability. New commands and tools should be able to reuse the same rendering primitives for progress, approval, and result display.
