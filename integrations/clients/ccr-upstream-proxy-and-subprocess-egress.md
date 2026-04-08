---
title: "CCR Upstream Proxy and Subprocess Egress"
owners: []
soft_links: [/integrations/clients/remote-and-managed-client-envelopes.md, /integrations/clients/ssh-remote-session-and-auth-proxy.md, /collaboration-and-agents/remote-session-contract.md, /platform-services/provider-specific-api-clients-and-auth-routing.md]
---

# CCR Upstream Proxy and Subprocess Egress

Claude Code has a second proxy contract besides the local auth proxy used by `claude ssh`. In CCR-backed remote sessions, the runtime can start a container-local upstream relay that gives agent subprocesses controlled HTTPS egress to organization-configured upstreams while keeping the relay token heap-only, injecting a custom CA bundle, and failing open if any part of the setup breaks. A faithful rebuild needs this as its own contract; otherwise CCR tool subprocesses either lose required upstream access or the rebuild incorrectly tunnels the wrong traffic through the wrong proxy path.

## Scope boundary

This leaf covers:

- the container-side upstream-proxy bootstrap path used inside CCR sessions
- session-token handling, process hardening, relay startup, and CA bundle provisioning
- how proxy and CA env vars are injected into agent subprocesses
- the routing boundary between proxied upstream traffic and explicitly exempt traffic

It intentionally does not re-document:

- generic remote-session ownership, viewer state, or live control semantics already covered in [../remote-session-contract.md](../../collaboration-and-agents/remote-session-contract.md)
- the user-facing `claude ssh` auth-proxy flow already covered in [ssh-remote-session-and-auth-proxy.md](ssh-remote-session-and-auth-proxy.md)
- provider-specific API client construction beyond the fact that Anthropic API traffic stays outside this proxy contract, already covered in [../../platform-services/provider-specific-api-clients-and-auth-routing.md](../../platform-services/provider-specific-api-clients-and-auth-routing.md)
- broader remote client envelope selection already covered in [remote-and-managed-client-envelopes.md](remote-and-managed-client-envelopes.md)

## This path is CCR-only, lazy-loaded, and fail-open

Equivalent behavior should preserve:

- the upstream-proxy module loading only in CCR-style remote sessions instead of on every local startup
- one explicit feature-and-environment gate deciding whether the contract is active: remote session posture, server-side proxy enablement, a remote-session ID, and a readable session-token file
- startup registering the proxy-env provider before ordinary subprocess spawning so later Bash, MCP, LSP, hook, and child CLI launches all see one consistent egress recipe
- any failure during token read, CA download, relay startup, or hardening logging a warning and disabling the proxy instead of aborting an otherwise-usable remote session
- the CCR-injected base URL being treated as authoritative for proxy bootstrap, rather than re-deriving the endpoint from ordinary local OAuth heuristics that do not match container launches

## Token handling is designed to reduce prompt-injection blast radius

Equivalent behavior should preserve:

- reading the upstream-proxy session token from a dedicated CCR file path rather than from long-lived user settings or ordinary env vars
- best-effort Linux hardening that marks the process non-dumpable before the normal agent loop can expose the token to same-UID ptrace scraping
- the token remaining available in process memory long enough to authenticate the relay, but the on-disk token file being unlinked only after the local relay is confirmed listening
- failed relay or CA setup leaving the token file in place so a supervisor restart can retry, instead of consuming the token too early and making recovery impossible

## The relay is local CONNECT over WebSocket, not a generic proxy daemon

Equivalent behavior should preserve:

- a local listener on `127.0.0.1` accepting HTTP `CONNECT` from ordinary subprocess tooling such as `curl`, `gh`, or other HTTPS-speaking utilities
- the listener tunneling bytes over a WebSocket to the CCR upstream-proxy endpoint because CCR ingress and path-prefix routing do not expose a raw CONNECT socket directly
- the WebSocket upgrade using session auth, while the first tunneled bytes carry the target `CONNECT` line plus per-session proxy authorization for the upstream relay
- the relay being HTTPS-only: it exists to tunnel CONNECT and inject trust for MITM HTTPS egress, not to become a generic plain-HTTP forward proxy
- buffering any bytes that arrive after the CONNECT header but before the WebSocket is fully open, so coalesced CONNECT-plus-TLS-handshake packets do not silently lose client data
- the relay itself being able to use the container's existing outbound proxy path for its own WebSocket upgrade when direct egress is blocked

## CA bundle and proxy env must propagate to subprocesses

Equivalent behavior should preserve:

- downloading the upstream-proxy CA certificate and concatenating it with the system trust bundle into a user-writable CCR-local bundle path
- exporting one shared env recipe for subprocesses that includes `HTTPS_PROXY` and the major CA-bundle variables used by Node, Python, curl, and similar toolchains
- that env recipe being injected centrally through the subprocess-environment builder instead of requiring each tool family to rediscover proxy state independently
- child Claude Code processes that cannot reinitialize the relay after the token file is unlinked still inheriting the already-resolved proxy and CA env from the parent when the relay is active

## Exempt traffic is part of the contract, not a debugging detail

Equivalent behavior should preserve:

- an explicit no-proxy allowlist for loopback and private-network ranges that should never traverse the relay
- Anthropic API hosts staying outside this upstream proxy so the runtime does not accidentally MITM its own first-party model traffic or break non-Bun trust chains
- package registries and GitHub-style hosts that CCR already reaches directly remaining exempt instead of being re-routed through the credential-injecting upstream relay
- the clean separation that this proxy exists for selected subprocess HTTPS egress, while first-party inference auth and local `claude ssh` auth tunneling remain separate contracts

## Failure modes

- **session-fatal proxying**: a broken CA fetch or relay startup aborts the entire CCR session instead of degrading to no-proxy mode
- **token exposure drift**: the session token remains on disk too long or the process skips the non-dumpable hardening step and becomes easier to scrape from a compromised tool run
- **subprocess split brain**: parent runtime believes the proxy is active but Bash, MCP, LSP, hooks, or child CLI processes never receive the proxy env and therefore bypass required upstream routing
- **traffic misclassification**: Anthropic, GitHub, or package-registry traffic is routed through the upstream relay and breaks a path that should have stayed direct
- **handshake byte loss**: CONNECT requests that coalesce with early TLS bytes lose data while the WebSocket handshake is still opening
- **retry dead end**: startup deletes the token file before the relay is actually ready, so a transient bootstrap failure cannot recover on supervisor restart
