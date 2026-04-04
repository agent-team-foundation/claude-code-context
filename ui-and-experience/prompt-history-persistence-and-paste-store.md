---
title: "Prompt History Persistence and Paste Store"
owners: []
soft_links: [/ui-and-experience/prompt-composer-and-queued-command-shell.md, /runtime-orchestration/unified-command-queue-and-drain.md, /memory-and-context/context-cache-and-invalidation.md, /ui-and-experience/vim-mode-and-modal-editing.md]
---

# Prompt History Persistence and Paste Store

Claude Code's prompt history is not just "remember the last string." It persists multi-session prompt history, keeps large pasted text outside the history log, and exposes three distinct recall surfaces with different filtering rules. A clean-room rebuild needs those differences or prompt recall will feel correct in simple cases but drift badly under real usage.

## Scope boundary

This leaf covers:

- durable prompt-history storage and flush behavior
- pasted-text persistence outside the inline prompt buffer
- the difference between Up-arrow history, incremental history search, and the modal history picker
- interrupted-submit undo behavior for history entries

It intentionally does not re-document:

- general prompt editing, queue recovery, and overlay arbitration already covered in [prompt-composer-and-queued-command-shell.md](prompt-composer-and-queued-command-shell.md)
- full queued-command semantics already covered in [../runtime-orchestration/unified-command-queue-and-drain.md](../runtime-orchestration/unified-command-queue-and-drain.md)

## History is append-first, flush-later

Equivalent behavior should preserve prompt history as an append-oriented log with an in-memory pending buffer.

That means:

- new entries first land in process memory
- disk flush runs asynchronously rather than blocking the submit path
- process cleanup performs a final wait-plus-flush so late entries are not silently lost
- repeated flush failure backs off instead of hot-looping forever

Prompt history should feel durable without turning every submit into a synchronous disk write.

## Durable storage shape

Equivalent behavior should preserve one shared history log under the Claude config home, with each entry carrying at least:

- display text
- timestamp
- project identity
- session identity
- serialized pasted-content references

The log is shared across sessions, so higher-level readers must decide how to filter or reorder entries for a given UX surface.

## File locking protects concurrent appends

Equivalent behavior should preserve:

- creating the history file before append if it does not exist
- locking the history path before appending JSONL entries
- releasing the lock even when append fails
- treating malformed historical lines as skippable read noise, not fatal corruption

This allows concurrent sessions to share history without requiring a database.

## Pasted text is stored by size class

Equivalent behavior should preserve two persistence modes for pasted text:

- short pasted text stored inline in the history entry
- larger pasted text stored separately in a content-addressed paste cache and referenced by hash from the history entry

Images do not use this same history-store path; they live in a separate image cache and are not serialized inline into prompt history.

## Paste cache contract

Equivalent behavior should preserve:

- hashing large pasted text before asynchronous storage so the caller can reference it immediately
- content-addressable writes where the same hash can be safely rewritten
- restrictive on-disk permissions for stored paste files
- lazy retrieval when history entries are resolved back into live pasted-content payloads
- best-effort cleanup of stale paste files by age rather than by reference counting

The cache is a resilience layer, not a perfect garbage-collected store.

## Reference placeholders must round-trip

Equivalent behavior should preserve placeholder references such as pasted-text and truncated-text markers as stable prompt-surface tokens.

That includes:

- parsing placeholder markers back out of the visible prompt text
- expanding pasted-text references into full text before actual execution
- leaving image references as structured attachments rather than inlining them into the prompt string
- resolving stored paste references lazily when a history entry is reloaded

Visible placeholder text is not the source of truth. It is a recoverable view over hidden pasted content.

## Up-arrow history is current-project and current-session biased

Equivalent behavior should preserve Up-arrow recall as:

- filtered to the current project
- newest first
- current-session entries shown before older entries from other sessions
- limited to a bounded window
- chunk-loaded and cached so rapid repeated keypresses do not perform one disk read per step

This is a very different contract from generic "global shell history."

## Draft preservation is part of history navigation

Equivalent behavior should preserve the first upward history step capturing:

- the exact draft text
- current mode
- cursor state
- prompt-local pasted contents

Downward traversal must restore that saved draft precisely. Clearing back to an empty buffer is only correct when no draft existed.

## Bash-mode history stays mode-filtered

Equivalent behavior should preserve history traversal locking onto bash-only entries when navigation began from bash mode. The reader should not mix ordinary prompt entries back into the same traversal until history navigation resets.

## Incremental search is a different reader

Equivalent behavior should preserve incremental history search as its own reverse reader with its own search state.

Important differences from Up-arrow navigation:

- it searches a reverse stream of history entries rather than the cached Up-arrow window
- it keeps a separate search query and original-buffer snapshot
- accept, cancel, and execute each restore or replace prompt state differently
- pasted contents travel with the accepted historical entry, not just the display string

This is not merely a UI wrapper around the Up-arrow history cache.

## Modal history picker uses a third projection

Equivalent behavior should preserve the modal history picker as a distinct projection that is:

- filtered to the current project
- deduplicated by visible prompt text
- timestamped for age display
- preview-oriented, including a short wrapped multiline excerpt
- lazily resolved into full pasted-content payloads only after selection

The picker is optimized for browsing and fuzzy filtering, not for exact reverse-step replay.

## Interrupted submit must undo history too

Equivalent behavior should preserve one-shot undo of the most recent history addition when a submitted prompt is semantically rewound before any response really starts.

That means:

- removing the entry from the pending in-memory buffer when possible
- otherwise marking the already-flushed timestamp as skipped so later readers ignore it
- avoiding duplicate recall where the restored input appears both as the live draft and as the newest history item

History correctness here depends on matching prompt restore semantics, not just disk append semantics.

## Large-input truncation still preserves recoverability

Equivalent behavior should preserve very large pasted text being compacted into a visible placeholder plus separately stored hidden content, rather than rendering the full blob inline forever. Recall, external-editor handoff, and submit expansion must still be able to recover the hidden body.

## Failure modes

- **lost late submit**: process exit happens after submit but before async history flush and the last prompt disappears
- **history duplication**: interrupted or restored prompts remain in history and reappear twice on the next Up-arrow
- **paste amnesia**: history restores the visible placeholder text but not the hidden pasted-content payload it refers to
- **surface drift**: Up-arrow, incremental search, and modal picker all read different history semantics by accident instead of by design
- **mode bleed**: bash-only history traversal leaks ordinary prompt entries into the same navigation run
- **cache thrash**: rapid history navigation re-reads disk repeatedly instead of sharing chunked loads
