---
title: "Settings Change Detection and Runtime Reload"
owners: []
soft_links: [/platform-services/policy-and-managed-settings-lifecycle.md, /platform-services/sync-and-managed-state.md, /tools-and-permissions/permissions/permission-rule-loading-and-persistence.md, /tools-and-permissions/permissions/sandbox-selection-and-bypass-guards.md, /integrations/plugins/plugin-runtime-contract.md, /ui-and-experience/shell-and-input/keybinding-customization-and-context-resolution.md, /platform-services/settings-schema-compatibility-and-invalid-field-preservation.md]
---

# Settings Change Detection and Runtime Reload

Claude Code does not wait for a restart before most settings changes take effect. A live pipeline detects file and non-file mutations, runs configurable veto hooks, resets caches once, reapplies merged settings into the active store, and lets downstream systems such as permissions, sandboxing, plugin hooks, and diagnostics refresh selectively. A faithful rebuild needs that whole pipeline; otherwise the TUI, headless SDK path, and background services will quietly drift apart.

## Scope boundary

This leaf covers:

- the shared detector that notices settings changes from filesystem and programmatic sources
- the fan-out contract that delivers those changes into interactive and headless runtime state
- the canonical reapply path that refreshes settings, permission context, hook snapshots, and denormalized state
- downstream side effects and selective subscribers that react after settings move through the main pipeline

It intentionally does not re-document:

- remote managed settings fetch, cache, polling, and eligibility logic already covered in [policy-and-managed-settings-lifecycle.md](policy-and-managed-settings-lifecycle.md)
- settings sync products and cross-environment transport already covered in [sync-and-managed-state.md](sync-and-managed-state.md)
- permission rule semantics or edit operations already covered in [permission-rule-loading-and-persistence.md](../tools-and-permissions/permissions/permission-rule-loading-and-persistence.md)
- feature-specific hot reload systems such as keybindings beyond the fact that they sit adjacent to this pipeline

## Shared design rule

Equivalent behavior should preserve:

- one central settings-change producer being responsible for cache reset and notification
- one shared runtime-apply function being used by both the interactive React path and the headless or SDK path
- settings changes refreshing more than the raw merged JSON: permission context, hook configuration, auth-helper caches, and environment overlays all need to stay in sync
- feature-specific consumers being allowed to subscribe selectively, but not to replace the canonical settings-reload path with their own shadow loader

## Detector topology and watch targets

Equivalent behavior should preserve:

- the file watcher being disabled entirely in remote mode
- initialization happening at most once per process, plus cleanup registration so graceful shutdown can stop watchers and timers
- a separate periodic poll for managed machine settings such as MDM or HKCU-style overlays, because those sources are not normal watched files
- filesystem watching only directories that already contain at least one known settings file at startup, to avoid crawling unrelated trees
- those watched directories still registering every potential settings file path for that directory, so a currently missing file can be created later and still be detected
- `flagSettings` being excluded from filesystem watching because command-line settings are treated as session-scoped inputs rather than live files
- the managed drop-in directory being watched separately at shallow depth, with each JSON fragment inside it mapped back to the managed-policy settings source
- special files such as sockets, FIFOs, or devices being ignored
- `.git` directories being ignored
- only immediate children of the watched directories being relevant, not arbitrary nested descendants

## Stability, suppression, and hook gating

Equivalent behavior should preserve:

- write-stability buffering before processing file mutations, so the runtime does not react to half-written JSON
- a distinct internal-write suppression map that marks in-process writes and consumes the mark on the first matching watcher event
- that internal-write suppression being time-windowed rather than permanent, so a real later external change to the same file still propagates
- deletion events using a grace period instead of firing immediately, to absorb delete-and-recreate patterns from updaters or sibling sessions
- a recreated file canceling the pending deletion and being treated as an ordinary change
- configuration-change hooks running before a change or deletion is applied to the live session
- blocking hook results vetoing the runtime reload rather than merely logging a warning after the change is already active

## Central fan-out and cache reset

Equivalent behavior should preserve:

- the detector resetting the merged-settings cache exactly once before notifying subscribers
- all notification paths, including programmatic ones, going through that same reset-and-emit function
- listeners reading fresh merged settings after notification instead of each listener defensively clearing the cache again
- the architectural invariant that one settings notification should produce one fresh disk or cache read, not one re-read per subscriber

Without that single-producer reset, the live system thrashes the disk and different subscribers can observe different snapshots of the same update.

## Non-filesystem change producers

Equivalent behavior should preserve:

- machine-managed settings pollers being able to trigger the same reload pipeline when their snapshot changes
- remote managed settings load, refresh, and background poll paths notifying the detector programmatically after their cache changes
- headless remote user-settings re-download paths notifying the detector when freshly pulled user settings were applied
- in-memory flag-settings updates from SDK or control-plane requests notifying the detector instead of calling the runtime-apply function directly
- ordinary settings-writing surfaces such as config or voice toggles being able to reuse the same notification path after user-settings writes complete

The important contract is that non-filesystem settings mutations still enter through the same fan-out point as watcher events.

## Interactive and headless delivery parity

Equivalent behavior should preserve:

- interactive sessions subscribing through one React-facing hook that receives the detector's source labels and then applies the shared runtime reload
- the React app-state provider using an effect-event style wrapper so the subscription stays stable while still calling the current store updater
- a mount-time repair path for the race where remote managed settings arrive before the React subscriber exists, especially for bypass-permissions disablement
- headless or SDK mode subscribing directly because there is no React tree to host the hook
- that headless subscription calling the same shared runtime-apply function as the TUI path
- headless mode also resynchronizing denormalized fast-mode state from settings after reload, because there is no interactive picker keeping that field current
- both interactive and headless stores being created with the same app-state change callback infrastructure so later state-diff side effects stay aligned

## What applying a settings change means

Equivalent behavior should preserve:

- re-reading the merged effective settings fresh when a notification arrives
- reloading permission rules from disk and resynchronizing them into the live permission context
- refreshing the hooks configuration snapshot on every settings apply so later hook execution sees the new config
- certain internal foreground builds re-stripping overly broad Bash permissions after rule sync, rather than assuming the previous in-memory pruning still matches disk
- re-disabling bypass-permissions mode if the freshly loaded settings or gates no longer allow it
- transitioning plan-auto permission state through the same helper used elsewhere, so settings reload does not leave auto-plan in an impossible intermediate state
- careful synchronization of denormalized effort state from settings, but only when the settings value itself actually changed and only when the new persisted value is defined
- session-only overrides such as CLI effort values not being wiped by unrelated settings churn

## Post-state side effects

Equivalent behavior should preserve:

- state-diff handling clearing cached api-key-helper, AWS, and GCP credentials whenever the settings object changes, so auth-related helpers react immediately
- settings env changes reapplying config-derived environment variables after state update
- that environment application being additive-only: new variables can appear, existing values can be overwritten, but removed keys are not forcibly unset from the process
- settings reload flowing through the same global app-state diff layer that also handles other persistence and metadata duties, rather than creating a special side channel just for settings

The practical point is that a settings reload is not finished when the settings object changes; it is finished only after the state-diff side effects have run.

## Startup timing and race handling

Equivalent behavior should preserve:

- settings-change detector startup being deferred until after the earliest render-critical initialization, so watcher setup does not block first paint
- remote managed settings loading beginning after core init enables safe config reading, with results applied later through hot reload when they arrive
- headless remote user-settings download starting early enough to overlap with MCP and tool setup, while still entering the same detector pipeline when applied
- the first interactive mount checking whether a managed-settings race already changed permission availability before the subscriber existed
- cleanup shutting down watchers, deletion timers, and machine-settings poll timers when the process disposes
- long-lived poll timers being prevented from keeping the process alive on their own

## Selective downstream subscribers

Equivalent behavior should preserve:

- settings-error surfaces re-reading validation state on each settings notification so warning banners and `/doctor` breadcrumbs stay current
- plugin-hook hot reload subscribing selectively to managed-settings changes, hashing only the plugin-affecting settings subset, and skipping reload when unrelated policy churn did not actually change plugin availability
- plugin-hook reload clearing plugin caches and hook caches before repopulating, but only when that narrowed snapshot really changed
- sandbox initialization attaching its own settings subscriber after startup so live sandbox policy can update in place without recreating the whole process
- sandbox config refresh reading the same merged settings snapshot as the rest of the runtime, not a bespoke parser

Equivalent behavior should also preserve the boundary that some neighboring hot-reload systems, such as keybindings, are specialized siblings rather than part of this generic settings detector.

## Failure modes

- **stale-cache split-brain**: one code path applies settings directly without going through the detector's centralized cache reset, so some subscribers read old settings while others read new ones
- **internal echo loop**: in-process writes are not suppressed and the watcher repeatedly replays the runtime's own file edits back into the session
- **false deletion**: delete-and-recreate writes are treated as real deletes and temporarily wipe settings from the live runtime
- **hook-veto bypass**: config-change hooks report a blocking result, but the reload still lands in app state
- **interactive-headless drift**: the TUI and headless SDK path stop sharing the same apply function and begin to diverge on permission, effort, or fast-mode behavior
- **permission-context drift**: settings JSON updates, but live permission rules or bypass-disable posture are not resynced
- **env drift**: auth helpers or config-driven environment variables keep using stale values after settings.env changes
- **startup race leak**: remote managed settings arrive before the interactive subscriber exists and a restricted mode, such as bypass disablement, never gets reconciled
- **overeager or missed plugin reload**: plugin hooks reload on every policy tick, or fail to reload because the change detector watches the wrong subset of settings
