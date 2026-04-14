---
title: "Minimal End-to-End Verification Chain"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/verification-and-acceptance-strategy.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/parity-capability-matrix.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/real-cli-e2e-scenario-corpus.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/released-cli-e2e-test-set.md
  - /integrations/clients/structured-io-and-headless-session-loop.md
  - /runtime-orchestration/sessions/resume-path.md
  - /tools-and-permissions/permissions/e2e-permission-testing-contracts.md
---

# Minimal End-to-End Verification Chain

The tree already had scenario corpora, acceptance strategy, and capability bands. What it still needed was a small, repeatable answer to a more operational question: **what is the shortest serious end-to-end chain a rewrite must clear before broader parity work is even worth discussing?**

This leaf defines that chain.

## Scope boundary

This leaf covers:

- the minimum stage order for an end-to-end parity lane
- which stages are hard gates versus later expansion
- what evidence each stage must leave behind

It intentionally does not re-document:

- the full capability inventory already captured in [parity-capability-matrix.md](parity-capability-matrix.md)
- the detailed scenario descriptions already captured in [real-cli-e2e-scenario-corpus.md](real-cli-e2e-scenario-corpus.md)
- every released-binary nuance already captured in [released-cli-e2e-test-set.md](released-cli-e2e-test-set.md)

## Why a chain matters

Without a fixed chain, parity work tends to drift into one of two bad patterns:

- broad prose coverage with no proof that the rewrite survives real command sequences
- isolated demo wins, such as one `-p` prompt or one plugin flow, with no assurance that adjacent stateful surfaces still work together

The chain fixes that by forcing the rewrite to clear the cheapest foundational checks first and only then advance to more stateful or more target-sensitive lanes.

## Required stage order

Equivalent behavior should preserve this stage order for serious parity work.

### Stage 0. Baseline process viability

Prove that the rebuild can:

- start in the target workspace posture
- answer one trivial headless prompt
- report help and version without crashing

Minimum evidence:

- one plain-text headless pass
- one machine-readable envelope pass when the surface supports it
- recorded command lines and exit behavior

No-go rule:

- if this stage is unstable, do not claim parity for any higher surface

### Stage 1. Structured I/O and protocol envelope

Prove that the rebuild can:

- emit JSON or structured output correctly
- enforce schema output when requested
- stream typed lifecycle events where the target surface requires them

Minimum evidence:

- deterministic protocol assertions
- one side-by-side comparison against a real Claude Code client for the chosen target line

No-go rule:

- do not treat plain `-p` success as proof that SDK- or automation-facing parity exists

### Stage 2. State-path round-trip

Prove that the rebuild can:

- persist session or config state
- read that state back correctly in a later invocation
- keep stdout behavior and on-disk behavior aligned

Minimum evidence:

- one command that writes state
- one later command that reads or resumes from that state
- explicit file-path or artifact confirmation

No-go rule:

- if state round-trip is missing, continuation, resume, plugin, and MCP claims remain provisional

### Stage 3. Tool and permission reality

Prove that the rebuild can:

- perform at least one real tool-backed workspace action
- narrow or disable tools correctly
- surface approval flow through the real permission path when required

Minimum evidence:

- one positive real-file or shell action
- one negative or denied capability case
- one approval-focused end-to-end case when the target includes approval UX

No-go rule:

- do not accept pseudo-tool narration as parity for real tool execution

### Stage 4. Resume and continuation

Prove that the rebuild can:

- continue the latest session in the correct workspace scope
- resume a named session
- preserve the working context needed by the next turn

Minimum evidence:

- latest-session continuation
- explicit session-ID resume
- one branch or fork-style continuation where supported

No-go rule:

- transcript existence alone is not enough; the resumed turn must behave as if the prior context is actually live

### Stage 5. Extension envelope

Prove that the rebuild can:

- load or manage at least one MCP or plugin-like extension path
- reflect the resulting capability change in the live session
- persist and later rediscover the related configuration state

Minimum evidence:

- one add/install flow
- one live-session effect
- one later list/status confirmation

No-go rule:

- config-only success without runtime effect does not clear this stage

### Stage 6. Interactive coding turn

Prove that the rebuild can execute one real coding loop end to end:

- inspect workspace state
- hit a real failure or task condition
- propose or apply a change
- verify the result
- summarize the outcome coherently

Minimum evidence:

- one trusted interactive workspace run
- transcript or state artifact confirming the turn shape
- one comparison against a real Claude Code interactive flow for the same class of task

No-go rule:

- passing headless smoke tests is not enough to claim interactive coding parity

### Stage 7. Maintenance and diagnostics

Prove that the rebuild can:

- report health or diagnostics
- expose install or update posture where that is part of the target
- fail cleanly in unsupported contexts such as non-TTY operational surfaces

Minimum evidence:

- one `doctor`-style or equivalent operational lane
- one install/update/status comparison when the target includes those surfaces

No-go rule:

- parity claims that ignore maintenance surfaces are incomplete for released-CLI targets

## Expansion stages

After the minimum chain, target-specific work can add:

- remote or SSH lanes
- bridge or companion lanes
- agent/team orchestration lanes
- voice or other specialized surface lanes

Those stages are still required for a full-scope parity claim when the chosen target includes them. They are simply not the shortest convincing chain.

## Artifact rule

Every chain run should leave behind:

- the exact commands or interactions used
- the target line and runtime posture
- pass/fail results per stage
- the first failing stage, if any
- any known divergence that still allows a conditional milestone label

If that artifact is missing, the chain was not reviewable.

## Relationship to the capability matrix

Use the two leaves together:

- the [parity capability matrix](parity-capability-matrix.md) says which capability families are parity-critical
- this chain says what the minimum proof ladder looks like when you start exercising those families end to end

The matrix prevents scope amnesia. The chain prevents unordered or cherry-picked validation.

## Failure modes

- **demo-only parity**: a rewrite clears one impressive scenario but never proves the lower stateful stages that make the scenario trustworthy
- **order inversion**: remote, plugin, or UI polish work advances while session, protocol, or state round-trip fundamentals still fail
- **artifactless confidence**: people remember that "we tested it" but cannot show which stage actually passed
- **late-surface blind spot**: maintenance or interactive coding lanes are skipped, so the rebuild looks fine in scripts but fails in real operator use
