---
title: "Remote Session Bootstrap and Environment Selection"
owners: []
soft_links: [/integrations/clients/remote-and-managed-client-envelopes.md, /integrations/clients/remote-setup-and-companion-bootstrap.md, /collaboration-and-agents/remote-and-bridge-flows.md, /collaboration-and-agents/bridge-transport-and-remote-control-runtime.md, /platform-services/auth-config-and-policy.md]
---

# Remote Session Bootstrap and Environment Selection

Claude Code has several ways to reach remote execution, but they all depend on explicit bootstrap contracts: choose the right environment, seed the session with enough repo and permission context, and fail clearly when auth or envelope prerequisites are missing.

## Direct-connect bootstrap

Equivalent behavior should preserve:

- direct-connect clients creating sessions through a server-owned `/sessions` endpoint rather than reusing the cloud remote-control envelope
- request bodies carrying the current working directory plus an explicit dangerous-permissions bypass flag when the caller opts into that mode
- optional bearer auth that can be attached without changing the rest of the bootstrap shape
- strict response validation before the runtime trusts the returned session ID, websocket URL, or normalized work directory
- when the server returns a normalized `work_dir`, that value becoming the effective runtime and UI cwd before the first turn so subsequent path resolution uses the server-approved directory rather than the caller's pre-bootstrap cwd

The clean-room point is that direct-connect is a distinct bootstrap surface with a much smaller but stricter contract.

## Environment discovery and default attribution

Equivalent behavior should preserve:

- environment discovery requiring first-party OAuth plus current-organization context rather than API-key auth alone
- empty environment sets being distinguishable from request failure
- effective-default selection starting from merged runtime settings, then matching `remote.defaultEnvironmentId` against the currently available environments
- source attribution scanning layered setting sources so the UI can explain which source actually set the winning default environment
- ordinary implicit fallback preferring a non-bridge environment before falling all the way back to the first available environment

This is how the product avoids both source opacity and accidental selection of bridge-only environments as the general compute default.

## Bootstrap-time selection rules

Equivalent behavior should preserve:

- configured default environments winning when they still exist in the live environment list
- some remote bootstrap paths intentionally bypassing the configured default and requiring a cloud-hosted environment instead
- those cloud-required paths retrying environment discovery once and then failing loudly instead of silently dropping into a BYOC environment that may not support the requested repo or permission mode
- bridge-only environments remaining eligible when explicitly chosen or resumed, while still not becoming the generic implicit default

The important contract is that environment choice depends on the bootstrap surface, not just on a single shared "pick the first environment" helper.

## Session envelope contract

Equivalent behavior should preserve:

- remote session creation always carrying an explicit `environment_id`
- bootstrap payloads being able to carry git-source identity, branch or outcome context, model choice, seed bundles, and PR context
- initial permission mode being seeded as part of bootstrap rather than waiting for a later best-effort update
- initial event history or first user input being attachable during session creation for surfaces that need immediate continuity

That envelope is what lets a generic remote environment still behave like the right repo-aware Claude Code session.

## Resume and bridge-registration interplay

Equivalent behavior should preserve:

- bridge resume flows being able to fetch an existing session to recover its environment binding before re-registering the local bridge worker
- reuse of the server-issued environment ID rather than inventing a fresh local one for resume
- graceful fallback to fresh session creation when the backend re-registers the bridge onto a different environment because the original one expired
- clear user-visible errors when the session no longer exists or no longer has a valid environment binding

Without this, resume flows either attach to the wrong environment or pretend continuity exists when the server already expired it.

## Header and routing boundaries

Equivalent behavior should preserve:

- environment-list and environment-creation APIs using org-scoped OAuth headers
- bridge session creation and fetch using sessions APIs that share the same org-scoped auth boundary but are still distinct from environment-registration APIs
- bootstrap code keeping those request families separate, because credentials or beta headers that work for one surface can still fail or misroute on another

This is a product contract, not just an HTTP detail: the wrong client envelope can make valid sessions appear missing.

## Failure modes

- **auth blind spot**: API-key-only auth is treated as sufficient for environment-backed remote bootstrap
- **source opacity**: the UI can name the selected environment but not explain which setting source chose it
- **silent byoc fallthrough**: a cloud-required flow lands in a BYOC environment after the configured default is skipped
- **bootstrap amnesia**: remote session creation omits repo, branch, model, or permission context and leaves the server to guess
- **direct-connect trust gap**: an invalid or partial session-creation response is accepted as if the websocket were ready
- **resume illusion**: bridge resume continues after the server rebounded the worker onto a different environment than the original session

## Test Design

In the observed source, client-integration behavior is verified through adapter regressions, transport-aware integration tests, and public-surface end-to-end flows.

Equivalent coverage should prove:

- message shaping, history or state projection, and surface-specific envelope rules stay stable across the client contracts described here
- auth proxying, environment selection, reconnect, and remote-session coordination behave correctly at the real process or transport boundary
- packaged client entrypoints still expose the same visible behavior as direct source invocation, especially for structured I/O and remote viewers
