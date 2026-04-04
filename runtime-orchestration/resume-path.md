---
title: "Resume Path"
owners: []
soft_links: [/product-surface/end-to-end-scenario-graphs.md, /product-surface/session-utility-commands.md, /runtime-orchestration/session-artifacts-and-sharing.md, /runtime-orchestration/app-state-and-input-routing.md, /runtime-orchestration/session-reset-and-state-preservation.md, /memory-and-context/context-lifecycle-and-failure-modes.md, /collaboration-and-agents/remote-handoff-path.md]
---

# Resume Path

Resume has multiple entry modes but one shared goal: recover a prior working session without losing its operational context.

## Entry variants

- interactive picker
- direct session ID
- continue-most-recent
- title or search based match
- resume-adjacent utility commands that bypass the picker when the target is unambiguous
- teleport or remote session resume

## Local resume path

1. Candidate sessions are discovered from lightweight local indexes instead of eagerly loading every full transcript.
2. Current session is excluded from the candidate set.
3. Subordinate task transcripts remain hidden from the top-level candidate list unless the user is explicitly foregrounding or inspecting that task.
4. User selects a session or provides a direct identifier.
5. Runtime upgrades from summary metadata to the full transcript and snapshot chain only for the chosen candidate.
6. Runtime restores session-scoped state such as message history, file history, attribution, tags or custom title, mode, worktree posture, tasks, and mode-relevant agent context.
7. Preserved background-task artifacts are rebound to the resumed session context when the stored lineage says they survived an earlier reset.
8. If the session belongs to another working directory, the runtime either blocks or produces an explicit "resume there" command.

## Teleported or remote resume path

1. Runtime validates auth and remote-session policy.
2. Session repository identity is compared with the local checkout.
3. Logs and branch hints are fetched from the remote session source.
4. Runtime checks out or attempts to recover the implied branch.
5. Resume-specific system and user messages explain the cross-machine continuation and any degraded live-control posture.

## Continuity contract

Resume is coupled to reset behavior as well as ordinary exit and restart.

A faithful rebuild should preserve:

- lineage between pre-reset and post-reset session identities
- branch or worktree hints that explain where a recovered session expects to run
- enough artifact metadata to distinguish top-level resumable sessions from subordinate task transcripts
- explicit recovery even when branch checkout fails, so transcript continuity and repo-state recovery can degrade independently

## Failure branches

- **session not found**
- **multiple matches need disambiguation**
- **cross-project mismatch**
- **repo mismatch on remote resume**
- **branch recovery failed but transcript still resumable**
- **partial state restore**

The important clean-room insight is that resume restores more than transcript text. It restores enough application state that the next turn behaves like a continuation instead of a cold start.
