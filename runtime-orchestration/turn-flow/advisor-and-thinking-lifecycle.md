---
title: "Advisor and Thinking Lifecycle"
owners: []
soft_links: [/runtime-orchestration/state/build-profiles.md, /product-surface/model-and-behavior-controls.md, /runtime-orchestration/turn-flow/api-request-assembly-retry-and-prompt-cache-stability.md, /runtime-orchestration/turn-flow/query-recovery-and-continuation.md, /runtime-orchestration/turn-flow/turn-assembly-and-recovery.md, /platform-services/provider-model-mapping-and-capability-gates.md, /ui-and-experience/shell-and-input/prompt-composer-and-queued-command-shell.md, /ui-and-experience/dialogs-and-approvals/focused-dialog-and-overlay-arbitration.md, /ui-and-experience/feedback-and-notifications/system-feedback-lines.md, /ui-and-experience/startup-and-onboarding/session-cost-threshold-acknowledgement.md]
---

# Advisor and Thinking Lifecycle

Claude Code's advanced reasoning posture is not one setting and not one model
parameter. It is a layered contract spanning model and provider support,
session-default thinking posture, one-turn reasoning escalations, UI affordances,
request-time protected-thinking cleanup, and an optional server-side advisor
tool that folds its own usage into the same turn and cost model.

## Scope boundary

This leaf covers:

- how default thinking posture, explicit thinking budgets, and per-turn effort
  escalation combine at request time
- how the optional advisor-side server tool is configured, admitted, and
  cleaned up across model switches and replay
- how these controls surface in transcript, prompt, and session-cost behavior

It intentionally does not re-document:

- the broader `/model`, `/effort`, `/fast`, and `/advisor` command family
  already covered in
  [../../product-surface/model-and-behavior-controls.md](../../product-surface/model-and-behavior-controls.md)
- the low-level request-builder mechanics already covered in
  [api-request-assembly-retry-and-prompt-cache-stability.md](api-request-assembly-retry-and-prompt-cache-stability.md)
- model/provider capability mapping already covered in
  [../../platform-services/provider-model-mapping-and-capability-gates.md](../../platform-services/provider-model-mapping-and-capability-gates.md)

## Reasoning posture is layered

Equivalent behavior should preserve several distinct layers that can all affect
one request:

- whether advanced thinking support exists for the current build, provider, and
  selected model
- whether the session default is "adaptive", explicitly budgeted, or disabled
- whether a persisted or environment override forces a different posture than
  the user's last session choice
- whether the current turn carries a one-shot escalation, such as an
  ultrathink-style trigger, that should affect only this request
- whether recovery logic must preserve or strip reasoning payloads when the
  turn retries on another model

These are related, but they are not the same state variable.

## Thinking has three semantic postures

Equivalent behavior should preserve:

- an adaptive posture where the runtime asks the provider to manage thinking
  depth without a fixed explicit budget
- an explicit-budget posture where the request carries a concrete reasoning
  budget
- a disabled posture where supported models still run without thinking-specific
  request state
- unsupported models gracefully falling back away from thinking-specific
  posture instead of pretending the provider accepted it

The runtime therefore needs more than a boolean "thinking on/off" bit.

## Default thinking posture is model-, provider-, and setting-aware

Equivalent behavior should preserve:

- thinking support depending on provider and model family rather than on the
  friendly model label alone
- default thinking staying enabled for supported models unless the user or
  environment explicitly disables it
- explicit env or CLI-style token overrides being able to force either an
  explicit budget or a full disablement
- persisted "always thinking" preference affecting the session default without
  erasing the model-specific capability checks underneath it
- adaptive-thinking eligibility being narrower than generic thinking support

## Effort, thinking, and ultrathink are related but distinct

Equivalent behavior should preserve:

- effort level controlling how much reasoning the model should apply when the
  selected model supports effort
- session-level thinking toggle controlling whether advanced thinking posture is
  even active for supported models
- ultrathink-style prompt triggers acting as a one-turn escalation hint instead
  of mutating the durable session setting
- that one-turn escalation being injected as a synthetic per-turn attachment or
  reminder before the model call, not as a visible user transcript edit
- that one-turn escalation remaining distinct from remote planning/review
  families that may also use stronger models but launch different task or
  session topologies
- model defaults being allowed to recommend medium effort while still leaving
  higher effort as a distinct user- or prompt-triggered step

If these concepts collapse into one setting, the product loses both its
low-friction defaults and its deliberate "think harder for this one turn"
affordance.

## Prompt and UI surfaces are part of the contract

Equivalent behavior should preserve:

- a prompt-surface toggle or picker that can change session-level thinking
  posture without opening a full settings editor
- keyboard affordances for that toggle living beside other prompt-owned
  pickers such as model and fast-mode selectors
- keyword detection and highlighting for ultrathink-style prompts happening in
  the composer before submission so the user can see the turn will escalate
  reasoning
- immediate feedback or notification when the user toggles session-level
  thinking posture
- the current build being able to suppress raw `thinking` transcript rows even
  when the underlying request still uses a thinking-capable mode

The UI is not just decoration here. It teaches the user when they have changed
the session's reasoning posture versus only the current turn's.

## Advisor is a separate server-side tool path

Equivalent behavior should preserve:

- the advisor path being optional and separately gated from ordinary thinking
  posture
- one model acting as the main worker while a second model can act as a
  stronger reviewer or advisor
- two distinct capability checks:
  - whether the current main model can invoke the advisor path
  - whether the chosen advisor model is valid as an advisor target
- some rollouts allowing direct user configuration of the advisor model while
  others bind the advisor model indirectly through experiment config
- advisor configuration persisting separately from the main model choice

This means "advisor enabled" and "advisor usable on this exact turn" are not
the same fact.

## Request assembly must separate parse-compatibility from active use

Equivalent behavior should preserve:

- parse-enabling request headers for advisor blocks staying present whenever the
  feature itself is active, even for non-agentic or side-path requests that may
  only need to replay existing history
- actual advisor tool admission happening only on request classes that are
  allowed to call tools and only when the current main/advisor model pair is
  valid
- advisor instructions or tool schema being injected only when the active
  request can truly use the advisor path
- model or provider switches stripping advisor-specific artifacts when the next
  request can no longer legally send them

Without this split, replay and compaction paths either fail to parse prior
history or falsely advertise a live advisor tool to requests that cannot use
it.

## Cache stability and speculative forks depend on this posture

Equivalent behavior should preserve:

- speculative helper calls and prompt-suggestion forks inheriting the relevant
  thinking, effort, and advisor posture when they are meant to stay aligned
  with the current session's live reasoning assumptions
- cache-sensitive request modifiers being treated carefully enough that
  mid-session posture churn does not accidentally destroy a large reusable
  prompt prefix
- some request modifiers remaining latched until an explicit cache-resetting
  boundary, such as clear or compaction, rather than toggling on and off every
  request

Reasoning posture is therefore part of prompt-cache stability, not just model
selection.

## Recovery must treat protected thinking state as model-bound

Equivalent behavior should preserve:

- protected-thinking payloads being treated as bound to the model that emitted
  them
- streaming fallbacks or model fallbacks tombstoning or stripping partial
  thinking output from abandoned attempts before retrying
- fallback retries removing reasoning payloads that would be invalid on the new
  model instead of replaying them blindly
- output-budget reductions preserving any still-required thinking budget rather
  than silently collapsing the request into a different reasoning mode

Reasoning recovery is therefore part of the main turn contract, not a UI-only
cleanup pass.

## Advisor usage folds into the ordinary session-cost model

Equivalent behavior should preserve:

- advisor-side usage being included in total session spend rather than tracked
  as an invisible side ledger
- per-model breakdown and total session cost staying aligned when advisor calls
  occur
- cost- or usage-facing UI such as session threshold acknowledgements reading
  the same shared totals that already include advisor-side work
- advisor-side analytics and observability being separate enough to diagnose
  usage, but not so separate that user-visible totals disagree

## Failure modes

- **state collapse**: session-level thinking posture, one-turn ultrathink
  escalation, and effort setting are merged into one value and lose their
  different scopes
- **phantom advisor**: the UI says advisor is enabled even though the current
  main model cannot invoke it
- **header mismatch**: replayed history still contains advisor blocks, but the
  request no longer carries the parse-enabling header and gets rejected
- **fallback pollution**: abandoned streaming attempts leave model-bound
  thinking payloads in transcript state and poison the retry
- **cost undercount**: advisor-side tokens are omitted from session totals, so
  status, spend prompts, and analytics disagree
- **transcript noise drift**: raw thinking rows become visible or hidden
  inconsistently across builds, leaving users unable to predict whether the
  runtime is quietly suppressing detail or not using the feature at all

## Test Design

In the observed source, turn-flow behavior is verified through a mix of deterministic module tests, resume-sensitive integration coverage, and CLI-visible end-to-end scenarios.

Equivalent coverage should prove:

- pre-query mutation, continuation branches, and typed terminal outcomes stay stable under test posture
- tool results, compaction, queued-command replay, and transcript persistence still compose correctly inside one logical turn
- interactive and structured-I/O paths surface the same visible outcome when interruption, permission denial, or recovery branches occur
