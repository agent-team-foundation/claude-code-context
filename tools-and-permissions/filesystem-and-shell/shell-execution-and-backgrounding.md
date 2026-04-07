---
title: "Shell Execution and Backgrounding"
owners: []
soft_links: [/tools-and-permissions/filesystem-and-shell/shell-command-parsing-and-classifier-flow.md, /runtime-orchestration/tasks/task-model.md, /runtime-orchestration/tasks/monitor-task-families-and-watch-lifecycle.md, /tools-and-permissions/execution-and-hooks/tool-batching-and-streaming-execution.md, /tools-and-permissions/execution-and-hooks/tool-execution-state-machine.md]
---

# Shell Execution and Backgrounding

Claude Code's shell tools are task-aware executors, not simple subprocess wrappers. A faithful rebuild needs foreground streaming, explicit background tasks, user-triggered backgrounding, and assistant-mode auto-backgrounding to share one lifecycle model.

## Shared shell contract

Both shell families expose the same core request shape:

- a command string
- an optional timeout
- an optional human-readable description
- an explicit background toggle
- an explicit sandbox override

When background tasks are globally disabled, the model-facing schema must hide the background toggle and execution must quietly stay in the foreground even if older callers still send that field.

## Foreground execution lifecycle

Equivalent shell execution should preserve these stages:

1. validate command-specific safety constraints before starting work
2. start the shell command with streaming progress callbacks
3. keep the command in the foreground for short operations
4. after a short threshold, surface progress updates and register the command as a foreground task that the UI can background in place
5. on completion, emit either inline output or a persisted-output handle when the full output was too large

Oversized output is not dropped. The runtime keeps a preview inline and persists the full artifact to a readable harness directory.

## Background entry points

A correct rebuild should support all of these ways for shell work to become a task:

- explicit `run_in_background` should immediately spawn a background task and return its task identifier
- once a long-running foreground command has been registered, the user can background that exact task from the UI instead of spawning a duplicate process
- timeout-aware shell commands may auto-background when the shell layer decides they exceeded a blocking budget
- in assistant mode on the main thread, a long-running blocking shell command should auto-background after a separate assistant responsiveness budget instead of freezing the turn

That assistant-mode auto-background path matters because the command keeps running while the conversation stays responsive. It should not fire for subagents, for already-backgrounded commands, or when background tasks are disabled.

## Commands that must not auto-background

Shell backgrounding is intentionally asymmetric:

- explicit backgrounding should always be honored when background tasks are enabled
- automatic backgrounding should refuse obvious top-level delay commands such as `sleep` or `Start-Sleep`

This preserves a difference between "the model asked to background this on purpose" and "the runtime opportunistically backgrounded a stalled command."

## Blocking-wait guard

When the monitoring toolchain is available and background tasks are enabled, obvious top-level wait loops should be rejected before execution unless the caller explicitly backgrounds them.

The durable rule is:

- top-level delay commands below 2 seconds are allowed as normal pacing
- top-level delays of 2 seconds or more must be rewritten as background work or as a dedicated monitor-style workflow
- waits hidden inside scripts, nested expressions, or later pipeline stages are not caught by this shallow guard and therefore fall back to ordinary execution

## Race handling and task reuse

Background transitions can race with process exit. The runtime must preserve this invariant:

- if the process actually finished before the background transition became externally visible, the final result should collapse back into an ordinary completed shell result rather than simultaneously returning a background task and a completed command

Related task invariants:

- if a foreground task already exists, backgrounding should reuse it instead of respawning the shell command
- task notifications should be suppressed once the runtime already surfaced the completed result
- cleanup ownership should transfer to the background-task subsystem only for commands that truly remain backgrounded

## Shared task channel

Background shell work must be registered through the shared task system rather than through a main-thread-only side channel.

That allows:

- async agents to create killable background shell tasks
- the main session to receive completion notifications
- task stop and cleanup behavior to stay consistent across main-agent and delegated execution

## Concurrency and read-only gating

Shell tools only join concurrent execution batches when their own read-only heuristic says that overlapping execution is safe.

Important asymmetries to preserve:

- Bash uses a synchronous shell-specific read-only check and exposes that directly as its concurrency-safe predicate
- PowerShell's synchronous read-only check is deliberately conservative; the richer parsed-AST read-only allow path happens later in permission evaluation, so some truly read-only PowerShell commands may still serialize
- read-only classification should remain tied to shell-aware decomposition, so redirects, cwd changes, forwarded subcommands, or other write-shaped structure can keep an otherwise familiar command out of overlap-safe execution

## Display heuristics

The shell UI also carries behavior that affects how users and models interpret results:

- read/search/list collapsing should only happen when every substantive segment of a pipeline or compound command belongs to a known read-like family
- semantic-neutral segments such as pure output/status commands may be ignored during that classification
- redirect operators should not cause a command to look read-only
- commands that normally emit no stdout on success should render as a clean success state rather than as fake empty output

## Family-specific nuance

PowerShell preserves one extra continuation behavior: when a conversational interrupt arrives while a command is still running and background tasks are allowed, the runtime prefers to background the command rather than kill it outright.

## Failure modes

- **turn freeze**: long shell work blocks the conversation because assistant-mode auto-backgrounding is missing
- **duplicate task spawn**: foreground work is backgrounded by starting a second process instead of reusing the registered task
- **completion race leak**: the user sees both a completed result and a redundant background-task notification
- **false concurrency**: a shell command is treated as overlap-safe even though its read-only heuristic was only partial
- **collapsed mislabeling**: mixed read-write pipelines get summarized like harmless reads
