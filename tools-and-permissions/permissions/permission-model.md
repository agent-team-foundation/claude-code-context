---
title: "Permission Model"
owners: []
soft_links: [/tools-and-permissions/permissions/permission-mode-transitions-and-gates.md, /tools-and-permissions/permissions/permission-decision-pipeline.md, /tools-and-permissions/permissions/permission-rule-loading-and-persistence.md, /tools-and-permissions/permissions/sandbox-selection-and-bypass-guards.md, /collaboration-and-agents/worker-execution-boundaries.md, /ui-and-experience/feedback-and-notifications/interaction-feedback.md, /platform-services/auth-config-and-policy.md]
---

# Permission Model

Tool execution is controlled by an explicit permission context and transition graph rather than ad hoc prompts.

## Permission posture families

Equivalent behavior should preserve several distinct postures:

- a conservative interactive default
- an edit-friendly posture that auto-allows a narrower class of local file changes
- a planning posture that changes what later turns are allowed to do
- a no-prompt posture for workers or headless flows that cannot interrupt the user
- a policy-gated bypass posture
- an optional classifier-backed automatic posture
- an internal worker forwarding posture that routes approval requests to a parent surface instead of deciding locally

## Decision context

The model should include more than a yes or no prompt:

- per-tool allow, deny, and ask rules with source attribution
- support for additional working directories beyond the main cwd
- managed-only policy modes that can remove user-editable rules from the active decision set
- different behavior for foreground sessions versus background agents that cannot interrupt the user directly
- sandbox-aware routing for shell and file operations
- safety filters for destructive commands, path escapes, and other high-risk actions

## Transition and projection rules

Permission state is session-critical and cannot be mutated independently by every surface.

A faithful rebuild should preserve:

- startup precedence across CLI flags, persisted defaults, and policy gates
- one centralized transition layer for entering or leaving plan, auto, bypass, or worker-specific modes
- strip-and-restore behavior for dangerous allow rules that would bypass classifier-based safety
- asynchronous availability checks for automatic approval without clobbering a newer user choice
- external metadata projection that hides internal-only worker modes from remote or SDK clients

Permission state is session-critical. Temporary modes such as planning or automation can relax or tighten behavior, but the runtime must be able to restore the prior posture cleanly.
