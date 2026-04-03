---
title: "UI and Experience"
owners: []
soft_links: [/product-surface, /tools-and-permissions]
---

# UI and Experience

This domain captures how Claude Code makes a complex agent runtime legible inside a terminal-first interface.

Relevant leaves:

- **[terminal-ui.md](terminal-ui.md)** — Composition of the terminal application and major UI regions.
- **[interaction-feedback.md](interaction-feedback.md)** — How the product communicates progress, risk, and outcomes.
- **[permission-prompt-shell-and-worker-states.md](permission-prompt-shell-and-worker-states.md)** — How queued approval prompts, shared permission dialog chrome, feedback-entry controls, and worker waiting cards behave.
- **[system-feedback-lines.md](system-feedback-lines.md)** — How system-generated status rows specialize by subtype, collapse noise, and preserve turn and recovery context.
- **[hook-execution-feedback.md](hook-execution-feedback.md)** — How hook progress rows, async hook attachments, stop-hook spinner suffixes, and dynamic-versus-static message behavior stay coordinated.
- **[teammate-mailbox-control-message-rendering.md](teammate-mailbox-control-message-rendering.md)** — How teammate mailbox envelopes, control-message cards, hidden protocol payloads, and compact summaries render across transcript and attachment paths.
- **[teammate-surfaces-and-navigation.md](teammate-surfaces-and-navigation.md)** — How swarm roster, spinner tree, transcript view, task dialogs, and banners stay synchronized.
- **[background-task-status-surfaces.md](background-task-status-surfaces.md)** — How coordinator rows, teammate pill strips, generic task pills, and named-agent banners divide and synchronize background work visibility.
- **[background-task-summary-labels.md](background-task-summary-labels.md)** — How the footer pill and transcript summaries compress visible background work into stable, type-aware labels.
- **[background-task-row-and-progress-semantics.md](background-task-row-and-progress-semantics.md)** — How one-line background-task rows choose titles, normalize statuses, expose unread work, and render compact progress.
- **[background-task-local-detail-metadata.md](background-task-local-detail-metadata.md)** — How local-agent and teammate detail dialogs compose titles, stats, prompt previews, and recent tool activity.
- **[background-task-detail-dialogs.md](background-task-detail-dialogs.md)** — How task inspection dialogs enter, return, cap readback, and specialize controls for local, remote, and dream work.
- **[feedback-state-machine.md](feedback-state-machine.md)** — UI state transitions from idle to progress, approval, recovery, and completion.
