---
title: "Out-of-Band Terminal Notification Routing"
owners: []
soft_links: [/ui-and-experience/feedback-and-notifications/status-line-and-footer-notification-stack.md, /ui-and-experience/feedback-and-notifications/idle-return-and-away-summary.md, /runtime-orchestration/turn-flow/turn-assembly-and-recovery.md, /tools-and-permissions/execution-and-hooks/tool-execution-state-machine.md]
---

# Out-of-Band Terminal Notification Routing

Claude Code has a notification channel that bypasses transcript rendering and footer queueing. It is used for terminal-native alerts when the user is likely away from the prompt, and for tool-triggered OS-style notices that should remain visible even when the main UI is idle.

## Scope boundary

This leaf covers:

- the notification dispatch contract from runtime events into terminal-native transports
- channel selection and fallback behavior for auto and explicit notification channels
- terminal protocol writers for iTerm2, Kitty, Ghostty, and bell-based fallback
- hook interception and analytics around notification delivery

It does not re-document:

- in-terminal footer message arbitration already captured in [status-line-and-footer-notification-stack.md](status-line-and-footer-notification-stack.md)
- general hook framework semantics beyond notification-specific hook invocation

## Notification entrypoints

Equivalent behavior should preserve:

- one shared notification service that accepts `{message, optional title, notification type}` and can be called from REPL, tool flows, and background pollers
- REPL-owned idle detection that emits a notification only after a turn has completed, the user has stayed inactive for the configured threshold, and no blocking input dialog is active
- tool-use context exposing a notification callback so tool-side flows can request out-of-band alerts without directly depending on terminal escape-sequence logic
- notification dispatch being fire-and-forget from caller perspective so UI responsiveness is not blocked on delivery

## Dispatch pipeline

Equivalent behavior should preserve this order:

1. read user preference for notification channel from persisted config
2. run notification hooks with the same message, title, and notification type
3. attempt channel delivery
4. emit telemetry about configured channel and actual method used

Notification hooks are part of the contract, not an optional side path. A rebuild should allow policy or automation to observe or react to outgoing notifications before transport writes happen.

## Channel model and routing

Equivalent behavior should preserve:

- an explicit channel enum with at least: `auto`, terminal-specific channels, bell-only, and disabled
- explicit channels directly invoking matching terminal notifiers
- `notifications_disabled` short-circuiting transport writes while still allowing hook execution and method tracking
- transport failures degrading to a non-throwing result code instead of surfacing user-visible runtime errors

## Auto-channel behavior

Equivalent behavior should preserve:

- terminal fingerprint-based routing in `auto` mode rather than guessing by OS alone
- iTerm2, Kitty, and Ghostty using native OSC notification sequences when detected
- Apple Terminal auto mode preferring bell fallback only when bell behavior is known to be compatible with the user's current profile settings
- unsupported terminals returning a no-method result rather than forcing a potentially noisy or broken fallback

## Terminal protocol writer contract

Equivalent behavior should preserve:

- one terminal-notification utility that writes raw OSC or BEL sequences through a shared writer context
- all OSC writes being wrapped for multiplexer compatibility when needed
- BEL writes remaining raw for tmux-compatible bell behavior
- terminal progress reporting sharing the same writer surface but remaining logically separate from notification dispatch

## Delivery semantics and non-goals

Equivalent behavior should preserve:

- no transcript row being appended solely because a terminal notification was sent
- no footer queue mutation as a side effect of out-of-band delivery
- repeated notifications being allowed when triggers are distinct; dedup belongs at caller-level gating, not transport-level suppression

## Failure modes

- **silent regressions in auto routing**: auto mode always returns no-method even on supported terminals
- **hook bypass**: notifications are sent directly by callers and skip notification hook execution
- **transport over-coupling**: notifier throws into UI call paths and interrupts turn completion
- **wrong terminal fallback**: Apple Terminal behavior ignores profile bell semantics and either spams sound or never surfaces alerts
- **channel drift**: explicit user channel preference is ignored and runtime always uses auto detection
