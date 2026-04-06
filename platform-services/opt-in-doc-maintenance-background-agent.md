---
title: "Opt-In Doc Maintenance Background Agent"
owners: []
soft_links: [/platform-services/background-housekeeping-and-deferred-maintenance.md, /runtime-orchestration/turn-flow/query-loop.md, /tools-and-permissions/filesystem-and-shell/path-and-filesystem-safety.md, /integrations/plugins/feature-gated-project-skill-improvement-loop.md]
---

# Opt-In Doc Maintenance Background Agent

Claude Code has an internal-only background documentation-maintenance service for markdown files that opt in with a reserved header block. Once such a file has been read, the runtime can keep it current by periodically launching a tightly constrained internal agent that rewrites the file in place from the latest conversation context. A faithful rebuild needs the tracking contract, idle-only scheduling, and file-edit sandbox to stay intact, or the feature will either never fire, spam on every turn, or escape into arbitrary file mutation.

## Scope boundary

This leaf covers:

- how a markdown file becomes a tracked opt-in document
- the header and inline-instruction contract
- the idle-time post-sampling update trigger
- the constrained agent execution model used to rewrite the document
- the prompt-template and custom-prompt override contract

It intentionally does not re-document:

- the broader background-housekeeping orchestrator already covered in [background-housekeeping-and-deferred-maintenance.md](background-housekeeping-and-deferred-maintenance.md)
- general post-sampling hook infrastructure already covered elsewhere in runtime orchestration
- generic file-edit tool semantics beyond the document-maintenance restriction boundary

## Opt-in document contract

Equivalent behavior should preserve:

- document maintenance being opt-in per file rather than a global "keep docs updated" mode
- opt-in detection being based on a reserved markdown heading that carries the document title in-band
- the detector reading that header from the document content itself instead of from sidecar metadata
- the title being trimmed from the header and treated as stable document identity for prompt construction
- an optional italicized line immediately after the header acting as document-specific update instructions
- one optional blank line between the header and that italicized instruction line still counting as part of the header block
- the italicized instruction line being preserved verbatim once discovered instead of being treated as expendable prose

## Discovery and tracking

Equivalent behavior should preserve:

- opt-in documents being discovered when the file is read through the ordinary file-read tool path, not by recursively scanning the whole repository for special headers
- registration happening through a file-read listener so the feature only tracks documents the session has actually touched
- tracked documents being keyed by file path and only registered once per path
- tracking only the path, with later update passes rereading live content instead of trusting stale cached doc bodies
- `/clear` or equivalent cache-clearing flows resetting the tracked-doc registry so a new conversation does not inherit stale documentation targets from the old one

## Idle-only update scheduling

Equivalent behavior should preserve:

- the maintenance service registering a background post-sampling hook rather than editing docs inline during the foreground response
- the service only being active for internal users
- update checks only running for the main REPL thread, not for background agents or other query sources
- updates only running when the latest assistant turn finished without tool calls, so documentation maintenance waits for an idle conversational moment
- no work happening when the tracked-doc set is empty
- multiple tracked docs being updated under one shared sequential runner so concurrent post-sampling passes do not collide with one another
- each tracked doc being processed serially within that runner rather than firing a swarm of simultaneous doc-maintenance agents

## Live reread and tracking eviction

Equivalent behavior should preserve:

- each update pass cloning the file-read state cache before rereading the tracked doc
- the tracked doc's cache entry being deleted from that clone so the reread gets actual file contents instead of a `file_unchanged` shortcut
- unreadable or missing docs being dropped from tracking instead of producing endless background errors
- docs that no longer contain the reserved opt-in header also being removed from tracking
- title and inline instructions being redetected from the latest document contents on every update pass rather than frozen from the first discovery read

## Update-agent execution boundary

Equivalent behavior should preserve:

- document updates running through a built-in agent path rather than by directly string-replacing markdown from the hook
- that built-in agent using an async forked context of the current conversation so it can learn from recent work without blocking the foreground transcript
- the agent carrying forward the current system prompt, user context, and system context rather than running in a totally detached synthetic environment
- the available tool list being inherited from the session but a custom `canUseTool` gate reducing actual permission to one file-edit tool on one exact file path
- only file-edit operations against the tracked document path being allowed
- all other tool calls being denied, even if the session at large would normally be allowed to use them
- the background hook consuming the agent stream silently until completion instead of rendering a separate foreground transcript for the maintenance run

## Documentation-update prompt contract

Equivalent behavior should preserve:

- the update prompt explicitly telling the model that the maintenance instruction is not part of the user conversation and must not leak into the document text
- the current document body, document path, detected title, and optional inline instructions all being injected into the maintenance prompt
- document updates being framed as "current state" maintenance rather than changelog writing
- preserving the reserved opt-in header exactly
- preserving the optional italicized instruction line exactly when it exists
- updating information in place, removing outdated sections instead of appending historical notes such as "previously" or "updated to"
- keeping the output terse and high-signal, focused on architecture, overviews, entry points, rationale, and navigation hints rather than exhaustive code walkthroughs
- only making edits when there is substantial new information to preserve
- allowing multiple edit operations in parallel within one agent turn if several sections need changes

## Custom prompt override

Equivalent behavior should preserve:

- a user-level custom prompt override file under the product config home in a feature-owned location
- silent fallback to the built-in default prompt when that override file is missing or unreadable
- prompt templating using named placeholders for document contents, path, title, and custom instructions
- substitution being single-pass so user content that happens to contain placeholder-like text is not re-expanded accidentally
- inline document-specific instructions being inserted into the prompt as a dedicated high-priority section rather than being smashed into the body text without explanation

## Design constraints

Equivalent behavior should preserve:

- the maintenance feature only tracking documents the user actually touched in the session
- the service always rereading the live file before editing, so manual edits outside the agent are folded into the next maintenance pass
- the maintenance agent being allowed to improve organization, clarity, and correctness, but not to turn the document into a low-level API reference or a historical changelog
- the maintenance path being narrowly file-scoped, so one tracked document cannot become a backdoor for editing unrelated files
- the maintenance feature remaining advisory automation over documentation, not a replacement for ordinary source of truth in the codebase itself

## Failure modes

- **never-tracked docs**: the implementation scans nothing on file reads or forgets to register matching files, so tracked docs silently never update
- **stale rereads**: the updater trusts cached `file_unchanged` state and misses the current file contents before issuing edits
- **header drift**: the updater rewrites or deletes the reserved header or its inline instruction line and thereby destroys the document's future opt-in metadata
- **tool escape**: the background agent can edit arbitrary files or use other tools because the file-path-specific `Edit` restriction was not enforced
- **changelog creep**: the prompt stops emphasizing current-state maintenance and the document accumulates historical notes instead of staying concise and current
- **background spam**: updates run after every tool-heavy turn or from non-main-thread query sources and consume too much background capacity
- **zombie tracking**: deleted files, inaccessible files, or docs whose headers were removed stay in the tracked set and generate repeated background failures
