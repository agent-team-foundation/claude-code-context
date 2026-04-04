---
title: "Stop-Hook Orchestration and Turn-End Bookkeeping"
owners: []
soft_links: [/runtime-orchestration/query-loop.md, /runtime-orchestration/query-recovery-and-continuation.md, /memory-and-context/turn-end-auto-memory-extraction.md]
---

# Stop-Hook Orchestration and Turn-End Bookkeeping

Stop hooks are part of the turn state machine, not a postscript. End-of-turn bookkeeping runs around them and changes continuation behavior.

## Stop-hook entry boundary

Normal stop-hook evaluation runs only when the turn has no immediate tool follow-up and the final assistant message is a valid model response.

If the final assistant message is an API error, normal stop hooks are skipped and only StopFailure hooks run. This avoids retry spirals where hook-injected text worsens already-failed oversized/error turns.

## Pre-hook bookkeeping at turn end

Before evaluating stop hooks, the runtime may execute turn-end side work:

- persist cache-safe context snapshot for main-session query sources
- classify template-job status for dispatched-job sessions
- launch background prompt suggestion
- launch auto-memory extraction and auto-dream workflows (main agent only)
- perform computer-use lock/unhide cleanup for eligible sessions

These side paths are intentionally outside the blocking stop-hook decision loop.

## Stop-hook execution model

Stop hooks run through a shared hook executor and stream progress artifacts:

- progress messages identify hook invocations
- attachment messages carry hook outputs/errors
- blocking hook results are converted to hidden meta user messages
- optional `preventContinuation` responses produce structured stop attachments

After hooks complete, a summary system message aggregates count, durations, and errors for operator visibility.

## Continuation control outcomes

Stop-hook handling returns one of three outcomes:

- `preventContinuation`: stop immediately
- blocking errors: append meta user blocks and recurse one more turn
- clean pass: continue to token-budget or final completion checks

When recursing on blocking results, the loop carries forward stop-hook-active state and critical recovery guards so prompt-too-long/reactive-compact branches do not re-enter infinite loops.

## Teammate-only follow-up hooks

After normal stop hooks pass, teammate contexts run additional end-of-work hooks (task-completed and teammate-idle). They share the same blocking/preventContinuation contract and can veto idling.

## Abort and failure behavior

If abort is signaled during hook execution, hook orchestration yields interruption semantics and exits early.

If hook infrastructure itself fails, runtime emits a diagnostic warning message for users and returns non-blocking completion instead of failing the whole turn.

## Failure modes

- **api-error hook spiral**: stop hooks run on raw API error responses
- **continuation dead loop**: blocking-stop retries reset recovery guards and re-trigger forever
- **missed cleanup**: turn-end cleanup paths skipped on abort/error exits
- **subagent/main-thread lock corruption**: subagent cleanup mutates shared main-thread computer-use lock state
- **silent hook failure**: hook runtime errors disappear without user-visible diagnostics
