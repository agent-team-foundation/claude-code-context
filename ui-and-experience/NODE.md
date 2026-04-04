---
title: "UI and Experience"
owners: []
soft_links: [/product-surface, /tools-and-permissions]
---

# UI and Experience

This domain captures how Claude Code makes a complex agent runtime legible inside a terminal-first interface.

Relevant leaves:

- **[terminal-ui.md](terminal-ui.md)** — Composition of the terminal application and major UI regions.
- **[terminal-runtime-and-fullscreen-interaction.md](terminal-runtime-and-fullscreen-interaction.md)** — Terminal capability negotiation, buffered redraws, fullscreen behavior, and input-protocol gating.
- **[interaction-feedback.md](interaction-feedback.md)** — How the product communicates progress, risk, and outcomes.
- **[status-line-and-footer-notification-stack.md](status-line-and-footer-notification-stack.md)** — Priority-driven footer arbitration, persistent indicators, and notification folding rules.
- **[permission-prompt-shell-and-worker-states.md](permission-prompt-shell-and-worker-states.md)** — How queued approval prompts, shared permission dialog chrome, feedback-entry controls, and worker waiting cards behave.
- **[plan-mode-approval-surfaces.md](plan-mode-approval-surfaces.md)** — How enter-plan and exit-plan approvals present plans, collect feedback, choose execution modes, and hand plan acceptance back into the session loop.
- **[ask-user-question-and-plan-interview-ui.md](ask-user-question-and-plan-interview-ui.md)** — How ask-user prompts paginate questions, render previews, collect notes and attachments, and expose plan-interview-specific footer actions.
- **[keybinding-customization-and-context-resolution.md](keybinding-customization-and-context-resolution.md)** — How `/keybindings`, config loading, context priority, chord interception, and warning surfaces stay aligned.
- **[prompt-composer-and-queued-command-shell.md](prompt-composer-and-queued-command-shell.md)** — How the interactive prompt shell coordinates composition, autocomplete, history, pasted artifacts, queue recovery, footer focus, and busy-state submission routing.
- **[companion-buddy-surface.md](companion-buddy-surface.md)** — How the hatched companion, `/buddy` affordances, sprite layout, teaser notifications, and reaction bubbles stay synchronized with prompt and model behavior.
- **[diff-dialog-and-turn-history-navigation.md](diff-dialog-and-turn-history-navigation.md)** — How `/diff` opens a modal overlay, combines current working-tree changes with per-turn edit history, paginates file lists, and branches detail rendering for untracked, binary, large, and truncated diffs.
- **[vim-mode-and-modal-editing.md](vim-mode-and-modal-editing.md)** — How `/vim`, editor-mode persistence, modal prompt parsing, repeat/register memory, and Vim-specific UI cues stay coordinated.
- **[voice-mode-and-hold-to-talk-dictation.md](voice-mode-and-hold-to-talk-dictation.md)** — How voice eligibility, hold-to-talk capture, streaming transcription, prompt injection, and voice-specific feedback stay coordinated.
- **[system-feedback-lines.md](system-feedback-lines.md)** — How system-generated status rows specialize by subtype, collapse noise, and preserve turn and recovery context.
- **[idle-return-and-away-summary.md](idle-return-and-away-summary.md)** — How long-idle returns trigger restart nudges, blocking continue-or-clear choices, and focus-loss recap summaries.
- **[hook-execution-feedback.md](hook-execution-feedback.md)** — How hook progress rows, async hook attachments, stop-hook spinner suffixes, and dynamic-versus-static message behavior stay coordinated.
- **[teammate-mailbox-control-message-rendering.md](teammate-mailbox-control-message-rendering.md)** — How teammate mailbox envelopes, control-message cards, hidden protocol payloads, and compact summaries render across transcript and attachment paths.
- **[teammate-surfaces-and-navigation.md](teammate-surfaces-and-navigation.md)** — How swarm roster, spinner tree, transcript view, task dialogs, and banners stay synchronized.
- **[background-task-status-surfaces.md](background-task-status-surfaces.md)** — How coordinator rows, teammate pill strips, generic task pills, and named-agent banners divide and synchronize background work visibility.
- **[background-task-summary-labels.md](background-task-summary-labels.md)** — How the footer pill and transcript summaries compress visible background work into stable, type-aware labels.
- **[background-task-row-and-progress-semantics.md](background-task-row-and-progress-semantics.md)** — How one-line background-task rows choose titles, normalize statuses, expose unread work, and render compact progress.
- **[background-task-local-detail-metadata.md](background-task-local-detail-metadata.md)** — How local-agent and teammate detail dialogs compose titles, stats, prompt previews, and recent tool activity.
- **[background-task-detail-dialogs.md](background-task-detail-dialogs.md)** — How task inspection dialogs enter, return, cap readback, and specialize controls for local, remote, and dream work.
- **[feedback-state-machine.md](feedback-state-machine.md)** — UI state transitions from idle to progress, approval, recovery, and completion.
