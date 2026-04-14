---
title: "Auto Mode Introspection CLI Surfaces"
owners: []
soft_links:
  - /tools-and-permissions/permissions/permission-mode-transitions-and-gates.md
  - /tools-and-permissions/permissions/permission-rule-loading-and-persistence.md
  - /tools-and-permissions/permissions/yolo-classifier-contracts.md
  - /platform-services/provider-model-mapping-and-capability-gates.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/released-cli-e2e-test-set.md
---

# Auto Mode Introspection CLI Surfaces

The analyzed source snapshot and reconstruction validation corpus expose a small top-level `claude auto-mode` namespace. It does not turn auto mode on, and it is not another permission prompt. It is a read-only diagnostic surface for understanding what the classifier would use: the published default rules, the currently effective merged rules, and an optional critique of custom overrides.

The local `claude 2.1.19` help output on this machine does not advertise `auto-mode`, so the safest clean-room claim is that this is a **version-sensitive public surface**, not a universal baseline command family.

## Scope boundary

This leaf covers:

- the read-only `claude auto-mode defaults`, `config`, and `critique` subcommands
- how those commands expose default classifier rules, effective merged rules, and critique behavior without mutating live permission state
- how custom-rule replacement semantics are reflected back to the user

It intentionally does not re-document:

- the deeper permission mode transition graph already covered in [permission-mode-transitions-and-gates.md](permission-mode-transitions-and-gates.md)
- the classifier acceptance oracle already covered in [yolo-classifier-contracts.md](yolo-classifier-contracts.md)
- the runtime approval pipeline that actually consumes auto mode during tool decisions

## This command family inspects auto mode; it does not activate it

Equivalent behavior should preserve:

- `claude auto-mode ...` staying separate from live mode-switch commands or startup permission flags
- these commands remaining safe, read-only inspection surfaces rather than hidden ways to widen tool permissions
- the command family disappearing entirely when the targeted build does not expose classifier introspection, instead of leaving dead stubs that promise behavior the runtime cannot fulfill

The reconstruction-critical distinction is that auto-mode introspection is about legibility of classifier policy, not changing the current approval posture.

## `defaults` exposes the published external baseline rules

Equivalent behavior should preserve:

- `claude auto-mode defaults` printing a machine-readable JSON payload
- that payload covering the main user-facing rule sections for the external classifier policy, including allow, soft-deny, and environment-oriented guidance
- the defaults command exposing the externally relevant baseline rather than leaking internal-only override layers that the ordinary user-facing classifier contract does not promise

## `config` exposes the effective merged rules with replace-by-section semantics

Equivalent behavior should preserve:

- `claude auto-mode config` printing JSON rather than human prose
- effective config reflecting user-supplied sections when present and falling back to defaults when a section is absent or empty
- section merging using replace-by-section semantics rather than concatenating user rules onto defaults blindly
- the output making it possible to see what the classifier would actually read without re-deriving precedence from several settings files by hand

The important clean-room point is that non-empty custom sections replace the corresponding default section; they do not merely append to it.

## `critique` is a side-query review surface over custom rules

Equivalent behavior should preserve:

- `claude auto-mode critique` acting only when the user actually has custom auto-mode rules
- an explicit empty-state response when no custom rules exist, including guidance to consult defaults for reference
- critique using the current main-loop model by default, with an optional model override
- the critique path reviewing custom rules in the context of the defaults they replace, not as isolated disconnected text snippets
- critique output focusing on clarity, completeness, conflicts, and actionability rather than pretending to be the classifier's final allow or block verdict
- critique failure surfacing as an explicit command error instead of silently falling back to invented advice

This preserves the user-facing promise: critique helps the operator improve custom rules, but it is not the auto-approval engine itself.

## Failure modes

- **surface conflation**: the command family is rebuilt as a hidden way to enter auto mode rather than to inspect it
- **append-only drift**: `config` merges user rules with defaults additively when the observed contract uses replace-by-section semantics
- **default leak**: `defaults` exposes internal-only policy layers or rollout-specific overrides instead of the ordinary external baseline
- **empty-state silence**: `critique` with no custom rules returns nothing useful and leaves the user without a next step
- **pseudo-classifier output**: critique is presented as if it were the actual approval verdict rather than advisory analysis of custom rules

## Test Design

In the observed source, this surface is exercised through packaged CLI checks and rule-shaping behavior that reuses the same classifier rule sources the runtime would later consume.

Equivalent coverage should prove:

- `defaults` and `config` return stable JSON shapes with the expected section semantics
- custom-section replacement versus default fallback behaves exactly as documented here
- `critique` produces the expected empty-state guidance when no custom rules exist and a bounded advisory response when they do
- command availability is version- or build-sensitive only where the product truly hides the surface, not because the rebuild forgot to wire it
