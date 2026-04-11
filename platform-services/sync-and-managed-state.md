---
title: "Sync and Managed State"
owners: []
soft_links: [/platform-services/auth-config-and-policy.md, /memory-and-context/memory-layers.md, /integrations/plugins/plugin-runtime-contract.md]
---

# Sync and Managed State

Claude Code relies on several background synchronization layers that change what the runtime knows before a user ever types a prompt.

The important layers are:

- **user settings sync** for carrying personal configuration and memory-related files across environments
- **remote managed settings** for organization-controlled policy and configuration overlays
- **team memory sync** for repo-scoped shared memory that multiple authenticated collaborators can read and update

The detailed contracts for the personal and shared layers live in [user-settings-sync-contract.md](user-settings-sync-contract.md) and [team-memory-sync-and-secret-guardrails.md](team-memory-sync-and-secret-guardrails.md).

Reconstruction requirements:

- User sync should be incremental rather than full-copy whenever possible. Local interactive environments push changed entries upward, while remote or containerized environments pull relevant settings before dependent systems such as plugin activation or remote execution begin.
- Managed settings should load early, be cacheable, and refresh in the background. They are an overlay, not the whole config system, and failures should usually degrade without blocking the core session.
- Shared team memory must stay distinct from personal memory. It should be repo-scoped, authenticated, and conservative about destructive actions so that one client cannot silently erase shared knowledge for everyone else.
- Sync systems should use freshness markers such as checksums or ETags so they can avoid re-uploading or re-downloading unchanged state.
- Security checks must happen before synchronized content is trusted. Secret scanning and managed-settings validation are part of the product contract, not optional polish.

This domain matters because Claude Code is not just a local CLI with one config file. It behaves like a multi-environment client whose effective behavior depends on what has been synchronized, validated, and allowed for the current user and workspace.

## Test Design

In the observed source, platform-service behavior is verified through sequencing-sensitive integration tests, deterministic state regressions, and CLI-visible service flows.

Equivalent coverage should prove:

- config resolution, policy gates, persistence, and service startup ordering preserve the contracts and failure handling described above
- provider-backed or OS-bound branches use fixtures, seeded stores, or narrow seams so auth, update, telemetry, and trust behavior stays reproducible
- users still encounter the expected startup, settings, trust, diagnostics, and account-state behavior through the real CLI surface
