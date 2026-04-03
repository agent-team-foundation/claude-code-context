---
title: "Teammate Mailbox Control Message Rendering"
owners: []
soft_links: [/ui-and-experience/teammate-surfaces-and-navigation.md, /collaboration-and-agents/teammate-mailbox-and-permission-bridge.md, /collaboration-and-agents/inbox-polling-and-control-delivery.md, /runtime-orchestration/task-model.md]
---

# Teammate Mailbox Control Message Rendering

Mailbox-derived teammate output is not rendered as one raw text blob. Claude Code first splits wrapped teammate envelopes, suppresses low-signal control traffic, and then chooses among rich control cards, compact summaries, and transcript-only full text. A faithful rebuild needs the same visibility gates and precedence rules or swarm coordination either becomes noisy or loses important control state.

## Envelope parsing and identity

Equivalent behavior should preserve:

- one dedicated teammate-message XML wrapper around each conversational mailbox item that reaches the transcript-facing render path
- support for multiple wrapped teammate messages inside one text block, preserving source order
- required teammate identity plus optional color and short summary metadata on each wrapper, with wrapped body text trimmed before display
- display names remaining almost identical to the wrapped teammate ID, with only the reserved lead name normalized to the same literal handle used elsewhere in swarm UI
- wrapper-level summary text acting only as a preview for plain-text rows; it does not outrank structured control renderers

## Visibility gates and protocol boundaries

Equivalent behavior should preserve:

- permission, sandbox-permission, team-permission-update, and mode-set control payloads being intercepted before generic teammate rendering rather than leaking into ordinary mailbox text
- transcript teammate rendering prefiltering shutdown-approved payloads and synthetic teammate-terminated payloads before building visible rows
- transcript teammate rendering returning no surface at all when that prefilter leaves zero remaining envelopes
- idle-notification payloads being hidden entirely from visible teammate rows instead of surfacing as ordinary chat text
- attachment-style mailbox rendering prefiltering shutdown-approved, idle-notification, and teammate-terminated payloads before it counts or displays messages, so compact mailbox surfaces never imply hidden rows exist
- transcript and attachment paths intentionally differing here: attachment filtering happens before per-message rendering, while transcript rendering hides idle notifications later in the render cascade

## Transcript render precedence

Equivalent behavior should preserve:

- one strict precedence chain for each visible teammate message: plan-approval rich card, shutdown rich card, task-assignment rich card, JSON special cases, then plain teammate text
- structured renderers short-circuiting the fallback path so one mailbox item never appears twice as both a card and a text row
- plan-approval responses taking visible sender identity from the mailbox envelope sender rather than from the response JSON itself
- plain-text fallback rows showing a colored `@teammate` header with optional wrapper summary, while the full body appears only in transcript mode

## Plan approval cards

Equivalent behavior should preserve:

- request messages using a dedicated plan-mode visual treatment distinct from ordinary teammate text
- request cards showing requester identity, markdown-rendered plan body, and the referenced plan file path
- response cards choosing success styling for approval and error styling for rejection
- rejected responses optionally surfacing reviewer feedback in a secondary block plus a revision nudge
- approved responses surfacing that execution restrictions have been lifted, rather than only echoing an approval boolean

## Shutdown, assignment, and completion special cases

Equivalent behavior should preserve:

- shutdown requests rendering as warning-toned cards with optional reason text
- shutdown rejections rendering as subdued cards with an explicit rejection reason and a hint that work continues
- shutdown-approved payloads being omitted from rich transcript rendering even though compact summary helpers can still describe them elsewhere
- task-assignment messages rendering in the transcript as team-colored cards with task id, assigner, bold subject, and optional description
- task-completed JSON payloads rendering as explicit completion rows that name the completed task id and optionally the task subject
- teammate-terminated JSON payloads being hidden from teammate transcript rows but still usable as compact summary text in non-transcript contexts

## Attachment-path compaction

Equivalent behavior should preserve:

- attachment-based teammate mailbox rendering attempting rich rendering only for plan-approval messages
- task-assignment payloads inside attachments collapsing into a single compact bullet row instead of the larger transcript card
- all other attachment-path teammate content flowing through one shared summary formatter before plain-text display
- task-assignment compact rows preferring the payload's assigner field but falling back to the wrapper sender when needed
- plain attachment rows reusing the same colored-header plus optional summary-preview structure as transcript fallback rows

## Shared summary formatter

Equivalent behavior should preserve:

- one reusable summary helper for compact surfaces with strict precedence: plan approval, shutdown, idle notification, task assignment, teammate-terminated message text, then raw content
- idle summaries combining an idle state with any completed-task outcome and last direct-message summary when present
- compact formatting never requiring the full transcript body to be visible in order to communicate why a teammate row exists
- summary formatting acting as a compaction layer only; rich transcript cards still outrank it when available

## Transcript-only body expansion

Equivalent behavior should preserve:

- plain teammate rows remaining compact outside transcript mode
- transcript mode expanding the body under the header with a left indent rather than merging header and body onto one line
- body text passing through an ANSI-aware renderer so worker-produced terminal formatting is retained
- structured cards bypassing that generic body expander and owning their own layout

## Failure modes

- **protocol leak**: permission or mode-control JSON bypasses the inbox poller and appears as teammate text
- **precedence drift**: plan, shutdown, or task-assignment payloads render through both a rich card and a plain summary
- **hidden-count mismatch**: attachment mailbox counts include idle or termination payloads that the UI then suppresses
- **summary inversion**: compact surfaces show raw content even though a structured summary exists
- **transcript flattening**: plain teammate rows always show full bodies and let swarm chatter overwhelm the main conversation
