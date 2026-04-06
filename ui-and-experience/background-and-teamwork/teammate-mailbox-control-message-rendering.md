---
title: "Teammate Mailbox Control Message Rendering"
owners: []
soft_links: [/ui-and-experience/background-and-teamwork/teammate-surfaces-and-navigation.md, /collaboration-and-agents/teammate-mailbox-and-permission-bridge.md, /collaboration-and-agents/inbox-polling-and-control-delivery.md, /collaboration-and-agents/peer-addressing-discovery-and-routing.md, /runtime-orchestration/tasks/task-model.md]
---

# Teammate Mailbox Control Message Rendering

Mailbox-derived teammate output is not rendered as one raw text blob. Claude Code splits teammate traffic across an XML-wrapped transcript path and a `teammate_mailbox` attachment path, suppresses some control payloads entirely, and then chooses among rich control cards, compact summaries, and transcript-only full text. A faithful rebuild needs the same source split, visibility gates, and precedence rules or swarm coordination will either leak protocol traffic into chat or hide important control state.

This leaf is swarm-specific. Cross-session peer messages use a different envelope and reply model, and should not be reconstructed as teammate mailbox rows or mailbox-count surfaces. That separate routing contract is captured in [peer-addressing-discovery-and-routing.md](../collaboration-and-agents/peer-addressing-discovery-and-routing.md).

## Envelope parsing and source aggregation

Equivalent behavior should preserve:

- one dedicated `teammate-message` XML wrapper around each transcript-facing mailbox item, with required teammate identity plus optional color and short summary metadata
- that teammate envelope staying distinct from the separate cross-session message envelope used for direct peer delivery between top-level sessions
- support for multiple wrapped teammate messages inside one text block, preserving source order and trimming the wrapped body before render routing
- display names remaining almost identical to the wrapped teammate id, with only the reserved lead id normalized to the same literal handle used elsewhere in swarm UI
- wrapper-level summary text acting only as a preview for plain teammate rows; it does not outrank structured control renderers
- attachment-side mailbox collection merging unread file-backed inbox messages with leader-side pending inbox messages already queued in app state
- leader-side pending inbox messages being excluded whenever the user is viewing a teammate transcript or the current process is itself an in-process teammate, preventing the leader's pending queue from leaking into a worker view
- file-backed and pending inbox sources being deduplicated with a composite sender-plus-timestamp-plus-text-prefix key so one teammate event cannot surface twice during poller races
- duplicate idle notifications collapsing to only the newest message per sender before attachment rendering begins

## Visibility gates and protocol boundaries

Equivalent behavior should preserve:

- attachment-mode mailbox generation filtering a fixed structured-protocol subset before it even builds a generic teammate-mailbox attachment
- that attachment-side protocol subset including permission requests and responses, sandbox-permission requests and responses, shutdown requests, shutdown approvals, team-permission updates, mode-set requests, and plan-approval requests and responses
- that attachment-side protocol subset being intentionally narrower than “all structured JSON,” so shutdown rejections, task assignments, idle notifications, task-completed payloads, and teammate-termination notices still reach later UI filtering or summary logic
- file-backed mailbox rows being marked read only after the non-protocol attachment payload has been assembled, preventing message loss if later processing fails
- transcript-mode mailbox delivery using a different path: inbox polling can perform side effects for plan-approval and shutdown payloads and still pass those same messages through as wrapped teammate envelopes for transcript-aware rendering
- transcript teammate rendering prefiltering shutdown-approved payloads and synthetic teammate-terminated payloads before building visible rows
- transcript teammate rendering returning no surface at all when that prefilter leaves zero remaining envelopes
- idle-notification payloads being hidden from visible teammate rows instead of surfacing as ordinary chat text
- attachment-style mailbox rendering prefiltering shutdown-approved, idle-notification, and teammate-terminated payloads before it counts or displays messages, so compact mailbox surfaces never imply hidden rows exist
- transcript and attachment paths intentionally differing here: attachment filtering happens before per-message rendering, while transcript rendering hides idle notifications later in the render cascade
- structured-protocol filtering and poller pass-through not being identical: some mailbox items are withheld from file-backed attachment generation but can still reach visible transcript content after the poller has already applied their side effects or queued them as regular teammate context

## Transcript render precedence

Equivalent behavior should preserve:

- one strict precedence chain for each visible teammate message: plan-approval rich card, shutdown rich card, task-assignment rich card, JSON special cases, then plain teammate text
- structured renderers short-circuiting the fallback path so one mailbox item never appears twice as both a card and a text row
- plan-approval responses taking visible sender identity from the mailbox envelope sender rather than from the response payload itself
- plain-text fallback rows showing a colored `@teammate` header with optional wrapper summary, while the full body appears only in transcript mode
- transcript-mode plain-body expansion using an ANSI-aware renderer, so worker-produced terminal styling survives instead of being flattened to plain prose

## Plan approval cards and security boundary

Equivalent behavior should preserve:

- request messages using a dedicated plan-mode visual treatment distinct from ordinary teammate text
- request cards showing requester identity, markdown-rendered plan body, and the referenced plan file path
- response cards choosing success styling for approval and error styling for rejection
- rejected responses optionally surfacing reviewer feedback in a secondary block plus a revision nudge
- approved responses surfacing that execution restrictions have been lifted, rather than only echoing an approval boolean
- plan-mode exit remaining an authorization decision separate from presentation: only plan-approval responses from the team lead are allowed to change permission mode, even though any parseable response that reaches transcript content can still render as a visible approval card
- leader-side plan-approval requests remaining visible even when the poller has already auto-approved them and written the response back to the worker

## Shutdown, assignment, and completion special cases

Equivalent behavior should preserve:

- shutdown requests rendering as warning-toned cards with optional reason text
- shutdown rejections rendering as subdued cards with an explicit rejection reason and a hint that work continues
- shutdown-approved payloads being omitted from rich transcript rendering even though compact summary helpers can still describe them elsewhere
- shutdown rejection remaining ordinary visible mailbox content rather than reserved protocol traffic, unlike shutdown request and shutdown approved
- task-assignment messages rendering in the transcript as team-colored cards with task id, assigner, bold subject, and optional description
- idle notifications being fully hidden rather than downgraded into summary-like plain teammate rows
- task-completed JSON payloads rendering in the wrapped-text transcript path as explicit completion rows that name the completed task id and optionally the task subject
- teammate-terminated JSON payloads being hidden from teammate transcript rows but still usable as compact summary text in alternate callers

## Attachment-path compaction

Equivalent behavior should preserve:

- attachment-based mailbox rendering operating on the surviving post-dedup, post-filter message set rather than on raw unread mailbox contents
- attachment-based teammate mailbox rendering attempting rich rendering only for plan-approval messages
- task-assignment payloads inside attachments collapsing into a single compact bullet row instead of the larger transcript card
- task-assignment compact rows preferring the payload's assigner field but falling back to the wrapper sender when needed
- all other attachment-path teammate content flowing through one shared summary formatter before plain-text display
- plain attachment rows reusing the same colored-header plus optional summary-preview structure as transcript fallback rows
- non-transcript attachment rows usually surfacing only the sender header and optional wrapper summary, because the shared teammate-content row hides its body unless transcript mode is active
- transcript-mode attachment rows expanding the formatted summary text rather than the original raw structured payload, unless the message took one of the dedicated rich-render branches above
- task-completed payloads having no attachment-only rich card path and no dedicated compact summary mapping, so attachment-mode transcript views fall back to raw content when no wrapper summary exists

## Shared summary formatter and parser strictness

Equivalent behavior should preserve:

- one reusable summary helper for compact surfaces with strict precedence: plan approval, shutdown, idle notification, task assignment, teammate-terminated message text, then raw content
- idle summaries combining an idle state with any completed-task outcome and last direct-message summary when present
- shutdown summaries covering shutdown-approved and shutdown-rejected text even though current mailbox renderers often suppress the approved payload before display
- compact formatting never requiring the full transcript body to be visible in order to communicate why a teammate row exists
- summary formatting acting as a compaction layer only; rich transcript cards still outrank it when available
- mixed parser strictness across mailbox message families: plan approval and shutdown variants use schema-validated detection, while idle notifications, task assignments, teammate termination notices, and several protocol detectors rely primarily on `type`-based JSON detection
- malformed plan-approval or shutdown JSON falling back toward plain-text handling instead of crashing the renderer

## Failure modes

- **protocol leak**: permission or mode-control JSON bypasses the inbox poller and appears as teammate text
- **precedence drift**: plan, shutdown, or task-assignment payloads render through both a rich card and a plain summary
- **hidden-count mismatch**: attachment mailbox counts include idle or termination payloads that the UI then suppresses
- **authorization-display confusion**: a visible plan-approval response is treated as trusted control state even though only team-lead responses may change permission mode
- **attachment-versus-transcript drift**: one path shows raw teammate bodies while the other is supposed to show compressed summaries, but a rebuild accidentally forces both through the same formatter
- **transcript flattening**: plain teammate rows always show full bodies and let swarm chatter overwhelm the main conversation
