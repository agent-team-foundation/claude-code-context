---
title: "Ask-User Question and Plan Interview UI"
owners: []
soft_links: [/ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md, /ui-and-experience/dialogs-and-approvals/plan-mode-approval-surfaces.md, /tools-and-permissions/permissions/permission-decision-pipeline.md, /tools-and-permissions/tool-catalog/tool-families.md, /product-surface/session-state-and-breakpoints.md]
---

# Ask-User Question and Plan Interview UI

Ask-user prompts are not a plain list of questions. Claude Code can turn one permission request into a paged interview flow with responsive tab headers, per-question text state, image attachments, preview-driven option layouts, review-before-submit, and plan-mode-only footer actions that either continue the interview or hand the conversation back to Claude. A faithful rebuild needs the same front-end flow control and answer-shaping or clarifications will feel lossy and plan interviews will branch incorrectly.

## Scope boundary

This leaf covers the local foreground ask-user / plan-interview UI from prompt render until it resolves through allow or reject callbacks.

It intentionally does not cover:

- the shared permission queue, delayed notifications, generic interrupt binding, and common dialog shell behavior already captured in [permission-prompt-shell-and-worker-states.md](permission-prompt-shell-and-worker-states.md)
- the separate enter-plan and exit-plan approval surfaces already captured in [plan-mode-approval-surfaces.md](plan-mode-approval-surfaces.md)
- the downstream query-loop behavior that consumes approved answers or rejection feedback after the prompt closes

## Surface activation and sizing

Equivalent behavior should preserve:

- validating ask-user input through the tool schema before rendering and treating malformed input as an empty question set rather than crashing the surface
- optional lazy-loading of CLI syntax highlighting, with a non-highlighted fallback view when highlighting is disabled or still loading
- one global content height and width budget being computed across all questions before the current question renders, so the interface does not jump as the user tabs between different question shapes
- that budget respecting a fixed minimum content area, the terminal row count, and extra chrome reserved for navigation bars, help text, and footers
- preview-bearing questions contributing both height and width pressure to the global layout budget, while simple text-only questions size mainly from option count

## Local question-flow state

Equivalent behavior should preserve:

- one reducer-like UI state owning the current question index, finalized answer strings, per-question transient state, and whether a text input is currently focused
- per-question transient state separating selected option values from freeform text so the UI can preserve partially typed answers while the user navigates away
- multi-select questions defaulting their selected value state to an empty list, while single-select questions default to no selected value
- moving to the next or previous question automatically clearing text-input mode so tab navigation can resume
- a single non-multi-select question hiding the synthetic submit tab and auto-submitting immediately after selection instead of forcing an extra review step

## Navigation bar contract

Equivalent behavior should preserve:

- a question-navigation strip that shows question headers, answer completion checkboxes, optional submit state, and left or right arrow affordances
- question headers preferring explicit `header` values and falling back to `Q1`, `Q2`, and so on when no short header exists
- terminal-width-aware truncation that preserves the current tab preferentially, shortens other tabs more aggressively, and degrades to an ultra-minimal current-only display when the terminal is too narrow
- answered questions showing a checked box and unanswered questions showing an empty box
- the submit tab disappearing entirely when the flow auto-submits after a single question

## Standard question layout

Equivalent behavior should preserve:

- ordinary non-preview questions rendering through a compact vertical select list rather than the plan-approval choice prompt
- every text-oriented question automatically appending an `Other` input option to the tool-provided options
- standard single-select questions committing an answer immediately and advancing to the next step, while multi-select questions keep collecting values until the user advances explicitly
- multi-select flows relabeling their advance button as `Submit` on the last question and `Next` otherwise
- the `Other` option persisting its draft text in per-question state and offering external-editor editing when that input is focused
- when the session is in plan mode and a plan file path exists, the question view surfacing a `Planning:` line above the question body that links back to the plan file

## Preview-question layout

Equivalent behavior should preserve:

- single-select questions with preview payloads switching to a different side-by-side layout instead of reusing the ordinary select list
- preview questions intentionally omitting the `Other` option and only exposing the tool-provided options
- the left pane showing numbered options with a moving pointer and a separate success marker for the selected option
- the right pane rendering preview content in a bordered preview box that respects the shared height budget, applies markdown rendering, and truncates oversized content with an explicit hidden-lines indicator
- preview notes being captured separately from the selected option, editable inline, and reopenable in the external editor via `ctrl+g` while notes input is focused
- selecting a preview option reusing the same immediate-answer path as other single-select questions, while notes stay separate until final submission turns them into annotations
- option focus resetting sensibly when the user changes questions, preferring the previously selected option for that question and otherwise falling back to the first option

## Keyboard and footer behavior

Equivalent behavior should preserve:

- arrow keys and `ctrl-p` or `ctrl-n` navigating options vertically, with moving past the last item transferring focus into the footer actions
- preview questions additionally supporting numeric hotkeys for direct option focus and `n` as a shortcut into the notes field
- the preview-question child surface re-registering tab-navigation bindings locally so tab switching remains reliable even when child input handlers run before the parent
- text-input focus temporarily disabling tab switching so the user can type without advancing questions accidentally
- both standard and preview layouts exposing a footer action to “Chat about this,” which hands the question set back to Claude instead of approving answers
- plan mode adding a second footer action to “Skip interview and plan immediately,” which ends the interview loop without approving the collected answers
- escape canceling the whole prompt from option, footer, or notes modes instead of only dismissing the currently focused control

## Answers, notes, and attachments

Equivalent behavior should preserve:

- per-question image attachments being stored independently so each answer can be composed with the right pasted images before final submission
- image attachments being cacheable, removable, and converted to resized content blocks only at resolution time
- freeform `Other` answers explicitly appending an image marker when the answer text is accompanied by pasted images
- image-only `Other` answers turning into a visible image-attached placeholder instead of vanishing as empty text
- accepted answers optionally carrying per-question annotations that include the chosen preview text and trimmed user notes, but only when either of those extra fields actually exists
- accepted ask-user submissions resolving through `onAllow(updatedInput, [], undefined, contentBlocks)` with no extra permission updates layered on top

## Submission and rejection branches

Equivalent behavior should preserve:

- canceling the prompt resolving through the shared reject path and, when metadata source is available, logging ask-user rejection analytics tagged with question count and plan-interview status
- the explicit submit-review screen showing a warning when not all questions have been answered, listing answered questions, explaining the permission reason, and offering only `Submit answers` or `Cancel`
- “Chat about this” rejecting the tool with a synthesized feedback message that summarizes the questions and current answers, asks Claude to take the user’s clarification into account, and invites a reformulated follow-up
- “Skip interview and plan immediately” rejecting the tool with a different synthesized feedback message that tells Claude to stop asking clarifying questions and finish the plan with the information already collected
- both special reject branches forwarding any pasted images along with their synthetic feedback message
- accepted submissions logging a distinct acceptance analytics event, including question count, answer count, source metadata, and whether the surface is operating as a plan interview

## Failure modes

- **layout thrash**: height or width is calculated from only the current question and the screen jumps wildly when the user tabs between preview-heavy and simple questions
- **tab hijack**: tab bindings stay active while the user is typing, causing text entry to switch questions unexpectedly
- **preview collapse**: preview questions reuse the generic `Other`-driven layout and lose side-by-side preview or notes behavior
- **answer corruption**: multi-select, freeform text, and image-only answers serialize differently across branches and reach the tool in inconsistent formats
- **footer ambiguity**: plan mode forgets to add the second footer action and cannot distinguish “keep interviewing” from “finish the plan now”
- **annotation loss**: selected preview snippets or notes never make it into accepted answer annotations, so Claude loses the rationale the user supplied during review
- **attachment loss**: pasted images appear in the UI but are not carried through the final allow or reject callback

## Test Design

In the observed source, dialog and approval behavior is verified through focused rendering or view-model regressions, store-backed integration tests, and interactive acceptance flows.

Equivalent coverage should prove:

- focus, overlay arbitration, diff navigation, structured rendering, and approval routing preserve the invariants documented in this leaf
- dialog state remains correctly coupled to permission, plan, session, and transcript stores without timing-dependent leaks
- users can actually reach, dismiss, accept, deny, export, or navigate these surfaces through the packaged interactive UI
