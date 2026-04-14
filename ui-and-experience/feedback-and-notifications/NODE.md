---
title: "Feedback and Notifications"
owners: []
---

# Feedback and Notifications

This subdomain captures how Claude Code communicates state, urgency, surveys, and idle-return context outside the main prompt text.

Relevant leaves:

- **[interaction-feedback.md](interaction-feedback.md)** — How the product communicates progress, risk, and outcomes.
- **[status-line-and-footer-notification-stack.md](status-line-and-footer-notification-stack.md)** — Priority-driven footer arbitration, persistent indicators, and notification folding rules.
- **[custom-status-line-setup-and-execution.md](custom-status-line-setup-and-execution.md)** — `/statusline` setup flow, persisted command shape, structured stdin payload, and trust/layout rules for custom status lines.
- **[out-of-band-terminal-notification-routing.md](out-of-band-terminal-notification-routing.md)** — Terminal-native notification routing outside transcript and footer queues.
- **[spinner-tips-and-contextual-loading-hints.md](spinner-tips-and-contextual-loading-hints.md)** — Spinner-tip scheduling, cooldown/relevance contracts, and elapsed-time hint overrides.
- **[system-feedback-lines.md](system-feedback-lines.md)** — How system-generated status rows specialize by subtype, collapse noise, and preserve turn/recovery context.
- **[hook-execution-feedback.md](hook-execution-feedback.md)** — How hook progress rows, async hook attachments, stop-hook spinner suffixes, and dynamic-vs-static message behavior stay coordinated.
- **[feedback-surveys-and-transcript-share-escalation.md](feedback-surveys-and-transcript-share-escalation.md)** — How session, post-compact, and memory surveys share one prompt-area state machine, transcript-share escalation, and richer feedback handoff paths.
- **[idle-return-and-away-summary.md](idle-return-and-away-summary.md)** — How long-idle returns trigger restart nudges, blocking continue-or-clear choices, and focus-loss recap summaries.
