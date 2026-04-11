---
title: "Doctor Command and Health Diagnostics"
owners: []
soft_links: [/product-surface/command-surface.md, /platform-services/bootstrap-and-service-failures.md, /ui-and-experience/feedback-and-notifications/interaction-feedback.md, /ui-and-experience/shell-and-input/keybinding-customization-and-context-resolution.md]
---

# Doctor Command and Health Diagnostics

Claude Code's doctor surface is not just one command that prints a couple of install checks. It is a dual-entry operational diagnostic plane that aggregates installation health, update posture, settings validation, MCP parsing, sandbox dependency status, plugin and agent load failures, permission-rule reachability, and context-budget warnings. A faithful rebuild needs both the shared diagnostic producers and the aggregation contract that keeps all of those sources visible in one place.

## Scope boundary

This leaf covers:

- the interactive `/doctor` command and the standalone `claude doctor` subcommand
- trust and side-effect posture for doctor-style health checks
- the shared installation and update health backend used by multiple surfaces
- the doctor screen's section ordering, data sources, and degradation rules
- persistent diagnostic surfaces for settings, keybindings, MCP, plugins, sandboxing, agents, version locks, and context overuse

It intentionally does not re-document:

- the full command catalog beyond the doctor entry point already summarized in [command-surface.md](../product-surface/command-surface.md)
- the full keybinding customization model beyond the fact that doctor hosts its persistent warning surface
- the full MCP, plugin, sandbox, or permission implementations beyond the warnings they feed into doctor

## Entry paths and trust posture

Equivalent behavior should preserve:

- an interactive `/doctor` command in the REPL command registry
- that interactive command being env-gated, so a truthy `DISABLE_DOCTOR_COMMAND` can remove it without changing the broader runtime
- the interactive command being thin: it simply resolves the shared `Doctor` screen inside the existing session
- a separate top-level `claude doctor` CLI subcommand that mounts the same shared `Doctor` screen outside the REPL loop
- the standalone CLI command explicitly warning that the workspace trust dialog is skipped and stdio MCP servers from `.mcp.json` may be spawned for health checks, so it should only be run in trusted directories
- the standalone CLI command logging its own analytics event, creating an Ink root, mounting app state and keybinding providers, and then exiting the process after dismissal
- the interactive REPL path dismissing back into the session with a system-style completion message rather than terminating the process

## Standalone CLI wrapper responsibilities

Equivalent behavior should preserve:

- the standalone `claude doctor` path mounting `AppStateProvider`, `KeybindingSetup`, and `MCPConnectionManager` even though it is not a full REPL session
- that CLI path wrapping the doctor screen in a plugin-management layer before rendering, so plugin command, agent, hook, MCP, and LSP load failures can populate app state and appear inside the doctor UI
- the MCP connection manager being started in a simple direct mode rather than requiring dynamic MCP config injection from another surface
- doctor therefore having real side effects in CLI mode: plugin loading, MCP server connection attempts, and related health checks are part of the command contract, not a purely static report

## Aggregation model

Equivalent behavior should preserve:

- the `Doctor` screen acting mainly as an aggregation layer rather than the sole producer of diagnostics
- one shared installation-health snapshot coming from `getDoctorDiagnostic()`
- a second async collection pass deriving context warnings, agent parse errors, and PID-based version-lock information from live app state plus local filesystem inspection
- the screen subscribing to current agent definitions, loaded MCP tools, live tool-permission context, and accumulated plugin errors from app state
- a loading placeholder while the core installation snapshot is still unresolved
- installation diagnostics and updates diagnostics sharing the same installation snapshot rather than each re-implementing their own detection logic
- the updates panel separately resolving release-channel metadata after installation type is known, choosing native release tags for native installs and npm dist-tags for non-native installs
- failed version-tag fetches degrading to a simple "failed to fetch versions" row instead of breaking the entire screen

## Shared installation and updater health backend

Equivalent behavior should preserve:

- one shared backend that is reused by `/doctor`, `claude doctor`, `claude update`, and status-style installation health output
- installation-type detection across development, native bundled installs, package-manager installs, local npm installs, global npm installs, and unknown cases
- reported metadata including current version, installation path, invoked binary, configured install method, package-manager identity when relevant, auto-update posture, update-permission status, and ripgrep status
- multiple-installation discovery instead of assuming the currently running binary is the only copy on disk
- ripgrep diagnostics reporting both whether search is working and whether the active resolver is system, bundled, or vendor-provided

## Installation warning synthesis

Equivalent behavior should preserve:

- doctor warnings being synthesized as issue-plus-fix pairs rather than opaque codes
- raw managed-settings inspection for `strictPluginOnlyCustomization` so invalid or forward-incompatible values are surfaced even when schema preprocessing would otherwise silently drop them
- native-install PATH checks warning when the expected user-level binary directory is missing from shell PATH
- platform-specific remediation text for PATH issues on Windows versus Unix-like shells
- config-versus-runtime mismatch warnings when the persisted install method does not match the installation actually being run
- local-install accessibility warnings when the local binary is neither on PATH nor reachable through a valid alias
- Linux-specific warnings when sandbox permission rules rely on glob patterns that the Linux sandbox layer cannot fully honor
- auto-update permission warnings for global npm installs that lack write access
- native-install cleanup warnings for leftover global npm installs, orphaned npm packages, or leftover local npm installs

## Reused and embedded diagnostic surfaces

Equivalent behavior should preserve:

- generic settings validation errors appearing in doctor through the shared settings-validation pipeline rather than a doctor-specific parser
- MCP parsing issues being split out into a dedicated MCP diagnostics section instead of being mixed into the generic settings error list
- keybinding configuration issues appearing through a dedicated persistent section that reads cached keybinding warnings and shows the keybindings file location
- sandbox dependency warnings appearing only when sandboxing is both supported on the platform and enabled in settings
- sandbox doctor rows distinguishing missing dependencies from warning-only states and pointing users toward `/sandbox` when install instructions are needed
- environment-variable checks for bounded output-length configuration, including invalid-value and capped-value states

## MCP and keybinding diagnostic presentation

Equivalent behavior should preserve:

- MCP config diagnostics reading each config scope once on mount instead of repeatedly re-reading files on every render
- MCP config diagnostics covering user, project, local, and enterprise scopes
- MCP config diagnostics splitting fatal parse failures from warnings, retaining server-name and path metadata when available
- MCP config diagnostics showing the concrete config-file location for each scope
- keybinding diagnostics only appearing when keybinding customization is actually enabled
- keybinding diagnostics separating errors from warnings, showing the config file path, and preserving suggestion text when available
- generic settings sections filtering MCP-tagged validation errors out of the main "Invalid Settings" section so doctor does not duplicate the same MCP problem in two places

## Context and policy warnings

Equivalent behavior should preserve:

- a dedicated context-warning collector rather than ad hoc checks inside the UI layer
- large `CLAUDE.md` warnings based on the shared memory-file sizing heuristic
- large custom-agent-description warnings based on the same token-budget logic used elsewhere in context/status surfaces
- large MCP-tool-context warnings using exact token counting when available, with a rough-estimation fallback when detailed counting fails
- MCP context warnings disappearing quietly when MCP tools are not loaded yet, rather than forcing a misleading "healthy" or "broken" judgment before connections are ready
- unreachable permission-rule warnings being computed from the live permission context, including sandbox-related behavior that can shadow rules
- unreachable permission-rule output preserving both the specific shadowed rule and a remediation hint

## Plugin, agent, and version-lock diagnostics

Equivalent behavior should preserve:

- plugin errors coming from persistent app-state plugin error storage rather than transient console logging
- plugin load failures across commands, agents, hooks, MCP plugin servers, LSP servers, and plugin-system bootstrapping all being eligible to surface in doctor
- agent parse errors using the existing agent-definition loader results instead of rescanning agent files separately inside doctor
- PID-based version-lock diagnostics only appearing when the PID-locking capability is enabled
- stale version locks being cleaned up before the version-lock section is rendered
- the version-lock section showing either "no active locks" or a per-version PID list with running-versus-stale status

## Presentation order and UI contract

Equivalent behavior should preserve this overall section order:

- `Diagnostics`
- `Updates`
- sandbox diagnostics
- MCP config diagnostics
- keybinding configuration issues
- environment-variable warnings
- version locks
- agent parse errors
- plugin errors
- unreachable permission rules
- broader context-usage warnings
- a dismiss/continue prompt

Equivalent behavior should also preserve:

- the doctor view living in one pane rather than spawning multiple subdialogs
- the diagnostics and updates sections using compact terminal rows rather than card-heavy layout
- invalid settings being grouped by file and nested dot-path tree so one malformed settings file does not turn into a flat wall of unrelated lines
- deduplicated suggestions and doc links for settings validation output
- a dismiss path wired through confirmation-context keybindings and a press-to-continue footer instead of requiring mouse interaction
- settings-validation notifications outside doctor explicitly pointing users toward `/doctor`, while remote mode suppresses that breadcrumb

## Shared behavior with update and status surfaces

Equivalent behavior should preserve:

- `claude update` reusing the same installation-health backend before attempting any updater action
- update flows surfacing the same multiple-installation and warning set that doctor would have shown, rather than silently marching past known conflicts
- status-style installation health output reusing doctor warnings such as invalid settings files, leftover installations, and update-permission issues
- doctor therefore being the canonical human-facing aggregation surface, while update and status reuse its lower-level health judgments

## Degradation rules

Equivalent behavior should preserve:

- non-essential fetches, such as release-tag lookup or approximate MCP token counting, failing soft without collapsing the whole doctor view
- settings, plugin, and MCP parse issues remaining visible even when the product falls back to defaults elsewhere
- doctor continuing to work as a degraded aggregator even when some producers are unavailable, delayed, or only partially initialized
- the wider product continuing to run if diagnostic subsystems fail, with doctor acting as the place where those failures become legible rather than as a startup gate

## Failure modes

- **trust drift**: standalone `claude doctor` loses or hides the warning that trust is skipped, and users unknowingly spawn local MCP health checks in untrusted directories
- **logic fork**: doctor, update, and status each grow their own installation heuristics and start disagreeing about the same machine state
- **silent fallback**: settings, keybinding, MCP, or plugin issues fall back internally but no longer leave a persistent breadcrumb in doctor
- **false health due to timing**: doctor treats not-yet-loaded MCP tools or plugin state as definitively healthy instead of recognizing partial initialization
- **plugin invisibility**: plugin load failures only hit logs and never make it into `AppState.plugins.errors`, so the doctor view looks healthy while capabilities are missing
- **blocking diagnostics**: optional health checks become hard dependencies and make doctor or startup unusably slow or fragile
- **section drift**: the screen order or filtering rules change and users see the same problem duplicated, hidden, or reclassified depending on which producer emitted it

## Test Design

In the observed source, platform-service behavior is verified through sequencing-sensitive integration tests, deterministic state regressions, and CLI-visible service flows.

Equivalent coverage should prove:

- config resolution, policy gates, persistence, and service startup ordering preserve the contracts and failure handling described above
- provider-backed or OS-bound branches use fixtures, seeded stores, or narrow seams so auth, update, telemetry, and trust behavior stays reproducible
- users still encounter the expected startup, settings, trust, diagnostics, and account-state behavior through the real CLI surface
