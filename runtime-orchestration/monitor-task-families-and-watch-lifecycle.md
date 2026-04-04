---
title: "Monitor Task Families and Watch Lifecycle"
owners: []
soft_links: [/runtime-orchestration/background-shell-task-lifecycle.md, /runtime-orchestration/task-model.md, /runtime-orchestration/task-registry-and-visibility.md, /runtime-orchestration/turn-attachments-and-sidechannels.md, /tools-and-permissions/shell-execution-and-backgrounding.md, /ui-and-experience/background-task-status-surfaces.md, /ui-and-experience/background-task-row-and-progress-semantics.md, /ui-and-experience/background-task-detail-dialogs.md, /ui-and-experience/permission-prompt-shell-and-worker-states.md]
---

# Monitor Task Families and Watch Lifecycle

Monitor behavior is not one extra flag on shell commands. Claude Code has two monitor-oriented task families, distinct completion meaning, prompt-side steering away from naive sleep loops, urgent notification handling, and teardown rules that keep watch processes from outliving the worker that started them.

## Two monitor families, not one

Equivalent behavior should preserve:

- monitor-style shell watches remaining `local_bash` tasks for compatibility, differentiated by a monitor kind rather than a separate top-level task type
- dedicated monitor-MCP work using a separate `monitor_mcp` task family with its own durable ID namespace
- both families participating in generic background-task visibility while still landing in different summary buckets, dialog sections, and stop paths
- shell-monitor rows using the human description as their primary label, because the raw command line is often the wrong user-facing identity for a long-lived watch
- monitor-MCP tasks keeping their own description-owned identity instead of borrowing shell or remote-session naming rules

## Prompting and entry guardrails

Equivalent behavior should preserve:

- when monitor tooling and background tasks are available, obvious top-level delay or poll patterns of 2 seconds or more being rejected unless they are explicitly backgrounded
- model-facing shell guidance steering streaming watch use cases to the Monitor tool and one-shot wait-until-done cases to background bash
- short deliberate sleeps under that threshold remaining allowed for ordinary pacing, so the guard does not ban all delay usage
- waits hidden inside scripts, nested expressions, or later pipeline stages falling back to ordinary execution because the guard is intentionally shallow
- monitor selection being part of the execution contract, not just a documentation hint

## Notification and completion semantics

Equivalent behavior should preserve:

- monitor-style shell tasks opting out of the shell stall watchdog, because quiet periods are normal for watches and should not look like blocked stdin
- monitor completions using distinct summary language such as stream ended, stopped, or script failed rather than generic "background command completed" wording
- successful generic background-bash completions being collapse-eligible, while monitor completions intentionally stay separate so watch endings are not folded into ordinary command batches
- monitor-related task notifications entering the pending-notification queue at urgent next-turn priority when the monitor feature set is active, so mid-turn attachment draining can surface them promptly
- stream-event notifications carrying no terminal status tag, preventing SDK or UI consumers from confusing intermediate watch output with task completion
- failed or killed monitor events remaining individually visible rather than being merged away

## Ownership, cleanup, and background partitioning

Equivalent behavior should preserve:

- both monitor families participating in background-task filters, while shell monitors stay inside the shell family and monitor-MCP tasks keep their own task type and ID prefix
- agents that spawn background shell monitors or monitor-MCP tasks retaining ownership through `agentId` so teardown can cascade when the parent worker exits
- agent cleanup killing both background bash tasks and monitor-MCP tasks to avoid orphaned watch processes after the worker dies
- shell-monitor task registration keeping the same cleanup-registry discipline as other background shell tasks
- background-task UI partitioning separating monitors from ordinary shells in summary pills, list sections, and detail routing

## Permission and detail gating

Equivalent behavior should preserve:

- specialized monitor permission and detail surfaces being feature-gated, with approval routing falling back safely to the generic permission renderer when specialized monitor UI is unavailable
- shell-monitor detail reusing the shell detail stack but changing title and label semantics, while monitor-MCP tasks route to their own dedicated detail dialog and stop implementation
- task registration and stop semantics staying valid even when a particular monitor-only renderer is absent from a given build

## Failure modes

- **family collapse**: monitor-style shell tasks and monitor-MCP tasks are flattened into one generic shell concept, breaking IDs, summaries, and stop routing
- **false prompt alarms**: quiet monitors keep triggering shell stall warnings because the watchdog does not exempt watch-style tasks
- **buried watch completions**: monitor endings are collapsed into generic background-command summaries or delayed behind later-priority task notifications
- **sleep-loop drift**: shell tools allow naive top-level polling loops instead of steering users toward explicit background work or the monitor tool
- **orphan watchers**: worker teardown forgets monitor-MCP or shell-monitor cleanup and leaves long-lived watch processes behind
- **renderer coupling**: missing specialized monitor UI breaks permission approval or detail inspection instead of degrading to the generic path
