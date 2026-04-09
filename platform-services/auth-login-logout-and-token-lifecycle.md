---
title: "Auth Login, Logout, and Token Lifecycle"
owners: []
soft_links: [/platform-services/auth-config-and-policy.md, /platform-services/policy-and-managed-settings-lifecycle.md, /collaboration-and-agents/remote-and-bridge-flows.md, /integrations/mcp/server-contract.md, /ui-and-experience/shell-and-input/voice-mode-and-hold-to-talk-dictation.md]
---

# Auth Login, Logout, and Token Lifecycle

Claude Code does not treat authentication as a static "token exists or not" check. Logging in, switching accounts, setting up limited-scope tokens, and logging out all trigger coordinated state migration across caches, policy overlays, experiments, transcript safety, bridge auth, and auth-sensitive hooks. A faithful rebuild must preserve that lifecycle as one system; otherwise account switches will appear to succeed while the running session still behaves like the previous identity.

## Scope boundary

This leaf covers:

- interactive `/login` and `/logout` command behavior inside a running session
- `claude auth login` and `claude auth logout` subcommand behavior
- the shared OAuth browser and manual-code transport used to acquire auth codes
- the central token-install path that replaces one authenticated identity with another
- logout teardown, cache invalidation, and auth-version-driven re-fetch behavior
- limited-scope token flows that intentionally do not replace the main session

It intentionally does not re-document:

- the full auth-source precedence and provider-selection rules already summarized in [auth-config-and-policy.md](auth-config-and-policy.md)
- the remote managed settings and policy service internals already covered in [policy-and-managed-settings-lifecycle.md](policy-and-managed-settings-lifecycle.md)
- the full bridge or remote-session transport model beyond the auth handoff points already named in [remote-and-bridge-flows.md](../collaboration-and-agents/remote-and-bridge-flows.md)
- the standalone launcher and setup-token command wrappers beyond the limited-scope auth semantics captured in [native-install-update-and-setup-token-cli-flows.md](native-install-update-and-setup-token-cli-flows.md)

## Shared lifecycle rule

Equivalent behavior should preserve:

- primary login flows treating new credentials as a full identity replacement, not an in-place patch over the old session
- one central token-install routine being responsible for clearing old auth state before storing newly acquired OAuth material
- in-session login doing extra live-runtime repair after token install so the already-running REPL stops behaving like the previous account
- limited-scope OAuth flows being kept separate from the full account-replacement path so they do not accidentally destroy the user's current session

## Primary login entry surfaces

Equivalent behavior should preserve:

- an interactive `/login` command that mounts the OAuth flow inside the running terminal UI
- a top-level `claude auth login` path that uses the same OAuth backend but prints progress to stdout and exits on success or failure
- an environment-driven refresh-token fast path that skips browser launch when a refresh token and scopes are provided, but still routes through the same token-install contract afterward
- forced login-method settings being treated as hard constraints, so the runtime can preselect Claude subscription auth or Console billing auth instead of always asking
- forced organization validation happening after token installation and before the flow is considered complete
- incompatible CLI flags for mutually exclusive login modes failing early instead of silently picking one

## OAuth transport contract

Equivalent behavior should preserve:

- one OAuth service owning PKCE generation, localhost callback listening, and final token exchange
- the callback listener binding an OS-assigned localhost port before opening the browser so the redirect target already exists when the provider returns
- generation of both automatic and manual authorization URLs from the same PKCE and state bundle
- automatic flow trying to open the browser while also surfacing a manual fallback URL
- manual entry accepting the copied `authorizationCode#state` payload format rather than inventing a second out-of-band exchange path
- a delayed terminal fallback that nudges the user toward manual paste or URL copy if browser launch does not complete the flow quickly
- the callback listener keeping the browser response open until token exchange succeeds or fails, then redirecting to a success or error page instead of leaving the browser on a raw localhost response
- cleanup always closing the callback listener and clearing pending handlers even when the flow errors or is abandoned

## Central token-install and account-switch contract

Equivalent behavior should preserve:

- newly acquired primary OAuth tokens flowing through one shared install routine before the session treats the user as logged in
- that install routine first performing a logout-style teardown without clearing onboarding state, so account switching removes the previous identity's secure storage, caches, and managed session artifacts before the new identity is written
- profile information being taken from prefetched OAuth profile data when available and otherwise fetched from the token, with fallback to token-exchange account metadata if the richer profile endpoint is unavailable
- stored account metadata preserving organization identity plus user-facing fields such as email, display name, billing posture, extra-usage eligibility, and creation timestamps when available
- token persistence being followed by cache invalidation for memoized OAuth lookups so downstream readers do not keep serving stale credentials
- Claude subscription-style auth fetching user roles and first-token metadata after install, while Console-style auth must create a managed API key as part of completing login
- failure to mint that managed API key being treated as a hard login failure for Console-style auth
- auth-related caches being cleared again after installation so experiment flags, policy overlays, tool schemas, and other auth-sensitive memoization are rebuilt under the new identity

## In-session `/login` migration inside a live REPL

Equivalent behavior should preserve:

- interactive `/login` notifying the running session that API-key-bearing auth changed, rather than only saving credentials on disk
- signature-bearing transcript blocks being stripped from existing conversation history before the new identity continues the session, so stale signature material tied to the prior key is not replayed
- post-login refresh of cost/accounting state so spend and quota surfaces do not carry over from the previous account
- non-blocking refresh of remote managed settings and policy limits immediately after successful login
- user cache reset happening before experiment or feature-flag refresh so auth-backed flag fetches resolve against the new credentials
- experiment and feature-flag refresh happening as part of login completion, not only on next launch
- permission killswitch checks being reset and re-run against the new organization so bypass or auto-mode availability can tighten after an account change
- the session incrementing an `authVersion`-style counter after login so auth-sensitive hooks can re-fetch their own derived state
- login cancellation producing an interrupted result instead of pretending success

## Trusted-device and auth-version side effects

Equivalent behavior should preserve:

- bridge trusted-device enrollment being tied to fresh login time rather than treated as a lazy background optimization that can happen arbitrarily later
- any previously stored trusted-device token being cleared before re-enrollment starts, so bridge calls made during the async enrollment window do not send the previous account's device token
- trusted-device persistence living in secure storage with memoization layered on top, and both the stored token and memo cache being clearable on auth changes
- environment-provided trusted-device tokens taking precedence over locally enrolled tokens when present
- auth-version bumps being reserved for explicit login or account-switch events, while ordinary background token refresh can keep using the current auth-derived state without forcing all hooks to recompute
- auth-sensitive consumers such as MCP config fetchers or voice auth checks keying their expensive revalidation off that version signal instead of polling auth state independently

## Onboarding-time login is similar but not identical

Equivalent behavior should preserve:

- onboarding-time login reusing the same auth-dependent refresh sequence for managed settings, policy limits, experiment flags, and trusted-device enrollment before the main session starts
- onboarding suppressing a redundant `/login` command immediately afterward if onboarding already completed the auth step
- onboarding completing global first-run state separately from token install, because the shared token-install routine deliberately avoids clearing or rewriting onboarding markers during ordinary account switches
- initial onboarding being able to finish login preparation without relying on an already-running session's auth-version bump semantics

## Logout and teardown contract

Equivalent behavior should preserve:

- logout flushing telemetry before credentials are cleared so org-tagged telemetry buffers are not stranded or leaked under the wrong identity
- logout removing managed API-key credentials and wiping secure storage, not merely clearing one in-memory token field
- logout clearing memoized OAuth tokens, trusted-device caches, beta caches, tool-schema caches, user caches, remote managed settings caches, policy caches, and other auth-sensitive derived state
- logout refreshing experiment or feature-flag state after user cache reset so post-logout entitlement checks stop seeing authenticated capabilities
- logout clearing stored account metadata from global config rather than leaving a stale profile alongside missing credentials
- one logout option that also resets onboarding-oriented state such as onboarding completion, subscription notices, available-subscription markers, and remembered custom-key approvals
- another logout option that preserves onboarding state while still removing credentials, so auth teardown can be reused safely inside account replacement and CLI auth subcommands
- the interactive slash-command logout path performing the full onboarding-clearing variant and then shutting down the session
- the top-level `claude auth logout` subcommand using the non-onboarding-clearing variant and exiting normally after printing success

## Limited-scope token flows that must not replace the main session

Equivalent behavior should preserve:

- setup-token-style flows being able to acquire long-lived or inference-only OAuth material without treating that token as a full login replacement
- plugin or integration OAuth helpers that need a token for GitHub Actions or similar external use being able to persist or display that token without performing the destructive account-replacement install routine
- those limited-scope flows reusing the OAuth browser transport where helpful, but deliberately bypassing full logout-before-install behavior
- limited-scope token setup warning users when they already have another auth method configured, instead of pretending the new token is their only active credential

## Failure modes

- **partial account switch**: new tokens are stored, but transcript safety cleanup, feature refresh, or cache invalidation is skipped and the live session still behaves like the previous account
- **destructive helper flow**: a limited-scope OAuth helper mistakenly reuses the full install path and wipes the user's real logged-in session
- **stale signature replay**: old signed transcript blocks survive an in-session login and the next request fails because they were bound to a different key
- **bridge identity leak**: trusted-device enrollment does not clear the previous token first, so bridge traffic briefly authenticates as the wrong account after login
- **stale auth observers**: MCP, voice, or other auth-sensitive hooks never notice explicit login and keep showing pre-login capabilities until restart
- **over-clearing logout**: account-switch teardown resets onboarding or first-run state that should only reset on the explicit full logout path
- **under-clearing logout**: secure storage or auth-related caches survive logout and leak entitlements, schemas, or account metadata into the next session
