---
title: "Interaction Feedback"
owners: []
soft_links: [/tools-and-permissions/permission-model.md, /runtime-orchestration/query-loop.md]
---

# Interaction Feedback

The product experience depends heavily on explaining what the agent is doing and why.

Important feedback patterns include:

- tool progress and intermediate status
- permission requests, rejections, and safety warnings
- summaries after compaction or long-running work
- agent and task status across collaborative flows
- diff presentation for proposed edits
- graceful recovery messaging after interruptions, retries, or remote mismatches

Equivalent implementations should optimize for user trust. When the system changes state, the UI should make that state understandable.
