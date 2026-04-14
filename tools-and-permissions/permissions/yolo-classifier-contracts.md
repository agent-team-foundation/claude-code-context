---
title: "YOLO Classifier Contracts"
owners: [bingran-you]
soft_links: [/tools-and-permissions/permissions/permission-decision-pipeline.md, /tools-and-permissions/permissions/permission-model.md, /reconstruction-guardrails/verification-and-native-test-oracles/native-test-derived-asset-provenance-and-acceptance-rules.md]
native_source: utils/permissions/yoloClassifier.ts
native_ref: utils/permissions/yoloClassifier.ts#structured-verdict-contract
test_asset_origin: source_snapshot_derived
acceptance_rule: Keep the auto-approval classifier machine-readable, fail-safe, escalation-capable, and resistant to assistant self-justification.
verification_status: native_test_derived
---

# YOLO Classifier Contracts

This leaf captures the acceptance oracle for Claude Code's automatic-approval classifier. The clean-room value is not the exact schema tags or parser helpers upstream used. It is the shape of the classifier input, the fail-safe verdict rules, and the extra deny overlays that keep auto mode from widening into silent over-permission.

## Scope boundary

This leaf covers:

- how action history is shaped before classification
- how verdict extraction stays machine-readable and fail-safe
- how fast and escalated classifier passes relate to each other
- how environment-specific deny guidance extends the generic auto-mode policy

It intentionally does not cover:

- the full permission-decision pipeline
- the broader permission posture model
- shell-specific parser contracts already documented elsewhere

## Transcript shaping must resist classifier manipulation

Equivalent behavior should preserve:

- user requests and assistant tool intents being the important classifier context
- assistant narration or persuasive self-explanation not being treated as authoritative classifier input
- queued or deferred actions still being representable in the classifier transcript when they are the real thing about to execute
- tool-owned compact action serialization being preferred when available, so the classifier sees a stable intent summary instead of arbitrary UI text

This transcript-shaping rule is one of the main guardrails against the model talking itself into permission.

## Verdict extraction must be machine-readable and fail-safe

Equivalent behavior should preserve:

- a machine-readable allow or block verdict, not only free-form rationale
- the ability to discard non-binding reasoning when extracting the actual decision
- a brief reason channel that can explain why a decision blocked or escalated
- safety-first behavior when parsing, schema validation, transport, or inference fails

The important product contract is that failure never silently turns into approval.

## Fast pass and escalated pass can coexist

The visible snapshot suggests a staged auto-approval design rather than one monolithic classifier pass.

Equivalent behavior should preserve:

- a cheap first-pass classifier that can allow obviously safe actions quickly
- escalation to a richer second pass when the fast answer is "block", ambiguous, or unparsable
- the possibility of leaving the auto lane entirely and returning to manual review when the classifier transcript is too large or otherwise unsuitable for safe automation

The exact envelope syntax is implementation detail. The architectural rule is that ambiguous cases get more scrutiny, not more trust.

## Environment-specific deny overlays still matter

Equivalent behavior should preserve:

- the ability to append extra deny guidance for environments whose risk profile differs from generic shell auto mode
- specialized treatment for surfaces such as PowerShell where code loading, persistence, execution-policy weakening, or network-backed execution carry distinct risk categories
- those deny overlays remaining an extension of the same classifier system rather than a separate permission engine with unrelated semantics

## Reconstruction rule

A faithful rebuild should preserve:

- transcript shaping that prioritizes user intent and tool intent over assistant self-justification
- a structured, machine-readable decision channel with explicit allow or block semantics
- fail-safe behavior on parser, transport, or inference failure
- a staged path where fast answers are allowed to escalate rather than forced to decide every ambiguous case
- environment-specific deny overlays for shells or runtimes whose risk classes differ from the default

## Failure modes

- **self-persuasion leak**: assistant narration becomes classifier input and lets the model argue itself into approval
- **free-form verdict drift**: the runtime relies on prose parsing instead of a stable allow-or-block channel
- **fail-open classifier**: parser or transport failure silently becomes approval
- **single-pass overconfidence**: ambiguous or likely-block actions never escalate to the richer review path
- **overlay loss**: PowerShell or other high-risk environments lose their extra deny guidance and inherit an unsafe generic auto-mode policy

## Test Design

In the observed source, permission behavior is verified through decision-matrix regressions, prompt-routing integration coverage, and approval-focused end-to-end flows.

Equivalent coverage should prove:

- mode resolution, rule precedence, and fail-closed safety edges choose the expected permission outcome for each tool request
- prompt routing, forwarding, sandbox selection, and persisted rule loading behave correctly across foreground, worker, and remote-capable contexts
- visible ask, grant, deny, cancel, and queue-advance behavior still flows through the real permission shell rather than a test-only shortcut
