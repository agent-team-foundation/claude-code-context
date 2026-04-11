---
title: "Remote Agent Restoration and Polling"
owners: []
soft_links: [/runtime-orchestration/tasks/task-model.md, /runtime-orchestration/tasks/task-output-persistence-and-streaming.md, /runtime-orchestration/automation/review-path.md, /collaboration-and-agents/remote-handoff-path.md, /collaboration-and-agents/remote-session-contract.md]
---

# Remote Agent Restoration and Polling

Remote work is represented locally as a shadow task that watches, interprets, and sometimes controls a remote Claude session. The local runtime does not just show a spinner: it persists reconnect metadata, polls remote events, translates task-type-specific completion signals, and decides what should come back to the local model versus what should stay a remote artifact.

Shared task registration, generic stop dispatch, `notified` barriers, terminal eviction rules, and SDK lifecycle bookends are captured in [shared-task-control-plane-and-lifecycle-events.md](shared-task-control-plane-and-lifecycle-events.md). This leaf focuses on the remote-session-specific restore, polling, and result-shaping logic layered on top.

## Local shadow-task contract

Equivalent behavior should preserve:

- a local task ID that is distinct from the remote session ID
- eager creation of a local output file before the first remote event arrives
- enough per-task metadata to distinguish plain remote agents from specialized review, planning, or monitor-style remote work
- task-type-specific completion logic that can be registered independently of the base poller

## Sidecar persistence

Remote task registration should persist identity, not authority.

The durable rule is:

- write a per-task sidecar containing local task ID, remote session ID, title, command, task type, and any specialized metadata needed for restore
- treat persistence as best effort so a sidecar write failure does not block task startup
- persist only reconnect identity locally; fetch live remote status fresh during restore rather than trusting stale local status

## Resume and restore

On local resume, the runtime should reconstruct still-live remote tasks from those sidecars.

Equivalent behavior should:

- scan the session's persisted remote-task metadata
- fetch each remote session's current status before re-registering it locally
- delete sidecars only when the remote session is truly gone or already archived
- treat auth problems and transient connectivity failures as recoverable, leaving the sidecar in place for a later reconnect
- re-register surviving tasks as running with a fresh local poll-start clock, then restart polling

That local-clock reset is load-bearing for review timeouts: a newly resumed client must not instantly fail a task just because the original spawn happened long ago.

## Polling loop

The poller is the local source of truth for remote progress.

A faithful rebuild should preserve:

- one append-only accumulated remote log per task
- a last-event cursor so each poll only processes new remote events
- appending only the new delta text to the local output file
- task-state updates that return the same object on true no-op polls, avoiding needless re-renders
- recomputation of derived UI state such as todo lists or remote-review heartbeat progress only when the log actually grows
- a race guard that bails out cleanly if stop or kill made the task terminal while a poll request was in flight

## Generic completion sources

Remote tasks can complete in multiple ways.

Equivalent behavior should support:

- explicit remote archival as a completion signal
- task-type-specific completion checkers that consult external metadata
- result-message completion for ordinary one-shot remote tasks
- opt-out from ordinary result-message completion for long-running monitors and remote planning flows that emit intermediate results repeatedly

When completion lands, the runtime should mark terminal state, notify once, evict in-memory output handling, and delete the restore sidecar.

## Specialized result shaping

Not every remote task should tell the local model to read a raw output file.

Required behavior:

- remote-review success should inject the parsed review text directly into the next local turn rather than exposing a machine-oriented log dump
- remote-review failure should send review-specific retry guidance
- machine-oriented planning failures should use a specialized summary instead of telling the model to inspect raw JSONL output
- remote planning flows should be able to hold a nonterminal local phase until the user either teleports an approved plan back or leaves execution in the remote session
- successful remote review should keep the remote session itself accessible as a durable external record even after the local task is done

## Remote-review completion heuristics

Remote review has its own completion logic beyond ordinary session status.

A correct rebuild should preserve:

- tagged-output detection from both assistant messages and hook-produced stdout
- a delta-scan path that looks only for explicit completion tags, so early untagged status chatter cannot prematurely complete the task
- stable-idle completion only after several consecutive idle polls with no log growth
- suppression of that stable-idle shortcut when hook traffic shows the review is running in a long-lived SessionStart workflow, where idle is not a trustworthy completion signal
- live heartbeat parsing for finding, verifying, and synthesizing progress counters
- timeout handling that still fires even if repeated API failures interrupt ordinary poll logic

## Stop semantics

Stopping remote work needs both local and remote cleanup.

Equivalent behavior should:

- mark the task `killed` and `notified` before later poll iterations can race in
- emit the SDK stopped bookend because the poller will no longer send a completion notification
- archive the remote session so it stops consuming cloud resources
- evict output writers and delete restore metadata so resume cannot resurrect stopped work

## Failure modes

- **stale resurrection**: restore recreates tasks for sessions that were already archived or deleted
- **recoverable-loss bug**: auth failure is mistaken for permanent session disappearance and the sidecar is deleted
- **false review completion**: hook-based remote review is marked done during a transient idle gap
- **duplicate closeout**: stop and poll completion both notify because terminal state was not re-checked after async polling
- **wrong artifact surface**: the local model is told to read a raw remote log instead of receiving parsed review or planning output

## Test Design

In the observed source, session behavior is verified through persistence-focused integration tests, deterministic state-shaping regressions, and resume-oriented end-to-end flows.

Equivalent coverage should prove:

- identifiers, checkpoints, artifacts, and persisted metadata survive restarts, forks, rewinds, and discovery scans without state drift
- storage, attachment, and remote-restoration paths compose correctly with the runtime services that read or mutate session state
- visible continue, resume, fork, restore, and sharing behavior matches the packaged CLI and remote surfaces rather than only direct module calls
