---
title: "Deferred Tool Discovery and Tool Search"
owners: []
soft_links: [/tools-and-permissions/tool-catalog/tool-pool-assembly.md, /tools-and-permissions/execution-and-hooks/tool-execution-state-machine.md, /runtime-orchestration/turn-flow/api-request-assembly-retry-and-prompt-cache-stability.md, /memory-and-context/compaction-execution-and-post-compact-rehydration.md, /integrations/mcp/config-layering-policy-and-dedup.md]
---

# Deferred Tool Discovery and Tool Search

Claude Code does not treat the tool catalog as a permanently inlined prompt appendix. Large or user-specific tool pools can be deferred, searched, and activated incrementally.

## Activation modes and gating

Equivalent behavior should preserve three practical modes:

- standard mode, where all tools are sent inline
- always-on deferred search mode
- auto mode, where deferred search turns on only when deferred tool descriptions exceed a model-relative threshold

The definitive request-time gate must check all of these together:

- whether the selected model supports `tool_reference` style discovery
- whether the search tool itself is actually available in the current tool pool
- whether auto-threshold evaluation says deferral is worth the prompt savings

Auto mode should prefer an exact token-count calculation and fall back to a character heuristic only when that exact count is unavailable.

## Optimistic versus definitive gating

Some call sites do not know the final model yet but still need to preserve compatibility.

Equivalent behavior should therefore preserve an optimistic check that answers:

- keep the search tool visible if deferred search might still be enabled later
- preserve `tool_reference` blocks in intermediate processing unless the feature is definitively off
- avoid falsely disabling deferred-tool flows for third-party proxies that can pass the feature through

This optimistic path prevents the product from destroying discovery state too early.

## Deferred pool semantics

Deferred tools are not just "hidden until needed." They change the shape of future requests.

Equivalent behavior should preserve:

- deferred tools being rendered with `defer_loading` semantics rather than full inline schemas
- non-deferred tools remaining always available
- search staying active when MCP servers are still connecting, even if the current deferred pool is empty
- certain heavy tool families, not just MCP tools, being eligible for the same deferral behavior

## Discovery state reconstruction

The runtime must be able to reconstruct which deferred tools the model has already discovered.

Equivalent behavior should preserve discovery-state extraction from:

- search-tool results that return `tool_reference` blocks
- compact-boundary metadata that carries the discovered set across transcript compaction
- preserved tool-reference-bearing messages or equivalent metadata during transcript snip and partial compaction

This is the bridge between initial discovery and later direct tool calls.

## Search-tool semantics

The search tool is not a fuzzy text toy. It is a control surface for loading schemas.

Equivalent behavior should preserve:

- direct `select:<tool>` style loading, including multiple comma-separated selections
- exact-name matches without requiring the explicit prefix, so the model can recover after compaction or partial memory loss
- server-prefix matching for MCP-style names
- keyword search over structured tool-name parts, curated search hints, and descriptions
- required-term matching for `+term` style queries
- pending-server hints when no match exists yet because integrations are still connecting

Successful results should return tool references, not full schema copies.

## Pool-change announcement

When the deferred pool changes mid-session, the model needs a delta, not a full re-announcement every turn.

Equivalent behavior should preserve:

- one diff pass between the current deferred pool and the already announced pool
- persisted delta attachments when that feature is enabled
- fallback to an ephemeral available-deferred-tools summary when persisted deltas are disabled
- silent handling for tools that stop being deferred but remain directly available, so the model is not incorrectly told they disappeared

## Dispatch-time recovery hint

Deferred discovery can fail late: the model may try to call a deferred tool whose schema was never actually loaded.

Equivalent behavior should preserve a dispatch-time hint path that:

- detects when typed input validation failed for a deferred tool
- rechecks whether the tool was in the discovered-tool set
- tells the model to load the tool first through the search tool, then retry

This is important because the raw validation error does not explain the real cause.

## Failure modes

- **false disablement**: optimistic gating removes discovery artifacts for providers or models that could have handled them
- **lost discovery state**: compaction or replay forgets which deferred tools were already loaded
- **pool spam**: every pool change re-announces the whole deferred catalog and destroys cache stability
- **schema-not-sent confusion**: deferred-tool validation errors look like ordinary type mistakes and do not teach the model to reload the schema
- **connecting-server blind spot**: search reports "nothing found" without explaining that the relevant integration is still connecting

## Test Design

In the observed source, tool-catalog behavior is verified through deterministic assembly regressions, cache-aware integration coverage, and availability-oriented surface checks.

Equivalent coverage should prove:

- discovery, precedence, filtering, and ordering logic preserve the catalog contracts described in this leaf
- deferred loading, refresh, and contributions from built-ins, agents, plugins, and MCP sources behave correctly with resettable caches and registries
- visible tool availability and ordering stay stable enough for prompt caching, search, and client expectations to remain consistent across sessions
