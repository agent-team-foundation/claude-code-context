---
title: "Tool Pool Assembly"
owners: []
soft_links: [/integrations/mcp/connection-and-recovery-contract.md, /tools-and-permissions/permission-model.md, /runtime-orchestration/turn-assembly-and-recovery.md]
---

# Tool Pool Assembly

Claude Code does not expose every possible tool to every session. The runtime assembles a session-specific tool pool and makes that pool stable enough for prompting, UI rendering, and permission reasoning.

## Assembly layers

The tool pool should be built in layers:

1. **Exhaustive built-in catalog**  
   A source-of-truth list of built-in tools, including world-facing tools, control-plane tools, and conditionally compiled tools.
2. **Mode-specific shrinking**  
   Session modes such as simple mode, REPL mode, worktree mode, or coordinator mode can replace or hide primitive tools.
3. **Permission pre-filtering**  
   Blanket deny rules should remove tools before the model sees them, not only at call time.
4. **Enablement checks**  
   Environment, platform, feature, and dependency checks decide which built-ins are truly usable.
5. **Integration merge**  
   MCP tools and other dynamic tool sources are merged into the same pool.
6. **Stable ordering and deduplication**  
   Built-ins keep precedence, name collisions are resolved deterministically, and ordering stays cache-friendly.

This layered assembly is essential because "which tools exist" is part of the session contract.

## Important invariants

- built-in tools should win on name collisions with extension tools
- server-prefix deny rules must be able to remove an entire MCP namespace
- special helper tools may exist in the runtime without being exposed like ordinary user tools
- some surfaces need the merged tool set, while other logic only needs built-ins
- a rebuild should preserve the distinction between the exhaustive catalog and the currently exposed pool

The model should only see tools that are both semantically allowed and presently usable.

## Mode interactions

Tool exposure changes with runtime posture:

- simple or constrained modes may collapse the pool to a very small set of editing primitives
- REPL-style execution can hide primitive tools in favor of one wrapped execution tool
- background or delegated agents may get narrower tool sets than the main foreground session
- search, LSP, browser, scheduling, and other specialized tools can appear only when their substrate is present

The reconstruction lesson is that tool availability is contextual, not static product branding.

## Why ordering matters

Stable ordering is not cosmetic. It affects prompt caching, host-client expectations, and deterministic debugging.

A correct rebuild should keep:

- deterministic ordering across runs with the same inputs
- contiguous precedence for built-ins before merged extension tools
- deduplication by canonical tool identity, not merely by object instance

## Failure modes

- **overexposed pool**: the model sees tools that should have been removed by deny rules or mode narrowing
- **underexposed pool**: usable extension tools never reach the turn despite successful connection
- **cache churn**: equivalent tool pools reorder themselves and invalidate downstream caching
- **name collision leakage**: an extension silently shadows a built-in tool with different semantics
- **special-tool confusion**: internal helper tools leak into the ordinary user-facing tool set
