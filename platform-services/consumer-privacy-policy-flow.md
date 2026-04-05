---
title: "Consumer Privacy Policy Flow"
owners: []
soft_links: [/platform-services/privacy-level-resolution.md, /platform-services/auth-config-and-policy.md, /ui-and-experience/interactive-setup-and-onboarding-screens.md, /product-surface/feedback-and-issue-commands.md]
---

# Consumer Privacy Policy Flow

Claude Code has a cache-first policy-notice flow for eligible consumer accounts. It decides whether privacy-setting dialogs should appear, when reminders should reappear, and how interactive versus headless sessions enforce response requirements.

## Scope boundary

This leaf covers:

- consumer-policy eligibility and cache behavior
- account-setting and notice-config state
- interactive startup, `/privacy-settings`, and headless enforcement flows

It intentionally does not re-document:

- broader auth or subscriber detection mechanics already covered in the auth leaves
- the env-driven privacy posture that gates whether this service is allowed to run at all, which lives in [privacy-level-resolution.md](privacy-level-resolution.md)

## State model and caching

Equivalent behavior should preserve:

- two nearby but distinct server-backed state shapes: account settings and notice configuration
- account settings carrying a tri-state opt-in value where `null` means the user has not accepted the policy or chosen a preference yet, plus a last-viewed timestamp for reminder logic
- notice configuration carrying whether the flow is enabled for the account, whether the user's domain is forced out, whether rollout is still in a grace period, and any reminder cadence
- per-session memoization of fetches to avoid repeat requests during one startup or command flow
- a per-account cache in global config that stores only the nullable opt-in choice plus freshness metadata
- cache-first startup qualification that can return "not qualified yet" immediately on a cold cache while refreshing in the background

## Eligibility and invalidation semantics

Equivalent behavior should preserve:

- only eligible consumer-style accounts with the right authenticated identity being checked
- background eligibility refresh staying non-blocking and debug-only on failure
- `essential-traffic` mode short-circuiting the whole flow instead of trying and failing later
- account-settings failures clearing their memoized entry so transient failures do not deadlock the dialog out for the rest of the session
- marking a notice viewed or changing the opt-in choice clearing cached account settings so immediate rereads observe the new server state

## Dialog decision and interactive startup

Equivalent behavior should preserve:

- any API failure hiding the dialog rather than showing a partial or broken flow
- a non-null opt-in value suppressing the policy dialog because the user has already made a choice
- callers being able to force dialog display even if reminder rules would otherwise suppress it
- grace-period rollout allowing deferral while post-grace rollout can require an explicit decision
- interactive startup running this check only after workspace trust and environment hydration are settled
- startup marking the notice viewed only when the dialog actually displays
- accept flows updating server settings immediately before startup continues
- post-grace cancellation being allowed to terminate startup instead of silently continuing

## `/privacy-settings` and headless behavior

Equivalent behavior should preserve:

- `/privacy-settings` first using coarse qualification, then falling back to a web destination when the in-terminal flow is unavailable
- already-configured users going straight to a compact toggle-style dialog instead of always replaying first-time policy acceptance
- domain-excluded users seeing the setting fixed to off and losing the toggle path
- headless or print-style startup reusing the same dialog-decision helper rather than duplicating policy logic
- grace-period headless sessions being able to continue after an informational notice, while post-grace sessions terminate nonzero until the user reviews the policy in an interactive client
- API failures in headless mode degrading to "do not block" because the shared dialog decision returned false

## Failure modes

- **cold-cache invisibility**: an eligible user misses the dialog forever because qualification blocks on the network or never persists refreshed cache state
- **dead memoization**: a transient fetch failure makes the dialog impossible to open until restart
- **phase confusion**: grace-period deferral and post-grace enforcement are swapped
- **domain-exclusion leak**: users who must stay opted out are shown a writable toggle
- **forced-flow regression**: `/privacy-settings` inherits startup reminder suppression and refuses to open when explicitly requested
