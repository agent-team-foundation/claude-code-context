---
title: "Policy and Managed Settings Lifecycle"
owners: []
soft_links: [/platform-services/sync-and-managed-state.md, /platform-services/auth-config-and-policy.md, /tools-and-permissions/permissions/permission-model.md]
---

# Policy and Managed Settings Lifecycle

Claude Code has two nearby but distinct remote-governance services:

- **remote managed settings**, which behave like a settings overlay
- **policy limits**, which behave like a feature restriction map

They share fetch patterns, but they should not be collapsed into one generic "remote config" subsystem.

## Eligibility is a real gate

Both services decide early whether the current session should even query the server.

Important eligibility dimensions include:

- first-party versus third-party model provider
- default Anthropic base URL versus custom endpoint
- whether the session has real API-key auth or Claude.ai OAuth auth
- OAuth subscription tier and scope
- surface-specific exclusions for environments where server-managed settings are not meant to apply

Remote managed settings are intentionally a little more permissive in borderline OAuth cases. If externally injected tokens lack subscription metadata, the client may still try the server and let the API return an empty result. Policy limits are stricter because they gate compliance-sensitive behavior.

## Fetch, cache, validate

Both services follow the same broad lifecycle:

1. initialize an optional "loading complete" promise early so other startup code can wait
2. read a local cache file if one exists
3. compute a deterministic checksum from normalized JSON
4. fetch with `If-None-Match` support and retry on retryable failures
5. on success, validate the response shape before applying it
6. persist the fresh result back to disk
7. start background polling for mid-session updates

The implementation detail that matters is checksum stability. A rebuild should normalize JSON deterministically before hashing so client-side cache validation matches server-side expectations.

## Fail-open, with important nuance

Both services mostly degrade by failing open:

- if the fetch fails and a disk cache exists, use stale cached data
- if the fetch fails and no cache exists, continue without blocking the core session
- auth failures should generally skip retry because waiting does not help

But policy limits have one important exception: some compliance-sensitive decisions should deny on cache miss when the session is already in an essential-traffic-only mode. Rebuilding this service as pure fail-open everywhere would silently re-enable features that are supposed to stay suppressed.

## Empty result handling

An empty server result is different from a network failure.

Equivalent behavior should preserve these semantics:

- `304` means "your cached content is still valid"
- "no settings" or "no restrictions" responses should clear stale cache files rather than keep applying old data forever
- an empty managed-settings payload means "overlay nothing," not "treat stale settings as current"
- an empty policy-limits payload means "no restrictions are configured," not "network failed"

This distinction is what lets the product remove org-level controls cleanly.

## Managed settings are applied as a live overlay

Remote managed settings are more than a downloaded JSON file.

A faithful rebuild should preserve these behaviors:

- dangerous settings changes can require a blocking user-acceptance flow in interactive mode
- rejecting that security check should prevent the new overlay from taking effect
- successful load or refresh should notify settings listeners so downstream caches, env application, telemetry, and permission-dependent systems can hot-reload
- auth changes should clear caches first, then reload the overlay from the new identity

Remote managed settings therefore participate in the broader settings-change detector, not just a polling loop.

## Policy limits are consulted synchronously

Policy limits are applied differently.

They should be usable from synchronous feature checks that ask "is this policy allowed right now?" using:

- in-memory session cache when available
- disk cache as a fallback
- fail-open defaults for unknown or unavailable policies
- explicit deny-on-miss for the small set of essential-traffic exceptions

The key contract is that policy limits are a runtime gate map, not a general settings merge.

## Background polling and waiters

Both services need long-lived operational behavior:

- background polling should run on a timer that does not keep the process alive by itself
- cleanup hooks should stop polling on shutdown
- waiters for initial load must always resolve eventually, even if the remote call never happens or fails
- background polling failures must remain fail-open and must not retroactively flip live runtime checks into deny-on-miss; the stricter essential-traffic carve-out applies only at synchronous policy-decision time when no cached policy data exists

Remote managed settings go further by allowing cached disk content to unblock waiters immediately while the network refresh continues in the background.

## Failure modes

- **eligibility drift**: the client queries remote services in environments that should never receive those overlays
- **checksum mismatch**: client and server normalize JSON differently and miss cache hits
- **stale ghost policy**: a removed remote policy keeps applying because empty responses do not clear cache
- **unsafe overlay activation**: newly dangerous settings apply without an acceptance step
- **compliance regression**: policy miss paths fail open even in essential-traffic-only scenarios that require deny-on-miss

## Test Design

In the observed source, platform-service behavior is verified through sequencing-sensitive integration tests, deterministic state regressions, and CLI-visible service flows.

Equivalent coverage should prove:

- config resolution, policy gates, persistence, and service startup ordering preserve the contracts and failure handling described above
- provider-backed or OS-bound branches use fixtures, seeded stores, or narrow seams so auth, update, telemetry, and trust behavior stays reproducible
- users still encounter the expected startup, settings, trust, diagnostics, and account-state behavior through the real CLI surface
