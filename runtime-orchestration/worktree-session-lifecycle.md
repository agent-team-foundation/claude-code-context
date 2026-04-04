---
title: "Worktree Session Lifecycle"
owners: []
soft_links: [/product-surface/interaction-modes.md, /product-surface/session-utility-commands.md, /runtime-orchestration/resume-path.md, /runtime-orchestration/session-reset-and-state-preservation.md, /runtime-orchestration/session-artifacts-and-sharing.md, /platform-services/interactive-startup-and-project-activation.md, /tools-and-permissions/control-plane-tools.md, /tools-and-permissions/agent-tool-launch-routing.md, /ui-and-experience/status-line-and-footer-notification-stack.md]
---

# Worktree Session Lifecycle

Main-session worktree mode is not the same thing as giving a child worker an isolated checkout. Claude Code lets the leader session itself enter a worktree-scoped posture, and that posture has distinct startup versus mid-session semantics, persisted resume state, prompt and statusline steering, IDE retargeting, and fail-closed exit rules.

## Two entry paths with different project-root semantics

Equivalent behavior should preserve:

- two ways for the main session to enter a worktree: startup `--worktree` and the mid-session `EnterWorktree` control-plane tool
- startup entry being allowed to create the worktree through either ordinary git mechanics or a configured hook-backed path, so non-git VCS can still participate when explicitly configured
- git-backed startup resolving to the canonical main repository root before creating the worktree, even when Claude Code was launched from an existing sibling worktree
- both entry paths being able to reopen an existing named worktree instead of forcing a brand-new checkout every time
- mid-session entry refusing to nest when the current session is already inside an active EnterWorktree-managed worktree
- startup `--worktree` rebasing the session's stable project root onto the worktree, so hooks, settings, skills, cron, and later session identity resolve there
- mid-session `EnterWorktree` changing the live working directory but intentionally leaving the stable project root anchored to the original project, so the worktree behaves like a temporary execution envelope rather than a new long-lived project identity

The load-bearing clean-room distinction is that "inside a worktree" is not one flat mode. Rebuilds need the split between startup worktree-as-project and mid-session worktree-as-temporary-shell-context.

## Active-session posture and operator surfaces

Equivalent behavior should preserve:

- a dedicated worktree session record that remembers the true pre-enter directory, worktree path, optional branch lineage, optional tmux session, and whether the worktree came from hooks rather than git
- the model-facing environment summary explicitly stating that the current directory is a git worktree and that commands should stay there rather than `cd` back to the original repository root
- statusline consumers receiving structured worktree metadata including worktree name, path, branch, original directory, and original branch when a main session is in worktree posture
- IDE-open flows targeting the active worktree path instead of the parent repository root, so editor actions stay aligned with the files the runtime is actually modifying
- ordinary exit commands switching into a worktree-specific exit flow when the main session is inside a worktree
- startup worktree entry reloading settings and hook snapshots from the worktree after the switch, while mid-session entry avoids pretending the worktree is the new source of stable project identity

Without these surfaces, the runtime may technically enter a worktree while the model, UI, and editor integrations still behave as though the original checkout were active.

## Persistence, clear, and resume continuity

Equivalent behavior should preserve:

- transcript persistence of a dedicated last-wins worktree-state record rather than reconstructing worktree posture from incidental cwd mentions
- serialization of only the stable worktree-session fields needed for resume, not transient creation analytics or one-time setup metrics
- clears and structured resets re-stamping the active worktree state after metadata wipe when the session is still operating inside that worktree
- resume honoring a fresh startup-created worktree over stale transcript state when both exist, so a new `--worktree` launch cannot be silently overwritten by older session metadata
- transcript-driven worktree restoration only when the recorded worktree path still exists on disk, with missing directories degrading to an exited state instead of poisoning the resumed session
- resume restoring cwd-sensitive caches and prompt sections after worktree restoration so later turns see the correct environment
- resume intentionally avoiding any guess that a restored worktree should also become the stable project root, because the transcript does not prove whether the original session entered through startup `--worktree` or a mid-session tool call

This is why resume can continue a worktree session without flattening the important distinction between "resume the shell context" and "rewrite the session's project identity."

## Exit, keep, and removal rules

Equivalent behavior should preserve:

- `ExitWorktree` operating only on worktrees the current session itself is actively managing, not on arbitrary filesystem worktrees or worktrees created in older sessions
- a non-destructive keep path that restores the main session to the original directory while leaving the worktree and branch on disk
- a destructive remove path that fails closed when the runtime cannot verify worktree state, and that requires explicit discard confirmation before deleting uncommitted files or unreached commits
- optional tmux-aware cleanup, where removing a tmux-backed worktree kills its tmux session first while keep flows can either preserve or explicitly terminate that tmux session
- every successful keep or remove flow clearing persisted worktree state, clearing cwd-sensitive prompt and memory caches, and restoring the main session's original directory
- restoration of the stable project root and hook snapshot only when the worktree was entered through startup `--worktree`, because mid-session enter never transferred that authority in the first place
- session shutdown inside a worktree using a dedicated keep-versus-remove dialog, with clean worktrees eligible for silent auto-removal and dirty worktrees surfacing an explicit choice instead of assuming deletion is safe

The important contract is that leaving a worktree is not just `cd ..`. It is a coordinated runtime-state transition with destructive branches that must stay conservative.

## Failure modes

- **project-root collapse**: startup and mid-session worktree entry are flattened into one behavior, so resume, skills, hooks, or session discovery attach to the wrong project identity
- **prompt drift**: the model is told the wrong active root and starts navigating back into the parent checkout
- **stale resurrection**: resume restores a worktree path that was already deleted, or lets stale transcript state override a fresh startup-created worktree
- **wrong-target tooling**: statusline, IDE open, or exit flows keep acting on the original checkout even though the session is operating in the worktree
- **unsafe deletion**: removal treats unknown git state as clean and destroys work that should have required an explicit discard confirmation
- **scope leak**: the exit tool starts mutating any worktree on disk instead of only the worktree posture owned by the current session
