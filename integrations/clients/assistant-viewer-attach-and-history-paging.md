---
title: "Feature-Gated Persistent Assistant Viewer Attach and History Paging"
owners: []
soft_links: [/collaboration-and-agents/remote-session-contract.md, /runtime-orchestration/automation/proactive-assistant-loop-and-brief-mode.md, /runtime-orchestration/tasks/task-registry-and-visibility.md, /integrations/clients/remote-and-managed-client-envelopes.md, /integrations/clients/remote-setup-and-companion-bootstrap.md, /integrations/clients/remote-session-message-adaptation-and-viewer-state.md]
---

# Feature-Gated Persistent Assistant Viewer Attach and History Paging

A feature-gated persistent-assistant attach surface is not a generic remote attach path. It is a viewer-skewed client for an already running long-lived assistant session: discover or choose the right session, attach without re-running leader bootstrap, lazy-page remote history, and keep compact assistant status output visible while ownership stays remote.

For the exact SDK-message adaptation, echo suppression, remote task counting, and viewer-state projection rules this attach flow relies on, see [remote-session-message-adaptation-and-viewer-state.md](remote-session-message-adaptation-and-viewer-state.md).

## Entry path and attach bootstrap

Equivalent behavior should preserve:

- an explicit session identifier attaching directly, while a bare attach entry first discovers available persistent assistant sessions
- zero-session discovery offering a local bootstrap flow and then telling the user to rerun after the assistant host has time to create a live session
- one discovered session auto-attaching, while multiple sessions require an explicit chooser
- authentication being refreshed before attach, but reconnects using a fresh-token closure instead of freezing the first access token forever
- attach-time feedback appearing immediately in the local terminal so the user can tell which remote session they joined

The important contract is that this surface connects to a preexisting assistant world. It does not silently create a brand-new ordinary remote chat.

## Viewer-only startup posture

Equivalent behavior should preserve:

- the local client enabling the assistant-compatible compact communication channel before the REPL starts, so remote status-style replies have a valid visible rendering path
- the attached client entering remote mode and a compact-output posture without enabling local assistant-leader startup effects
- local bridge and local assistant ownership flags remaining off, so the viewer does not try to become the session's leader, rebuild teammates, or re-bootstrap autonomous state
- the command set being filtered to the remote-safe subset before the viewer REPL launches

This is an asymmetric posture: the user can still converse with the remote assistant, but the local client is not the source of truth for the session's long-lived orchestration.

## Lazy history bootstrap and upward paging

Equivalent behavior should preserve:

- the REPL opening without a blocking full-history fetch
- newest history loading asynchronously after mount, anchored to the latest remote events and kept in chronological order
- older history pages being fetched only when the user scrolls near the top, using the oldest loaded event as the next cursor
- history conversion using the same viewer-facing message adapters as live traffic, including user-text conversion and tool-result conversion, so compact assistant replies do not render as blank tool stubs
- top-of-transcript sentinel states for `loading`, retryable load failure, and true start-of-session
- prepending history with scroll anchoring and unseen-divider adjustment so the viewport stays stable instead of jumping
- chaining a bounded number of older-page fetches on first paint until the transcript actually overflows the viewport

The clean-room point is that persistent-assistant history is a lazy transcript surface layered onto a live viewer, not a giant blocking preload.

## Live stream merge and remote-ownership boundaries

Equivalent behavior should preserve:

- live traffic arriving over a remote event stream while history paging stays a separate best-effort fetch path
- local echo filtering being limited to messages the viewer itself posted, so the client does not accidentally act as a universal history deduper
- remote background-work counts being derived from remote lifecycle events rather than synthesized from the local task registry
- permission prompts still being answerable from the attached viewer, because the remote assistant may need user approval to continue
- viewer clients not owning session-title mutation, inactivity timeout warnings, or Ctrl+C interrupts, because those controls belong to the remotely running assistant session
- reconnects clearing any locally cached remote task or spinner state that may have drifted during a websocket gap

This split is load-bearing: the viewer is interactive, but it is not the owner of remote execution.

## Failure modes

- **attach split-brain**: the viewer replays local assistant bootstrap and corrupts remote ownership assumptions
- **invisible compact replies**: remote compact-channel output is not converted from tool results, so the assistant appears to say nothing
- **history jump**: older-page prepends move the viewport or unseen-divider baseline unpredictably
- **phantom task list**: remote background work is reconstructed from local task state and shows tasks that do not actually exist in the viewer process
- **unsafe takeover**: the viewer is allowed to rename or interrupt a remotely owned assistant session
- **stale-auth reconnect**: attach succeeds once but later reconnects fail because the client cached a single bearer token instead of refreshing on demand

## Test Design

In the observed source, client-integration behavior is verified through adapter regressions, transport-aware integration tests, and public-surface end-to-end flows.

Equivalent coverage should prove:

- message shaping, history or state projection, and surface-specific envelope rules stay stable across the client contracts described here
- auth proxying, environment selection, reconnect, and remote-session coordination behave correctly at the real process or transport boundary
- packaged client entrypoints still expose the same visible behavior as direct source invocation, especially for structured I/O and remote viewers
