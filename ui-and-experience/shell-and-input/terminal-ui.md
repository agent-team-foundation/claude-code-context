---
title: "Terminal UI"
owners: []
soft_links: [/product-surface/interaction-modes.md, /ui-and-experience/shell-and-input/terminal-runtime-and-fullscreen-interaction.md, /ui-and-experience/feedback-and-notifications/status-line-and-footer-notification-stack.md, /collaboration-and-agents/multi-agent-topology.md]
---

# Terminal UI

Claude Code uses a rich terminal UI rather than a bare prompt and plain text dump.

The UI layer should provide:

- prompt input, queued command composition, and conversation rendering
- dialogs, onboarding flows, and alternate-screen or fullscreen surfaces when the interaction needs denser layout
- status lines, footer notifications, progress indicators, and agent activity displays
- diff and file-change visualization
- settings, help, and trust or security prompts
- background-task, teammate, and remote-session views that can coexist with the main transcript
- reusable component primitives that keep the interface consistent across commands and tools

The key requirement is composability. New commands and tools should be able to reuse the same rendering primitives for progress, approval, and result display, while the terminal runtime layer handles capability negotiation and redraw mechanics underneath.

## Test Design

In the observed source, shell-and-input behavior is verified through deterministic key-sequence regressions, store-backed integration coverage, and interactive terminal end-to-end checks.

Equivalent coverage should prove:

- input reducers, keybinding resolution, history state, and prompt composition preserve the invariants documented above
- queue, history, suggestion, and terminal-runtime coupling behave correctly with real stores, temp files, and reset hooks between cases
- multiline entry, fullscreen behavior, pickers, and suggestion surfaces work through the packaged interactive shell instead of only through isolated render helpers
