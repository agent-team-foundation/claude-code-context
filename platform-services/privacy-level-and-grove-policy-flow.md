---
title: "Privacy Levels and Grove Policy Flow"
owners: []
soft_links: [/platform-services/usage-analytics-and-migrations.md, /platform-services/policy-and-managed-settings-lifecycle.md, /product-surface/command-dispatch-and-composition.md]
---

# Privacy Levels and Grove Policy Flow

Claude Code has a small privacy-level resolver that gates a surprisingly wide slice of product behavior. Grove then builds on top of that gate to decide whether consumer-policy prompts, opt-in state, and privacy-setting dialogs can run at all.

## Scope boundary

This leaf covers:

- env-driven privacy-level resolution
- how telemetry-only suppression differs from essential-traffic-only suppression
- how Grove eligibility is cached and refreshed
- how interactive startup, `/privacy-settings`, and headless `--print` paths use Grove
- how choice state, viewed state, and domain exclusions alter the flow

It intentionally does not re-document:

- broader auth and subscriber detection mechanics already covered in the auth leaves
- generic command-catalog composition already captured in [command-dispatch-and-composition.md](../product-surface/command-dispatch-and-composition.md)
- the generic telemetry sink architecture already noted in [usage-analytics-and-migrations.md](usage-analytics-and-migrations.md)

## Privacy level resolution

Equivalent behavior should preserve:

- three ordered levels: `default`, `no-telemetry`, and `essential-traffic`
- `essential-traffic` winning over `no-telemetry` if both env signals are present
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` mapping to `essential-traffic`
- `DISABLE_TELEMETRY` mapping to `no-telemetry` only when `essential-traffic` is absent
- no file-backed or remote setting overriding this resolver; it is an env-first process contract
- helper predicates splitting the result into two questions: "disable telemetry?" and "disable all nonessential traffic?"
- user-facing diagnostics surfacing the env var responsible for `essential-traffic` mode when features such as auto-update explain why they are disabled

## Global enforcement surface

Equivalent behavior should preserve:

- `no-telemetry` disabling analytics and feedback-survey style telemetry while the rest of the product can still run normally
- `essential-traffic` suppressing all of the above plus optional network-backed helpers such as Grove, release notes, bootstrap enrichment, model-capability refreshes, metrics opt-out fetches, trusted-device enrollment, and similar nonessential API calls
- some product surfaces adding extra suppression on top of privacy level, such as test mode or third-party-provider mode for analytics, rather than folding those conditions into the privacy resolver itself
- compliance-sensitive checks using `essential-traffic` mode as a reason to fail closed on specific cache misses instead of always failing open
- command availability using the same `essential-traffic` gate for product feedback so hidden-command state and runtime behavior stay aligned

## Grove state model

Grove is driven by two nearby but distinct data shapes:

- account settings, with a tri-state `grove_enabled` value where `null` means the user has not accepted the terms or chosen a preference yet, plus a `grove_notice_viewed_at` timestamp for reminder logic
- notice configuration, with whether Grove is enabled for the account, whether the user's email domain forces opt-out, whether the rollout is still in a grace period, and an optional day-based reminder frequency

Important persistence rules:

- per-session memoized fetches cache account settings and notice config to avoid repeat requests
- the global user config also keeps a per-account Grove eligibility cache keyed by account UUID, storing only `grove_enabled` plus a timestamp
- that eligibility cache expires after 24 hours
- eligibility-cache writes are skipped when the stored value is still fresh and unchanged

## Eligibility and cache-first startup behavior

Equivalent behavior should preserve:

- only consumer subscribers with an OAuth account UUID being eligible for Grove checks
- eligibility being non-blocking and cache-first rather than waiting on the network during startup
- a cold cache returning "not qualified" immediately while kicking off a background fetch, which means an eligible user can miss the dialog on the first session and only see it later
- a stale cache returning the old value immediately while refreshing in the background
- a fresh cache returning immediately with no network dependency
- background eligibility refresh failures being debug-only and never blocking startup

## Grove API and invalidation semantics

Equivalent behavior should preserve:

- `essential-traffic` mode short-circuiting Grove fetches entirely rather than trying and failing later
- Grove account-settings fetches and notice-config fetches both returning an explicit success/failure result so callers can distinguish transport failure from successful responses with nullable fields
- notice-config fetches using a short timeout and degrading by skipping the dialog if the service is slow
- account-settings failures not being cached for the whole session; transient failures must clear the memoized entry so the dialog is not deadlocked out of rendering or confirming changes
- marking the notice viewed clearing cached account settings because reminder logic depends on the server-side viewed timestamp
- updating the Grove choice clearing cached account settings so immediate follow-up reads observe the new value

## Dialog show decision

The Grove dialog decision is stricter than a simple "eligible and not chosen" check.

Equivalent behavior should preserve:

- any API failure hiding the dialog rather than showing a broken or partial flow
- a non-null `grove_enabled` value suppressing the policy dialog because the user has already accepted terms and chosen a setting
- callers being able to force dialog display even if the notice was already viewed, which is how `/privacy-settings` can open the flow on demand
- when forced display is not requested, non-grace-period rollout state showing the dialog immediately
- during grace period, reminder frequency being measured in whole days since the last viewed timestamp
- if no reminder frequency is configured, or the notice has never been viewed, the dialog being shown
- reminder logic treating "viewed long enough ago" as eligible to re-show

## Interactive startup flow

Equivalent behavior should preserve:

- the Grove check running only after workspace trust is settled and full environment variables are applied
- telemetry initialization being scheduled before the Grove dialog path, but deferred so the dialog still appears during startup
- interactive startup consulting the cache-first qualification check before lazy-loading the Grove dialog UI
- startup showing the dialog in either onboarding or policy-update mode depending on whether onboarding was already shown
- if the dialog decides not to render, startup continuing silently
- every actual dialog display marking the notice as viewed and logging viewed analytics with location and grace-period metadata
- accepting either opt-in or opt-out updating server settings immediately and then continuing startup
- cancel behavior differing by rollout phase: grace-period cancel means defer and continue, while post-grace cancel is treated as an escape or exit path
- choosing the escape path during interactive startup terminating the process cleanly instead of letting the user continue without responding

## `/privacy-settings` command flow

Equivalent behavior should preserve:

- the slash command first using Grove qualification as a coarse gate
- unqualified users receiving a fallback web-settings destination instead of an in-terminal dialog
- settings fetch failure after qualification also falling back to the web destination rather than showing a partial terminal UI
- notice-config failure being tolerated for the command path; the settings dialog can still open without domain-exclusion metadata
- users who already have a boolean `grove_enabled` value going directly to a compact privacy-settings dialog instead of the policy-acceptance flow
- the compact dialog behaving like a one-setting terminal control for the consumer training opt-in
- domain-excluded users seeing that setting fixed to off and losing the keyboard toggle path
- non-excluded users toggling the boolean with Enter, Tab, or Space and pushing the update immediately
- after any accepted policy flow or settings toggle, the command re-fetching account settings and announcing the effective value
- analytics only recording a toggle event when a pre-existing boolean value actually changed

## Headless and non-interactive behavior

Equivalent behavior should preserve:

- headless `--print` startup reusing the same qualification check before running a non-interactive Grove enforcement step
- that step reusing the same dialog-show decision helper as interactive mode instead of duplicating policy logic
- when the rollout is still in grace period, headless mode printing an informational policy-update notice to stderr, marking the notice viewed, and continuing execution
- when grace period has ended, headless mode printing an action-required notice and terminating with a nonzero exit so the user must run the interactive product to review the update
- if either Grove API call fails, headless mode treating that as "do not block" because the shared dialog decision returns false on failure

## Failure modes

- **cold-cache invisibility**: an eligible user never sees Grove because qualification was changed to block on network failure or because the background cache write never persists
- **dead memoization**: a transient settings-fetch failure is cached for the whole session, making the privacy dialog impossible to open or confirm until restart
- **phase confusion**: grace-period cancel exits the app, or post-grace cancel merely defers, breaking the intended enforcement split
- **forced-flow regression**: `/privacy-settings` reuses startup reminder rules and therefore refuses to open a dialog the user explicitly requested
- **domain-exclusion leak**: domain-excluded accounts are offered an opt-in or toggle path that the server policy intends to forbid
- **privacy under-enforcement**: `essential-traffic` mode disables analytics but still allows optional product network calls such as Grove or bootstrap
- **privacy overreach**: `no-telemetry` mode is incorrectly treated as full `essential-traffic` mode and disables unrelated nonessential product features
