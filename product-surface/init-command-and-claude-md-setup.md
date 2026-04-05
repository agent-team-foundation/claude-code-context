---
title: "Init Command and CLAUDE.md Setup"
owners: []
soft_links: [/product-surface/command-dispatch-and-composition.md, /memory-and-context/instruction-sources-and-precedence.md, /ui-and-experience/startup-welcome-dashboard-and-feed-rotation.md, /ui-and-experience/interactive-setup-and-onboarding-screens.md]
---

# Init Command and CLAUDE.md Setup

`/init` is a prompt-command entrypoint for bootstrapping repository instructions. It does not directly write files as local command logic; it injects a guided setup contract into the model loop.

## Command-surface contract

The init command is dynamically described and selected between two instruction regimes:

- legacy: focused CLAUDE.md generation/refinement
- new flow: staged setup for project/personal instruction files plus optional skills/hooks

Selection is feature-gated and env-gated, but both variants preserve one invariant: invoking `/init` marks project-onboarding progress checks as completed when eligible.

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

Project onboarding includes creating repository instructions as a first-class step. `/init` and terminal setup both participate in onboarding-completion bookkeeping so the product can stop repeating setup nudges once the workspace is actually initialized. That onboarding feed is distinct from the earlier pre-REPL setup screens described in [../ui-and-experience/interactive-setup-and-onboarding-screens.md](../ui-and-experience/interactive-setup-and-onboarding-screens.md).

## Failure modes

- **prompt-only drift**: `/init` treated as plain advice and not as a staged artifact workflow
- **precedence inversion**: local/project/user/managed instruction ordering loaded incorrectly
- **unsafe include loading**: external includes loaded before trust approval
- **worktree duplication**: same checked-in instructions loaded twice via nested worktree traversal
- **cache reason loss**: all memory-file invalidations treated as identical reload causes
