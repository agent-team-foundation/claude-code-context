---
title: "Skill Improvement Detection and Apply Flow"
owners: []
soft_links: [/integrations/plugins/plugin-and-skill-model.md, /integrations/plugins/skill-loading-contract.md, /runtime-orchestration/query-loop.md, /ui-and-experience/feedback-surveys-and-transcript-share-escalation.md]
---

# Skill Improvement Detection and Apply Flow

Claude Code has an ant-only closed loop for improving project skills from live usage. It watches the main REPL conversation in batched windows, asks a side-channel model whether the user made durable process corrections, surfaces the suggested changes in the prompt area, and can rewrite the skill file asynchronously after user approval. A faithful rebuild needs that loop to stay separate from ordinary feedback surveys and from generic skill loading, or the product will either mutate the wrong skill, overfit one-off instructions, or lose the explicit human approval step.

## Scope boundary

This leaf covers:

- the background registration and gating for the skill-improvement detector
- the post-sampling batching and classifier contract that proposes skill updates
- the app-state handoff from detection into the prompt-area approval surface
- the apply-versus-dismiss response flow
- the asynchronous skill-file rewrite contract

It intentionally does not re-document:

- ordinary skill discovery and prompt expansion already covered in [skill-loading-contract.md](skill-loading-contract.md)
- the broader distinction between skills and plugins already covered in [plugin-and-skill-model.md](plugin-and-skill-model.md)
- the shared feedback-survey prompt area and numeric-response shell beyond the minimal reuse point already covered in [../../ui-and-experience/feedback-surveys-and-transcript-share-escalation.md](../../ui-and-experience/feedback-surveys-and-transcript-share-escalation.md)

## Activation model

Equivalent behavior should preserve:

- skill improvement being an internal background capability, not a user-configurable hook exposed through ordinary settings
- startup wiring registering the capability from background housekeeping rather than only when the user opens a specific command
- activation requiring both the compile-time `SKILL_IMPROVEMENT` feature and the runtime rollout gate for this experiment
- the concern being ant-only in practice because the shipped external REPL strips the approval UI even if neighboring infrastructure exists
- failure to initialize or run the detector never blocking the main REPL startup path

## Detection scope and cadence

Equivalent behavior should preserve:

- the detector only running for queries whose source is the main interactive REPL thread
- the detector refusing to run when no currently invoked project-local skill exists
- project-local skill detection being based on the invoked-skill registry, not on blindly scanning every skill file on disk
- only the first invoked project skill being chosen as the candidate to improve, rather than trying to update many skills at once from one conversational window
- batching the analysis so the detector only rechecks after every five additional user messages instead of on every turn
- separate counters for how many user turns have already been analyzed and where the next incremental slice of messages begins
- each analysis pass only looking at the new message suffix since the prior check rather than rescanning the whole transcript every time

## Classifier prompt contract

Equivalent behavior should preserve:

- the classifier seeing the full current project-skill definition plus only the recently added conversation window
- recent-message formatting being limited to user and assistant turns, with each rendered entry truncated so the classifier prompt stays cheap
- assistant message formatting extracting textual content rather than replaying arbitrary non-text blocks into the classifier
- the classifier prompt explicitly asking for durable process improvements, not one-off answers or transient chat context
- the prompt steering toward three classes of durable change: added steps, changed behavior, and corrections about how future runs should work
- the prompt explicitly telling the model to ignore routine conversation and anything the skill already does
- the required output shape staying a JSON array inside `<updates>` tags
- each suggested update carrying `section`, `change`, and `reason` fields so the approval UI can summarize what would change
- parsing failures degrading to "no updates" instead of surfacing a user-visible error

## Model and execution boundary

Equivalent behavior should preserve:

- the detector running as a post-sampling side-channel model call after the main reply completes rather than competing with the foreground response
- the side-channel call using a small fast model, disabled thinking, and no tools
- hook errors being logged but never aborting the foreground turn
- non-empty results being the only case that mutates app state or opens UI
- analytics recording both the number of detected updates and the affected skill name when the detector finds suggestions

## Suggestion handoff into the REPL

Equivalent behavior should preserve:

- detector success writing one structured suggestion object into app state, containing the target skill name and the proposed updates
- the approval surface opening automatically when a new suggestion arrives rather than waiting for a separate command
- the latest suggestion being cached locally in the UI hook so the surface can keep rendering the current proposal even if the underlying app state gets cleared during the close path
- appearance analytics firing once per suggestion instead of on every render
- the detector and the UI remaining loosely coupled through app state rather than by directly mutating prompt components from the hook

## Approval surface contract

Equivalent behavior should preserve:

- the approval surface living in the prompt area rather than opening a fullscreen editor or diff dialog
- the surface showing the target skill name and a short bulleted list of proposed `change` summaries
- the action map being intentionally binary: `1 = apply`, `0 = dismiss`
- numeric responses being typed into the main prompt input rather than captured by a dedicated modal input loop
- full-width digits being normalized before response handling
- valid approval digits being consumed from the input buffer before normal prompt submission continues
- the surface hiding itself while the user is typing unrelated text, so freeform composition wins over the suggestion prompt
- this approval flow reusing the general feedback-survey response type vocabulary internally, with `good` meaning apply and `dismissed` meaning reject, without exposing those labels to the user

## Apply and dismiss behavior

Equivalent behavior should preserve:

- both apply and dismiss logging a response event with the target skill name
- any non-dismiss response being treated as approval to apply the suggestion
- dismiss closing the surface and clearing the outstanding suggestion without touching the skill file
- apply starting an asynchronous rewrite operation without blocking the main conversation loop
- successful apply appending a compact system-style transcript message that names the updated skill
- both apply and dismiss clearing the stored suggestion from app state so the same proposal does not reopen on the next render
- the local "appearance logged" flag resetting when the suggestion closes so a future suggestion can be logged cleanly

## Skill rewrite contract

Equivalent behavior should preserve:

- rewrites only targeting project-local skills under `.claude/skills/<skill-name>/SKILL.md` relative to the current working directory
- the current skill file being read first and the rewrite aborting softly if that file cannot be read
- the rewrite request sending the full current skill file plus a condensed bullet list of requested improvements to a side-channel model
- the rewrite prompt instructing the model to preserve frontmatter exactly, preserve overall format and style, and avoid deleting unrelated content
- the rewrite response being required to return the complete new file inside `<updated_file>` tags rather than a patch fragment
- missing or malformed `<updated_file>` output aborting the write instead of risking a partial or ambiguous skill mutation
- successful rewrites replacing the entire `SKILL.md` contents in one write step
- write failures being logged without surfacing a fatal REPL error

## Design constraints

Equivalent behavior should preserve:

- skill improvement being advisory and approval-gated rather than silently editing skills behind the user's back
- only project-owned skills being eligible, so a session does not rewrite bundled, user-global, or plugin-provided skills from incidental corrections
- incremental windows being treated as process memory, so the detector remembers which conversation slice it already analyzed
- the approval surface summarizing only the proposed behavioral deltas, not dumping the whole rewritten skill file into the prompt area
- the actual rewrite being delegated to a side-channel model so the main assistant turn is not forced to become its own skill-file editor

## Failure modes

- **wrong skill target**: the detector updates a bundled or user-global skill because project-skill selection was not scoped to invoked `projectSettings:` skills
- **repeat nagging**: the analyzer rescans old transcript windows and resurfaces the same correction every five turns forever
- **one-off overfitting**: the classifier treats transient chat answers as durable process changes because the prompt no longer distinguishes reusable preferences from one-time context
- **approval bypass**: suggested changes are written automatically without the prompt-area apply or dismiss step
- **frontmatter corruption**: the rewrite path emits only a patch fragment or rewrites metadata that should have been preserved exactly
- **foreground blockage**: applying a suggestion blocks the main conversation loop or fails hard when the side-channel model or filesystem write errors out
- **vanishing proposal**: the UI loses the pending suggestion because app state is cleared before the hook keeps a local copy for rendering
