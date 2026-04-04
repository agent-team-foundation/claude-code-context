---
title: "Permission Mode Transitions and Gates"
owners: []
soft_links: [/tools-and-permissions/permission-model.md, /tools-and-permissions/permission-rule-loading-and-persistence.md, /tools-and-permissions/permission-decision-pipeline.md]
---

# Permission Mode Transitions and Gates

Permission posture is not just an enum. Claude Code has user-facing modes, worker-only internal modes, asynchronous gate checks, and transition-time cleanup that changes which rules remain active.

## Mode families

Equivalent behavior should preserve these distinct families:

- a conservative interactive default
- an edit-friendly mode that auto-allows a narrower class of filesystem changes
- a planning mode that changes later-turn expectations
- a no-prompt posture that converts unresolved asks into denials
- a bypass posture that is still subject to policy kill-switches
- an optional classifier-backed automatic mode
- an internal worker mode that forwards approval prompts to a parent surface instead of handling them locally

The clean-room requirement is the distinction, not the literal source names.

## Startup mode selection

Initial permission posture is resolved from layered inputs, not from one setting.

A faithful rebuild should preserve this precedence model:

1. explicit full-bypass startup flags
2. explicit CLI mode selection
3. persisted default-mode settings
4. fallback to ordinary default

Important gates:

- organization policy can disable bypass mode even when the user requested it
- remote-only surfaces may accept only a subset of startup modes
- classifier-backed auto mode can be rejected synchronously at startup by cached circuit-breaker state and then corrected again by an asynchronous authoritative gate check

## Centralized transition handler

Mode-switch side effects must be centralized so every entry path behaves identically.

Equivalent behavior should preserve one transition layer that:

- handles plan-mode entry and exit bookkeeping
- activates or deactivates classifier state
- strips or restores dangerous allow rules when classifier semantics begin or end
- records that plan mode has been exited when later UI or attachment behavior depends on that fact

Without a central transition handler, the keyboard carousel, slash commands, remote control surfaces, and plan-exit flows will drift apart.

## Plan-mode entry and exit

Planning mode preserves where the user came from.

Equivalent behavior should:

- stash the pre-plan permission posture
- restore that posture on exit when safe
- optionally keep classifier semantics active during plan mode when the user has explicitly opted into that hybrid behavior
- refuse to activate classifier semantics inside plan mode when the pre-plan posture was already too dangerous to inherit safely

This is why plan mode is not just a boolean flag layered on top of another mode.

## Classifier-mode gates

Classifier-backed automatic approval must pass multiple gates:

- global enablement or circuit-breaker state
- model support
- settings-based disablement
- optional speed-mode or similar runtime breakers
- explicit or implicit user opt-in, depending on rollout posture

Equivalent behavior should also support an asynchronous verification pass that:

- re-reads authoritative gate state after startup
- updates availability without clobbering a user's mid-turn mode change
- kicks the session out of automatic mode if the gate becomes unavailable
- emits a user-facing explanation only when the user actually wanted that mode

## Dangerous-rule stripping and restoration

Classifier-backed approval cannot inherit every allow rule.

On entry to classifier semantics, equivalent behavior should:

- detect rules that would bypass classification entirely
- remove them from active execution
- stash only the subset that was actually stripped

On exit, it should:

- restore the stripped rules to their original writable sources
- clear the stash so restoration is idempotent

The critical contract is that safety tightening is reversible.

## Internal prompt-forwarding worker mode

Some worker tasks can surface approval requests through a parent terminal rather than deciding locally.

Equivalent behavior should preserve:

- a worker-only mode for this purpose that is not exposed as a user-selectable persisted default
- no external metadata projection of that internal mode
- separate prompt-avoidance behavior for workers that cannot surface prompts at all

This is the bridge between multi-agent execution and one shared approval UX.

## Failure modes

- **transition drift**: one entry path strips or restores rules differently from another
- **gate race**: an asynchronous availability check reverts a user's newer mode choice
- **silent downgrade**: leaving automatic mode discards stripped rules instead of restoring them
- **external leakage**: worker-only internal mode names surface into remote metadata or persisted defaults
