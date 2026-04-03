---
title: "Query Recovery and Continuation"
owners: []
soft_links: [/runtime-orchestration/turn-assembly-and-recovery.md, /memory-and-context/compact-path.md, /tools-and-permissions/tool-batching-and-streaming-execution.md]
---

# Query Recovery and Continuation

The query loop treats recovery as part of the normal turn contract. A rebuild cannot model retries, compaction, and continuation as side jobs after the "real" request, because the same turn state is deliberately threaded through all of them.

## Cross-iteration state

One active turn must carry mutable state across recursive iterations, including:

- the full live message trajectory after the most recent compact boundary
- the current tool-use context, including in-progress tool IDs and permission posture
- auto-compact tracking for the current post-compact era
- a one-shot guard for reactive compaction
- output-limit recovery counters and any temporary output-token override
- the pending tool-use summary promise for the next iteration
- whether the previous iteration was already inside a stop-hook retry
- the current turn count
- the reason the previous iteration continued

That last field is not just for observability. Several recovery branches are intentionally single-shot and use the previous transition reason to avoid loops.

## Pre-request pressure handling order

Before each model call, context pressure is reduced in a fixed order:

1. apply per-message storage budgets to oversized tool results
2. optionally snip old history
3. run micro-compaction
4. project and commit any staged context-collapse work
5. run full auto-compaction if still needed

This order matters. Fine-grained reductions happen before summary-based reductions so the runtime preserves as much recoverable detail as possible.

## Budget carry-forward across compaction

Turn-level task budgets cannot simply restart after compaction.

When compaction happens, the runtime captures the final pre-compact context window and subtracts that from the remaining task budget before retrying. Otherwise the server would only see the compacted summary and undercount work that already consumed budget.

## Streaming-time withholding

Some API failures are intentionally withheld from the outward stream while recovery is attempted.

Equivalent behavior should withhold, but still retain in internal assistant history:

- prompt-too-long failures
- recoverable media-size failures
- output truncation caused by the model hitting its output-token cap

This prevents host clients from prematurely ending the session while the loop is still capable of recovering.

## Fallback retry semantics

Model fallback is still part of the same turn.

If the runtime switches to a fallback model mid-turn, it should:

- discard partial tool execution from the failed attempt
- repair any already-emitted tool calls with synthetic error results so the transcript stays balanced
- reset streaming tool execution state
- retry the same request on the fallback model
- strip any model-bound protected-thinking payloads that would be invalid on the new model

The key invariant is continuity without leaking orphan tool results from the abandoned attempt.

## Post-stream recovery order

When streaming ends without a new tool phase, recovery proceeds in a strict sequence.

### Prompt-too-long and media recovery

If the last assistant message represents a recoverable context or media overflow:

1. drain staged context-collapse work once, if that path is enabled and has not already been tried
2. if overflow remains, attempt one reactive compact-and-retry pass
3. if recovery fails, surface the withheld error and stop

Prompt overflow prefers collapse draining before full reactive compaction because collapse preserves more structure than a wholesale summary.

### Output-cap recovery

Output truncation follows a different ladder:

1. if the request used the default capped output limit, retry the same request once with an escalated cap
2. if truncation happens again, append a meta continuation nudge and recurse
3. allow at most 3 continuation nudges in one turn
4. if truncation still persists, surface the withheld error

The continuation nudge must tell the model to resume directly from the interruption point rather than recap or apologize.

### Stop-hook and budget continuations

After recoverable API errors are exhausted or absent:

- blocking stop-hook output can append structured blocking messages and recurse
- token-budget logic can append a continuation nudge and recurse when the turn is still making progress
- both of these branches must preserve the live trajectory rather than starting a fresh turn

Stop-hook retries must not reset the reactive-compaction guard, or prompt-overflow failures can spin forever.

## API-error handling boundary

Ordinary stop hooks should not run on raw API-error messages.

If the model never produced a valid assistant response, the runtime should skip normal stop-hook evaluation and only run failure-cleanup hooks. Otherwise the system can spiral by adding more blocking text to an already-overfull turn.

## Failure modes

- **recovery leakage**: a recoverable error is surfaced before the loop finishes attempting recovery
- **budget reset drift**: compaction causes task-budget accounting to forget already-spent context
- **retry loops**: collapse, reactive compact, or stop-hook branches re-enter without a one-shot guard
- **fallback corruption**: a model fallback leaves behind tool results tied to abandoned tool IDs
- **continuation recap drift**: output-limit recovery restarts the answer instead of continuing the same thought
