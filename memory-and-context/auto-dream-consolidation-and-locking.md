---
title: "Auto-Dream Consolidation and Locking"
owners: []
soft_links: [/memory-and-context/compaction-and-dream.md, /memory-and-context/durable-memory-recall-and-auto-memory.md, /runtime-orchestration/tasks/dream-task-visibility.md, /memory-and-context/memory-management-and-context-inspection.md]
---

# Auto-Dream Consolidation and Locking

Claude Code's automatic durable-memory consolidation is not a cron-like background daemon. It is a turn-end hook that opportunistically launches a forked memory-only worker when a three-gate trigger opens, and it uses a lock file whose mtime doubles as the durable "last consolidated" timestamp. Rebuilding it faithfully means preserving that scheduling and locking model, not just the idea of "occasionally run /dream."

## Scope boundary

This leaf covers:

- how auto-dream is enabled, initialized, and triggered from the main runtime
- the exact time gate, session gate, scan throttle, and cross-process lock contract
- the forked worker's prompt, tool restrictions, and transcript-isolation behavior
- how success, kill, failure, and manual-trigger paths reuse the same consolidation-marker lineage

It intentionally does not re-document:

- the broader durable-memory storage model already covered in [durable-memory-recall-and-auto-memory.md](durable-memory-recall-and-auto-memory.md)
- the UI task shell for dream inspection already covered in [../runtime-orchestration/tasks/dream-task-visibility.md](../runtime-orchestration/tasks/dream-task-visibility.md)
- the wide compaction-versus-consolidation framing already covered in [compaction-and-dream.md](compaction-and-dream.md)
- the `/memory` dialog's toggle and status row behavior already covered in [memory-management-and-context-inspection.md](memory-management-and-context-inspection.md)

## Trigger origin and enablement

Equivalent behavior should preserve:

- auto-dream being initialized during startup housekeeping but actually executing only from the main turn-stop hook, not from its own standalone timer
- fire-and-forget invocation only on main-thread turns, never from subagents or other `agentId`-bearing turns
- the whole background-memory housekeeping family being skipped in bare or simple-style sessions where forked memory workers should not contend for shutdown time
- auto-dream being disabled in remote mode, disabled in proactive assistant mode, and disabled whenever auto-memory itself is off
- the enable flag coming from a small config helper where an explicit `autoDreamEnabled` user setting overrides the server-side experiment default, while an unset setting falls through to the experiment payload

## Trigger thresholds and gate ordering

Equivalent behavior should preserve:

- a cheapest-first gate sequence of time check, session scan, then lock acquisition
- threshold knobs being read from the same experiment payload as the enable default, with defensive per-field validation and independent fallback to defaults when cached experiment values are wrong-type, non-finite, or non-positive
- default scheduling thresholds of roughly 24 hours since the last successful consolidation and at least 5 other sessions touched since then
- the time gate reading one durable timestamp only: the lock artifact's modification time, which stands for `lastConsolidatedAt`
- the session gate counting transcript files whose mtime is newer than that timestamp, then excluding the current session so a single active conversation does not self-qualify merely by continuing to write its own transcript
- a scan throttle of about 10 minutes once the time gate is open but the session gate is still closed, so repeated turns do not rescan transcript metadata every time
- session counting being based on sessions touched since the last consolidation rather than turns inside the current session, so the trigger prefers cross-session accumulation of stable signal

## Lock artifact contract

Equivalent behavior should preserve:

- one lock artifact living inside the durable memory directory, so the lock keys on the same git-root memory scope as the memories it protects
- the lock artifact body carrying the holder PID while its modification time carries the precondition timestamp for future runs
- missing lock artifacts meaning "never consolidated" with an effective timestamp of zero
- lock acquisition first reading any existing PID and mtime, then treating a recent live PID holder as authoritative and bailing without firing another dream
- stale or reclaimable holders including dead PIDs, unparseable bodies, and holders whose mtime is older than about one hour even if the PID still exists, as a PID-reuse guard
- successful acquisition creating the memory directory if needed, writing the current PID, then rereading the file so two simultaneous reclaimers resolve by last writer wins and the loser exits
- the acquisition result returning the pre-acquire mtime so later rollback can restore the old schedule instead of inventing a new one

## Rollback and retry semantics

Equivalent behavior should preserve:

- successful dream completion leaving the lock mtime at "now", so the next time gate starts from the finished run rather than from an earlier partial attempt
- failed fork launches rewinding the lock to its prior timestamp so the time gate stays open and a later turn can retry
- rollback deleting the file entirely when there was no previous lock, and otherwise clearing the PID body then restoring the prior mtime
- rollback failures being non-fatal but effectively delaying the next trigger until the normal minimum-hours window, because the timestamp could not be rewound
- user kill and ordinary fork failure sharing the same rollback primitive so all aborted consolidations reopen the door for future runs
- kill paths and outer abort cleanup not both rewinding the lock for the same run; once the task layer handled the abort, the outer auto-dream catcher must simply notice the aborted signal and exit
- foreground or manual consolidation runs stamping the same durable "last consolidated" marker lineage, so a successful manual pass suppresses immediate auto-redreaming instead of looking unrelated to the background scheduler

## Session discovery semantics

Equivalent behavior should preserve:

- transcript discovery scanning per-project stored sessions for the original cwd rather than the current possibly-forked execution context
- session selection being based on transcript mtimes rather than birthtimes, because touched-session recency is the meaningful signal and some filesystems do not expose useful birthtimes
- candidate validation excluding synthetic or agent-only transcript artifacts before the auto-dream gate sees them
- undercounting across worktree-specific transcript layouts being acceptable because the session scan is only a skip gate; false negatives merely delay consolidation, while false positives would fire too often

## Forked worker and prompt contract

Equivalent behavior should preserve:

- auto-dream launching a forked agent rather than mutating memories inline in the main conversation loop
- the fork being hidden from the main transcript with transcript sharing intentionally skipped, so the dream worker does not pollute the foreground conversation with its own exploration turns
- the prompt being built from the durable memory root, the project transcript directory, and run-specific context listing which session IDs have accumulated since the last consolidation
- the prompt explicitly structuring the work into orient, gather, consolidate, and prune/index phases
- the gather phase preferring daily logs first, then drift in existing memories, then narrow transcript grep only for already-suspected details, rather than exhaustive transcript reading
- the consolidation phase telling the worker to improve or merge top-level memory topic files, convert relative dates to absolute ones, and delete contradicted facts at the source instead of piling on append-only contradictions
- the prune phase keeping `MEMORY.md` as a strict index under both line-count and size budgets, with one-line hooks rather than inlined memory content
- the dream prompt deferring to the system prompt's auto-memory format rules as the source of truth for what memory files should look like

## Tool boundary and write scope

Equivalent behavior should preserve:

- the fork using the same auto-memory permission helper as memory extraction rather than a bespoke dream-only permission path
- unrestricted read-style tools for file read, grep, and glob, because the dream worker must inspect both memories and source context
- shell access being limited to commands that pass a read-only check, with writes, redirects, and other mutating shell behavior denied
- file edit and file write being allowed only inside the durable memory directory, never in the project source tree
- the prompt itself reiterating that shell is read-only for this run, so the worker plans around the restriction instead of discovering it only through denials
- REPL-style wrappers remaining usable only because their inner primitive operations are rechecked against the same permission policy, preserving the effective write boundary

## Completion and visible side effects

Equivalent behavior should preserve:

- registration of a dream task before the fork begins so progress, abort, and lock rollback have a durable control surface
- successful completion logging cache-read, cache-creation, and output-token usage for the background pass
- the main conversation receiving only a lightweight inline "memory improved" style system note when the dream task is known to have touched durable memory files
- no inline completion note when no durable memory files were observed as changed
- progress inference being driven by assistant text plus observed memory-file writes, with touched-file tracking treated as best-effort rather than exhaustive

## Failure modes

- **timer illusion**: auto-dream is rebuilt as a wall-clock daemon instead of a turn-end opportunistic hook and starts running at the wrong times or in the wrong environments
- **current-session self-trigger**: the active session is counted toward the recent-session threshold and every long conversation eventually auto-qualifies by itself
- **scan hot loop**: once the time gate opens but the session gate is still closed, every turn rescans transcript metadata because the 10-minute scan throttle is missing
- **lock wedge**: a killed or failed run leaves the lock timestamp advanced and future consolidations stop firing for a full day
- **double-fire race**: two reclaimers both believe they acquired the lock because there is no PID liveness check or no post-write verification read
- **memory-scope escape**: the dream worker can edit project files or run mutating shell commands instead of being confined to durable memory maintenance
- **transcript flood**: the worker reads whole JSONL transcripts or shares its own fork transcript back into the main session, turning consolidation into context pollution
- **mode collision**: proactive assistant-mode distillation and auto-dream both run against the same memory root and create conflicting consolidation behavior

## Test Design

In the observed source, memory and context behavior is verified through deterministic transformation regressions, persistence-aware integration tests, and continuity-focused conversation scenarios.

Equivalent coverage should prove:

- selection, compaction, extraction, and invalidation rules preserve the invariants and bounded-resource behavior documented above
- cache state, memory layers, session persistence, and rehydration paths compose correctly across resume, compact, and recovery flows
- visible context continuity still matches the product contract when deterministic fixtures or replay replace live upstream variability
