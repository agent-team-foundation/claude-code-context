---
title: "Rebuild Phasing"
owners: []
soft_links: [/reconstruction-guardrails/rebuild-standard.md, /product-surface/end-to-end-scenario-graphs.md]
---

# Rebuild Phasing

This node answers the practical clean-room question: if another team starts from zero, what should they build first, what can wait, and which capabilities only make sense as a bundle?

## Phase 1: Minimal core loop

Build first:

- startup and settings bootstrap
- interactive session shell
- message and transcript model
- query loop with streaming output
- core tool registry
- basic permission context
- filesystem, search, and shell tool families

These must ship together:

- query loop + tool registry + permission model
- context bootstrap + working-directory awareness
- basic UI feedback for progress and errors

Without this bundle, you do not yet have a real Claude Code equivalent.

## Phase 2: Durable local workflow

Build next:

- command families over the core loop
- session persistence and local resume
- manual and automatic compaction
- task model for background work
- review path in its local form

These should ship together:

- resume + transcript persistence + state restoration
- compaction + post-compact rehydration

This phase turns the system from a short-lived assistant into a usable daily coding agent.

## Phase 3: Extension envelope

Build after local durability:

- skills
- MCP integration
- plugin loading and trust model
- client-surface narrowing rules

Recommended order:

1. skills
2. MCP
3. plugins

Reason:
skills shape behavior with lower operational risk; MCP adds live protocol integration; plugins add the heaviest discovery, trust, and lifecycle complexity.

## Phase 4: Multi-surface and remote capability

Build later, once the local product is stable:

- remote session creation and resume
- teleport or handoff flows
- bridge or companion-client control
- remote review or planning paths

These must ship together:

- remote session contract + auth/policy checks
- reconnect and recovery behavior
- branch or repo reconciliation on return

Do not build remote execution before local resume and compaction are trustworthy, or debugging state drift becomes much harder.

## Phase 5: Advanced differentiation

Can come later:

- richer review variants
- deeper multi-agent orchestration
- enterprise policy nuance
- usage or billing overlays
- voice, browser, and other specialized surfaces

## Decision rule

If a capability changes the session state machine, it belongs earlier.
If a capability mostly adds optional surfaces or integrations to an already-stable state machine, it can come later.
