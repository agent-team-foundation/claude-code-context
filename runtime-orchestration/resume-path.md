---
title: "Resume Path"
owners: []
soft_links: [/product-surface/end-to-end-scenario-graphs.md, /memory-and-context/context-lifecycle-and-failure-modes.md, /collaboration-and-agents/remote-handoff-path.md]
---

# Resume Path

Resume has multiple entry modes but one shared goal: recover a prior working session without losing its operational context.

## Entry variants

- interactive picker
- direct session ID
- continue-most-recent
- title or search based match
- teleport or remote session resume

## Local resume path

1. Candidate sessions are discovered from local storage.
2. Current session is excluded from the candidate set.
3. User selects a session or provides a direct identifier.
4. Runtime loads the full transcript if only a light summary is currently indexed.
5. Runtime restores session-scoped state such as message history, file history, attribution, tasks, and mode-relevant agent context.
6. If the session belongs to another working directory, the runtime either blocks or produces an explicit "resume there" command.

## Teleported or remote resume path

1. Runtime validates auth and remote-session policy.
2. Session repository identity is compared with the local checkout.
3. Logs and branch hints are fetched from the remote session source.
4. Runtime checks out or attempts to recover the implied branch.
5. Resume-specific system and user messages explain the cross-machine continuation.

## Failure branches

- **session not found**
- **multiple matches need disambiguation**
- **cross-project mismatch**
- **repo mismatch on remote resume**
- **branch recovery failed but transcript still resumable**
- **partial state restore**

The important clean-room insight is that resume restores more than transcript text. It restores enough application state that the next turn behaves like a continuation instead of a cold start.
