---
title: "Browser Automation and Native Computer Use"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /integrations/mcp/connection-and-recovery-contract.md, /runtime-orchestration/state/build-profiles.md, /runtime-orchestration/turn-flow/stop-hook-orchestration-and-turn-end-bookkeeping.md, /ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md, /product-surface/command-execution-archetypes.md]
---

# Browser Automation and Native Computer Use

Claude Code exposes a generic built-in WebBrowser surface plus two more privileged control surfaces that must not be collapsed together. One privileged surface controls the user's authenticated Chrome session through an extension-backed MCP server. The other controls the local desktop directly through a native computer-use MCP surface. Rebuilding the product faithfully means preserving those splits instead of treating every browser or desktop action as one generic tool.

## Scope boundary

This leaf covers:

- authenticated Chrome automation through the Claude-in-Chrome integration
- native desktop computer use through the local computer-use MCP surface
- the separation between those privileged surfaces and the generic built-in WebBrowser capability
- setup, gating, approval, session-state, and cleanup rules that make those surfaces safe and usable

It intentionally does not re-document:

- generic MCP server lifecycle already covered in [../integrations/mcp/server-contract.md](../integrations/mcp/server-contract.md)
- the broader tool-family inventory already covered in [tool-families.md](tool-families.md)
- the deeper built-in WebBrowser contract, which is only partially visible in this source snapshot and belongs in its own leaf once the clean-room evidence is stronger
- generic permission-dialog shell behavior already covered in [../ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md](../ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md)

## Authenticated Chrome automation is an optional dynamic MCP integration

Equivalent behavior should preserve:

- Chrome automation targeting the user's real Chrome or Chromium session rather than a generic ephemeral browser
- the surface being admitted as a reserved dynamic MCP server with reserved tool names, not as ordinary built-in browser commands
- two distinct admission paths:
  - explicit opt-in, where CLI flag beats env and config defaults and non-interactive sessions stay off unless the CLI explicitly forces on
  - passive auto-attach, where an interactive session notices that the extension is already installed and rollout-eligible, then adds the integration without globally enabling the full browser instructions up front
- passive auto-attach prepending only a short startup hint that tells the model to invoke the `claude-in-chrome` skill before using Chrome tools
- explicit opt-in admitting the browser MCP tools directly and appending the full Chrome-specific operating guidance immediately
- public builds surfacing subscriber entitlement as part of Chrome availability rather than silently pretending the feature exists for every account
- a startup notification path that distinguishes "feature enabled but extension missing" from "feature enabled by default and ready"

## Chrome setup is best-effort and intentionally non-blocking

Equivalent behavior should preserve:

- startup not waiting for native-host installation before the session can continue
- creation of a wrapper executable because browser native-messaging manifests cannot encode process arguments directly
- install or refresh of native-host manifests in browser-specific locations, including Windows registry registration where needed
- avoiding unnecessary rewrites when wrapper or manifest content already matches the desired state
- opening a reconnect page only after a manifest rewrite when the extension is already installed, so the extension can rebind to the refreshed host
- extension detection scanning supported Chromium-family profile locations instead of trusting one browser path
- only positive extension detections being cached durably, so one machine without Chrome does not poison auto-enable for every other machine that shares config

## Chrome permissions live with the extension, not the generic Claude prompt

Equivalent behavior should preserve:

- site-level browser approvals being owned by the extension side of the integration rather than the ordinary Claude tool permission dialog
- session permission-bypass mode being mirrored into the Chrome integration so the extension can skip its own checks when the session is already in full-bypass posture
- runtime permission-mode changes being pushable into the connected browser integration instead of being fixed only at startup
- model guidance that is specific to the fragility of extension-driven browsing:
  - start by reading current tab context
  - do not reuse stale tab ids across sessions
  - avoid JavaScript modal dialogs that would block the extension event loop
  - stop and ask for help after a short run of repeated browser failures instead of looping indefinitely
- tool-search-specific instructions being injected only when the current tool pool actually requires ToolSearch to load Chrome MCP tools
- coexistence with a generic WebBrowser surface, with the Chrome integration reserved for the user's authenticated browser state, OAuth flows, or desktop-coupled tasks

## Native computer use is a separate local desktop-control surface

Equivalent behavior should preserve:

- native computer use being a distinct capability from Chrome automation, with its own reserved MCP server name and its own tool family
- availability being limited to interactive macOS sessions and gated by both build-time capability and runtime rollout config
- public rollout additionally depending on account tier while internal dogfooding can bypass that tier check
- some internal development environments being blocked unless explicitly overridden, so accidental monorepo/dev-shell inheritance does not silently expose the surface
- startup registering only a lightweight dynamic MCP entry while deferring heavy native module loading until the first actual computer-use call
- no fake fallback path once the native executor is actually needed; if the local native backend cannot run, the session should fail that capability rather than pretending to keep going

## Native computer use owns its own approval model

Equivalent behavior should preserve:

- generic per-tool approval being bypassed for the `mcp__computer-use__*` family
- approval becoming session-scoped inside the computer-use subsystem instead
- approval splitting into two different branches:
  - OS-level macOS permission recovery for missing Accessibility or Screen Recording grants
  - per-session app allowlisting and extra grant flags such as clipboard or system-key access
- approval UI being mid-tool, blocking, and prompt-input-hiding until the user resolves it
- abort or Ctrl+C cancelling the approval dialog cleanly instead of leaving a dangling tool wait
- permission/list-style tools being allowed to inspect lock state without necessarily acquiring exclusive desktop ownership yet

## Native computer use keeps long-lived session state and exclusive ownership

Equivalent behavior should preserve:

- one Claude session at a time owning active desktop control, enforced through a file lock under the Claude config home
- same-session re-entrancy succeeding while cross-session conflicts fail closed with a clear "already in use by another session" style refusal
- stale-lock recovery when the recorded owning process is gone
- a shutdown cleanup hook that releases the lock even if normal turn-end cleanup never runs
- session state persisting across calls for:
  - allowed apps
  - grant flags
  - selected and pinned display
  - auto-resolved display affinity
  - last screenshot dimensions
  - apps hidden during the current turn
- coordinate mode being latched once per session so prompt instructions, coordinate transforms, and screenshots stay aligned for the life of that session

## Native computer use has explicit entry and exit ceremony

Equivalent behavior should preserve:

- the first real desktop-control acquisition registering a global Escape hotkey
- Escape aborting the active turn or tool rather than being treated as ordinary UI navigation
- OS notifications marking both entry into and exit from active computer use
- turn-end cleanup running on both normal completion and abort paths
- cleanup un-hiding any apps hidden during the turn, clearing that hidden-app state, unregistering the global Escape hook, and releasing the exclusive lock
- unhide work being time-bounded so abort handling cannot hang indefinitely on cleanup
- exit notification only being emitted if the current session actually held the lock

## Failure modes

- **surface collapse**: the built-in WebBrowser surface, Chrome automation, and native computer use are flattened into one generic browser or desktop tool, losing their distinct approval and lifecycle rules
- **silent impersonation**: user-supplied MCP config is allowed to reuse the reserved server names and masquerade as the built-in browser or desktop surfaces
- **auto-enable poison**: a negative Chrome-extension detection is cached durably and prevents later sessions on other machines from auto-attaching correctly
- **dialog deadlock**: native computer-use approval leaves prompt input active or cannot be aborted, trapping the session mid-tool
- **lock leak**: the exclusive desktop lock survives a completed or aborted turn and blocks the next session from acquiring computer use
- **cleanup drift**: hidden apps or global Escape hooks survive beyond the computer-use turn and affect unrelated later work

## Test Design

In the observed source, specialized-tool behavior is verified through narrow schema regressions, subsystem integration tests, and surface-realistic end-to-end probes.

Equivalent coverage should prove:

- capability gates, input validation, and refusal rules remain stable for the edge cases that this tool family is expected to handle
- each tool still works correctly at the real subsystem boundary it touches, including browser, web, interview, or native-control style integrations when applicable
- ordinary tool-pool invocation preserves the visible success, rejection, contention, and cleanup behavior without relying on bespoke test backdoors
