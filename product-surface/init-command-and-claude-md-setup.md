---
title: "Init Command and CLAUDE.md Setup"
owners: []
soft_links: [/product-surface/command-dispatch-and-composition.md, /memory-and-context/instruction-sources-and-precedence.md, /ui-and-experience/startup-and-onboarding/startup-welcome-dashboard-and-feed-rotation.md, /ui-and-experience/startup-and-onboarding/interactive-setup-and-onboarding-screens.md]
---

# Init Command and CLAUDE.md Setup

`/init` is a prompt-command entrypoint for bootstrapping repository instructions. It does not directly write files as local command logic; it injects a guided setup contract into the model loop.

## Command-surface contract

The init command is dynamically described and selected between two instruction regimes:

- legacy: focused CLAUDE.md generation/refinement
- new flow: staged setup for project/personal instruction files plus optional skills/hooks

Selection is feature-gated and env-gated, but both variants preserve one invariant: invoking `/init` re-runs project-onboarding completion checks against the current workspace state, so the onboarding feed can clear once the workspace actually satisfies its enabled steps.

## New-flow behavioral shape

The expanded init flow is a multi-phase setup assistant, including:

- interactive scope selection (team-shared file, personal local file, or both)
- optional skill/hook setup preference capture
- codebase survey via delegated analysis
- targeted gap-filling questions for team or personal context
- proposal preview and user pruning before writing artifacts
- optional optimization suggestions after baseline setup

A clean-room rebuild should preserve this phase structure and artifact-choice discipline, not the exact wording.

## Instruction-file discovery and precedence

Setup quality depends on how instruction files are later loaded. Runtime loading behavior spans:

- managed/global instruction layers
- user-level instruction layers
- project-level CLAUDE files and rule directories discovered from root-to-cwd walk
- local personal CLAUDE.local files with higher priority near cwd

Nested worktree handling must avoid double-loading checked-in project instructions while still allowing private local files.

## Include and trust boundaries

Instruction files support include directives with guardrails:

- include expansion is recursive with cycle protection
- only text-like extensions are admitted
- external includes outside workspace scope require explicit trust/approval flow before regular loading

Interactive startup enforces workspace trust checks and include warnings independently of tool-permission mode, so instruction loading remains a separate security boundary.

## Cache invalidation and reload semantics

Instruction-file caches have two different invalidation paths:

- plain cache clear for correctness-only refreshes
- reset-with-reason for semantic reload events (for example post-compact reload), which also drives instruction-loaded hook reason reporting

Rebuilds that collapse these paths lose hook fidelity and produce misleading reload telemetry.

## Onboarding coupling

Project onboarding includes creating repository instructions as a first-class step, but it is not the same thing as the earlier pre-REPL onboarding/trust startup gate.

Equivalent behavior should preserve:

- a workspace-state-driven onboarding model where empty workspaces nudge project creation/clone, while non-empty workspaces nudge `/init`/`CLAUDE.md`
- `/init`, `/terminal-setup`, and real user-prompt submission each re-running the completion check rather than blindly flipping a completion bit
- the feed stopping only when the workspace's currently enabled onboarding steps are actually satisfied
- that workspace onboarding feed remaining distinct from the earlier pre-REPL setup screens described in [../ui-and-experience/startup-and-onboarding/interactive-setup-and-onboarding-screens.md](../ui-and-experience/startup-and-onboarding/interactive-setup-and-onboarding-screens.md)

## Failure modes

- **prompt-only drift**: `/init` treated as plain advice and not as a staged artifact workflow
- **precedence inversion**: local/project/user/managed instruction ordering loaded incorrectly
- **unsafe include loading**: external includes loaded before trust approval
- **worktree duplication**: same checked-in instructions loaded twice via nested worktree traversal
- **cache reason loss**: all memory-file invalidations treated as identical reload causes

## Test Design

In the observed source, product-surface behavior is verified through command-focused integration tests and CLI-visible end-to-end checks.

Equivalent coverage should prove:

- parsing, dispatch, flag composition, and mode selection preserve the public contract for this surface
- downstream runtime, tool, and session services receive the correct shaping when this surface is used from interactive and headless entrypoints
- user-visible output, exit behavior, and help or error routing remain correct through the packaged CLI path rather than only direct module calls
