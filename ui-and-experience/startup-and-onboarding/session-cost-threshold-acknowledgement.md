---
title: "Session Cost Threshold Acknowledgement"
owners: []
soft_links: [/platform-services/usage-analytics-and-migrations.md, /platform-services/auth-login-logout-and-token-lifecycle.md, /platform-services/claude-ai-limits-and-extra-usage-state.md, /ui-and-experience/feedback-and-notifications/status-line-and-footer-notification-stack.md, /ui-and-experience/dialogs-and-approvals/focused-dialog-and-overlay-arbitration.md, /runtime-orchestration/turn-flow/advisor-and-thinking-lifecycle.md, /platform-services/session-cost-accounting-and-restoration.md]
---

# Session Cost Threshold Acknowledgement

Claude Code has a one-time spend acknowledgement for Anthropic Console API sessions. Once the current session's accumulated API cost reaches a fixed threshold, the REPL can surface a blocking acknowledgement dialog with a docs link. A faithful rebuild needs that behavior to stay distinct from Claude.ai subscriber quota or overage warnings: this flow is about acknowledging raw API spend inside one session, not about subscription limits or usage caps.

## Scope boundary

This leaf covers:

- the session-cost accumulator contract that the acknowledgement uses
- the $5 threshold trigger and the distinction between "shown this session" versus "durably acknowledged"
- billing-access gating for whether the dialog is actually rendered
- the dialog's timing, priority, and acknowledgement behavior

It intentionally does not re-document:

- Claude.ai subscriber limit and extra-usage state already covered in [../../platform-services/claude-ai-limits-and-extra-usage-state.md](../../platform-services/claude-ai-limits-and-extra-usage-state.md)
- the broader status line surface that reuses the same cost totals, already covered in [status-line-and-footer-notification-stack.md](status-line-and-footer-notification-stack.md)
- general auth and account metadata flows beyond the billing-access gate already covered in [../../platform-services/auth-login-logout-and-token-lifecycle.md](../../platform-services/auth-login-logout-and-token-lifecycle.md)
- the deeper session-ledger pricing, unknown-cost fallback, and save/restore rules already covered in [../../platform-services/session-cost-accounting-and-restoration.md](../../platform-services/session-cost-accounting-and-restoration.md)

## One shared session-cost source

Equivalent behavior should preserve:

- one session-scoped total-cost accumulator reused by the threshold dialog, status line, query-budget checks, and end-of-process cost summaries instead of separate counters per surface
- cost accumulation covering both the primary model response and any advisor-side usage that is intentionally folded into session spend
- per-model usage breakdown and total cost moving together, so the session total always matches the more detailed usage accounting
- the acknowledgement reading whatever the shared ledger currently knows, even
  when some model pricing had to fall back to an approximate unknown-model
  tier, rather than maintaining its own corrected counter
- saving the active session's current cost snapshot before switching to another session, then resetting local counters before restoring the target session's saved totals
- restoring spend only when resuming the same saved session identity, so unrelated sessions do not inherit each other's cost history
- auth resets such as fresh login clearing this cost state instead of letting one identity inherit another identity's prior spend totals

## Threshold trigger and local suppression

Equivalent behavior should preserve:

- a fixed acknowledgement threshold at $5 of accumulated session spend in the current build
- checking that threshold from the live session total rather than from a separate billing fetch or periodic poll
- only triggering when the threshold has been crossed and neither the session-local shown flag nor the durable acknowledgement flag is already set
- logging the threshold crossing once per session when the threshold is first reached
- flipping the session-local shown flag immediately when the threshold is reached, even before renderability is decided, so later transcript changes do not keep retriggering the same event forever
- deferring any actual dialog presentation until the session is no longer loading, so a cost acknowledgement never interrupts an in-flight turn midway through generation

## Who can see the dialog

This acknowledgement is intentionally narrower than "anyone who spent $5."

Equivalent behavior should preserve:

- an operator kill switch that can disable cost warnings entirely
- no session-cost acknowledgement for Claude.ai subscriber mode, because that environment uses a different quota and billing model
- no acknowledgement for logged-out sessions or sessions with no usable auth material
- no acknowledgement for accounts whose billing-role metadata is missing, so grandfathered or partially refreshed accounts do not see a dialog the client cannot validate
- acknowledgement eligibility for Console-style API users only when the account has billing-capable admin or billing roles at the organization or workspace level
- the important distinction between "threshold reached" and "dialog rendered": ineligible sessions still mark the threshold as locally shown for that run, but they do not gain the durable acknowledgement bit

## Dialog timing and focus priority

Equivalent behavior should preserve:

- one shared focused-input dialog lane deciding whether the cost acknowledgement is currently allowed to take focus
- cost acknowledgement participating only when the session is idle enough to show dialogs, not while the prompt is actively typing or a turn is still loading
- higher-priority interrupt surfaces such as message selection, permission prompts, and interactive requests being able to win focus ahead of the cost dialog
- once the session becomes idle and the focus lane is free, the already-armed cost dialog appearing without needing the threshold logic to re-run again

## Dialog contract

Equivalent behavior should preserve:

- dialog copy that states the user has spent $5 on the Anthropic API in this session
- a short explanatory body that points the user to spend-monitoring documentation rather than trying to embed a full billing UI inside the terminal
- a single explicit acknowledgement action rather than a branching choice tree
- cancel or Escape being treated the same as acknowledging the notice, so the user cannot get stuck behind a spend acknowledgement loop

## Acknowledgement persistence

Equivalent behavior should preserve:

- acknowledgement hiding the dialog immediately for the current REPL instance
- acknowledgement persisting one durable config bit so future sessions start in the already-acknowledged state and do not show the threshold dialog again
- the session-local shown flag and the durable config bit remaining separate concepts: local shown suppresses repeat firing for the current run, while durable acknowledgement means the user explicitly accepted the notice
- analytics distinguishing threshold reached from threshold acknowledged

## Relationship to other spend surfaces

Equivalent behavior should preserve:

- API-session spend acknowledgement staying separate from Claude.ai quota, extra-usage, and rate-limit warnings even though all are user-visible cost or usage signals
- reuse of the same session-cost accumulator that feeds status-line cost reporting and exported status-line hook data, so all spend surfaces agree on the session total
- no attempt to proxy full billing management in the dialog itself; the surface is an acknowledgement and education step, not an in-terminal billing console

## Failure modes

- **threshold spam**: sessions without billing access keep re-logging or re-arming the $5 notice on every later message because the local shown bit was tied to render success instead of threshold crossing
- **cross-session bleed**: resuming or switching sessions carries cost totals into the wrong session and shows a threshold acknowledgement for spend the user did not incur in the current conversation
- **wrong audience**: Claude.ai subscriber sessions, logged-out sessions, or non-billing users see a Console API spend dialog they cannot act on
- **surface disagreement**: the threshold dialog, status line, and query-budget enforcement read different cost totals and disagree about how expensive the session already is
- **mid-turn interruption**: the dialog appears while a response is still loading instead of waiting for an idle dialog-safe moment
