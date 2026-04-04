---
title: "Interaction Feedback"
owners: []
soft_links: [/tools-and-permissions/permission-model.md, /ui-and-experience/status-line-and-footer-notification-stack.md, /ui-and-experience/system-feedback-lines.md, /ui-and-experience/background-task-status-surfaces.md, /ui-and-experience/permission-prompt-shell-and-worker-states.md, /runtime-orchestration/query-loop.md]
---

# Interaction Feedback

The product experience depends heavily on explaining what the agent is doing and why.

Important feedback patterns include:

- tool progress and intermediate status
- permission requests, rejections, and safety warnings
- footer and status-line notices that compress ambient system state without drowning the main transcript
- summaries after compaction or long-running work
- agent and task status across collaborative flows
- diff presentation for proposed edits
- graceful recovery messaging after interruptions, retries, or remote mismatches

Equivalent implementations should optimize for user trust. When the system changes state, the UI should make that state understandable.

That requires more than one message row:

- immediate prompts and waiting states for approvals or structured questions
- persistent but low-noise footer indicators for auth, updater, memory, sandbox, or voice state
- compact background-task surfaces that explain what is still running without reopening every transcript
- recovery messages that distinguish local failure, remote degradation, compaction, and user-cancelled stops
