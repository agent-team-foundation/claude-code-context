---
title: "Permission Decision Pipeline"
owners: []
soft_links: [/tools-and-permissions/permissions/permission-model.md, /tools-and-permissions/agent-and-task-control/delegation-modes.md, /ui-and-experience/feedback-and-notifications/interaction-feedback.md]
---

# Permission Decision Pipeline

Tool approval is not a single yes-no lookup. Claude Code runs a layered decision pipeline that first computes a policy result and then resolves any remaining "ask" state through automation, delegation, or an interactive prompt.

## Two-stage architecture

Reconstruction should preserve two distinct stages:

1. a policy engine that returns `allow`, `deny`, or `ask`
2. a resolution layer that decides how an `ask` becomes an approval, rejection, cancellation, or forwarded request

The policy result may also carry rewritten input, explanatory metadata, and persistence suggestions. Later stages must preserve those payloads.

## Stage 1: static policy order

The base permission engine evaluates in this order:

1. whole-tool deny rules
2. whole-tool ask rules
3. tool-specific permission checks such as subcommand rules, path checks, sandbox checks, and safety gates
4. mode-level bypass or allow paths for anything still eligible
5. whole-tool allow rules
6. conversion of undecided passthrough results into `ask`

Order matters because earlier objections intentionally override later broad allows.

## Skill-specific split inside stage 1

Skill execution is not one uniform permission path.

Equivalent behavior should preserve:

- skill-level deny rules being evaluated before any auto-allow path, including feature-gated remote discovered-skill execution
- remote discovered-skill execution requiring prior discovery in the current session before permission resolution proceeds
- that remote discovered-skill branch remaining a separate model-facing path from ordinary local skill lookup, with default allow only after deny checks have had a chance to block it
- local prompt skills with only a reviewed safe metadata subset auto-allowing through SkillTool
- local prompt skills with richer properties falling back to `ask`, with explicit exact-name and prefix allow-rule suggestions for future approvals
- non-prompt or model-invocation-disabled skill targets failing validation before the normal permission dialog path, rather than being treated as ordinary ask decisions

## Bypass-immune checks

Some asks must survive even the most permissive modes.

Equivalent behavior should keep these classes bypass-immune:

- tool operations that require explicit user interaction
- content-specific ask rules such as risky shell subcommands
- sensitive-path safety checks for protected configuration or repository control paths

These checks happen before any broad "just run it" mode can fire.

## Decision payloads

A permission result is richer than `allow` or `deny`.

Important payload fields include:

- rewritten input that downstream execution must actually use
- rule or directory suggestions that the UI may persist
- structured reason metadata for logging and explanation
- optional content blocks or feedback that should accompany the decision

If a rebuild drops the rewritten-input path, later approval flows will appear to succeed while still executing the wrong command or path.

## Mode transformations

After the base policy engine decides `ask`, session mode can still transform the result.

Important transformations:

- `dont ask` converts unresolved asks into immediate denials
- `auto` mode routes eligible asks through an action classifier
- plan mode can temporarily behave like auto mode when the session entered plan from an auto-style posture
- headless or background contexts that cannot prompt the user fall back to hook-based approval and then auto-deny if still unresolved

Mode logic is therefore part of permission semantics, not just UI behavior.

## Auto-mode classifier rules

Auto mode has its own layered shortcuts and guardrails.

A correct rebuild should preserve these rules:

- non-approvable safety checks stay interactive and never go through automatic approval
- tools that inherently require user interaction are not classifier-approved
- PowerShell stays opt-in for automatic approval rather than following Bash by default
- operations that would already be allowed by a safer edit-only posture can skip classifier review
- a small safe-tool allowlist can also skip classifier review
- successful actions reset the consecutive-denial streak
- after 3 consecutive denials or 20 total denials, the system falls back to explicit prompting

That denial fallback is part of the safety contract. It prevents the runtime from endlessly auto-rejecting without user review.

## Classifier failure behavior

Classifier failure is not handled uniformly.

Equivalent behavior should distinguish at least three cases:

- if the classifier's own transcript is too large, fall back to manual approval instead of retrying the classifier forever
- if the classifier service is unavailable, configuration may choose fail-closed or fail-open behavior
- if prompting is impossible in a headless context, repeated denial states should abort the worker rather than loop uselessly

## Stage 2: resolving `ask`

When the policy engine still returns `ask`, the runtime resolves it through a layered mediator:

1. optional automated checks for coordinator-style or background contexts
2. worker-to-leader forwarding when the request belongs to a subordinate worker
3. a short speculative grace window for shell auto-approval before showing a dialog
4. the interactive permission dialog or equivalent bridge/channel callback

Aborts and cancellations should resolve through this permission context instead of throwing uncontrolled exceptions through the turn loop.

## Explanatory messaging

User-facing approval prompts vary by reason.

Equivalent implementations should explain different cases distinctly, including:

- a blocking rule
- a hook decision
- a multi-part shell command where only some parts require approval
- a working-directory escape
- a sandbox override
- a mode-imposed approval
- a classifier-imposed approval

Without this distinction, users cannot tell whether they are overriding their own rule, a managed policy, or a runtime safety check.

## Failure modes

- **payload loss**: a permission decision rewrites input, but execution still uses the original version
- **bypass leak**: broad bypass modes suppress content-specific ask rules or protected-path safety checks
- **auto-mode deadloop**: repeated classifier denials never escalate to human review
- **headless ambiguity**: a worker that cannot prompt neither aborts nor returns a deterministic deny
- **explanation collapse**: every approval prompt looks the same and users cannot distinguish rule, hook, classifier, or path reasons
