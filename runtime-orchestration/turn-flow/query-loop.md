---
title: "Query Loop"
owners: []
soft_links: [/runtime-orchestration/turn-flow/turn-assembly-and-recovery.md, /runtime-orchestration/turn-flow/structured-output-enforcement-and-artifact-projection.md, /runtime-orchestration/turn-flow/unified-command-queue-and-drain.md, /memory-and-context/memory-layers.md, /tools-and-permissions/tool-catalog/tool-families.md, /integrations/clients/sdk-control-protocol.md]
---

# Query Loop

Claude Code's main loop is not "send prompt, get answer." One user turn becomes a streaming control loop that can preprocess slash input, persist state, call the model multiple times, run tools, recover from context failures, and still return one coherent terminal outcome.

## Scope boundary

This leaf covers the turn-time control loop itself:

- pre-query input processing and early turn bookkeeping
- one live assistant trajectory across streaming, tools, and continuation
- recursive recovery branches inside the same turn
- the terminal result taxonomy exposed to SDK and headless callers

It does not re-document:

- exact request assembly and retry headers already covered in [api-request-assembly-retry-and-prompt-cache-stability.md](api-request-assembly-retry-and-prompt-cache-stability.md)
- post-tool attachment drains and side channels already covered in [turn-attachments-and-sidechannels.md](turn-attachments-and-sidechannels.md)
- queue priority and replay mechanics already covered in [unified-command-queue-and-drain.md](unified-command-queue-and-drain.md)

## Pre-query entry is part of the turn contract

Equivalent behavior should preserve that a user turn can do meaningful work before the first assistant token arrives.

That includes:

- processing prompt input through slash-command and local-command machinery that may mutate the message store, emit local command output, narrow allowed tools, or decide that no model query is needed
- deriving the system prompt and user/system context after those mutations, not from a stale pre-command snapshot
- starting the logical turn with typed bookkeeping such as request-start emission, query-chain identity, and SDK-visible denial accumulation before any tool or model output is finalized
- persisting normalized turn state early enough that resume, replay, and headless clients do not lose the turn boundary when the query later fails or recovers

The clean-room requirement is that "start of turn" is earlier than "first assistant text."

## One assistant trajectory can span multiple model requests

Equivalent behavior should preserve one logical assistant trajectory even when the loop re-enters the model.

Important invariants:

- every iteration begins with one request-start marker, then reuses the same turn state rather than starting a new session-level conversation
- the loop may rewrite the queryable history before each request through tool-result budgeting, snip-style reduction, microcompaction, or collapse projection
- assistant streaming, tool execution, post-tool summaries, and queued follow-up commands all stay inside the same turn controller
- tool calls do not terminate the turn; they append results and continue the same trajectory
- if the assistant emitted a tool call, the loop must eventually provide a matching real or synthetic tool result instead of leaving the transcript structurally incomplete

This is why a rebuild cannot model tools as a sidecar detached from the streaming assistant path.

## Recovery branches are recursive, not exceptional exits

Equivalent behavior should preserve recovery as ordinary loop behavior.

That means:

- autocompact, reactive compact, max-output-token recovery, and other context-pressure branches can rewrite history and continue the same turn
- transient API failure paths may withhold intermediate errors until the recovery ladder decides whether continuation is still possible
- queued command replay and post-tool drains happen after recovery-aware state updates, so later iterations see the corrected message store
- query-chain identity and depth continue across these retries, making analytics and downstream observers treat them as one branched turn rather than unrelated calls

The load-bearing rule is that compaction and continuation are part of the turn, not a restart after failure.

## Terminal results are typed and product-visible

Equivalent behavior should preserve a small explicit set of terminal outcomes rather than one generic success/failure blob.

A correct rebuild should distinguish at least:

- normal completion with the final assistant/result payload
- reaching `maxTurns`, including the special case where the limit is crossed during an abort path rather than ordinary completion
- reaching a configured budget ceiling for the turn
- structured-output exhaustion where repeated retries still fail to satisfy the requested schema
- user interruption, unrecoverable permission/tool failure, or unrecoverable API failure

Structured-output exhaustion matters especially because some headless requests can complete through a hidden structured-output artifact even when little or no user-facing assistant text was produced.

These terminals matter because SDK and headless callers react differently to them, and some of them are surfaced as explicit user-facing errors instead of silent loop shutdown.

## Failure modes

- **pre-query blind spot**: slash processing or local command output is treated as outside the turn and disappears from persistence or replay
- **trajectory split**: tool continuations, retries, or compaction branches are modeled as unrelated requests and break provenance
- **orphaned tool call**: a streamed tool use never receives a matching result after interruption or recovery
- **leaked intermediate error**: a recoverable max-output/context failure is exposed as terminal before the recovery ladder finishes
- **terminal collapse**: max-turn, max-budget, structured-output exhaustion, and generic failure all become one indistinguishable error path
