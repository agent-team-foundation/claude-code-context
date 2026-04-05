---
title: "Remote Transcript Persistence and Cross-Machine Replay"
owners: []
soft_links: [/collaboration-and-agents/remote-handoff-path.md, /collaboration-and-agents/remote-session-contract.md, /collaboration-and-agents/remote-session-live-control-loop.md, /runtime-orchestration/resume-path.md]
---

# Remote Transcript Persistence and Cross-Machine Replay

Cross-machine continuation depends on durable transcript persistence, ordered append semantics, and replay paths that can tolerate partially migrated backends.

## Ordered append contract

Equivalent behavior should preserve per-session serialized transcript appends.

That means:

- one in-process append queue per remote session
- no concurrent writes for the same session from one client process
- each append carrying the client's current notion of the last persisted entry

This is optimistic concurrency, but it is still intentionally ordered.

## Concurrency control and adoption

Remote persistence should preserve a last-entry token, not blind append.

Equivalent behavior should preserve:

- sending the locally known last entry identifier on append
- updating that local identifier only after a confirmed success
- treating a conflict response as recoverable when the server proves the just-sent entry is already the head
- otherwise adopting the server's current head, either from an explicit response header or by re-fetching the session transcript, then retrying

This is the key contract that lets a surviving client recover after another process died mid-write.

## Retry boundaries

Equivalent behavior should preserve:

- retrying transient network failures, 5xx responses, and throttling-style 4xx responses
- exponential backoff with a bounded ceiling
- immediate failure on expired or invalid auth tokens
- a hard retry cap after which persistence is considered failed for that append

Remote continuation should degrade predictably rather than silently dropping transcript entries.

## Hydration paths

There are multiple fetch surfaces for rebuilding a remote transcript.

Equivalent behavior should preserve:

- a direct session-ingress style fetch path that hydrates all currently stored entries and refreshes the local last-entry token from the fetched tail
- an OAuth-backed legacy fetch path for older cross-machine resume flows
- a newer paginated event feed for remote replay, where each page returns opaque event payloads and an opaque cursor for the next page

The product contract is compatibility across storage generations, not one permanent backend shape.

## Paginated replay semantics

The paginated replay path should preserve:

- fetching up to a server-chosen page size with an explicit client-side page cap
- echoing opaque cursors back without interpreting them
- skipping null or non-transcript payloads rather than failing the whole replay
- treating "not found on first page" as ambiguous during migration windows so callers can fall back to the legacy fetch path
- treating "not found after some pages" as partial success and returning what was already recovered

Partial transcript recovery is better than abandoning cross-machine or remote resume entirely.

## Replay and resume guarantees

Equivalent behavior should preserve a clear preference order:

1. use the newest replay surface when available
2. fall back to the legacy fetch path when the newer one is absent or not yet backfilled for this session
3. refresh local append state from whatever replay path succeeded before new appends begin

Otherwise a resumed session can immediately conflict with its own remote history.

## Local cache cleanup

Remote transcript persistence keeps session-local append metadata.

Equivalent behavior should preserve explicit cleanup for:

- one session's remembered tail entry
- one session's sequential append queue
- global session-persistence caches on broad reset operations

Without cleanup, long-running clients leak per-session state long after the session is gone.

## Failure modes

- **append reordering**: one process writes two entries for the same session concurrently and corrupts optimistic ordering
- **stale-tail deadlock**: a 409 conflict does not adopt the server head and the client can never append again
- **migration blind spot**: the replay path treats a not-yet-backfilled session as hard missing instead of falling back
- **partial-replay discard**: mid-pagination deletion or backend failure throws away already recovered transcript history
- **tail-cache leak**: cleared or deleted sessions leave stale append metadata that poisons later resumes
