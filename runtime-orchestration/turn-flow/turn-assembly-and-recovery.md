---
title: "Turn Assembly and Recovery"
owners: []
soft_links: [/memory-and-context/context-bootstrap.md, /tools-and-permissions/tool-catalog/tool-pool-assembly.md, /memory-and-context/compact-path.md, /runtime-orchestration/turn-flow/advisor-and-thinking-lifecycle.md]
---

# Turn Assembly and Recovery

One user turn in Claude Code is a long-lived envelope, not a single model request. Commands, context assembly, streaming, tool execution, recovery, and persistence all belong to the same unit of work.

## Turn stages

1. **Input normalization**  
   The runtime resolves user text, queued command effects, attachments, and any pre-turn transformations that should become part of the request.
2. **Context assembly**  
   System context, user context, memory attachments, and session-scoped runtime state are gathered and cached where appropriate.
3. **Turn configuration**  
   The runtime resolves model choice, thinking behavior, output budget, task budget, tool pool, and continuation limits.
4. **Streaming request**  
   Assistant output arrives incrementally rather than only at completion.
5. **Tool batch execution**  
   Tool calls are partitioned into concurrency-safe batches and serial batches, then executed without breaking turn continuity.
6. **Result integration**  
   Tool results, stop-hook outputs, summaries, and state mutations are folded back into the same conversation trajectory.
7. **Recovery branch**  
   The runtime may compact, continue after output-budget pressure, retry on recoverable failures, or repair missing tool-result edges.
8. **Persistence and flush**  
   Usage, transcript state, file history, and session storage are updated so resume and analytics paths can explain what happened.

The critical property is loopability. Stages 4 through 7 may repeat several times before the user sees one turn as complete.

## Recovery expectations

Recovery is not exceptional glue. It is part of the main design.

Important recovery classes:

- context-pressure recovery through compaction or micro-compaction
- output-budget continuation when a useful response can continue safely
- fallback model or retry behavior on recoverable API failures
- interruption handling that still produces coherent tool-result state
- stop-hook and post-tool cleanup that may alter the next request envelope

If a rebuild treats these as side paths instead of first-class turn states, long sessions will drift or break.

## State that must survive inside the turn

- mutable message history for the active conversation trajectory
- the current tool-use context, including permission posture and in-progress tool IDs
- file-read and file-history caches that prevent unstable re-reads
- budget counters, usage totals, and continuation counts
- discovered skills, memory attachments, or other turn-scoped enrichments

This is why a standalone request-response API is not enough to reproduce the product.

## Failure modes

- **half-integrated tool work**: a tool runs, but its result does not land back in the active trajectory
- **recovery without provenance**: compaction or continuation happens, but later resume or analytics cannot explain it
- **state loss across retries**: a retry drops discovered context, permission state, or prior tool effects
- **false concurrency**: mutating tools run in parallel and corrupt session state
- **flush skew**: the UI shows a finished turn, but persisted session artifacts lag behind

## Test Design

In the observed source, turn-flow behavior is verified through a mix of deterministic module tests, resume-sensitive integration coverage, and CLI-visible end-to-end scenarios.

Equivalent coverage should prove:

- pre-query mutation, continuation branches, and typed terminal outcomes stay stable under test posture
- tool results, compaction, queued-command replay, and transcript persistence still compose correctly inside one logical turn
- interactive and structured-I/O paths surface the same visible outcome when interruption, permission denial, or recovery branches occur
