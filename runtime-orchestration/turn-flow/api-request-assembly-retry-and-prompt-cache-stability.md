---
title: "API Request Assembly, Retry, and Prompt-Cache Stability"
owners: []
soft_links: [/runtime-orchestration/turn-flow/query-loop.md, /runtime-orchestration/turn-flow/query-recovery-and-continuation.md, /tools-and-permissions/tool-catalog/deferred-tool-discovery-and-tool-search.md, /memory-and-context/tool-result-microcompaction-and-cache-editing.md, /platform-services/claude-ai-limits-and-extra-usage-state.md]
---

# API Request Assembly, Retry, and Prompt-Cache Stability

Claude Code's model call path is not "messages plus tools." It is a cache-sensitive request builder with provider-specific headers, dynamic tool filtering, and multiple retry or fallback branches.

## Pre-request tool and feature gating

Equivalent behavior should preserve one request-time assembly pass that decides all of these together:

- which beta or extra-body feature flags are active for the selected model and query source
- whether advisor-style server tools are eligible for this turn
- whether deferred-tool search is enabled for this exact request
- whether prompt caching can use a global system-prompt scope or must avoid cache markers because user-specific tool sections will render

These decisions cannot be split across unrelated helpers without risking cache-key drift.

## Dynamic tool filtering

When deferred-tool search is enabled, the runtime should not send the full deferred tool pool on every request.

It should instead:

- keep non-deferred tools always available
- keep the search tool itself available so more deferred tools can be discovered later
- include a deferred tool only after that tool has already been discovered from prior transcript state
- keep tool search alive when MCP servers are still connecting, even if no deferred tools are currently available

This is the contract that lets the product scale to large MCP tool inventories without exploding prompt size.

## Schema building versus transcript visibility

Tool-schema rendering and transcript normalization are related but not identical.

Equivalent behavior should preserve:

- building API schemas from the filtered tool set
- still letting the search-tool prompt describe the broader deferred pool when needed
- stripping search-specific artifacts such as `tool_reference` blocks or tool-call metadata fields when the newly selected model cannot handle them
- repairing orphaned tool-use and tool-result pairs before sending a resumed or teleported transcript back to the API

Model switches must not leave old request-only content in the transcript and trigger avoidable 400s.

## Synthetic context and normalization order

Equivalent behavior should preserve a stable ordering:

1. normalize transcript messages
2. repair invalid tool pairing
3. strip feature-gated content that the chosen request cannot legally send
4. trim excess media to the provider limit
5. compute any attribution fingerprint from the actual user-visible transcript
6. only then inject synthetic helper context such as deferred-tool summaries or late-bound tool instructions

That ordering matters because some synthetic helper blocks are intentionally excluded from attribution and cache-break analysis.

## Prompt-cache stability rules

Prompt-cache behavior is guarded by several stability rules:

- cache-key tracking must consider system prompt, rendered tool schemas, model, fast-mode posture, cache strategy, beta headers, effort level, and extra-body params
- deferred tools sent only through `defer_loading` must be excluded from schema-hash comparisons because they are not part of the effective cached prompt
- expected cache-read drops caused by cache-edit deletions must not be misclassified as accidental cache breaks
- overage-state changes must be observable for diagnostics without forcing a mid-session TTL flip that would blow away a large cached prefix

The product does not just detect cache breaks. It also explains whether they came from prompt changes, beta/header changes, model changes, cache-scope changes, or likely server-side eviction.

## Sticky header latches

Several dynamic features are intentionally sticky within a session once first used.

Equivalent behavior should preserve latching for cache-sensitive request modifiers such as:

- auto or away-mode style headers
- fast-mode headers
- cache-editing headers
- stale-context or thinking-clear markers

Once latched on, they remain on until an explicit cache-resetting operation such as session clear or compaction. This prevents a mid-session toggle from changing the server-side cache key and destroying a large reusable prefix.

## Provider-specific request assembly

The request builder must preserve provider-specific behavior, including:

- some betas being transmitted as standard beta headers on first-party style providers
- some providers requiring the same capability to move into extra-body fields instead
- structured-output configuration merging into the same output config object used by effort and task-budget controls
- model experiments such as enlarged context windows being injected late, at the concrete request layer, not only at startup

The rebuild target is semantic parity, not one universal HTTP payload shape.

## Retry context and adaptive output budget

Equivalent behavior should preserve a retry context that can modify later attempts without mutating the original turn definition.

It needs to support at least:

- reducing max output tokens after context-overflow failures while preserving a floor for useful output
- preserving any required thinking budget when output ceilings are reduced
- switching from a primary model to a configured fallback model after repeated overload errors
- retrying with a refreshed client after auth failures, revoked tokens, or stale keep-alive sockets

This retry context is part of the runtime contract, not just transport plumbing.

## Fast-mode fallback and persistent retry

Fast mode has its own recovery logic.

Equivalent behavior should preserve:

- short 429 or 529 retry-after windows keeping fast mode active to preserve cache reuse
- long or unknown retry-after windows entering a cooldown and retrying at standard speed
- permanent fast-mode disablement when the backend proves the feature is unavailable for the account or current overage posture
- non-foreground query sources refusing to amplify overload cascades with repeated retries
- optional persistent retry mode chunking long waits into heartbeat-style progress so unattended sessions do not appear dead

## Streaming versus bounded non-stream fallback

The runtime should prefer streaming, but it also needs a bounded fallback path.

Equivalent behavior should preserve:

- a non-streaming fallback with its own timeout ceiling
- carrying forward overload-attempt accounting so streaming plus fallback do not silently double the allowed retry budget
- explicit stream cleanup, including canceling response bodies, so native buffers do not leak after aborted or failed requests

Without this, long-lived sessions either wedge during backend trouble or leak memory over time.

## Failure modes

- **cache-key drift**: semantically identical turns produce different header or beta sets and lose prompt reuse
- **tool-set desync**: discovered deferred tools are available in transcript history but missing from the actual request schemas
- **model-switch breakage**: unsupported search or advisor artifacts survive a model change and trigger request rejection
- **retry amplification**: background or auxiliary calls retry aggressively during overload and worsen service pressure
- **fallback resource leaks**: failed streaming attempts keep sockets or native buffers alive after recovery
