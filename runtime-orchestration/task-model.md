---
title: "Task Model"
owners: []
soft_links: [/collaboration-and-agents/multi-agent-topology.md, /tools-and-permissions/delegation-modes.md, /runtime-orchestration/workflow-script-runtime.md]
---

# Task Model

Claude Code treats long-running work as explicit tasks with typed lifecycle management rather than as anonymous detached side effects.

Required task qualities:

- A task has a stable identifier, type, status, description, and output location.
- A task can move through non-terminal and terminal states; terminal tasks must reject further writes.
- The UI and tool surface can inspect, stream, update, and stop task execution.
- Task types own their completion semantics. Generic polling can stream output and evict finished work, but task-specific code decides when a task is truly complete and how it should notify the model or SDK.
- Task identity can outlive a foreground turn and, for some task families, even survive a session clear or local process restart.

Important task families include:

- local shell tasks that can begin in the foreground and later background in place
- local agent tasks that may remain inline, move to background, receive follow-up prompts, or be resumed from transcript state
- local workflow tasks that orchestrate multi-step scripted work with their own progress tree and operator controls
- backgrounded main-session tasks that keep running the ordinary query loop under an isolated task transcript
- remote agent tasks that shadow off-machine sessions and must be restorable after reconnect
- monitor tasks that remain visible as long-lived watches instead of one-shot shell work
- dream-style consolidation tasks that are visible in UI but do not use the normal model-facing notification path

This separation matters because Claude Code mixes interactive foreground turns with work that may outlive a single turn, span different permission or transport boundaries, and surface its results asynchronously.
