---
title: "API Request Assembly, Retry, and Prompt-Cache Stability"
owners: []
soft_links: [/runtime-orchestration/turn-flow/query-loop.md, /runtime-orchestration/turn-flow/query-recovery-and-continuation.md, /tools-and-permissions/tool-catalog/deferred-tool-discovery-and-tool-search.md, /memory-and-context/tool-result-microcompaction-and-cache-editing.md, /platform-services/claude-ai-limits-and-extra-usage-state.md, /runtime-orchestration/automation/prompt-suggestion-and-speculation.md, /memory-and-context/context-cache-and-invalidation.md]
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

## Tool-schema bytes must stay stable for shared-prefix requests

Equivalent behavior should preserve:

- one stable rendered schema shape for each effective tool body within a
  session or shared-prefix request lineage
- embedded JSON schema differences being treated as true schema differences even
  when the visible tool name stays the same
- request-time fields such as `defer_loading` and cache markers behaving like
  overlays on top of that stable base shape instead of causing unrelated byte
  churn
- building the final API tool array only after that stable base plus
  per-request overlay layering is complete

This is part of prompt-cache correctness, not just a performance optimization:
identical turns must serialize to identical tool-schema bytes.

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

## Stable system-prompt segmentation and one-marker cache writes

Equivalent behavior should preserve:

- system-prompt assembly splitting into a small fixed set of semantic blocks:
  attribution, CLI prefix, cache-stable core content, and any dynamic suffix
- global-scope system caching being used only when the request has no
  user-specific MCP tool section that would poison a shared cache prefix
- falling back to organization-scoped system caching when user-specific tool
  sections must render
- exactly one message-level cache marker in a given request
- fire-and-forget helper forks that skip cache writes moving that one marker
  back to the last shared-prefix message instead of leaving the fork's private
  tail in the cache
- cache-edit deletion inserts and cache-reference blocks being positioned
  relative to that single marker so the provider can delete or reuse the right
  prefix safely

The rebuild target is not simply "use prompt caching." It is one precise marker
strategy that preserves reuse without polluting the cache with disposable fork
tails.

## Cache-safe helper forks must reuse the parent request shape

Equivalent behavior should preserve:

- post-turn helpers such as prompt suggestion, speculation, side questions, or
  memory extractors reusing a saved cache-safe envelope from the parent turn
- that saved envelope carrying the parent system prompt, user context, system
  context, effective tool set, model, live transcript prefix, and inherited
  thinking posture
- helper forks being free to change only client-side controls such as abort
  handles, transcript suppression, permission callbacks, or cache-write
  suppression when they want to preserve cache sharing
- helper forks avoiding request-shape changes such as different effort,
  max-output ceilings, tools, or thinking posture when cache reuse is the goal

These helper paths are deliberately parasitic on the parent cache prefix. If a
rebuild treats them as ordinary side queries with their own request shape, they
become much more expensive and change parent-session cache behavior.

## Cache-break diagnostics distinguish expected resets from real drift

Equivalent behavior should preserve diagnostics that can separate:

- prompt or tool-byte changes
- model changes
- beta or extra-body changes
- effective effort changes
- global cache strategy changes
- expected cache-read drops after cache-edit deletions
- expected baseline resets after compaction
- likely 5-minute or 1-hour TTL expiry when the prompt stayed unchanged
- likely server-side eviction or routing disagreement when the prompt stayed
  unchanged and the gap remained below TTL

The goal is not just "did the cache miss?" but "was that miss caused by client
drift, an intentional reset, ordinary TTL expiry, or likely provider-side
behavior?"

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
- preserving the same logical request shape and usage-accounting contract across
  the fallback path instead of treating fallback as an unrelated side query
- explicit stream cleanup, including canceling response bodies, so native buffers do not leak after aborted or failed requests

Without this, long-lived sessions either wedge during backend trouble or leak memory over time.

## Failure modes

- **cache-key drift**: semantically identical turns produce different header or beta sets and lose prompt reuse
- **fork-tail pollution**: fire-and-forget helper forks mark their private tail
  as cacheable and contaminate the shared foreground prefix
- **tool-set desync**: discovered deferred tools are available in transcript history but missing from the actual request schemas
- **model-switch breakage**: unsupported search or advisor artifacts survive a model change and trigger request rejection
- **false cache alarms**: compaction or cache-edit deletions are reported as
  accidental prompt drift instead of expected baseline resets
- **retry amplification**: background or auxiliary calls retry aggressively during overload and worsen service pressure
- **fallback resource leaks**: failed streaming attempts keep sockets or native buffers alive after recovery

## Test Design

In the observed source, turn-flow behavior is verified through a mix of deterministic module tests, resume-sensitive integration coverage, and CLI-visible end-to-end scenarios.

Equivalent coverage should prove:

- pre-query mutation, continuation branches, and typed terminal outcomes stay stable under test posture
- tool results, compaction, queued-command replay, and transcript persistence still compose correctly inside one logical turn
- interactive and structured-I/O paths surface the same visible outcome when interruption, permission denial, or recovery branches occur
