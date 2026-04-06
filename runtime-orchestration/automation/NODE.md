---
title: "Automation and Persistent Flows"
owners: []
---

# Automation and Persistent Flows

This subdomain captures runtime behaviors that keep working across turns or time: assistant posture, workflows, schedules, and long-lived review/planning paths.

Relevant leaves:

- **[proactive-assistant-loop-and-brief-mode.md](proactive-assistant-loop-and-brief-mode.md)** — How assistant mode, proactive ticks, BriefTool, and startup team bootstrap create a persistent autonomous posture.
- **[prompt-suggestion-and-speculation.md](prompt-suggestion-and-speculation.md)** — How leader-only next-input suggestions are generated, filtered, optionally pre-executed in overlays, and accepted or aborted.
- **[remote-planning-session-loop.md](remote-planning-session-loop.md)** — How the gated remote-planning flow launches a remote plan-mode session, polls approval artifacts, and splits into remote execution or local handoff.
- **[remote-scheduled-agents-and-trigger-management.md](remote-scheduled-agents-and-trigger-management.md)** — How cloud-side scheduled agents, trigger APIs, `/schedule`, environment selection, and connector setup stay distinct from local cron.
- **[review-path.md](review-path.md)** — End-to-end path for local review and remote ultrareview-style flows.
- **[scheduled-prompts-and-cron-lifecycle.md](scheduled-prompts-and-cron-lifecycle.md)** — How local scheduled prompts, `/loop`, cron persistence, jitter, multi-session ownership, and missed-task catch-up behave as one runtime subsystem.
- **[workflow-script-runtime.md](workflow-script-runtime.md)** — How workflow definitions become badged commands, bootstrap bundled flows, run as background workflow tasks, emit phase progress, and clean up workflow worktrees.
