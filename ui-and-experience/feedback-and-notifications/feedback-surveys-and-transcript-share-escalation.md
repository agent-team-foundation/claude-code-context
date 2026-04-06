---
title: "Feedback Surveys and Transcript-Share Escalation"
owners: []
soft_links: [/memory-and-context/durable-memory-recall-and-auto-memory.md, /memory-and-context/compact-path.md, /product-surface/command-surface.md, /ui-and-experience/shell-and-input/prompt-composer-and-queued-command-shell.md]
---

# Feedback Surveys and Transcript-Share Escalation

Claude Code treats lightweight feedback as a staged escalation ladder rather than as one isolated modal. Session feedback, post-compact feedback, and memory-specific feedback all reuse one survey state machine, one digit-input capture pattern, and one transcript-sharing backend. A faithful rebuild needs that layering to stay intact or the product will ask at the wrong moments, reroll probabilities incorrectly, or lose the handoff from lightweight ratings into richer issue reporting.

## Scope boundary

This leaf covers:

- the shared survey shell that lives in the prompt area and reads numeric responses from the main composer
- the common survey state machine, transcript-share prompt, and transcript-submission contract
- session feedback survey pacing and transcript-share escalation
- post-compact and memory-specific survey triggers
- detailed-feedback follow-up, auto-run issue notification, and internal-only escalation extensions

It intentionally does not re-document:

- compaction internals beyond the survey trigger boundary already covered in [../memory-and-context/compact-path.md](../memory-and-context/compact-path.md)
- durable-memory storage and recall beyond the memory-survey trigger conditions already covered in [../memory-and-context/durable-memory-recall-and-auto-memory.md](../memory-and-context/durable-memory-recall-and-auto-memory.md)
- the broader command semantics behind `/feedback`, `/issue`, or `/good-claude`, which belong with the command surface
- the separate internal-only skill-improvement survey, which reuses the same prompt region but applies suggested skill edits instead of collecting product feedback

## Shared prompt-area shell

Equivalent behavior should preserve:

- these feedback surfaces living in the ordinary prompt area instead of a separate fullscreen workflow
- the whole stack only rendering while prompt input is visible, no higher-priority focused dialog has taken the lane, the session is not exiting, and the transcript cursor bar is not active
- survey-opening logic refusing to arm while permission prompts, ask-user prompts, sandbox requests, elicitation prompts, or worker-permission prompts are already visible
- a stable precedence inside the prompt area: auto-run issue notification first, then post-compact survey, then memory survey, then ordinary session survey
- an internal-only frustration transcript-share surface remaining a separate sibling slot after those ordinary surveys instead of being folded into the session-survey logic
- internal-only skill-improvement and issue-flag surfaces rendering lower in the same prompt-area region without displacing the higher-priority survey surfaces above them

## Shared digit-input contract

Equivalent behavior should preserve:

- feedback surveys reusing the main prompt input instead of capturing raw keypresses through a separate modal-specific input loop
- all survey responses being single-digit choices consumed from the trailing prompt input buffer after a short debounce instead of firing on the very first numeric keystroke
- a debounce window long enough to avoid accidental submission when users begin a message with something like `1.` in a numbered list, but short enough to still feel immediate for intentional answers
- normalization of full-width digits before validating a response
- the survey prompt hiding itself when the current input buffer contains unrelated numeric text that does not match the active response map, so freeform typing does not silently trigger the wrong action
- ordinary survey choices staying `1 = bad`, `2 = fine`, `3 = good`, `0 = dismiss`
- transcript-share choices staying `1 = yes`, `2 = no`, `3 = don't ask again`
- the optional detailed-feedback follow-up on the thanks screen being a separate one-shot `1` gesture rather than part of the original rating question

## Shared survey state machine

Equivalent behavior should preserve:

- one reusable survey state machine with the states `closed`, `open`, `thanks`, `transcript_prompt`, `submitting`, and `submitted`
- each fresh appearance minting a new `appearanceId` UUID so analytics and transcript-share uploads are keyed per appearance instead of per session
- the open callback firing as soon as the survey opens, not after the user responds
- the select callback firing before any later transition, so analytics always record the original rating even if a transcript-share prompt appears next
- `dismissed` closing immediately and clearing the remembered last response instead of flowing through the thanks state
- survey implementations deciding per response whether to branch into `transcript_prompt`
- transcript-share `yes` moving through `submitting` and ending in `submitted` only if upload succeeds
- transcript-share failure or exceptions falling back to the ordinary `thanks` state instead of leaving the UI stuck in a spinner
- `no` and `don't ask again` skipping submission and going directly to the same short-lived thanks state
- both `thanks` and `submitted` auto-closing after the configured delay, which is currently three seconds for the shipped survey variants in this area

## Session feedback survey

Equivalent behavior should preserve:

- the ordinary session survey only opening when it is closed, the session is idle, and no prompt-class UI is already active
- model gating being driven by dynamic config, including an allowlist that can target specific main-loop models or all models
- kill switches from environment flags and analytics config being able to suppress the survey globally
- product-feedback policy checks blocking the survey when the organization disallows that data flow
- first appearance in a session requiring both a minimum elapsed session age and a minimum number of user submits since session start
- later appearances in the same session requiring both a minimum elapsed time and a minimum number of new user submits since the last appearance
- a separate cross-session cooldown stored in global config, so multiple sessions on the same machine still pace survey frequency together
- the current fallback defaults remaining approximately: ten minutes before first appearance, five user turns before first appearance, one hour between later appearances in the same session, ten additional user turns between later appearances, and about twenty-eight hours between appearances across sessions
- survey probability being dynamic-config driven, with a per-user settings override, but rolled only once per eligibility window keyed by submit count instead of rerolling on every render
- last-shown pacing state being written when the survey appears, not only when the user responds, so passive dismissals still count for pacing

## Transcript-share escalation

Equivalent behavior should preserve:

- only `bad` and `good` survey ratings being eligible to escalate into a transcript-share ask
- separate probability gates for bad and good transcript-share asks in the ordinary session survey
- the global `transcriptShareDismissed` config bit suppressing future asks across both session and memory surveys
- product-feedback policy checks also blocking transcript-share escalation, not just the original survey
- transcript-share appearance and response events being logged with a trigger that distinguishes bad-feedback, good-feedback, memory-survey, and frustration-survey origins
- choosing `don't ask again` persisting the durable dismissal bit immediately
- choosing `yes` collecting the normalized current transcript, any available subagent transcripts, and the raw JSONL session transcript when that file is small enough to read safely
- the submission payload being redacted before upload rather than trusting raw transcript text
- transcript sharing refreshing auth if needed and then posting the redacted bundle plus the survey `appearanceId` to Anthropic with a bounded network timeout
- success showing a dedicated submitted message, while failure quietly degrades into an ordinary thank-you rather than surfacing a hard error dialog

## Post-compact survey

Equivalent behavior should preserve:

- this survey being separately feature-gated instead of piggybacking on the ordinary session-survey rollout
- the REPL disabling it entirely during remote sessions
- compact boundaries being tracked by message UUID so the hook can tell which compactions are new
- one pending compact boundary being remembered after compaction, with the newest unseen boundary winning if several boundaries appear before a follow-up message
- the survey not opening immediately when compaction happens
- the actual decision point being deferred until a later user or assistant message arrives after the pending compact boundary
- the probability roll happening only at that later follow-up point, with a fixed twenty-percent chance in the shipped implementation
- already-seen compact boundaries not retriggering the survey on later renders
- this survey reusing the common rating and thanks flow, but not the transcript-share branch

## Memory survey

Equivalent behavior should preserve:

- this survey being separately feature-gated and defaulting off in third-party environments that do not receive the relevant rollout config
- the REPL disabling it entirely during remote sessions
- auto-memory needing to be enabled before the survey is even considered
- the same product-feedback policy and global survey kill switches applying here too
- the last assistant message needing to be new for evaluation, so the hook does not reroll probability for the same assistant turn across re-renders
- eligibility requiring the latest assistant text to explicitly mention memory
- eligibility also requiring that the conversation has previously included a file-read tool call against an auto-managed memory file, so the survey only appears after Claude actually touched memory storage
- the expensive memory-file-read scan becoming sticky for the rest of the session once observed, instead of rescanning the whole transcript every render
- both the sticky memory-read flag and the set of already-evaluated assistant messages resetting when `/clear` empties the message list even though the REPL component stays mounted
- the final probability gate being a fixed twenty-percent chance per newly eligible assistant message in the shipped implementation
- the memory survey using its own prompt text, asking how well Claude used its memory rather than how the session went overall
- narrower internal builds escalating both bad and good memory ratings into transcript-share without an extra probability gate once the survey is shown
- public builds omitting that transcript-share branch even though the shared transcript-submit backend still supports the `memory_survey` trigger

## Detailed feedback handoff and auto-run issue

Equivalent behavior should preserve:

- the thanks screen being more than a dead end: it can still hand the user into richer feedback capture
- a good response showing an optional one-shot `1` follow-up that launches a richer feedback command
- a fine response showing informational guidance toward the richer feedback command without auto-launching it
- a bad response showing issue-reporting guidance rather than the good-response follow-up affordance
- the richer follow-up command being `/feedback` in the shipped public build and a diagnostics-oriented command in narrower internal builds
- one REPL-side wrapper around the ordinary session survey being responsible for deciding whether a bad response should arm auto-run issue behavior
- that wrapper only considering auto-run when the response was `bad` and no transcript-share prompt took over the flow
- the auto-run notification living above the survey stack, auto-submitting its command on mount, and still wiring Escape as a cancellation path for the notification surface
- a sticky per-cycle ref suppressing the ordinary follow-up affordance after auto-run has been armed, so the user is not immediately offered a second redundant escalation path from the same rating
- the shipped external build currently leaving `shouldAutoRunIssue(...)` hard-false for both bad and good reasons, so the helper types and UI exist but no automatic feedback command actually triggers there
- the helper contract still reserving a future good-response auto-run path, including a distinct positive-feedback reason and helper in narrower builds

## Internal-only issue-flag banner

Equivalent behavior should preserve:

- a separate internal-only banner surface that nudges the user toward a diagnostics-oriented issue command when the latest user message looks frustrated
- friction detection being based on the latest user message rather than on a vague whole-session sentiment score
- the trigger patterns including direct corrections, references to missed instructions, `why did you`, `you were supposed to`, `try again`, and undo or revert phrasing
- a minimum of three user submits before this banner can appear
- a thirty-minute cooldown between banner activations
- once triggered, the banner staying visible until the next user submit rather than disappearing on the next render tick
- compatibility checks suppressing the banner for sessions that already crossed into incompatible containers, especially any session that used MCP tools
- the same compatibility check also suppressing the banner when prior Bash tool calls match external-command patterns such as `curl`, `ssh`, `kubectl`, `docker`, cloud CLIs, `git push/pull/fetch`, or `gh pr`/`gh issue`
- public builds omitting the banner UI even though adjacent hooks still reveal the extension point

## Adjacent internal-only transcript-share hook

Equivalent behavior should preserve:

- a dedicated frustration-detection slot after the ordinary surveys instead of pretending every transcript-share request originates from the session survey
- the transcript-share backend still reserving a `frustration` trigger value even in the external source dump
- the current public build stubbing the frustration hook to a permanently closed state and omitting the implementation module from the snapshot
- rebuilds therefore keeping frustration-triggered transcript sharing as a separate extension point, even if the precise internal detector must be reconstructed from other evidence later

## Failure modes

- **survey spam**: probability is rerolled on every render or only response time updates pacing state, so a user gets repeatedly re-asked after one eligibility window
- **prompt-area collisions**: surveys open while permission or ask-user prompts are already active, or multiple survey types render at once instead of respecting the intended precedence chain
- **post-compact mistiming**: the compaction survey opens immediately at the compact boundary instead of waiting for a later conversational turn
- **memory false positives**: the memory survey fires just because Claude mentioned memory, even though no auto-managed memory file was actually read, or it leaks eligibility across `/clear`
- **transcript-share drift**: uploads omit subagent transcripts or raw JSONL data, skip redaction, or lose the durable `don't ask again` dismissal bit
- **double escalation**: auto-run issue and the ordinary follow-up affordance can both fire from one bad rating cycle
- **banner overreach**: the issue-flag banner appears in MCP-heavy or externally orchestrated sessions where `/issue` nudging would be noisy or misleading
