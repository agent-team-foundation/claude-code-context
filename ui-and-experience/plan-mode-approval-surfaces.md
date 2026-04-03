---
title: "Plan Mode Approval Surfaces"
owners: []
soft_links: [/ui-and-experience/permission-prompt-shell-and-worker-states.md, /tools-and-permissions/permission-decision-pipeline.md, /runtime-orchestration/turn-attachments-and-sidechannels.md, /product-surface/session-state-and-breakpoints.md]
---

# Plan Mode Approval Surfaces

Plan mode does not reuse the generic permission experience as-is. Entering plan mode uses a short specialized confirmation, while exiting plan mode expands into a plan-review surface that can show the drafted plan, explain why approval is required, let the user edit the plan, accept with several execution postures, or reject with text and image feedback. A faithful rebuild needs these plan-specific surfaces and their decision routing, or the product will lose the boundary between "design first" and "start executing now."

## Enter-plan approval contract

Equivalent behavior should preserve:

- entering plan mode using a dedicated plan-colored permission dialog instead of a generic tool card
- the enter-plan surface explaining that Claude wants to inspect the codebase and prepare an implementation approach before making edits
- the confirmation copy emphasizing that no code changes happen until the user later approves the plan
- the action list staying intentionally binary: accept plan mode or skip directly to implementation
- canceling that prompt being treated the same as declining plan mode
- accepting plan mode logging the dedicated enter-plan analytics event, transitioning the permission context into `plan`, closing the dialog, and approving the tool with a session-scoped mode update
- declining plan mode closing the dialog, triggering the standard rejection path, and leaving execution in the existing mode

## Exit-plan surface selection

Equivalent behavior should preserve:

- exit-plan approval using a different specialized plan-colored surface rather than the shared generic choice prompt
- non-empty plans rendering as a review screen titled like a readiness-to-code checkpoint, not just a yes-or-no confirmation
- empty plans taking a simplified fallback surface with only a minimal exit confirmation, because there is no plan body to review or scroll
- V2 exit-plan requests treating the plan as file-backed state and V1 requests treating it as inline tool input, while both still surface one current editable plan string
- the long-plan surface rendering the plan body as markdown inside a dedicated bordered review region instead of flattening it into plain prompt text
- the plan review section including permission-rule rationale and any requested prompt-based permission grants before the user chooses how to proceed
- requested prompt grants only appearing when classifier-backed permissions are enabled and the plan actually requested prompt-scoped allowances

## Approval option matrix

Equivalent behavior should preserve:

- the exit-plan option list being assembled dynamically from settings and permission availability rather than hard-coded to one fixed pair of answers
- clear-context options only appearing when the user setting to show them on plan acceptance is enabled
- clear-context labels including current context usage percentage when usage data exists, so users can see why clearing context may matter
- the first acceptance slot preferring auto mode when available, otherwise bypass-permissions when available, otherwise accept-edits
- the second acceptance slot being the keep-context elevated option, again preferring auto mode over bypass-permissions over accept-edits
- a manual-approval keep-context option always remaining available as the lower-risk accept path
- the Ultraplan deferral option appearing only when the feature is enabled and no Ultraplan session is already active or launching
- the final "keep planning" option being an input-backed response rather than a plain reject button, so the user can send revision guidance back with the rejection
- the option order remaining stable: clear-context first when enabled, then elevated keep-context, then manual keep-context, then optional Ultraplan, then the input-backed rejection path

## Feedback, editing, and attachments

Equivalent behavior should preserve:

- the rejection path capturing trimmed textual feedback and treating blank feedback as absent
- the rejection option staying in input mode until the user actually provides text or pasted images, instead of rejecting immediately on an untouched field
- the rejection option advertising that `shift+tab` can approve with the current feedback instead of forcing a reject-and-replan round trip
- `shift+tab` immediately choosing the elevated keep-context approval path that corresponds to the current permission posture
- pasted images being accepted on the plan-review surface, stored as pending content, removable before submission, and resized or downsampled before they are forwarded with a rejection
- rejecting with no text but with images still being valid, with the rejection feedback downgraded to a generic attachment notice
- `ctrl-g` opening an external editor from the exit-plan screen, with V2 editing the plan file directly and V1 editing the in-memory plan text
- successful external edits updating the visible plan, flashing a transient saved indicator, and marking V2 plans as locally edited when the edited content differs from the previously displayed plan
- the editor hint showing the external editor name and, for V2 file-backed plans, the display path to the plan file

## Acceptance routing and mode transitions

Equivalent behavior should preserve:

- every accept path setting the one-shot "has exited plan mode" marker so later attachment logic can tell the model it has left planning
- keep-context acceptance paths also setting the dedicated plan-mode-exit attachment marker, because the session is continuing in place
- clear-context acceptance paths not using the normal allow-and-continue flow; they seed a new initial user message, locally reject the permission dialog to unblock the loop, and let REPL restart execution with the selected mode
- the seeded initial message containing the approved plan plus transcript-location guidance, optional team-creation advice, and any user acceptance feedback
- accepted feedback traveling on approve paths as accept-side guidance instead of being discarded or treated as a rejection artifact
- session permission updates being built from the chosen keep-context or standard accept mode, including prompt-scoped allow rules when classifier permissions requested them
- auto-mode keep-context being handled as a special case instead of flowing through the generic permission-update builder, because generic external-mode mapping would otherwise collapse auto back to default
- when auto mode was used during planning but the chosen exit path is not auto, dangerous permissions being restored and a separate auto-mode-exit attachment being requested
- clear-context auto acceptance stripping dangerous permissions for the new run and marking auto mode active before the fresh query starts
- empty-plan acceptance defaulting back to standard manual approval mode rather than exposing the richer option matrix

## Session continuity and side-channel behavior

Equivalent behavior should preserve:

- accepted clear-context plans optionally auto-naming the next session from the plan contents when persistence is enabled and the session was not already explicitly named
- clear-context acceptance preserving the current plan slug before the new session starts, so the next session can still find the plan file
- REPL consuming the pending initial-message handoff atomically by clearing the queued message, applying the chosen permission updates, and optionally storing the approved plan for later verification bookkeeping
- the plan-review surface using refs when it registers a fullscreen sticky footer, so footer controls keep select focus and input state even while the surrounding component rerenders
- fullscreen mode moving the choice list into the sticky footer only when a real non-empty plan exists, while scrollback mode keeps the options inline below the plan body
- sticky-footer teardown clearing the footer registration when the dialog disappears, so long-plan controls do not leak into later UI states
- choosing Ultraplan dismissing the local dialog immediately, rejecting the local plan execution, and launching the remote refinement flow asynchronously so the command loop is not blocked

## Failure modes

- **mode collapse**: auto-mode approval falls through generic permission updates and silently returns the session to default mode
- **lost plan edits**: V2 local plan edits are not echoed back through approval input when needed, so the executing model never sees the revised plan text
- **sticky-footer leak**: fullscreen plan controls remain mounted after the approval surface closes
- **feedback drop**: accept-side feedback or pasted rejection images disappear during submission and never reach the next planning or execution step
- **wrong option ordering**: bypass, auto, and manual approval choices appear in the wrong priority order and change the execution posture the shortcut keys assume
- **empty-plan mismatch**: the UI tries to render the long review surface for an empty plan and exposes controls that depend on plan content that is not there
