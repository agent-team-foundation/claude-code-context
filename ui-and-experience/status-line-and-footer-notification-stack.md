---
title: "Status Line and Footer Notification Stack"
owners: []
soft_links: [/ui-and-experience/interaction-feedback.md, /ui-and-experience/system-feedback-lines.md, /ui-and-experience/terminal-ui.md, /ui-and-experience/companion-buddy-surface.md, /tools-and-permissions/permission-model.md]
---

# Status Line and Footer Notification Stack

Claude Code's footer is not one message string. It is an arbitration layer that combines fixed indicators, queued notifications, auth and token state, updater state, memory state, IDE state, sandbox hints, and voice state.

## Queue model

Equivalent behavior should preserve a notification store with:

- one current notification
- a queued backlog
- explicit priority levels
- optional invalidation keys so one notification can remove stale related ones
- optional fold behavior so repeated events with the same key merge instead of stacking forever
- per-notification timeout control

The next displayed queued notification should be chosen by priority, not simple arrival order.

## Immediate-preemption behavior

Some footer notices must preempt everything else.

Equivalent behavior should preserve:

- immediate notifications replacing the current one right away
- re-queuing of the previous current notification only when that previous item was not itself immediate
- timeout reset whenever an immediate notification takes over
- invalidation of obsolete queued items that the new notification supersedes

This is how short-lived but important hints stay visible without permanently erasing slower background notices.

## Composition stack

The footer should combine dynamic notifications with persistent indicators.

Equivalent behavior should preserve a stack that can show:

- IDE or editor-connection status
- the current queued notification, if any
- usage-mode notices such as overage state
- slow helper warnings
- auth or login problems
- debug and verbose token diagnostics
- compaction pressure warnings
- updater state
- voice errors
- memory-usage indicators
- sandbox-specific footer hints

These are separate producers, not one monolithic formatter.

## Arbitration rules

Several special rules keep the footer readable:

- active voice capture or processing replaces the ordinary footer stack with a voice-only indicator
- IDE-selection state suppresses successful updater chatter so the footer does not compete with file-context indicators
- environment-hook notices enter through the notification queue with short timeouts and lower priority unless they are errors
- external-editor hints appear only in a narrow wrapped-input state and only when larger warning surfaces are not already occupying the same attention budget

This is not just cosmetics. It prevents mutually contradictory hints from appearing at once.

## Failure modes

- **priority inversion**: low-value noise blocks urgent safety or environment notices
- **notification duplication**: repeated events stack instead of folding or invalidating
- **mode override loss**: voice capture or similar dominant state fails to suppress the normal footer
- **stale hint linger**: a superseded hint remains visible after the relevant state changed
