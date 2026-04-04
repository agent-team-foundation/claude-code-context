---
title: "User Settings Sync Contract"
owners: []
soft_links: [/platform-services/sync-and-managed-state.md, /platform-services/settings-change-detection-and-runtime-reload.md, /memory-and-context/memory-layers.md, /integrations/plugins/plugin-runtime-contract.md]
---

# User Settings Sync Contract

Claude Code's personal sync layer is not a generic file backup service. It moves a narrow set of user settings and memory artifacts across environments, with different behavior for interactive local sessions and remote or headless sessions.

## Surface split

Equivalent behavior should preserve two distinct sync directions:

- interactive local sessions upload changed local artifacts in the background
- remote or headless sessions download remote artifacts before dependent systems, such as plugin activation, rely on them

These directions share storage and auth rules, but they are not triggered at the same time and do not have the same retry posture.

## Eligibility and auth boundary

Equivalent behavior should preserve:

- first-party OAuth as the eligibility gate for settings sync
- interactive-only upload behavior
- remote or headless download behavior even when no terminal UI is present
- fail-open startup when sync is unavailable or the network call fails

The important contract is that missing sync should degrade the experience, not prevent the core runtime from starting.

## Synced artifact map

The synchronized payload should stay narrow and predictable.

Equivalent behavior should preserve at least these artifact classes:

- global user settings
- global user memory
- project-local settings keyed by a stable repository identity
- project-local memory keyed by the same repository identity

If the session cannot establish a stable project identity, project-scoped artifacts should simply be omitted instead of being guessed.

## Transfer semantics

Equivalent behavior should preserve:

- downloading one authoritative snapshot from the server
- uploading only entries whose content differs from the remote snapshot
- a shared startup download promise so multiple startup subsystems can join the same fetch instead of racing duplicate downloads
- an explicit redownload path for user-triggered refreshes that bypasses the startup cache

This is how the runtime avoids both duplicate network traffic and stale plugin or settings state in remote sessions.

## Apply semantics and cache invalidation

Applying remote settings is not finished when bytes hit disk.

Equivalent behavior should preserve:

- file-size limits and skipping of empty or oversized entries
- marking local settings writes as internal writes so the file watcher does not immediately replay the runtime's own sync output back into the settings pipeline
- resetting settings caches after synced settings files change
- clearing memory-file caches after synced memory files change
- a boundary between startup-time application, where internal-write suppression is desirable, and mid-session refresh, where callers may need to re-enter the live settings-change pipeline afterward

Without that distinction, synced files either thrash the reload loop or quietly fail to update live runtime state.

## Remote-session dependency ordering

Equivalent behavior should preserve that remote downloads can matter before other startup work completes.

In practice, a correct rebuild should allow:

- headless remote sessions to fetch synced settings early enough that plugin availability, extra marketplaces, or related settings can affect the first meaningful runtime refresh
- explicit reload flows to force a fresh sync before plugin or extension refresh when that is the user intent

The key clean-room point is that sync can influence later activation surfaces, not just user-visible config files.

## Failure modes

- **auth-only blind spot**: API-key sessions pretend sync is available and fail later in confusing ways
- **project drift**: project-local settings are synced without a stable repo identity and land in the wrong workspace
- **startup split-brain**: two startup consumers kick off separate downloads and apply different snapshots
- **reload miss**: synced files land on disk but the live runtime never refreshes the caches or downstream state that depend on them
- **echo loop**: synced settings writes trigger the watcher as if they were external edits and replay indefinitely
- **oversize surprise**: large remote artifacts are written blindly and destabilize local settings or memory handling
