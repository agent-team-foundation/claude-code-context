---
title: "SSH Remote Session and Auth Proxy"
owners: []
soft_links: [/integrations/clients/direct-connect-session-bootstrap-and-environment-selection.md, /integrations/clients/remote-session-message-adaptation-and-viewer-state.md, /product-surface/startup-entrypoint-routing-and-session-handoff.md, /platform-services/provider-specific-api-clients-and-auth-routing.md]
---

# SSH Remote Session and Auth Proxy

`claude ssh` is not a thin wrapper around an external shell. It keeps the transcript and approval UI on the local machine, runs tools and model work on the remote host, and tunnels first-party API auth back through a local proxy. A faithful rebuild needs all three layers.

## Bootstrap contract

Equivalent behavior should preserve:

- local startup collecting the remote host, optional remote cwd, permission mode, dangerous permission bypass, and local test mode before normal command dispatch
- `--continue`, `--resume`, and `--model` being forwarded to the initial remote CLI spawn so they apply to the remote session history and remote model choice rather than to the local shell
- successful bootstrap returning a normalized remote working directory that becomes the cwd shown by the local UI
- one initial informational system row clearly labeling the host, resolved remote cwd, and the fact that auth is flowing through a local proxy

## Local UI, remote execution

Equivalent behavior should preserve:

- the local REPL remaining the prompt, transcript, keybinding, and notification surface
- tool execution, file mutation, and model interaction occurring on the remote side through an SSH-backed session manager
- interrupts being sent to the remote session rather than cancelling only local UI state
- a local-only test mode being able to exercise the same auth-proxy plumbing without requiring real SSH deployment

## Permission approval bridge

Equivalent behavior should preserve:

- remote permission asks becoming the same local approval rows used by other remote-capable surfaces
- tool lookup preferring a known local tool definition but synthesizing a placeholder when the remote asks for a tool the local catalog does not know yet
- allow, deny, and abort responses travelling back to the remote side with updated input when the user changed it
- the approval UI clearing the loading state while it waits for a local decision, then restoring loading when execution resumes

## Transcript adaptation and deduplication

Equivalent behavior should preserve:

- streamed remote SDK messages being adapted into ordinary local transcript rows rather than exposing transport-native payloads
- duplicate remote initialization messages being deduplicated because the remote stream can emit them more than once across turns
- session-end messages clearing local loading state
- reconnect warnings surfacing in the transcript so the user can see why output paused

## Reconnect and process exit behavior

Equivalent behavior should preserve:

- a dropped SSH transport first entering a reconnecting state with visible attempt counters
- in-flight work being treated as lost during reconnect instead of pretending a partial turn can resume mid-stream
- permanent disconnect exiting the local process with a final human-readable reason
- remote stderr being surfaced when it looks relevant, especially on pre-connect failures or non-zero remote exits

## Auth proxy boundary

Equivalent behavior should preserve:

- the remote CLI receiving a dedicated session-scoped route that tunnels Anthropic API traffic through an SSH reverse-forwarded local auth proxy
- that socket override being scoped only to Anthropic API clients, not to generic fetches, MCP HTTP or SSE transports, or other outbound traffic
- non-Anthropic traffic continuing to use its normal proxy or direct-routing rules
- cleanup shutting down both the SSH session manager and the local proxy helper when the session ends

## Failure modes

- **local/remote inversion**: the UI stays local but tools or model calls accidentally run locally
- **approval desync**: remote permission asks never become local approval rows or never clear from the queue
- **reconnect illusion**: the product implies an interrupted turn is still running when only the transport recovered
- **auth proxy bleed**: the unix-socket override leaks into non-Anthropic requests and misroutes them
