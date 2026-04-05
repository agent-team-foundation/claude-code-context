---
title: "Interactive Setup and Onboarding Screens"
owners: []
soft_links: [/ui-and-experience/startup-welcome-dashboard-and-feed-rotation.md, /ui-and-experience/terminal-setup-and-multiline-entry-affordances.md, /ui-and-experience/focused-dialog-and-overlay-arbitration.md, /platform-services/interactive-startup-and-project-activation.md, /platform-services/workspace-trust-dialog-and-persistence.md, /platform-services/auth-login-logout-and-token-lifecycle.md]
---

# Interactive Setup and Onboarding Screens

Claude Code has a concrete pre-REPL startup gate. Before the normal prompt loop is fully available, the product can run a first-run wizard, workspace-trust review, startup-only policy/security confirmations, account setup, and terminal-specific affordances. A faithful rebuild needs that staged startup gate, not just a welcome banner plus later slash commands.

## Scope boundary

This leaf covers:

- the first-run onboarding wizard before the main REPL is live
- the broader pre-REPL startup gate that includes trust and post-trust confirmations before ordinary prompt use
- startup-only setup surfaces that are distinct from later REPL dialog arbitration

It does not re-document:

- the post-REPL startup dashboard/feed surface
- steady-state REPL dialog arbitration or the later low-priority recommendation band once normal prompt usage is active
- the standalone `/terminal-setup` command internals beyond how onboarding enters that flow

## Top-level gating and persistence

Equivalent behavior should preserve:

- test/demo-style environments being able to suppress the startup gate entirely
- onboarding appearing at least once when the user has not completed first-run setup or still lacks a persisted theme choice
- onboarding completion writing durable first-run markers rather than relying only on process memory
- setup/trust screens being interactive-session behavior, not something automatically mirrored into bare headless paths

The clean-room requirement is that first-run setup is a real persisted lifecycle, not an ephemeral splash screen.

## First-run wizard versus broader startup gate

Equivalent behavior should preserve:

- the first-run onboarding wizard being only one possible prefix of startup, not the whole pre-REPL gate
- workspace trust still running afterward when needed, even if the first-run wizard did not show at all
- post-trust confirmations such as policy/privacy, custom API-key, dangerous-mode, auto-mode, dev-channel, or browser-specific startup screens still resolving before ordinary prompt use becomes available
- this startup-only gate not sharing the same arbitration lane as later REPL-only low-priority dialogs such as IDE onboarding, remote-control first use, plugin recommendations, or desktop upsell
- project onboarding in the welcome dashboard remaining a later workspace-nudge surface, not part of this pre-REPL gate

## Onboarding itself is a multi-step screen flow

Equivalent behavior should preserve an ordered onboarding sequence rather than one monolithic modal.

The load-bearing steps are:

- preflight checks when OAuth-capable auth is relevant
- theme selection as an explicit first-run choice
- optional custom API-key approval when a new key is already present in the environment
- OAuth/login setup unless that path was intentionally skipped by the approved API-key branch
- security notes before the user reaches the full tool-using product
- terminal setup as a final onboarding step when the current terminal benefits from it

This ordering matters because theme, auth, terminal affordances, and safety notes are not presented as unrelated tips.

## Trust is a separate boundary after onboarding

Equivalent behavior should preserve:

- workspace trust review always remaining distinct from tool-permission mode
- interactive trust/setup happening even when the user prefers permissive tool execution
- trust completion reinitializing trust-dependent services before later startup continues
- trust-time follow-up checks for pending project MCP approvals and external instruction includes before the main REPL becomes ordinary working state

The important product rule is that onboarding and workspace trust are adjacent, but not the same decision.

## Post-trust setup dialogs still belong to startup

Equivalent behavior should preserve that several setup screens can still appear after trust is accepted but before the session settles into normal use.

Important examples include:

- policy/privacy or enterprise gating dialogs
- custom API-key confirmation when relevant
- dangerous-mode confirmation for bypass-style execution
- first-time auto-mode opt-in when that mode is selected
- environment/channel confirmation flows
- first-time companion/browser/chrome onboarding flows that belong to startup rather than to the normal transcript

This is why a rebuild cannot treat "onboarding finished" as the single end of interactive setup.

## Terminal setup is both onboarding and a standalone capability

Equivalent behavior should preserve:

- terminal setup being callable later via `/terminal-setup`
- the same terminal setup capability also appearing as the final onboarding step when the host terminal needs it
- terminal setup completion feeding onboarding/tips state so first-run nudges can stop once multiline entry is genuinely available

## Failure modes

- **banner-only rebuild**: onboarding is collapsed into a welcome card and loses its actual step order
- **wizard/gate conflation**: first-run onboarding, trust, and later startup-only confirmations are flattened into one indistinct flow
- **trust conflation**: workspace trust is treated as just another permission prompt and appears at the wrong time
- **post-trust drift**: MCP/include/policy/auth startup dialogs are postponed until after ordinary prompt usage begins
- **terminal-setup orphaning**: onboarding shows terminal guidance but never reuses the real setup capability or completion flags
- **first-run amnesia**: onboarding completion is not persisted, so the user keeps seeing setup screens every launch
