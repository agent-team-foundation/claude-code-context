---
title: "Remote Setup and Companion Bootstrap"
owners: []
soft_links: [/integrations/clients/remote-and-managed-client-envelopes.md, /collaboration-and-agents/bridge-transport-and-remote-control-runtime.md, /platform-services/auth-login-logout-and-token-lifecycle.md, /ui-and-experience/terminal-ui.md]
---

# Remote Setup and Companion Bootstrap

Claude Code does not leave browser or companion setup entirely outside the product. It ships a set of local bootstrap surfaces that turn local auth, OS integrations, environment settings, extension state, and deep links into a usable web, desktop, mobile, or browser-connected experience. A full reconstruction needs these orchestration flows, not only the underlying transport contracts.

## Scope boundary

This leaf covers:

- the local bootstrap commands that provision or hand off to web, desktop, mobile, and browser-connected companion surfaces
- how remote-environment selection resolves the currently effective environment and lets the user change it
- how bridge status is turned into a QR-capable in-terminal companion dialog
- how local OS, browser, and extension checks gate the user-visible bootstrap path

It intentionally does not re-document:

- bridge transport, reconnect, dedup, and teardown internals already captured in [bridge-transport-and-remote-control-runtime.md](../../collaboration-and-agents/bridge-transport-and-remote-control-runtime.md)
- the broader remote and managed client envelope model already captured in [remote-and-managed-client-envelopes.md](remote-and-managed-client-envelopes.md)
- generic command-safety rules beyond the bootstrap-specific fact that these surfaces are local orchestration wrappers rather than remote-safe bridge commands

## Bootstrap surfaces are local orchestration wrappers

Equivalent behavior should preserve:

- companion bootstrap commands running locally because they need local Ink UI, local auth inspection, local filesystem or session state, OS protocol handlers, browser launching, or extension detection
- these commands wrapping the same underlying session and environment model instead of inventing a second remote product state machine
- failure states being explained in terms of the missing local prerequisite, such as Claude auth, GitHub auth, environment availability, app installation, browser extension installation, subscription eligibility, or OS support
- session-oriented bootstrap surfaces handing control to another client without silently changing the logical session identity underneath
- install-oriented bootstrap surfaces being allowed to stop at store, download, or reconnect instructions rather than pretending they completed a live handoff

The key distinction is that these surfaces help the user reach a usable companion client. They do not replace the runtime semantics captured elsewhere.

## Web bootstrap and GitHub credential import

Equivalent behavior should preserve:

- `/remote-setup` first requiring Claude.ai OAuth identity, not API-key-only auth
- the next gate checking whether GitHub CLI exists and is authenticated locally, with a direct browser fallback when it is missing or not logged in
- a browser fallback URL that lands the user in an alternate-auth onboarding step instead of a generic homepage dead end
- local GitHub tokens being wrapped in a redacted object so logs, stringification, and accidental error formatting cannot leak the raw token value
- token import going through one dedicated backend endpoint that validates the token with GitHub, stores it in a web-session-compatible way, and returns structured not-signed-in, invalid-token, server, or network outcomes
- success continuing with best-effort default-environment creation only when the user has no environments already, so re-running setup does not create duplicates
- environment creation failures remaining non-fatal once token import succeeded, because the web app can still route the user into environment setup on arrival
- the success path ending by opening the Claude Code web surface directly after credential import instead of asking the user to manually navigate there

This bootstrap path is important because the web surface depends on credentials and environment metadata that the local CLI can already verify and provision.

## Remote environment discovery and source-aware selection

Equivalent behavior should preserve:

- environment discovery using the authenticated environment-provider API together with the current organization identity
- no-environment situations surfacing a setup hint rather than a mysterious empty selector
- effective-environment resolution starting from the merged runtime settings, then matching that configured default environment ID against the actually available environment list
- if no configured default matches, the runtime preferring a non-bridge environment as the implicit default and falling back to the first available environment only when necessary
- the UI being able to tell the user where the current default came from by scanning setting sources and reporting the highest-priority source that actually set that environment ID
- one-environment situations collapsing to an informational dialog instead of forcing a meaningless picker
- multi-environment situations showing the current environment, optionally annotating that it came from a non-local source, and then offering a compact picker over environment name plus stable environment ID
- selecting a new environment writing only `remote.defaultEnvironmentId` into local settings, even if the currently effective value came from another source
- loading, error, and cancel states remaining explicit so the user knows whether the selector failed, had nothing to choose, or simply exited without changes

## Desktop handoff and deep-link resume

Equivalent behavior should preserve:

- `/desktop` checking whether Claude Desktop is installed and meets a minimum supported version before attempting handoff
- install detection being platform-aware instead of a single hardcoded path, with different checks for app presence, protocol handling, or registry support depending on OS
- development builds using a development deep-link scheme and launch path rather than assuming the production desktop protocol
- deep-link handoff encoding both the current session identity and the current working directory so the desktop app can reopen the right session in the right repo context
- session storage being flushed before the deep link is opened, ensuring the receiving desktop client can resume a fully persisted transcript instead of a stale partial snapshot
- missing or outdated desktop installs prompting an immediate download path instead of failing silently
- successful desktop handoff briefly confirming transfer and then gracefully shutting down the CLI so the session is not actively owned by two local clients at once
- deep-link open failures surfacing a concrete manual-retry error instead of pretending the transfer happened

## Bridge dialog and in-terminal companion pairing UX

Equivalent behavior should preserve:

- one bridge-status dialog overlay reading live bridge state from app state rather than recomputing transport truth on its own
- status display choosing a session URL once a session is active and a connect URL while the bridge is only ready to pair
- QR generation happening only when the user explicitly toggles it and a displayable URL exists
- the dialog adding repo basename and current branch as lightweight pairing context so the user can tell which workspace they are about to control
- footer text following the same ready, active, and failed status model as the rest of the bridge surface instead of inventing different wording for the dialog
- verbose mode being able to expose raw environment and session identifiers for debugging without forcing those details into the normal UX
- keyboard behavior supporting close, QR toggle, and disconnect directly inside the dialog
- disconnect mutating persistent startup preference only when remote control was explicitly turned on by the user, while settings-driven or rollout-driven auto-connect paths get session-only disconnect so the dialog does not silently overwrite broader config decisions

## Mobile install and Chrome companion wrappers

Equivalent behavior should preserve:

- `/mobile` acting as an install and acquisition helper rather than a live session-handoff surface
- mobile bootstrap precomputing both iOS and Android QR codes so switching platforms is instant and does not flicker through a second async generation step
- mobile install UI showing the exact store destination and allowing quick keyboard switching between platforms plus immediate dismiss
- `/chrome` treating Claude-in-Chrome as an extension-backed companion wrapper with its own install, reconnect, permission-management, and default-enable flows
- Chrome bootstrap checking both local support constraints, such as WSL, and product eligibility constraints, such as requiring a claude.ai subscription
- extension presence and MCP connection status being shown separately, because an installed extension and an actively connected browser bridge are not the same condition
- reconnect and permission-management actions opening the appropriate browser destinations, while the default-enable toggle persists a local preference for future sessions
- site-level browsing permissions remaining owned by the browser extension settings rather than being reimplemented inside the CLI command

## Failure modes

- **auth confusion**: setup treats API-key auth as sufficient for web or environment bootstrap, so users hit later failures that should have been caught up front
- **token leak**: the GitHub bootstrap path logs or stringifies a raw local token while reporting an import failure
- **duplicate environment sprawl**: re-running remote setup creates a new default environment every time instead of first checking whether one already exists
- **source opacity**: the remote-environment picker changes behavior based on layered settings but does not explain which source currently wins
- **desktop split-brain**: the CLI opens the desktop deep link without flushing transcript state or without shutting itself down afterward, so the resumed desktop session diverges
- **bootstrap false-positive**: install or extension checks mark a companion surface ready even though the local OS or subscription cannot actually complete the flow
- **disconnect overreach**: closing bridge pairing persists a global opt-out for users who were only temporarily auto-connected by settings or rollout state
- **status drift**: the pairing dialog shows a stale connect URL, wrong session phase, or missing QR state because it no longer reflects the live bridge app state
