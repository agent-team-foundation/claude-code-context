---
title: "Plugin Management and Marketplace Flows"
owners: []
soft_links: [/integrations/plugins/plugin-runtime-contract.md, /integrations/plugins/lsp-plugin-and-diagnostics.md, /platform-services/trust-and-capability-hydration.md, /ui-and-experience/feedback-and-notifications/interaction-feedback.md]
---

# Plugin Management and Marketplace Flows

Claude Code's plugin UX is not just a thin wrapper over "download a package and flip a boolean." It is a layered control plane that parses `/plugin` subcommands, separates desired state from materialized state and live runtime state, respects scope precedence, keeps trust and policy boundaries intact, and makes plugin refresh an explicit user-facing step. A faithful rebuild needs those layers and handoffs, or plugin installs will appear to succeed while commands, hooks, MCP servers, and LSP surfaces still reflect stale state.

## Scope boundary

This leaf covers:

- the `/plugin` interactive command family and its aliases
- discover, installed, marketplaces, errors, help, and validate surfaces
- scope-aware install, enable, disable, uninstall, and update behavior
- background marketplace reconciliation, delist enforcement, and refresh signaling
- the boundary between settings intent, on-disk plugin materialization, and live session activation

It intentionally does not re-document:

- the generic plugin admission and loading model already captured in [plugin-runtime-contract.md](plugin-runtime-contract.md)
- the deeper LSP-specific runtime and diagnostics loop beyond the plugin-management hooks that refresh or configure it
- the full trust model outside the plugin-specific startup and installation gates covered here

## Command shell and routing

Equivalent behavior should preserve:

- one immediate local-JSX `/plugin` command with `/plugins` and `/marketplace` aliases
- a lightweight command entrypoint that always routes into one shared plugin-settings shell rather than implementing separate interactive commands per subfeature
- argument parsing that recognizes at least `help`, `install`, `manage`, `uninstall`, `enable`, `disable`, `validate`, and `marketplace`
- `install <plugin>@<marketplace>` resolving as an exact plugin target, while `install <plugin>` stays marketplace-agnostic and `install <path-or-url>` is treated as marketplace input instead of a plugin ID
- `marketplace add|remove|update|list` being treated as sub-actions under one plugin-management namespace instead of as unrelated top-level commands
- unknown or incomplete subcommands falling back to the main plugin menu instead of hard failing immediately
- help, validation, and marketplace-list requests being able to short-circuit the tabbed shell and complete directly
- direct-target invocations such as "install this plugin," "update this marketplace," or "remove this marketplace" opening the same underlying views as the interactive menu and auto-running the requested action after target resolution

## Three-layer state model

Equivalent behavior should preserve a three-layer mental model:

1. **Intent layer**: settings files declare what plugins or extra marketplaces should exist and whether a plugin is enabled or disabled in each scope.
2. **Materialized layer**: marketplace clones, versioned plugin caches, and the installed-plugins index record what bits are actually on disk.
3. **Active layer**: the running session's `AppState`, hook registry, agent registry, MCP plugin server set, and LSP configuration determine what is live right now.

Equivalent behavior should also preserve:

- interactive plugin-management flows usually mutating only the intent layer and sometimes the materialized layer, then marking the active layer as stale
- a deliberate `needsRefresh` flag instead of silently hot-swapping the live session after every toggle
- `/reload-plugins` or an explicit auto-refresh path being the only supported way to rehydrate Layer 3 consistently
- error surfaces understanding all three layers, so the UI can tell the user whether a failure was a settings problem, a marketplace/materialization problem, or a live-load problem

## Plugin settings shell

Equivalent behavior should preserve:

- one tabbed shell with `Discover`, `Installed`, `Marketplaces`, and `Errors`
- the shell being able to start on a non-default tab when the parsed subcommand implies a more specific initial view
- discover mode supporting both a cross-market aggregated plugin list and a marketplace-specific browser
- an installed view focused on already enabled or cached plugins, not a duplicate of the discover catalog
- a marketplaces view that manages marketplace sources, refresh actions, and auto-update posture
- an errors view that counts both persistent plugin-load errors and failed marketplace-installation status rows
- direct add-marketplace mode temporarily replacing the tabbed shell with a focused input flow, then returning to marketplace management or plugin discovery depending on how the action was invoked
- successful CLI-style subflows returning a result string to the caller so the surrounding command can finish non-interactively instead of leaving the TUI open

## Discover and install flows

Equivalent behavior should preserve:

- a cross-market discover surface that aggregates plugins from every successfully loaded marketplace
- policy-blocked plugins being hidden from install choices rather than shown as selectable dead ends
- only globally installed plugins being excluded from discover by default; project- or local-scope installs should not block the user from later promoting the same plugin to user scope
- discover lists being sorted by popularity when install-count telemetry is available and degrading to alphabetical ordering when it is not
- marketplace-specific browsing keeping the selected marketplace identity visible and sortable independently from cross-market discover
- partial marketplace-load failure degrading to a warning while still showing plugins from the marketplaces that did load
- target-plugin deep links searching across all known marketplaces and either landing in a details view or returning a clean "already installed / not found" result
- the details view carrying install actions, homepage/open-link actions, and any plugin-specific post-install configuration branch
- every discover and browse surface carrying a persistent plugin-trust warning, including optional extra trust text from plugin helpers

## Marketplace lifecycle

Equivalent behavior should preserve:

- marketplace input accepting GitHub shorthand, SSH Git URLs, HTTPS sources, and local filesystem paths
- marketplace input being normalized before save so the runtime stores a resolved source instead of the raw unparsed user string
- adding a marketplace materializing it first and only then persisting the new source into editable settings
- clearing plugin and marketplace caches after marketplace changes so later loads cannot reuse stale "marketplace not found" or stale manifest results
- the interactive add flow navigating directly into the new marketplace's discover page after success, while CLI-targeted add flows complete with a text result instead
- marketplace lists showing source display text, last-updated information, plugin counts, installed-plugin counts, and auto-update posture
- the primary marketplace list sorting the official directory ahead of other sources, with the rest stable enough for keyboard targeting
- update actions refreshing marketplace clones first and then updating installed plugin records that came from those marketplaces, so the installed-plugins index cannot keep pointing at old versions after the source clone changed
- update flows distinguishing between newly materialized marketplaces and already-known marketplaces that merely refreshed
- remove actions uninstalling or disabling the marketplace's installed plugins from user-editable settings before deleting the marketplace source itself
- marketplaces injected by policy or other managed layers being visible but not removable through the ordinary editable-source path
- marketplace auto-update being configurable per marketplace rather than only as one global plugin switch

## Scope-aware plugin operations

Equivalent behavior should preserve these scope rules:

- install supports only `user`, `project`, and `local`; `managed` is an observed scope, not an end-user install target
- update is broader and may target `managed` installs because managed content can still need version refresh bookkeeping
- `project` and `local` scopes carrying current-project identity, while `user` scope stays project-agnostic
- scope resolution preferring the most specific editable scope when the user omits `--scope`
- explicit higher-precedence overrides being legal, such as writing a local disable that masks a project-scope enablement instead of mutating the shared project settings
- cross-scope mistakes returning corrective hints instead of generic failure, especially when the plugin exists but at a different scope than the user requested

Equivalent behavior should preserve these operation semantics:

- **install**: search exact marketplace when provided, otherwise scan all configured marketplaces until the named plugin is found
- **install**: reject organization-blocked plugins and plugins whose dependencies are blocked by policy
- **enable/disable**: treat settings as the source of intent first, rather than requiring the installed-plugins index to prove the plugin is already cached
- **enable/disable**: built-in plugins bypass install bookkeeping and always write through user settings
- **enable/disable**: disabling a plugin warns about reverse dependents but does not hard-block the action
- **uninstall**: use the installed-plugins index as the source of truth for scope-specific installations, including delisted plugins that no longer exist in marketplace manifests
- **uninstall**: special-case project-scope guidance because shared `.claude/settings.json` should push users toward a local override when they only want to disable the plugin for themselves
- **uninstall**: removing the last remaining installation also wipes saved plugin options, plugin secrets, and optionally the plugin data directory
- **uninstall**: old version directories are not deleted synchronously; they are marked orphaned when the last scope stops referencing them
- **update**: perform non-in-place updates by materializing a new versioned cache path, repointing the installed-plugins index, and marking the old version orphaned only if no installation still references it
- **update**: validate that local marketplace paths and plugin source paths still exist instead of silently reusing an old git-derived version answer
- **update**: report success as a version transition that still requires restart or reload before the running session actually reflects the new bits

## Post-install and post-enable configuration

Equivalent behavior should preserve:

- a post-install and post-enable diversion into a plugin-options flow when the plugin declares unconfigured top-level options or channel-specific MCP-style user configuration
- loading the just-installed plugin back from fresh plugin state instead of trying to guess configuration schema from stale pre-install state
- top-level plugin options and channel-specific config steps being walked through one shared dialog abstraction
- configuration dialogs pre-filling already-saved values where safe, while still respecting secret or sensitive-field handling
- "nothing to configure" short-circuiting cleanly instead of forcing the user through an empty wizard
- configuration cancel being treated as a skipped follow-up, not as an install rollback

## Startup reconciliation and trust gating

Equivalent behavior should preserve:

- plugin startup checks running only after workspace trust is accepted in interactive sessions
- untrusted interactive sessions skipping background marketplace and plugin installation entirely
- seed marketplaces being registered before diffing declared versus materialized marketplaces, so seeded content is not redundantly recloned as "missing"
- seed-marketplace changes invalidating earlier plugin caches and setting `needsRefresh` if the initial load may already have memoized stale "missing marketplace" results
- background installation tracking only marketplace-level pending/installing/installed/failed rows, because marketplace clone/update work is the slow visible operation
- a startup diff between declared marketplaces and materialized marketplaces driving background reconciliation
- newly installed marketplaces attempting an automatic Layer-3 refresh because the first live plugin load may have happened before the marketplace cache existed
- update-only reconciliation not forcing an automatic live swap; instead it should set `needsRefresh` and ask the user to run `/reload-plugins`
- auto-refresh failure degrading to `needsRefresh` rather than leaving the session with neither fresh state nor a recovery hint

## Delisted and flagged plugin handling

Equivalent behavior should preserve:

- delist detection comparing installed plugin IDs against current marketplace manifests for marketplaces that explicitly opt into force-removal of deleted entries
- delist enforcement skipping managed-only installations, because enterprise-managed removal belongs to the administrator path
- user-, project-, and local-scope installs of a delisted plugin being auto-uninstalled from every user-controllable scope
- flagged-plugin records being written after delist enforcement so the user gets a durable explanation rather than a silent disappearance
- the installed-plugin UI surfacing flagged plugins as their own special rows or detail states, not quietly merging them into generic plugin failures
- pending flagged plugins producing a high-priority notification that points the user back to `/plugins`
- flagged entries being markable as seen once the installed view actually renders them

## `needsRefresh` and `/reload-plugins`

Equivalent behavior should preserve:

- ordinary interactive plugin-management actions setting `needsRefresh` instead of immediately mutating the running command, hook, agent, MCP, and LSP registries
- `useManagePlugins` showing a notification that tells the user to run `/reload-plugins` when `needsRefresh` becomes true, but not auto-consuming that flag
- `/reload-plugins` being the canonical Layer-3 refresh primitive for interactive sessions
- the refresh primitive clearing all plugin caches, reloading enabled and disabled plugin sets, rehydrating plugin commands, rehydrating agent definitions, reloading plugin hooks, and repopulating plugin MCP and LSP metadata
- the refresh primitive consuming `needsRefresh` and bumping the MCP plugin reconnect key so connection-management effects actually re-run against the new plugin server set
- LSP manager reinitialization happening unconditionally after plugin refresh, so both added and removed plugin LSP servers take effect
- refresh reporting separate counts for enabled plugins, plugin commands, agents, hooks, plugin MCP servers, and plugin LSP servers
- refresh returning a compact success summary but also explicitly nudging the user toward `/doctor` when load errors remain
- remote-capable `/reload-plugins` paths re-downloading synced user settings before the cache sweep so remotely changed enabled-plugin or extra-marketplace settings can take effect mid-session
- managed settings intentionally not being refetched by `/reload-plugins`, because that channel already has its own slower polling and stale-cache contract

## Error and degradation model

Equivalent behavior should preserve:

- core plugin operations being pure library-style functions that return structured success or failure results, while CLI wrappers add stdout, exit codes, and telemetry
- interactive UI and non-interactive CLI wrappers sharing the same install, uninstall, enable, disable, and update logic instead of drifting into separate semantics
- transient marketplace or git/network failures being identifiable as restart-or-retry candidates rather than being mixed with permanent validation or policy failures
- partial marketplace-load success still populating discover or marketplace views, with warning banners instead of whole-command failure
- persistent plugin-load errors from commands, agents, hooks, MCP plugin servers, LSP plugin servers, and plugin-system bootstrap all flowing into shared app-state error storage
- the errors tab offering actionable routing when possible: navigate to uninstall a broken plugin, navigate to remove a broken marketplace, or explain that a managed source must be fixed by an administrator
- plugin-management surfaces continuing to function even when install counts, external metadata, or some marketplace clones fail to load

## Failure modes

- **layer collapse**: settings are updated but the live runtime silently stays stale because the rebuild skipped `needsRefresh` and the explicit reload contract
- **scope corruption**: a local override rewrites shared project intent, or a scope-specific uninstall removes the wrong installation record
- **false install success**: the UI reports success after changing settings, but the marketplace clone, cache copy, or live refresh never happened
- **managed-source clobbering**: editable UI paths allow deletion or mutation of policy-owned marketplaces or plugins
- **delist invisibility**: removed marketplace entries disappear without flagged-user explanation, making plugin loss look arbitrary
- **refresh skew**: commands refresh but MCP and LSP state do not, so the extension surface disagrees with itself after `/reload-plugins`
- **cache ghosting**: marketplace or plugin caches survive source changes and keep returning stale manifests, versions, or "not found" outcomes
- **config dead-end**: plugins that require user configuration install successfully but never divert into the follow-up options flow, leaving them half-usable
