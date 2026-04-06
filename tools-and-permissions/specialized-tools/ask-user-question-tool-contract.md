---
title: "Ask-User Question Tool Contract"
owners: []
soft_links: [/tools-and-permissions/agent-and-task-control/control-plane-tools.md, /tools-and-permissions/permissions/permission-decision-pipeline.md, /ui-and-experience/dialogs-and-approvals/ask-user-question-and-plan-interview-ui.md, /runtime-orchestration/turn-flow/turn-attachments-and-sidechannels.md]
---

# Ask-User Question Tool Contract

`AskUserQuestion` is not a generic text prompt. It is a deferred control-plane tool with a strict multiple-choice schema, optional preview payloads, plan-mode-specific prompt rules, and a result format that feeds the user's selections back into the same turn. Reproducing Claude Code requires the same tool-layer contract or the ask-user UI will collect answers that the runtime, SDK, and model cannot interpret consistently.

## Scope boundary

This leaf covers the tool-layer contract for ask-user flows:

- tool identity, enablement, and registry semantics
- input and output schema rules
- preview-format guidance and validation
- permission-check behavior specific to this tool
- tool-result rendering and model-facing serialization

It intentionally does not cover:

- the foreground questionnaire UI, pagination, notes entry, image paste UX, or footer navigation already captured in [ask-user-question-and-plan-interview-ui.md](ask-user-question-and-plan-interview-ui.md)
- the generic permission queue, classifier escalation rules, and shared approval pipeline already captured in [permission-decision-pipeline.md](permission-decision-pipeline.md)
- downstream query-loop behavior after the tool has been approved or rejected

## Tool identity and availability

Equivalent behavior should preserve:

- one stable tool identity named `AskUserQuestion`, discoverable as a multiple-choice user-elicitation tool rather than a freeform chat primitive
- the tool being declared deferred, read-only, and concurrency-safe, so it waits on the permission flow instead of pretending to execute immediately or mutate the filesystem
- the tool explicitly requiring live user interaction, making it ineligible for any rebuild path that assumes silent background completion
- the tool returning an empty user-facing name, so generic permission-attention messaging is used unless a dedicated ask-user surface overrides it
- the tool being disabled entirely when the session is running through allowed out-of-band channels with no keyboard-visible terminal, because the multiple-choice dialog would otherwise hang with no viable interaction path

## Input schema contract

Equivalent behavior should preserve:

- input accepting 1-4 questions, with each question carrying a full `question` string, a short `header`, 2-4 options, and an optional `multiSelect` flag that defaults to false
- each option carrying a `label`, `description`, and optional `preview`, with labels intended to stay concise and descriptions carrying the trade-off explanation
- `header` being a very short chip-style label rather than another long prompt line, with a hard presentation budget of 12 characters
- question texts needing to be unique across the whole tool call, and option labels needing to be unique within each individual question
- option lists intentionally excluding any built-in `Other` choice, because the permission surface injects that affordance automatically for non-preview text questions
- `multiSelect` changing only answer semantics, not relaxing the rest of the schema or uniqueness rules
- optional `answers`, `annotations`, and `metadata.source` fields existing on input so the permission surface can round-trip user responses and tracking metadata back through the same tool input
- `metadata.source` staying analytics-oriented and non-user-visible

## Public SDK and output shape

Equivalent behavior should preserve:

- the public SDK-facing input and output schemas matching the internal schemas once `preview` and per-question `annotations` are exposed
- output returning the original `questions` array plus an `answers` record keyed by question text, with every value serialized as a string
- multi-select answers being flattened into one comma-separated string per question rather than a structured string array in output
- `annotations` being optional and keyed by question text, with each annotation carrying only `preview` and `notes`
- the tool's `call()` path acting as an echo-style wrapper that returns the asked questions, collected answers, and optional annotations without inventing any extra result fields

## Prompt and preview-format contract

Equivalent behavior should preserve:

- the base tool prompt positioning ask-user as a way to gather preferences, clarify ambiguity, request decisions during execution, and offer concrete choices
- the prompt teaching the model that any recommended option should be listed first and suffixed with `(Recommended)`
- the prompt teaching the model that users will always have an `Other` text-input escape hatch even though that option is not part of the schema
- plan mode having extra prompt guidance: the tool may clarify requirements before the plan is finalized, but it must not ask for plan approval or refer to a plan the user cannot yet see; plan approval belongs to the exit-plan tool instead
- preview guidance being omitted entirely when no preview format is configured, because some SDK consumers may not render previews at all
- a configured `markdown` preview format adding prompt guidance for ASCII mockups, code snippets, diagram variants, and config examples, with the expectation that previews render in a monospace markdown box
- a configured `html` preview format adding prompt guidance for HTML mockups and richer formatted comparisons, but constraining previews to self-contained HTML fragments
- preview payloads being treated as a single-select affordance only; rebuilds should not rely on preview-driven comparison UIs for multi-select questions

## Preview validation rules

Equivalent behavior should preserve:

- HTML preview validation only running when the configured preview format is `html`; markdown or undefined preview formats skip this validation layer
- HTML preview validation being intentionally lightweight and intent-focused rather than a full HTML parser
- rejecting previews that contain `<html>`, `<body>`, or `<!DOCTYPE>`, because the contract expects a fragment rather than a whole document
- rejecting previews that contain `<script>` or `<style>` tags, while still leaving final sanitization responsibility to the embedding consumer
- rejecting HTML-mode previews that contain no actual HTML tag at all, so plain text cannot masquerade as fragment-mode HTML
- validation failures pointing back to the specific option label and question text that violated the contract

## Permission and interaction semantics

Equivalent behavior should preserve:

- `checkPermissions()` always returning behavior `ask`, the unchanged input as `updatedInput`, and a tool-specific prompt message asking the user to answer questions
- the tool remaining bypass-immune in practice because it explicitly requires user interaction, even when the surrounding runtime has more permissive auto or bypass modes available for other tools
- any classifier-facing summary text, when requested by shared permission infrastructure, being derived from the question texts rather than option descriptions or preview payloads
- the permission router selecting a dedicated ask-user permission component instead of the generic fallback renderer

## Result and transcript behavior

Equivalent behavior should preserve:

- no separate tool-use or in-progress transcript row being emitted before the permission surface resolves
- accepted tool results rendering a compact transcript summary that lists each answered question and the chosen answer
- rejected tool results rendering a simple declined-to-answer message rather than replaying the whole questionnaire
- error-result rendering being absent, leaving failure presentation to higher-level permission or runtime flows
- model-facing tool-result block serialization flattening each answer into a quoted `question = answer` pair
- that same serialized tool-result block appending selected preview content and user notes inline when annotations exist for that question
- the final tool-result text explicitly telling the model to continue with the user's answers in mind, so later reasoning does not need to rediscover where the answers came from
- image attachments or other rich side-channel payloads from the permission surface not becoming schema fields on the tool output; they travel separately through approval/rejection content blocks

## Failure modes

- **schema drift**: the SDK surface, internal schema, and permission callback payloads stop agreeing on whether `preview` and `annotations` are legal fields
- **duplicate-choice ambiguity**: repeated question texts or option labels make the returned `answers` record impossible to interpret deterministically
- **preview-mode mismatch**: HTML-mode previews are accepted without fragment validation, or markdown-mode consumers are forced to satisfy HTML-only checks
- **plan-approval misuse**: the tool prompt lets the model ask users to approve or comment on an unseen plan instead of routing through exit-plan approval
- **channel hang**: ask-user stays enabled in channel-only contexts and deadlocks waiting for a terminal interaction path that does not exist
- **annotation loss**: selected preview content and user notes are visible in the UI but never survive into tool results or model-facing tool-result blocks
- **sidechannel collapse**: attachments are incorrectly stuffed into schema fields instead of traveling as separate approval content blocks
