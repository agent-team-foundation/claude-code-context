---
title: "Team Memory Sync and Secret Guardrails"
owners: []
soft_links: [/platform-services/sync-and-managed-state.md, /memory-and-context/memory-layers.md, /memory-and-context/durable-memory-recall-and-auto-memory.md, /tools-and-permissions/filesystem-and-shell/path-and-filesystem-safety.md]
---

# Team Memory Sync and Secret Guardrails

Claude Code's shared team memory is a synchronized, repo-scoped memory surface. It is not just another durable-memory file: it has server merge semantics, watcher-driven uploads, conflict handling, and extra safeguards to keep secrets out of a file set that every collaborator can inherit.

## Availability and identity

Equivalent behavior should preserve these gates:

- team memory is feature-gated
- it requires first-party OAuth with enough scope to identify both the user and the shared repo
- it is keyed to a stable repository identity, not just a local path
- non-supported repos should fail early instead of spawning a watcher that can never sync successfully

The clean-room requirement is that shared memory belongs to a repo and an authenticated collaboration context, not to one machine.

## Pull model

Equivalent behavior should preserve:

- a conditional fetch path using a remembered server checksum
- `not modified` and `no remote data yet` outcomes that are distinct from request failure
- server-provided per-entry checksums that refresh the client's belief about what the server currently holds
- server-wins pull semantics for entries that exist remotely
- path validation before writing remote entries into the local team-memory directory
- downstream memory-cache invalidation when pulled files changed on disk

That combination lets the client refresh local shared memory without re-uploading everything immediately afterward.

## Push model

Equivalent behavior should preserve:

- recursive local reads of the team-memory directory
- per-entry content hashing
- delta upload based on differences between local hashes and the last known server hashes
- upsert semantics on the server, so omitted keys are preserved
- no delete propagation, meaning local deletion alone does not erase server data
- request-body batching to stay under gateway size limits

The important product behavior is that a small local edit should not trigger a full repo-memory upload.

## Conflict handling

Equivalent behavior should preserve optimistic locking rather than hidden merge magic.

That means:

- push requests can fail with a conflict when the server changed since the last known checksum
- the client should respond by fetching only remote hashes, not the full content set, and recomputing its delta
- keys whose remote hash already matches the local edit should naturally drop out of the retry delta
- if both sides edited the same key differently, the active local push should be allowed to overwrite the server on retry
- server-enforced entry-count limits can be learned from structured failures and cached for later truncation decisions

This is intentionally asymmetric: pull is server-wins; push is local-wins for the actively edited key.

## Watcher behavior

The sync service is long-lived, not a one-shot command.

Equivalent behavior should preserve:

- an initial pull before watcher startup
- a recursive directory watch so new files and subdirectories are noticed
- debounced uploads after local changes settle
- suppression of infinite retry loops after permanent failures such as no auth, no eligible repo, or hard server-side rejection
- a recovery path where unlink-style cleanup can clear suppression for certain failure classes

The watcher should be able to idle quietly for days without hammering the server when the session is not in a recoverable state.

## Secret guardrails

Shared team memory needs stronger write safety than personal notes.

Equivalent behavior should preserve:

- client-side secret scanning before team-memory content is uploaded
- skipping secret-bearing files instead of pushing them
- a direct file-write or file-edit guard that blocks the model from writing secret-bearing content into team-memory paths in the first place
- user-visible messaging that explains why the write or sync was blocked without printing the secret value itself

Because team memory is synchronized to collaborators, secret protection is part of the contract, not an optional lint step.

## Failure modes

- **watcher storm**: a repo that can never sync keeps retrying on every local change
- **shared-secret leak**: the model or sync service writes secret-bearing content into team memory and propagates it to collaborators
- **false delete**: a local file deletion erases shared remote memory when the product contract was meant to preserve it
- **conflict clobbering**: a teammate's unrelated server update causes the client to re-upload the whole tree instead of only the still-different keys
- **repo ambiguity**: team memory is synced without a stable repo identity and crosses project boundaries
- **oversize deadlock**: the client never learns server-side entry caps and keeps failing on the same oversized or overfull payload

## Test Design

In the observed source, platform-service behavior is verified through sequencing-sensitive integration tests, deterministic state regressions, and CLI-visible service flows.

Equivalent coverage should prove:

- config resolution, policy gates, persistence, and service startup ordering preserve the contracts and failure handling described above
- provider-backed or OS-bound branches use fixtures, seeded stores, or narrow seams so auth, update, telemetry, and trust behavior stays reproducible
- users still encounter the expected startup, settings, trust, diagnostics, and account-state behavior through the real CLI surface
