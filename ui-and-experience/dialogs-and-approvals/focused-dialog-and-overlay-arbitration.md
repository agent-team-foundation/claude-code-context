---
title: "Focused Dialog and Overlay Arbitration"
owners: []
soft_links: [/ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md, /ui-and-experience/shell-and-input/workspace-search-and-open-overlays.md, /ui-and-experience/shell-and-input/prompt-history-picker-dialog.md, /ui-and-experience/startup-and-onboarding/low-priority-recommendation-and-upsell-dialogs.md, /ui-and-experience/startup-and-onboarding/session-cost-threshold-acknowledgement.md, /ui-and-experience/shell-and-input/terminal-runtime-and-fullscreen-interaction.md, /runtime-orchestration/turn-flow/advisor-and-thinking-lifecycle.md]
---

# Focused Dialog and Overlay Arbitration

Claude Code does not let every dialog, prompt, search overlay, or startup callout compete equally for focus. The terminal UI owns a real arbitration model that decides which single dialog currently has input focus, which prompt-owned overlay can temporarily replace the composer, and which surfaces must stay hidden while the user is actively typing.

## One focused input dialog at a time

Equivalent behavior should preserve one focused-input dialog slot rather than multiple equally active modal layers.

The high-priority arbitration contract is:

1. exit/shutdown state wins and suppresses ordinary dialog focus
2. message-selector-style restore UI wins over everything else
3. when the user is actively typing, interruptive approval/prompt dialogs are temporarily suppressed instead of stealing focus
4. otherwise, blocking request dialogs such as sandbox approval, tool permission, prompt questions, worker-network approval, elicitation, cost threshold, idle-return, and remote-planning choice/launch take precedence
5. lower-priority onboarding, callout, recommendation, and upsell dialogs only appear when higher-priority blockers are absent

The point is not just visual stacking. The focused dialog controls cancellation, attention routing, and in some cases whether transcript animation is allowed to continue.

## Prompt-owned overlays are a second arbitration band

Equivalent behavior should preserve a separate class of overlays owned by the prompt/composer layer itself.

These include examples such as:

- background-task and teams dialogs
- quick-open and global-search overlays
- prompt-history picker
- model/fast/thinking pickers
- bridge dialog and similar prompt-local modals

These overlays are not the same as the focused REPL dialog slot above. They temporarily replace or suppress the composer, footer, and normal input handling from inside the prompt surface.

## Active typing suppresses some dialogs

Equivalent behavior should preserve:

- active prompt composition preventing interrupt-style dialogs from stealing focus immediately
- permission and prompt queues remaining pending while suppressed
- explicit "suppressed dialogs exist" state so the UI can still hint that something is waiting
- resumed dialog focus once the user stops actively typing

This is a real product behavior, not just a timing accident. It keeps the prompt shell usable without dropping queued approvals.

## Fullscreen overlay mechanics matter

Equivalent behavior should preserve:

- fullscreen-only portal/overlay mounting for dialogs that must escape the prompt slot's clipping region
- tool-permission overlay appearance and dismissal repinning scroll so a blocking approval cannot render off-screen
- companion/prompt/footer surfaces yielding when a true modal overlay is active instead of continuing to accept navigation input underneath
- some tool-owned JSX surfaces being allowed to keep transcript animation alive, while others fully suppress dialog routing

## Low-priority recommendation band is still ordered

Equivalent behavior should preserve a deterministic ordering among lower-priority dialogs such as:

- IDE onboarding
- model/effort/remote-control callouts
- plugin/LSP recommendations
- desktop upsell

These are not equal-priority notifications. They share one late-position band that only becomes eligible after higher-priority blockers are gone.

## Failure modes

- **modal stack confusion**: two dialogs both think they own focus and keyboard input
- **typing theft**: approval or recommendation dialogs steal focus while the user is actively composing text
- **hidden blocker**: a blocking approval exists, but the viewport or scroll position leaves it off-screen
- **overlay leakage**: prompt-local overlays leave composer or footer handlers active underneath
- **priority inversion**: low-priority onboarding/recommendation UI appears while a higher-priority blocking dialog should have focus
