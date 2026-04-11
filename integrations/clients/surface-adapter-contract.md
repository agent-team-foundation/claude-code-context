---
title: "Surface Adapter Contract"
owners: []
soft_links: [/integrations/clients/sdk-control-protocol.md, /ui-and-experience/shell-and-input/terminal-ui.md, /collaboration-and-agents/remote-session-contract.md]
---

# Surface Adapter Contract

Claude Code should be reconstructed as one runtime with several adapters, not as unrelated products that happen to share a name.

## Shared core

Every surface must preserve the same underlying semantics for:

- session identity and resume
- command availability and command meaning
- tool availability and permission decisions
- task visibility and background-work lifecycle
- context, compaction, and recovery behavior
- model and capability envelopes after auth, policy, and feature gating

If one surface invents its own meaning for these concepts, the product will drift.

## Adapter responsibilities

Different clients can own different presentation and transport concerns:

- the interactive terminal can render dialogs, status rows, and rich streaming UX
- SDK or automation hosts can externalize permission prompts, interruptions, and lifecycle events as typed protocol messages
- IDE, desktop, mobile, browser, or companion surfaces can wrap the same runtime with their own launch, navigation, or approval affordances
- remote or managed clients can add environment selection, bootstrap checks, and enterprise overlays before the session becomes interactive

These are adapters around the runtime, not excuses to fork it.

## Required adapter behaviors

- surface bootstrap should tell the host what commands, tools, models, and capability limits are currently in effect
- permission prompts must stay semantically equivalent even when rendered outside the terminal
- lifecycle events should be typed and replayable enough that late-attaching hosts can still make sense of an active turn
- interruption, resume, and reconnect must preserve the same session identity instead of synthesizing a new conversation silently
- heavy UI code can be loaded lazily, but the runtime contract must remain available before those widgets load

The goal is semantic parity with presentation freedom.

## Boundary with remote execution

A surface adapter is not the same thing as a remote executor.

- a local client may still drive remote work
- a remote session may still be controlled by a local or companion client
- browser handoff, QR-style pairing, or direct-connect flows should preserve this distinction

This matters because transport location and execution location are related but separate choices.

## Failure modes

- **surface drift**: one client exposes stale command, tool, or permission semantics
- **host-side reinterpretation**: an SDK host changes the meaning of approval outcomes or lifecycle states
- **bootstrap opacity**: the user cannot tell which capabilities are active on the current surface
- **reconnect identity loss**: resume appears to work, but the surface is actually attached to a different logical session
- **presentation coupling**: the runtime cannot operate unless one specific terminal UI implementation is present

## Test Design

In the observed source, client-integration behavior is verified through adapter regressions, transport-aware integration tests, and public-surface end-to-end flows.

Equivalent coverage should prove:

- message shaping, history or state projection, and surface-specific envelope rules stay stable across the client contracts described here
- auth proxying, environment selection, reconnect, and remote-session coordination behave correctly at the real process or transport boundary
- packaged client entrypoints still expose the same visible behavior as direct source invocation, especially for structured I/O and remote viewers
