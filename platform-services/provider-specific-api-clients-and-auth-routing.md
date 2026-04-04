---
title: "Provider-Specific API Clients and Auth Routing"
owners: []
soft_links: [/platform-services/auth-config-and-policy.md, /platform-services/auth-login-logout-and-token-lifecycle.md, /product-surface/model-and-behavior-controls.md, /runtime-orchestration/api-request-assembly-retry-and-prompt-cache-stability.md]
---

# Provider-Specific API Clients and Auth Routing

Claude Code does not have one universal "call Anthropic" path. It first decides which inference provider owns the session, then routes credentials, base URLs, regions, and SDK client construction through provider-specific branches. A faithful rebuild must preserve that routing layer or the same settings will authenticate correctly in one environment and fail in another.

## Scope boundary

This leaf covers:

- provider selection and host-owned routing env behavior
- auth-source precedence only as it affects live API client construction
- managed-session exceptions that suppress user-terminal auth overrides
- first-party, Bedrock, Vertex, and Foundry client construction differences

It intentionally does not re-document:

- the user-facing `/login` and logout lifecycle already covered in [auth-login-logout-and-token-lifecycle.md](auth-login-logout-and-token-lifecycle.md)
- the user-facing `/model` and `/fast` controls already covered in [../product-surface/model-and-behavior-controls.md](../product-surface/model-and-behavior-controls.md)
- request assembly, retry, and turn-loop behavior already covered in [../runtime-orchestration/api-request-assembly-retry-and-prompt-cache-stability.md](../runtime-orchestration/api-request-assembly-retry-and-prompt-cache-stability.md)

## Provider selection is a runtime fork

Equivalent behavior should preserve one active provider family per process:

- `bedrock`
- `vertex`
- `foundry`
- `firstParty`

Provider selection is environment-driven, not inferred from model names. If multiple provider flags are accidentally present, the resolver should still choose one deterministic winner rather than constructing a hybrid client.

## Host-owned routing must survive settings reloads

Equivalent behavior should preserve a host-managed routing mode where spawn-time environment decides:

- which provider is active
- which endpoint family is legal
- which provider-specific model defaults or auth variables are authoritative

When host-managed routing is enabled, settings-sourced env must not be allowed to override provider-selection, endpoint, auth, or provider-model variables. Otherwise a user-level Bedrock or proxy setup can silently hijack a desktop, bridge, or remote-controlled subprocess that expected first-party routing.

## Managed-session auth suppression rules

Certain managed contexts deliberately ignore ordinary terminal auth overrides.

Equivalent behavior should preserve:

- remote or desktop-managed OAuth sessions refusing to fall back to the user's ordinary API-key helper or local API-key env
- SSH-tunneled remote sessions preserving the launcher-provided proxy/OAuth placeholders instead of letting remote settings rewrite them
- bare mode disabling OAuth entirely and permitting only hermetic API-key-style auth inputs

The important contract is "managed auth stays managed." Local convenience settings must not accidentally take over a host-owned session.

## First-party auth enablement is conditional

Equivalent behavior should preserve first-party Anthropic auth only when all of these remain true:

- the session is not in bare mode
- no third-party provider is selected
- no external API-key or bearer-token source is actively taking precedence, unless the session is one of the managed OAuth contexts above

That means first-party OAuth is not merely "available if tokens exist." It is disabled when the runtime has already been told to authenticate some other way.

## Auth-source precedence for live requests

Equivalent behavior should preserve separate precedence chains for bearer-token auth and API-key auth.

For bearer-style auth, precedence should preserve:

- explicit bearer token env when not in a managed OAuth context
- explicit OAuth token env for managed launches
- OAuth token file-descriptor or managed disk fallback for subprocesses that cannot inherit the original pipe
- configured API-key helper as a bearer-token source when that path is authoritative
- stored Claude.ai OAuth tokens when the session is actually using first-party subscriber auth

For API-key auth, precedence should preserve:

- bare-mode environment key or bare-mode helper first
- direct environment key for CI, print-style, or explicit third-party-preference flows
- file-descriptor-provided API key before slower local fallbacks
- configured `apiKeyHelper` as an authoritative source even when its cache is still cold
- login-managed keychain or global-config key only after higher-precedence sources decline

When `apiKeyHelper` is configured, callers must not silently fall through to stored keys just because the helper has not finished warming yet.

## First-party client construction

Equivalent behavior should preserve first-party sessions using the Anthropic SDK branch with these rules:

- Claude.ai subscriber-style sessions send an OAuth access token instead of an API key
- non-subscriber API sessions send an API key and may also layer a bearer `Authorization` header from helper-driven auth-token flows
- staging or special first-party environments may override the base URL only through the dedicated first-party auth config path
- shared request headers still include session identity, user-agent, remote-session markers, and client-app metadata

The first-party branch is the only one that should behave like "ordinary Anthropic API auth."

## Bedrock client construction

Equivalent behavior should preserve a dedicated Bedrock SDK branch with:

- region selection from AWS region variables, plus a special override for the small fast model
- optional no-auth or proxy-friendly mode for controlled skip-auth environments
- support for either a Bedrock bearer token or refreshed AWS credentials
- explicit propagation of access key, secret key, and session token when refreshed credentials exist
- provider-specific proxy wiring rather than reuse of first-party OAuth assumptions

Bedrock must not reuse the first-party auth-token rules or first-party request-ID assumptions.

## Vertex client construction

Equivalent behavior should preserve a dedicated Vertex SDK branch with:

- refresh of GCP credentials before use unless auth skipping is explicitly enabled
- a Google-auth object scoped for cloud-platform access
- per-model region selection rather than one universal region for all models
- a last-resort project-ID fallback that avoids slow metadata-server probing when users have not configured a project anywhere else
- a mock or no-op auth object for controlled skip-auth and proxy scenarios

The clean-room requirement is that Vertex auth and region selection remain separate concerns from first-party OAuth and Bedrock AWS credentials.

## Foundry client construction

Equivalent behavior should preserve a dedicated Foundry branch with:

- API-key auth when a Foundry API key is configured
- otherwise Azure AD bearer-token acquisition through the default credential chain
- a controlled skip-auth path for testing or gateway scenarios
- provider-specific base URL or resource targeting rather than reuse of Anthropic API hosts

Foundry is closer to first-party than Bedrock or Vertex in feature shape, but it still needs its own credential and endpoint construction.

## Request metadata is provider-aware

Equivalent behavior should preserve:

- common session metadata headers across all providers
- client-generated request IDs only for true first-party Anthropic endpoints where the backend expects and logs them
- avoidance of first-party-only headers on third-party providers or generic proxies that may reject unknown metadata

The client wrapper must know not only "which provider," but also whether the current base URL is truly a first-party host.

## Failure modes

- **provider split-brain**: settings reload changes provider routing under a host-managed session and the client starts sending the wrong credential type
- **managed-session hijack**: desktop or remote OAuth sessions pick up a stale local API-key helper and start authenticating as the wrong account
- **helper fallthrough**: a configured helper is still authoritative, but a temporary cache miss incorrectly falls through to stored keychain auth
- **wrong SDK branch**: Bedrock, Vertex, or Foundry sessions reuse the first-party client and fail on endpoint, region, or auth format
- **metadata rejection**: first-party-only headers are sent to third-party providers or custom gateways and break otherwise valid requests
- **trust leak**: project-sourced provider env vars are applied before trust and redirect traffic to an attacker-controlled backend
