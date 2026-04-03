---
title: "Feedback State Machine"
owners: []
soft_links: [/ui-and-experience/interaction-feedback.md, /tools-and-permissions/tool-execution-state-machine.md]
---

# Feedback State Machine

The UI should make runtime state legible as it changes.

## Primary feedback states

1. Idle.
2. User input composing.
3. Active streaming.
4. Tool progress visible.
5. Approval or warning visible.
6. Deferred-background activity visible.
7. Recovery or reconnect visible.
8. Completed or archived.

## Design requirements

- transitions must explain why the user is waiting
- permission and trust prompts must be visually distinct from ordinary output
- background work must stay visible without overwhelming the foreground task
- recoveries such as compaction, reconnect, or remote mismatch should be surfaced as state transitions, not mysterious transcript jumps

## Failure modes

- **Invisible work**: the system is active, but the user sees no progress signal.
- **State aliasing**: success, warning, and pending states look too similar.
- **Recovery opacity**: the transcript changed due to compaction, reconnect, or resume, but the UI does not explain it.
- **Prompt flooding**: too many simultaneous notices compete for the same attention channel.
