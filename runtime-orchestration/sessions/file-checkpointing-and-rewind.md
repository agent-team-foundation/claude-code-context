---
title: "File Checkpointing and Rewind"
owners: []
soft_links: [/runtime-orchestration/sessions/session-artifacts-and-sharing.md, /runtime-orchestration/sessions/resume-path.md, /tools-and-permissions/filesystem-and-shell/file-read-write-edit-and-notebook-consistency.md, /ui-and-experience/dialogs-and-approvals/diff-dialog-and-turn-history-navigation.md]
---

# File Checkpointing and Rewind

Claude Code's rewind feature depends on a per-message file-checkpoint system. It is not enough to diff the current worktree or rely on Git alone.

## Feature gating

Equivalent behavior should preserve two separate enablement paths:

- ordinary interactive sessions can enable file checkpointing by default unless the user or environment explicitly disables it
- SDK or non-interactive sessions require a separate positive enablement gate

This avoids surprising checkpoint overhead in headless contexts while still allowing explicit support there.

## Pre-edit tracking

Checkpointing begins before a write happens.

Equivalent behavior should preserve a pre-edit tracking step that:

- records the file against the most recent snapshot, not only against a future one
- captures version 1 of the pre-edit content before the mutation lands
- records `null` as the backup marker when the file did not yet exist
- refuses to overwrite the deterministic first backup if the same file is tracked again before a new snapshot is committed

That "first version is sacred" rule is what makes rewind semantically meaningful.

## Per-message snapshot creation

The runtime should create a new snapshot at stable message boundaries, keyed by user-message UUID.

Equivalent behavior should preserve:

- re-backing up only tracked files whose contents or metadata actually changed
- reusing the latest backup version for unchanged files
- carrying forward files that were newly tracked while asynchronous snapshot I/O was in flight
- capping retained snapshots while still incrementing a monotonic sequence counter so UI activity signals do not stall when the ring buffer fills

The snapshot is a message-scoped checkpoint, not a free-running timer.

## Backup storage contract

Equivalent behavior should preserve:

- one backup namespace per session
- backup file names derived deterministically from the original file path plus a version number
- permission bits copied onto backups and restored from backups
- null backups meaning "the file should not exist at this version"

Storing "missing file" as first-class state is required for correct rewind of newly created files.

## Change detection before restore

Rewind and diff preview should share the same comparison model.

Equivalent behavior should preserve change detection that checks:

- existence asymmetry
- mode and file-size changes
- mtime as a fast skip when the original is clearly older than the backup
- full-content comparison when metadata alone is insufficient

The same underlying notion of "would this file actually change" should power both dry-run previews and real restore operations.

## Rewind semantics

Rewinding to a message should:

- locate the last snapshot associated with that user message
- restore each tracked file to the snapshot's backed-up version
- delete files whose target backup is `null`
- fall back to the earliest known version when a file was already part of the session but had not yet been explicitly tracked in the target snapshot
- leave checkpoint history intact rather than mutating the snapshot store itself

Rewind is a filesystem side effect, not a state reset.

## Dry-run preview and CLI behavior

Equivalent behavior should preserve a dry-run path that returns:

- whether rewind is available
- which files would change
- insertion and deletion counts where calculable

CLI-style rewind operations should require a user-message UUID and exit immediately after restoring files, instead of entering the ordinary interactive loop.

## Resume and restore behavior

Checkpoint state must survive resume.

Equivalent behavior should preserve:

- restoring snapshot metadata from stored session logs during startup or resume
- initializing checkpoint state only once when the transcript is hydrated
- migrating backup artifacts into a new session namespace on resumed or forked sessions, preferably by hard-linking and falling back to copying when links are unavailable

Without this, resumed sessions can show rewind UI that points at backups the new session cannot actually read.

## Failure modes

- **first-backup corruption**: repeated pre-edit tracking overwrites the original checkpoint with post-edit content
- **async gap loss**: a file tracked during snapshot creation disappears from the committed snapshot
- **rewind mismatch**: dry-run diff and real restore disagree about whether a file would change
- **resume orphaning**: resumed sessions inherit snapshot metadata without migrating the underlying backup artifacts
- **new-file leak**: files created after the target snapshot are not deleted because missing-file state was never recorded explicitly
