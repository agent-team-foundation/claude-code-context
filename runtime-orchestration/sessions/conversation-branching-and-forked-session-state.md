---
title: "Conversation Branching and Forked Session State"
owners: []
soft_links: [/runtime-orchestration/sessions/session-artifacts-and-sharing.md, /runtime-orchestration/sessions/resume-path.md, /product-surface/session-state-and-breakpoints.md, /memory-and-context/context-lifecycle-and-failure-modes.md]
---

# Conversation Branching and Forked Session State

Claude Code's `/branch` command is a conversation fork, not a git branch helper. Rebuilding it correctly means cloning the resumable session state at one point in time, excluding sidechains and ephemeral progress noise, preserving tool-result replacement state, assigning a new session identity, and then immediately hopping the live REPL into the fork while keeping a clean path back to the original session.

## Scope boundary

This leaf covers:

- the user-visible `/branch` command contract, including its optional fork-style alias behavior
- how the current session transcript is copied into a new fork session
- how titles, collision handling, and resume metadata are derived for the new fork
- how content-replacement state is preserved so resumed forks stay cache-friendly and tool-result previews do not regress
- how the live session resumes directly into the fork and how fallback messaging behaves when live resume is unavailable

It intentionally does not re-document:

- the broader resume picker and remote resume flows already captured in [resume-path.md](resume-path.md)
- the full session artifact inventory already captured in [session-artifacts-and-sharing.md](session-artifacts-and-sharing.md)
- generic session-state phases already captured in [session-state-and-breakpoints.md](../product-surface/session-state-and-breakpoints.md)
- unrelated transcript compaction or context-collapse behavior already captured in [context-lifecycle-and-failure-modes.md](../memory-and-context/context-lifecycle-and-failure-modes.md)

## `/branch` forks conversation state, not repository state

Equivalent behavior should preserve:

- `/branch` creating a new conversation branch from the current point in the live session instead of creating or switching a git branch
- an optional name argument being treated as the requested base title for the fork rather than as a filesystem path or git ref
- the command being able to surface under a `/fork` alias only when a dedicated fork command is not present in the build, so aliasing stays feature-sensitive
- a missing current transcript, an empty transcript file, or a transcript with no mainline messages causing an immediate "nothing to branch" style failure rather than creating an empty shell session

## Fork creation copies only mainline transcript messages and rewrites session identity

Equivalent behavior should preserve:

- fork creation allocating a fresh session ID and a new transcript path inside the same project-level session storage area
- the project directory being created on demand with private permissions before any fork file is written
- the source transcript being parsed as JSONL entries and then filtered down to main conversation transcript messages only
- non-message entries, sidechain messages, and legacy progress-style UI noise being excluded from the forked conversation chain rather than copied wholesale
- each copied message preserving its original message-level metadata while receiving the fork session ID, a rebuilt parent chain, and explicit `forkedFrom` traceability back to the original session ID and source message ID
- the rebuilt parent chain advancing only through real transcript messages so resumed forks do not inherit broken linkage from progress-like artifacts
- the fork transcript being written as a new append-oriented JSONL file with private file permissions

## Replacement state and naming metadata are preserved through session-native artifacts

Equivalent behavior should preserve:

- content-replacement records from the original session being copied into one fork-scoped replacement entry so resumed forks can reconstruct which oversized tool results were already preview-substituted
- that replacement-state copy being treated as load-bearing for offline `claude -r <fork>` resume, because otherwise previously replaced tool results would come back as full content and silently change prompt-cache and overage behavior
- in-session `/branch` resume not needing to reconstruct replacement state from scratch, because the live REPL already holds the correct tool-use identity mapping for the fork handoff
- the default fork title base being derived from the first user message's first text content, with whitespace collapsed to one line and the result truncated to a short single-line hint
- title derivation falling back to a generic branch label when the first user message has no usable text content
- the stored fork title always receiving a visible branch suffix so forked sessions remain distinguishable in `/status`, `/resume`, and other session surfaces
- title collision handling searching same-repo worktree sessions case-insensitively and appending incrementing numeric suffixes when the plain branch suffix is already taken
- the chosen fork title being persisted as a native session-title entry before resume so later session search, status, and resume flows all agree on the fork name

## Success resumes directly into the fork while preserving a route back

Equivalent behavior should preserve:

- the fork command building a resume-ready session log for the new fork instead of treating the new transcript as write-only storage
- that log carrying the fork transcript path, timestamps, first-prompt hint, message count, custom title, and copied content-replacement summary
- live command contexts that support resume switching immediately into the forked session instead of forcing the user to run a second `/resume` command
- the handoff into the new session being tagged as a fork-style entrypoint so downstream resume logic can keep the right replacement-state behavior
- success messaging making it clear that the user is now in the branch while also giving an explicit hint for resuming the original session
- contexts without live resume support falling back to a direct `/resume <fork-session-id>` instruction rather than pretending the switch already happened
- analytics and UI feedback treating the operation as a conversation fork event, not as an ordinary rename or generic resume

## Failure modes

- **empty-fork creation**: a rebuild creates a new session even when the current transcript is missing, empty, or contains no mainline messages
- **sidechain leakage**: teammate or sidechain messages are copied into the fork and change what the new conversation sees on resume
- **progress-chain corruption**: progress-like entries participate in the copied parent chain and orphan later real messages
- **replacement-state loss**: content-replacement records are not copied, so resumed forks inflate prompt size and replay full tool results that the original session had already preview-trimmed
- **metadata overcopy**: every JSONL metadata entry is cloned blindly, carrying stale tags, titles, or unrelated session-scoped state into the fork
- **title collision drift**: branch names only check the current directory and miss same-repo worktree sessions, causing ambiguous duplicate fork titles in resume search
- **resume split-brain**: the fork transcript is written, but the live REPL does not actually switch sessions, leaving messages to append to the wrong session file
- **no-way-back UX**: success output switches into the fork without preserving an obvious route to the original session
