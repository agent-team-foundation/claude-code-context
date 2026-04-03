---
title: "Tool Batching and Streaming Execution"
owners: []
soft_links: [/runtime-orchestration/query-loop.md, /tools-and-permissions/tool-execution-state-machine.md, /runtime-orchestration/state-machines-and-failures.md]
---

# Tool Batching and Streaming Execution

Claude Code does not wait for the full assistant message before deciding what to do with tools. It supports both streaming execution and a batch fallback, and both paths preserve the same transcript and state invariants.

## Shared execution contract

Regardless of executor style, every tool call should pass through the same stages:

- resolve the proposed tool against the active session tool pool
- validate input shape and semantic validity
- run pre-tool hooks that may rewrite input or stop execution
- evaluate permissions
- execute the tool while surfacing progress
- run post-tool hooks and integrate any context mutations
- emit a structured tool result that stays inside the same turn

Unknown tools, invalid input, and execution failures must become structured tool-result errors rather than uncaught runtime failures.

## Batch partitioning rules

When the runtime executes tools in batches, it does not simply run all read-like tools together.

The batching rule is:

- every non-concurrency-safe tool becomes its own serial batch
- only consecutive concurrency-safe tools are grouped into one concurrent batch

Concurrency safety is determined by a tool-specific predicate over parsed input. If parsing fails or the predicate throws, the tool must be treated as non-concurrent.

## Concurrent batch invariants

Concurrent batches still preserve deterministic state.

Important behavior:

- concurrent tools run with a bounded concurrency ceiling
- progress messages may appear as soon as each tool emits them
- context mutations from concurrent tools are not applied immediately
- instead, those mutations are queued and committed later in the original tool order

That last rule is essential. It allows parallel execution without letting read-mostly tools race to mutate session state unpredictably.

## Serial batch behavior

Serial tools mutate the live tool-use context immediately after each update.

This path is used for tools whose effects are order-sensitive, stateful, or otherwise unsafe to overlap with neighbors.

## Streaming executor behavior

The streaming executor starts tool work as tool calls arrive from the model stream.

Equivalent behavior should preserve these rules:

- concurrency-safe tools may overlap with other concurrency-safe tools already running
- exclusive tools wait until no other tool is executing
- progress is yielded immediately
- final results are still yielded in tool-arrival order
- queued tools can be discarded if the current streaming attempt is abandoned

This gives low-latency progress without sacrificing transcript determinism.

## Synthetic result repair

The executor must be able to synthesize tool results when normal execution cannot finish.

Important synthetic cases include:

- unknown tool names
- validation failures
- generic execution exceptions
- sibling-cancelled parallel tools
- user interruptions
- abandoned work from a discarded streaming attempt

The invariant is simple: if the assistant emitted a tool call, the transcript must eventually contain a matching tool result.

## Failure cascading

Parallel tool failure is selective rather than global.

Equivalent behavior should preserve these rules:

- shell failures can cancel sibling shell subprocesses because they often represent one dependent operation chain
- unrelated tool families do not automatically cancel each other on failure
- sibling cancellation should not abort the whole turn controller unless the cancellation reason truly belongs to the entire turn

This requires a child-abort mechanism for sibling tools, separate from the parent turn abort.

## Interrupt behavior

Tools do not all respond to interruption the same way.

A correct rebuild should support per-tool interrupt posture:

- cancelable tools stop when the user interrupts the turn
- blocking tools continue and keep the turn in a non-interruptible state until they settle

The UI's "can interrupt now" state therefore depends on the currently running tool mix, not just on whether any tool is active.

## Hook control plane

Tool execution also carries a hook-driven control plane.

Equivalent behavior should support:

- pre-tool hooks that rewrite input or stop execution
- permission-denied hooks that run after a rejection
- post-tool hooks that attach extra messages or request continuation stop

A hook-produced continuation-stop signal must be able to halt recursion after the tool phase even when tool execution itself succeeded.

## Relationship to background work

Some tools can choose not to hold the turn open and instead hand back a background task handle. That background lifecycle belongs to the task system, but the tool executor still must treat that handle as the tool's successful result inside the current turn.

## Failure modes

- **state race**: concurrent tools apply context mutations as soon as they finish and reorder session state
- **orphaned tool call**: a streamed tool_use never receives a tool_result after interruption or retry
- **global over-cancel**: one tool failure aborts unrelated work that should have continued
- **progress starvation**: long-running tools execute correctly but provide no mid-flight visibility
- **interrupt mismatch**: the UI advertises interruptibility even though a blocking tool is still running
