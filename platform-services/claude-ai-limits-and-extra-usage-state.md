---
title: "Claude AI Limits and Extra Usage State"
owners: []
soft_links: [/platform-services/usage-analytics-and-migrations.md, /product-surface/model-and-behavior-controls.md, /ui-and-experience/feedback-and-notifications/status-line-and-footer-notification-stack.md, /product-surface/review-and-pr-automation-commands.md]
---

# Claude AI Limits and Extra Usage State

Claude Code's Claude.ai subscriber path does not treat limits as a one-off error message. It maintains a shared limit-state model that is updated from normal responses, preflight quota checks, and 429s, then reused by warning surfaces, recovery menus, fast-mode fallback, prompt-cache policy, model eligibility checks, and the `/usage` and `/extra-usage` product surfaces. A faithful rebuild needs that shared contract, not just a generic "show rate limit" behavior.

## Scope boundary

This leaf covers:

- the shared Claude.ai quota and extra-usage state model
- quota preflight, header parsing, early-warning heuristics, and stale-state clearing
- how 429s become structured product behavior instead of generic transport errors
- how limit state fans out into footer notifications, transcript messaging, `/usage`, `/extra-usage`, and rate-limit recovery menus
- the cross-coupling from extra-usage state into 1M model access, fast mode, and prompt-cache policy

It intentionally does not re-document:

- the broader auth and account lifecycle already covered in [auth-login-logout-and-token-lifecycle.md](auth-login-logout-and-token-lifecycle.md)
- the full model picker and command semantics already covered in [../product-surface/model-and-behavior-controls.md](../product-surface/model-and-behavior-controls.md)
- the generic footer queue implementation already covered in [../ui-and-experience/feedback-and-notifications/status-line-and-footer-notification-stack.md](../ui-and-experience/feedback-and-notifications/status-line-and-footer-notification-stack.md)
- the dedicated ultrareview billing flow already covered in [../product-surface/review-and-pr-automation-commands.md](../product-surface/review-and-pr-automation-commands.md)

## Shared limit-state model and intake gate

Equivalent behavior should preserve:

- one session-wide Claude.ai limit record with at least these user-relevant dimensions: base quota status, representative limit type, reset time, advisory fallback availability, overage status, overage reset time, overage disabled reason, whether the session is currently consuming extra usage, and any warning-threshold metadata
- a separate raw-utilization store for the 5-hour and 7-day windows so status-line style consumers can read exact percentages without inheriting the warning-state heuristics
- quota handling running only for real Claude.ai subscribers or explicit internal mock-limit sessions, with all stale limit state being cleared once the runtime should no longer process quota headers at all
- essential-traffic-only mode skipping the dedicated quota network call entirely
- interactive sessions performing an explicit lightweight quota preflight, while non-interactive sessions skip that extra request and let the first real model request populate the shared state from its own headers
- the preflight query using a minimal fast model call only to learn quota state, not to mutate conversation history

## Header normalization and warning semantics

Equivalent behavior should preserve:

- response-header parsing consuming the unified limiter fields for base status, representative claim, reset timing, overage status, overage reset timing, overage disabled reason, and fallback availability
- `isUsingOverage` becoming true only when the subscription limit itself is rejected while the overage layer is still allowed or warning, so "hard stop" and "continue on extra usage" remain different states
- advisory fallback availability being stored as UI state only; it warns about possible degraded-limit posture but does not itself switch models
- early-warning detection preferring explicit server-sent "surpassed threshold" headers for 5-hour, 7-day, and overage windows
- client-side time-relative warning heuristics being used only as a fallback when the server does not send threshold markers, so users still get warned when they are burning quota too quickly early in the window
- user-visible warning state being stricter than raw header state: an API `allowed_warning` without meaningful utilization or threshold evidence should collapse back to plain `allowed` instead of leaving stale warning banners alive after a reset
- raw per-window utilization being updated on every processed response even when the user-visible warning state stays `allowed`
- the extra-usage disabled reason being cached in global config across sessions, with `null` meaning "enabled", `undefined` meaning "not known yet", and concrete string reasons distinguishing provisioned-vs-disabled accounts

## 429 interpretation, retry posture, and fast-mode coupling

Equivalent behavior should preserve:

- 429 handling distinguishing structured quota rejections from generic capacity or entitlement failures instead of treating every 429 as the same user-facing message
- 429s with unified limiter headers being turned into structured limit messaging that can say "session limit", "weekly limit", "Opus limit", "Sonnet limit", "using extra usage", or "out of extra usage" based on the parsed state
- 429s without unified limiter headers surfacing the real server reason instead of a fake quota explanation, including the separate "extra usage required for 1M context" path
- error-driven quota extraction forcing the shared status to `rejected` on any processed 429 even when the headers are partial, so a half-populated error response cannot leave the runtime believing the user is still fully allowed
- ordinary retry policy not blindly retrying subscriber 429s forever the way API-key-style flows might, with enterprise and explicit unattended persistent-retry modes remaining special cases
- fast mode handling 429 and 529 differently from ordinary retry logic: short retry-after values should preserve fast mode and retry quickly, while long or unknown delays should trigger a cooldown and retry at standard speed to avoid cache thrash
- 429s that specifically prove extra usage is unavailable for fast mode permanently disabling fast mode and retrying at standard speed instead of looping on an impossible paid path

## Notification and recovery-surface propagation

Equivalent behavior should preserve:

- the shared limit state fanning out through a listener or hook layer so footer notifications, transcript error rows, recovery menus, and other UI surfaces all read the same current quota truth
- local rate-limit notifications being suppressed entirely in remote mode, because the authoritative user-facing surface is remote and duplicate local toasts would be misleading
- warning notifications being deduplicated by their rendered text so repeated equivalent warnings do not spam the footer queue
- entering overage mode generating a distinct one-shot "now using extra usage" transition notification, with the one-shot guard resetting only after the session leaves overage mode
- team and enterprise users without billing access suppressing some local overage-entry or approaching-limit notifications when their org can seamlessly roll into overage or when they are not the actor who can actually buy anything
- transcript rate-limit messages auto-opening the rate-limit options menu only when the current live limit state proves the user is still rejected and not merely because an old 429 transcript line exists from earlier in the session
- upsell and recovery copy varying by rate-limit tier, Max 20x posture, billing access, extra-usage enablement, and whether the runtime is opening a recovery menu immediately versus merely showing advice text

## `/usage`, `/extra-usage`, and rate-limit options

Equivalent behavior should preserve:

- `/usage` being just the Usage tab in Settings rather than a separate reporting engine
- usage fetches running only for subscriber accounts with profile scope, with expired OAuth tokens returning a benign null result instead of forcing a visible 401 failure
- the usage tab showing session and weekly bars broadly, but only showing the separate Sonnet-week bar on plans where Sonnet quota meaningfully differs from the general weekly limit
- the extra-usage section in `/usage` being consumer-oriented: shown only on Pro or Max style plans, with separate branches for disabled, unlimited, and monthly-capped extra usage
- non-subscription or non-profile-scope users seeing an empty or unavailable `/usage` surface instead of a hard billing error
- `/extra-usage` availability depending on both session mode and provisioning-allowed billing types, with distinct interactive and non-interactive command variants rather than one command pretending both environments work the same way
- running `/extra-usage` marking that the user has visited the feature and invalidating the current organization's overage-credit grant cache before any follow-up reads
- Team or Enterprise users without billing access taking a request-to-admin path rather than always opening billing pages directly
- that admin-request path short-circuiting when the org already has unlimited extra usage, checking whether requests are even allowed, deduplicating pending or dismissed requests, and only then creating a fresh limit-increase request
- billing-capable users or consumer plans opening the correct Claude.ai settings page for personal or admin usage management instead of trying to proxy the whole configuration flow locally
- the interactive rate-limit options menu hiding the extra-usage/request-more action entirely for non-billing Team or Enterprise users when the org is in a spend-cap-depleted state and there is nothing actionable for that user to request

## Cross-runtime reuse outside the obvious quota UI

Equivalent behavior should preserve:

- million-context model access checks reusing the cached extra-usage disabled reason instead of waiting for a fresh quota call every time, so subscriber access to 1M variants depends on whether extra usage is cached as provisioned
- that cached reason distinguishing "provisioned but out of credits" from "not provisioned at all", because those two states should both block current spending but should not produce the same model-eligibility answer
- prompt-cache policy latching 1-hour cache eligibility based on whether the user is a subscriber who is not currently in overage, so a mid-session overage transition does not silently flip cache TTLs and destroy server-side cache reuse
- prompt-cache break diagnostics treating overage-state changes as a first-class cache-break cause, even when the runtime intentionally latches TTL policy to avoid an immediate live flip

## Failure modes

- **stale quota ghost**: a logout, auth change, or non-subscriber session keeps showing old limit warnings because the shared state is never cleared
- **warning inflation**: the runtime trusts raw `allowed_warning` headers without threshold validation and shows warning surfaces long after the real limit window reset
- **overage blind spot**: base-limit rejection and active extra-usage continuation collapse into one "blocked" state, so users get told to stop when they could keep working
- **429 misclassification**: headerless entitlement or capacity 429s are mislabeled as ordinary session-limit failures and point users to the wrong recovery action
- **fast-mode thrash**: long 429 or 529 delays keep fast mode enabled and churn prompt-cache assumptions instead of entering cooldown or permanently stepping down after overage rejection
- **remote toast duplication**: remote sessions still emit local limit notifications and produce conflicting surfaces
- **admin-request dead end**: Team or Enterprise non-billing users are pushed into billing URLs they cannot use, or are allowed to request impossible spend-cap states
- **1M access drift**: model gating ignores the cached extra-usage posture and exposes million-context variants to subscriber accounts that should not have them
- **cache-policy split brain**: overage transitions silently change prompt-cache TTL behavior without the runtime tracking or explaining the break
