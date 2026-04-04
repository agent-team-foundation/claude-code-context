---
title: "OAuth, Step-Up, and Client Registration"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /integrations/mcp/config-layering-policy-and-dedup.md, /platform-services/auth-config-and-policy.md, /integrations/clients/structured-io-and-headless-session-loop.md]
---

# OAuth, Step-Up, and Client Registration

MCP authentication is not one generic "open browser and get token" path. Claude Code supports per-server OAuth, step-up authorization when a token lacks scope, and a separate federated path for servers that defer trust to a shared identity provider.

## Auth path selection

Equivalent behavior should preserve at least these branches:

- a standard per-server consent flow for HTTP or SSE style MCP servers
- an alternate federated path when the server is configured to use a shared external identity provider
- no silent fallback from the federated path back to ordinary consent when the server explicitly declared the federated mode

That last point is important because the two paths may have different trust posture, scope posture, and admin intent.

## Discovery and metadata contract

Before the browser opens, the client should already know more than the server URL.

Equivalent behavior should preserve:

- support for an explicitly configured auth-metadata endpoint
- discovery from the server or protected resource when no explicit metadata URL is configured
- caching of authorization-server metadata so later refresh, scope display, and step-up handling do not have to rediscover everything
- treating configured metadata as part of the same trust boundary as the server itself

The clean-room contract is that metadata is not optional decoration. It directly affects scopes, redirect behavior, and refresh policy.

## Interactive and remote-friendly callback handling

Equivalent behavior should preserve two callback collection modes:

- a local redirect listener using a chosen or discovered callback port
- a manual callback-URL submission path for cases where the user's browser cannot reach the local loopback listener

Both paths should validate the same state token, support cancellation, and terminate the flow cleanly on timeout or user abort.

## Credential reset before re-auth, with state carry-forward

Reauthentication should start fresh without losing the information needed for a correct second attempt.

Equivalent behavior should preserve:

- clearing existing stored credentials before a fresh registration attempt
- carrying forward cached step-up scope requests and resource-metadata hints before clearing the old entry
- rebuilding redirect URIs, local listener state, and client-registration state for the new flow

This is how the client avoids reusing stale credentials while still remembering why the last token proved insufficient.

## Step-up authorization is not refresh

One of the most important auth contracts is the separation between token refresh and scope escalation.

Equivalent behavior should preserve:

- refresh being able to renew or replace existing tokens
- refresh not being expected to grant broader scope than the current token already has
- insufficient-scope responses marking a step-up authorization requirement instead of looping through refresh forever
- persistence of the requested higher scope so the next explicit auth flow can ask for the right capability immediately

Without that separation, the runtime can get trapped retrying a refresh path that will never satisfy the server.

## Provider quirks and normalization

OAuth providers are not uniform.

Equivalent behavior should preserve:

- normalization of provider-specific token errors into the runtime's canonical auth-failure categories
- distinction between invalid-grant style permanent failures and transient server or rate-limit failures
- secure logging that redacts state, verifier, challenge, and authorization code material from URLs or debug traces

The product contract is stable user-visible behavior even when providers disagree about wire details.

## Secure persistence boundary

Equivalent behavior should persist enough material to support later refresh and reauth, while keeping the secrets out of ordinary settings files.

That persistence model should preserve:

- a per-server credential identity that is stable across reconnects
- secure storage for tokens and client-registration state
- retained discovery metadata and step-up hints that are safe to reuse later
- targeted invalidation scopes so the runtime can clear just tokens, or tokens plus client-registration state, without flattening unrelated auth state

## Failure modes

- **fallback surprise**: a federated server silently drops into ordinary consent and violates admin intent
- **state mismatch acceptance**: the client accepts a callback that does not match the original auth attempt
- **scope loop**: insufficient-scope tokens keep refreshing instead of forcing a higher-scope reauth
- **stale registration reuse**: a fresh auth attempt reuses broken prior client-registration state
- **provider-leak logging**: raw OAuth callback parameters are written to logs or diagnostics
- **remote callback dead end**: browser-hosted or remote users have no manual path to complete the auth handshake
