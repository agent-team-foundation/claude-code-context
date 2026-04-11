---
title: "Task Output Persistence and Streaming"
owners: []
soft_links: [/runtime-orchestration/tasks/task-model.md, /runtime-orchestration/tasks/background-shell-task-lifecycle.md, /tools-and-permissions/filesystem-and-shell/shell-execution-and-backgrounding.md]
---

# Task Output Persistence and Streaming

Claude Code's task-output layer is the single source of truth for long-running process output. It is responsible for bounded in-memory buffering, session-stable disk paths, shared progress polling, and safe readback for both live turns and later task inspection.

## Single output owner

Each long-running task should have one output owner that all readers and notifiers agree on.

Equivalent behavior should preserve:

- one task ID maps to one canonical output path
- shell progress, final tool results, task-detail views, and task notifications all read from that same output source
- foreground and background transitions must not swap output files mid-flight

## File mode versus pipe mode

The output system supports two materially different write paths:

- file mode for shell commands, where stdout and stderr are written straight to disk and progress is recovered by polling the file tail
- pipe mode for JS-visible streams such as hook execution, where output is buffered in memory first and only spills to disk after crossing a memory limit

In file mode, stderr is effectively interleaved into the file-backed output stream. In pipe mode, stdout and stderr can still be buffered separately before any spill.

## Shared poller contract

Progress polling should be centralized rather than one timer per task.

Required behavior:

- register file-backed outputs that expose progress callbacks
- activate polling only while the UI is actually watching that task
- use one shared unref'd interval to read small tails from all active outputs
- stop the interval when nothing is actively being observed

Even when a command is silent, the poller still needs to wake the progress consumer so timeout, backgrounding, or other liveness checks do not stall behind "no new bytes."

## Progress estimation

Progress is approximate but monotonic for large files.

A correct rebuild should preserve:

- exact line counts when the whole file fits in the sampled tail window
- extrapolated line counts when only a tail sample is available
- a monotonic guard so the displayed total line count never moves backwards just because a later tail sample has longer lines

## Session-stable storage location

Task output files live under a project-scoped temporary area that is also session-scoped.

Important invariants:

- the session identifier must be captured the first time the task-output directory is computed
- later session-ID resets must not move already-running tasks onto a new directory
- the location should remain inside an internally readable harness directory so later file reads do not require fresh approval

That captured-path rule is load-bearing for `/clear`-style flows that regenerate session identity while background work survives.

## Disk writer contract

The disk writer exists to protect memory as much as to persist bytes.

Equivalent behavior should preserve:

- a single-drain queue rather than a long promise chain that keeps old chunks alive
- conversion of queued strings into one buffer batch before append so the queue can be garbage-collected immediately
- a shared multi-gigabyte hard cap that prevents unbounded disk growth
- a clear truncation marker once the cap is exceeded
- secure file creation that resists symlink-following attacks where the host platform supports it

If the platform cannot create the exact secure symlink/file primitive, the runtime should degrade safely rather than hanging the whole task-output pipeline.

## Readback semantics

Reading output later should be bounded and mode-aware.

Equivalent behavior should support:

- bounded prefix reads for immediate tool results
- bounded tail reads for task-detail inspection
- delta reads from a byte offset for polling and attachment generation
- cheap size checks without loading the file into memory

If a file-backed output disappears unexpectedly, the system should surface a diagnostic readback marker rather than silently returning empty output and pretending nothing happened.

## Overflow behavior

Pipe-mode overflow should not lose all operator visibility.

The durable contract is:

- keep recent visible lines even after spilling to disk
- tell readers that the displayed output is truncated
- include the canonical output path so a later task-output read can recover the rest

## Symlink-backed outputs

Some task types reuse an existing transcript or log file instead of writing a fresh task-output file.

Equivalent behavior should allow the task-output path to become a symlink to a live transcript, but if symlink setup fails the runtime should fall back to a normal owned output file instead of abandoning task visibility.

## Cleanup and retention

In-memory output writers should be evicted once their task finishes and flushing is complete, but the persisted file should remain available until explicit cleanup.

That split is important because task memory pressure and task inspectability are different concerns.

## Failure modes

- **session drift**: a regenerated session ID strands a still-running task behind a new output directory
- **memory balloon**: queued output chunks remain captured in long-lived promise chains
- **empty-read lie**: a missing output file is reported as empty success instead of as a broken readback
- **poller explosion**: every task creates its own timer instead of sharing one visibility-driven poller
- **symlink escape**: insecure output-file creation lets a sandboxed process redirect host writes to arbitrary files

## Test Design

In the observed source, task behavior is verified through lifecycle regressions, registry-backed integration tests, and concurrency-sensitive foreground or background scenarios.

Equivalent coverage should prove:

- state transitions for launch, running, streaming, cancellation, completion, and failure remain deterministic and resettable between cases
- task registries, monitor families, shared-control events, and persisted output compose correctly across main-session and worker contexts
- users can still observe, foreground, stop, and inspect task output through the same surfaces they use in normal interactive or automated runs
