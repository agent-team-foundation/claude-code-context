---
title: "Session Cost Accounting and Restoration"
owners: []
soft_links: [/ui-and-experience/startup-and-onboarding/session-cost-threshold-acknowledgement.md, /runtime-orchestration/turn-flow/advisor-and-thinking-lifecycle.md, /platform-services/provider-model-mapping-and-capability-gates.md, /tools-and-permissions/specialized-tools/web-fetch-and-search-tool-contracts.md, /platform-services/auth-login-logout-and-token-lifecycle.md, /runtime-orchestration/sessions/resume-path.md]
---

# Session Cost Accounting and Restoration

Claude Code does not treat cost as a disposable printout from the last API
call. It keeps one session ledger that accumulates provider usage, folds
advisor-side work into the same spend truth, survives resume when the session
identity matches, and resets deliberately on account or session boundaries. A
faithful rebuild needs that shared ledger or user-visible spend surfaces will
drift from each other.

## Scope boundary

This leaf covers:

- the shared session-ledger contract for API spend and per-model usage
- how provider-local model IDs are normalized for pricing and reporting
- fast-mode price differences and unknown-model fallback behavior
- inclusion of cache reads, cache writes, and web-search usage in the ledger
- save, restore, session-switch, and auth-reset behavior for that ledger

It intentionally does not re-document:

- the user-facing $5 acknowledgement dialog already covered in [../ui-and-experience/startup-and-onboarding/session-cost-threshold-acknowledgement.md](../ui-and-experience/startup-and-onboarding/session-cost-threshold-acknowledgement.md)
- broader quota and overage behavior for Claude.ai subscriber mode already covered in [claude-ai-limits-and-extra-usage-state.md](claude-ai-limits-and-extra-usage-state.md)
- the lower-level provider model mapping contract already covered in [provider-model-mapping-and-capability-gates.md](provider-model-mapping-and-capability-gates.md)

## One ledger powers all spend surfaces

Equivalent behavior should preserve:

- one shared session-scoped ledger for total spend instead of separate counters
  per UI surface
- the same ledger feeding threshold acknowledgement, status reporting, exported
  hook data, end-of-process summaries, and resume-time restored state
- per-model usage detail and total session spend moving together, so user-facing
  totals always reconcile back to a more detailed breakdown
- usage accumulation remaining active even on side paths such as non-streaming
  fallback, so recovery branches do not become invisible spend

## Pricing keys off canonical model identity, not raw transport strings

Equivalent behavior should preserve:

- pricing lookup normalizing provider-local runtime strings back to canonical
  model identity before choosing a price tier
- that normalization still working when the runtime model string is a Bedrock
  inference profile, an ARN, a custom override, or another provider-local
  deployment identifier
- detailed usage being allowed to retain the original runtime model string for
  auditing while user-facing aggregation can fold several runtime IDs back into
  one canonical model family
- fast-mode price differences being applied as a pricing-tier choice on the
  same canonical model family rather than pretending fast mode is a different
  model altogether

Without canonical pricing resolution, switching providers or using overrides
changes what the same visible model appears to cost.

## The ledger counts more than prompt and completion tokens

Equivalent behavior should preserve each model entry accumulating at least:

- input tokens
- output tokens
- cache-read input tokens
- cache-creation input tokens
- provider-native web-search request counts
- derived USD spend

That means the spend ledger reflects prompt caching and web-search work instead
of treating them as invisible side channels.

## Advisor usage folds into the same visible spend truth

Equivalent behavior should preserve:

- advisor-side iterations being costed separately from the primary model call
- those advisor costs being added back into the same shared session ledger
- per-model breakdown expanding to include advisor models when they are used
- user-visible totals therefore including advisor spend automatically instead of
  hiding it in a separate diagnostic ledger

This is the accounting counterpart to the advisor lifecycle contract: the user
sees one session spend truth, not one main-model total plus hidden reviewer
costs.

## Unknown pricing degrades explicitly, not silently

Equivalent behavior should preserve:

- unknown or custom model strings still producing a cost estimate through a
  documented fallback tier instead of disappearing from the ledger
- the session entering an explicit "unknown model cost" state when that
  fallback is used
- downstream status or summary surfaces being able to warn that totals may be
  approximate, while still showing one coherent session total

The important invariant is that custom or newly launched models do not create a
hole in the visible cost ledger.

## Save, switch, and restore are keyed to session identity

Equivalent behavior should preserve:

- saving the current ledger snapshot before switching away from a live session
- storing that snapshot together with the session identity it belongs to
- restoring spend only when the target session identity matches the saved
  snapshot identity
- resetting local cost state before restoring another session so the restored
  ledger starts from a clean slate
- resume flows and in-session session switches both using that same
  save-then-reset-then-restore pattern

This prevents cost bleed between unrelated conversations while still letting a
true resume feel continuous.

## Auth resets clear the ledger

Equivalent behavior should preserve:

- logout or full account replacement clearing session cost state
- in-session login/account switch paths resetting the ledger before continuing
  under the new identity
- auth-sensitive spend surfaces therefore reflecting the current account only,
  not whichever account previously occupied the REPL

## Failure modes

- **cross-session bleed**: switching or resuming causes one session to inherit
  another session's accumulated spend
- **advisor undercount**: reviewer-side usage is logged diagnostically but left
  out of user-visible totals
- **fast-mode mispricing**: fast-mode requests are billed at the ordinary tier
  or shown as a different fake model instead of as a pricing variant
- **unknown-model hole**: custom or newly launched runtime IDs drop out of the
  ledger instead of using an explicit approximate-cost state
- **recovery blind spot**: fallback or retry paths consume tokens but do not
  update the shared session ledger
- **auth carryover**: logging in or switching accounts leaves the previous
  identity's spend totals active in the new session
