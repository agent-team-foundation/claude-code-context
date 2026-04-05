---
title: "Feedback and Issue Commands"
owners: []
soft_links: [/ui-and-experience/feedback-surveys-and-transcript-share-escalation.md, /runtime-orchestration/build-profiles.md, /platform-services/consumer-privacy-policy-flow.md, /platform-services/auth-config-and-policy.md]
---

# Feedback and Issue Commands

Claude Code does not expose one undifferentiated "report a problem" button. The public build has a manual `/feedback` flow. The clean-room snapshot also shows stubs, UI hints, and escalation wiring for richer `/issue` and positive-feedback paths that belong to narrower builds. Rebuilding the surface faithfully means preserving that split and flagging what is still only partially visible.

## Scope boundary

This leaf covers:

- the public `/feedback` command
- the observable semantic role of `/issue` and `/good-claude`
- the reserved auto-run escalation path from surveys into those commands

It intentionally does not re-document:

- the full survey state machine already covered in [../ui-and-experience/feedback-surveys-and-transcript-share-escalation.md](../ui-and-experience/feedback-surveys-and-transcript-share-escalation.md)
- generic prompt-area rendering and notification stacking already covered in the UI domain

## `/feedback` is the public manual feedback lane

Equivalent behavior should preserve:

- `/feedback` existing as a local JSX command rather than a plain prompt expansion
- `/bug` being an alias for the same surface
- an optional argument pre-filling the initial report text
- availability being gated off for:
  - third-party provider builds such as Bedrock, Vertex, or Foundry
  - essential-traffic-only privacy posture
  - explicit env kill-switches
  - certain internal first-party builds that route feedback elsewhere
  - policy configurations that disallow product feedback

## `/feedback` is a staged capture and consent flow

Equivalent behavior should preserve:

- a multi-step dialog with:
  - freeform issue description
  - consent review
  - submitting state
  - completion state
- consent copy making it clear that the report includes more than the freeform text alone
- the submission payload collecting a normalized snapshot of the current session state, including:
  - the current conversation transcript
  - sanitized in-memory errors
  - the latest assistant request id when available
  - the latest API request metadata
  - subagent transcripts recovered from disk or background-task state
  - the raw JSONL transcript only when the file is small enough to read safely
- secret and token redaction running before upload and before GitHub-issue drafting
- failure preserving the user's typed report so retry is possible without re-entry

## `/feedback` uploads first, then offers GitHub drafting

Equivalent behavior should preserve:

- first attempting a first-party authenticated feedback upload instead of jumping directly to GitHub
- refreshing auth before upload when needed
- successful upload returning a durable feedback id
- that feedback id being reused in later analytics and in any GitHub issue draft that the UI offers afterward
- only after successful upload offering Enter to open a prefilled GitHub issue draft in the browser
- custom-data-retention or ZDR-style server refusal surfacing a specific explanatory message instead of a generic network failure

## `/issue` and the positive-feedback lane are narrower build-specific surfaces

Equivalent behavior should preserve:

- the current clean-room evidence showing `/issue` and the positive-feedback counterpart as hidden inert stubs rather than usable public commands
- rebuilds not inventing detailed public behavior for those commands purely from their names
- the semantic split that is still visible around them:
  - `/issue` is the model-behavior or diagnostics-oriented escalation path
  - the positive-feedback counterpart is reserved for narrower builds
- `/issue` being treated as distinct from general product feedback or broad product bugs, even when the concrete UI implementation is absent in this snapshot
- `/issue` likely carrying a richer diagnostics posture than `/feedback`, because surrounding tooling explicitly preserves extra per-request traces for issue-style debugging

## Survey escalation reserves auto-run behavior, but the external build keeps it disabled

Equivalent behavior should preserve:

- the session survey wrapper only considering auto-run escalation for a bad response when transcript-share escalation did not already take over
- auto-run state being represented explicitly in REPL state instead of being hidden inside the survey hook
- an auto-run notification surface that:
  - appears above the ordinary survey stack
  - launches the target command automatically once on mount
  - supports Escape cancellation
- suppressing the ordinary "tell us more" follow-up affordance for that survey cycle once auto-run has been armed
- the external build still returning false for both bad and good auto-run reasons, so no automatic `/issue` or `/good-claude` launch actually occurs there
- the positive-feedback auto-run slot remaining reserved so future narrower builds can route good-survey escalation somewhere other than `/issue`

## Proactive `/issue` nudges are a separate extension point

Equivalent behavior should preserve:

- issue-style nudges being able to appear from frustration detection or banner logic without collapsing them into the ordinary `/feedback` survey path
- the external build compiling that banner path away even though the surrounding hooks and command references still reveal the intended contract

## Failure modes

- **surface flattening**: `/feedback`, `/issue`, and the positive-feedback lane are treated as one generic report flow with no distinction between product feedback and model-behavior diagnostics
- **public overclaim**: the rebuild invents a concrete `/issue` or positive-feedback body that is not actually visible in the clean-room snapshot
- **report undercapture**: `/feedback` collects only freeform text and drops transcript, subagent, or request context that the product relies on for debugging
- **auto-run surprise**: the external build starts auto-launching `/issue` even though the observed snapshot keeps that path wired but disabled
- **retention mismatch**: ZDR or custom-retention refusal is treated like an ordinary transient network error instead of a policy-specific block
