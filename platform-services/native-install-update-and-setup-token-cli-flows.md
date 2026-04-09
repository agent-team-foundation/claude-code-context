---
title: "Native Install, Update, and Setup-Token CLI Flows"
owners: []
soft_links: [/platform-services/doctor-command-and-health-diagnostics.md, /platform-services/auth-login-logout-and-token-lifecycle.md, /platform-services/deep-link-protocol-trampoline-and-origin-banner.md]
---

# Native Install, Update, and Setup-Token CLI Flows

Claude Code's standalone management commands are not just thin wrappers around
one config file. `claude install`, `claude update`, and `claude setup-token`
share installation-health logic with `claude doctor`, but each also adds its
own launch, repair, and user-handoff behavior. A faithful rebuild needs those
CLI-specific flows rather than only the lower-level auth or diagnostics
backends.

## Scope boundary

This leaf covers:

- the standalone `claude install` native-launcher flow
- the standalone `claude update` flow and its shared health checks
- the standalone `claude setup-token` limited-scope OAuth flow
- the TTY and browser-handoff expectations that matter for these commands

It intentionally does not re-document:

- the full diagnostics aggregation model already covered in
  [doctor-command-and-health-diagnostics.md](doctor-command-and-health-diagnostics.md)
- the broader auth lifecycle already covered in
  [auth-login-logout-and-token-lifecycle.md](auth-login-logout-and-token-lifecycle.md)
- the deep-link or terminal-launch trampoline beyond how launcher paths are
  surfaced to users

## Shared management-command posture

Equivalent behavior should preserve:

- one shared installation-health backend reused by `doctor`, `install`, and
  `update`
- top-level commands printing compact terminal rows rather than opening the full
  REPL
- raw-mode-dependent flows failing early outside a TTY instead of degrading into
  partially interactive nonsense
- install/update warnings being phrased as issue-plus-fix text, not only as
  opaque status codes

## `claude install` is a native-launcher flow

Equivalent behavior should preserve:

- `claude install` opening with `Checking installation status...`
- the default target being the current native release channel rather than a
  project-local development install
- explicit targets such as `stable`, `latest`, or a concrete version string
  resolving before the launcher is rewritten
- native install creating or updating the user-facing launcher path and then
  surfacing shell-integration guidance
- PATH remediation being shown immediately when the user-level native bin
  directory is not available from the current shell
- success output including a version line, launcher location, and a simple "next
  step" handoff

The important reconstruction lesson is that install is not just "copy a
binary." It also repairs the runnable launcher surface and teaches the user how
that launcher becomes reachable.

## `claude update` reuses health checks before attempting mutation

Equivalent behavior should preserve:

- `claude update` opening with the current version and the release channel it is
  checking
- the same PATH and install-method mismatch warnings that `doctor` would have
  surfaced
- install-method mismatch repair happening inline before the updater proceeds,
  instead of forcing the user to run a second command manually
- repair not short-circuiting the rest of the update flow when a newer native
  version is still available
- up-to-date states being explicit when the shipped native build is already at
  the newest observed release, while available updates still end in a concrete
  success summary such as `Successfully updated from X to version Y`

The rebuild target is not merely "check if a version differs." It is a
diagnostics-aware updater that can repair known launcher metadata drift and then
continue.

## Launcher and install metadata stay user-visible

Equivalent behavior should preserve:

- the currently running native version being distinguishable from the latest
  available version
- launcher-path metadata being available to both install/update summaries and
  doctor diagnostics
- persisted install-method state being repairable when the launcher on disk and
  the saved install metadata drift apart
- versioned native-install records remaining inspectable enough that later
  health commands can explain what is supposed to be running

## `claude setup-token` is a limited-scope OAuth helper, not a full login

Equivalent behavior should preserve:

- the command being a top-level CLI entry point rather than an alias for full
  account login
- a TTY/raw-mode requirement because the flow expects interactive browser or
  manual-code handoff
- a welcome banner before browser launch
- a warning only when another auth source is already configured, clarifying
  that this flow will create an additional OAuth token rather than replacing
  the main session
- browser-open first, followed by a manual fallback URL and pasted-code prompt
  if the browser does not complete the flow quickly
- the resulting token being treated as limited-scope material, not as a signal
  to tear down and replace the current logged-in identity

This flow lives on the auth stack, but it must not reuse the destructive
logout-before-install path that a real account switch uses.

## Delayed manual fallback is part of the UX contract

Equivalent behavior should preserve:

- an initial optimistic browser-open step instead of requiring manual code entry
  every time
- a delayed terminal fallback that prints the authorization URL in a copyable
  form when browser launch does not complete
- a pasted-code prompt that keeps the user inside the same CLI flow instead of
  forcing them to restart the command

## Failure modes

- **launcher drift**: install/update reports success but leaves the runnable
  launcher pointing at an older or unrelated binary
- **repair dead-end**: `update` notices install-method drift but stops after
  rewriting metadata instead of continuing to the available update
- **PATH invisibility**: native install succeeds on disk but never explains why
  `claude` is still not found from the user's shell
- **destructive token helper**: `setup-token` accidentally replaces the main
  logged-in identity instead of creating limited-scope OAuth material
- **browser dead-end**: browser launch fails and the CLI never prints the
  fallback URL or pasted-code prompt
