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
- **[interactive-setup-and-onboarding-screens.md](interactive-setup-and-onboarding-screens.md)** — Pre-REPL onboarding, trust/setup dialogs, and the staged first-run/startup screen flow.
- **[startup-welcome-dashboard-and-feed-rotation.md](startup-welcome-dashboard-and-feed-rotation.md)** — Startup header mode selection, welcome dashboard composition, and right-column feed arbitration.
- **[terminal-setup-and-multiline-entry-affordances.md](terminal-setup-and-multiline-entry-affordances.md)** — `/terminal-setup` install flows, multiline-enter fallbacks, and terminal-specific input compatibility.
- **[interaction-feedback.md](interaction-feedback.md)** — How the product communicates progress, risk, and outcomes.
- **[status-line-and-footer-notification-stack.md](status-line-and-footer-notification-stack.md)** — Priority-driven footer arbitration, persistent indicators, and notification folding rules.
- **[out-of-band-terminal-notification-routing.md](out-of-band-terminal-notification-routing.md)** — Terminal-native notification routing outside transcript and footer queues.
- **[spinner-tips-and-contextual-loading-hints.md](spinner-tips-and-contextual-loading-hints.md)** — Spinner-tip scheduling, cooldown/relevance contracts, and elapsed-time hint overrides.
- **[permission-prompt-shell-and-worker-states.md](permission-prompt-shell-and-worker-states.md)** — How queued approval prompts, shared permission dialog chrome, feedback-entry controls, and worker waiting cards behave.
- **[plan-mode-approval-surfaces.md](plan-mode-approval-surfaces.md)** — How enter-plan and exit-plan approvals present plans, collect feedback, choose execution modes, and hand plan acceptance back into the session loop.
- **[ask-user-question-and-plan-interview-ui.md](ask-user-question-and-plan-interview-ui.md)** — How ask-user prompts paginate questions, render previews, collect notes and attachments, and expose plan-interview-specific footer actions.
- **[session-cost-threshold-acknowledgement.md](session-cost-threshold-acknowledgement.md)** — How Anthropic API session spend reaches a one-time $5 acknowledgement threshold, who can see it, and how the dialog persists.
- **[low-priority-recommendation-and-upsell-dialogs.md](low-priority-recommendation-and-upsell-dialogs.md)** — How IDE onboarding, effort onboarding, remote first-use, plugin recommendations, and desktop upsell share one low-priority dialog band.
- **[feedback-surveys-and-transcript-share-escalation.md](feedback-surveys-and-transcript-share-escalation.md)** — How session, post-compact, and memory surveys share one prompt-area state machine, transcript-share escalation, and richer issue or feedback handoff paths.
- **[keybinding-customization-and-context-resolution.md](keybinding-customization-and-context-resolution.md)** — How `/keybindings`, config loading, context priority, chord interception, and warning surfaces stay aligned.
- **[prompt-composer-and-queued-command-shell.md](prompt-composer-and-queued-command-shell.md)** — How the interactive prompt shell coordinates composition, autocomplete, history, pasted artifacts, queue recovery, footer focus, and busy-state submission routing.
- **[prompt-history-persistence-and-paste-store.md](prompt-history-persistence-and-paste-store.md)** — How durable prompt history, paste-cache indirection, Up-arrow recall, search, and interrupted-submit undo stay consistent across sessions.
- **[companion-buddy-surface.md](companion-buddy-surface.md)** — How the hatched companion, `/buddy` affordances, sprite layout, teaser notifications, and reaction bubbles stay synchronized with prompt and model behavior.
- **[diff-dialog-and-turn-history-navigation.md](diff-dialog-and-turn-history-navigation.md)** — How `/diff` opens a modal overlay, combines current working-tree changes with per-turn edit history, paginates file lists, and branches detail rendering for untracked, binary, large, and truncated diffs.
- **[message-selector-and-restore-flows.md](message-selector-and-restore-flows.md)** — How rewind filters for real user prompts, chooses between conversation/code/summarize restore variants, and reuses the same semantics for cancel-time undo.
- **[transcript-message-actions-and-cursor-mode.md](transcript-message-actions-and-cursor-mode.md)** — How fullscreen transcript cursor mode curates actionable rows, navigates them, expands them, copies their content, and hands user prompts back into rewind semantics.
- **[transcript-search-and-less-style-navigation.md](transcript-search-and-less-style-navigation.md)** — How fullscreen transcript search anchors incremental `/` queries, preserves `n/N` navigation, invalidates stale highlights, and coordinates pager-style dump or editor escape hatches.
- **[resume-picker-search-preview-and-filters.md](resume-picker-search-preview-and-filters.md)** — How the interactive resume browser layers search, tag and branch filters, worktree and all-project toggles, fork-group expansion, preview, rename, and cross-project safeguards over lightweight session discovery.
- **[workspace-search-and-open-overlays.md](workspace-search-and-open-overlays.md)** — How quick-open and workspace-search overlays take over prompt focus, preview workspace files or matches, and either open them externally or insert structured references back into the draft.
- **[prompt-history-picker-dialog.md](prompt-history-picker-dialog.md)** — How the modal prompt-history picker loads timestamped candidates, ranks exact versus subsequence matches, previews multiline prompts, and restores full composer state on selection.
- **[conversation-export-dialog.md](conversation-export-dialog.md)** — How `/export` chooses clipboard versus file delivery, handles filename editing and back-navigation, and keeps export feedback aligned across direct and interactive paths.
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
- **[focused-dialog-and-overlay-arbitration.md](focused-dialog-and-overlay-arbitration.md)** — How blocking dialogs, prompt-owned overlays, typing suppression, and low-priority callouts arbitrate for focus.
