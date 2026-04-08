---
title: "Dialogs and Approvals"
owners: []
---

# Dialogs and Approvals

This subdomain captures focused overlays that collect structured input, approvals, or mode-specific decisions before the runtime continues.

Relevant leaves:

- **[ask-user-question-and-plan-interview-ui.md](ask-user-question-and-plan-interview-ui.md)** — How ask-user prompts paginate questions, render previews, collect notes/attachments, and expose plan-interview-specific footer actions.
- **[focused-dialog-and-overlay-arbitration.md](focused-dialog-and-overlay-arbitration.md)** — How blocking dialogs, prompt-owned overlays, typing suppression, and low-priority callouts arbitrate for focus.
- **[permission-prompt-shell-and-worker-states.md](permission-prompt-shell-and-worker-states.md)** — How queued approval prompts, shared permission dialog chrome, feedback-entry controls, and worker waiting cards behave.
- **[plan-mode-approval-surfaces.md](plan-mode-approval-surfaces.md)** — How enter-plan and exit-plan approvals present plans, collect feedback, choose execution modes, and hand plan acceptance back into the session loop.
- **[conversation-export-dialog.md](conversation-export-dialog.md)** — How `/export` chooses clipboard versus file delivery, handles filename editing/back-navigation, and keeps export feedback aligned.
- **[diff-dialog-and-turn-history-navigation.md](diff-dialog-and-turn-history-navigation.md)** — How `/diff` opens a modal overlay, combines working-tree changes with per-turn edit history, paginates file lists, and branches detail rendering.
- **[structured-diff-rendering-and-highlight-fallback.md](structured-diff-rendering-and-highlight-fallback.md)** — How diff hunks choose syntax-aware versus fallback rendering, preserve conservative word-diff behavior, and split fullscreen gutters for clean selection.
