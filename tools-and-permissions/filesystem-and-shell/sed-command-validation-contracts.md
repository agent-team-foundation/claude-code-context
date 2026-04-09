---
title: "Sed Command Validation Contracts"
owners: [bingran-you]
soft_links: [/tools-and-permissions/filesystem-and-shell/shell-command-parsing-and-classifier-flow.md, /tools-and-permissions/permissions/permission-decision-pipeline.md, /reconstruction-guardrails/verification-and-native-test-oracles/native-test-derived-asset-provenance-and-acceptance-rules.md]
native_source: tools/BashTool/sedValidation.ts
verification_status: native_test_derived
---

# Sed Command Validation Contracts

This leaf captures the acceptance oracle for when `sed` can stay on a low-risk inspection or bounded rewrite path and when it must escalate to explicit approval. The clean-room value is the behavioral boundary, not the exact parser helpers or regexes upstream used.

## Scope boundary

This leaf covers:

- the safe `sed` shapes that can remain on an automatic path
- the high-risk shapes that must escalate
- the hardening rules that make tricky or ambiguous programs fail closed

It intentionally does not cover:

- the general shell parsing stack
- the broader permission-decision pipeline already covered elsewhere

## Read-oriented inspection can stay narrow

Equivalent behavior should preserve a narrow inspection path for `sed` commands that are clearly being used to read or print content rather than to mutate or execute anything.

That safe path should preserve:

- quiet line-printing programs whose purpose is to reveal selected lines
- simple addressed print selectors for targeted inspection
- file arguments when the command is still plainly inspection-only
- a boundary that stays narrow enough that complex `sed` programs do not accidentally inherit read-only trust

## Simple rewrite-to-stdout can stay distinct from persistence

The visible upstream oracle also distinguishes a limited rewrite path from full shell mutation.

Equivalent behavior should preserve:

- simple substitution-style rewrites whose output still goes to stdout rather than to the filesystem
- a stricter posture for in-place or file-targeted rewrites than for inspection-only use
- the ability for a separately authorized file-write posture to allow some rewrite flows without collapsing into "arbitrary `sed` is safe"

## Dangerous or ambiguous programs must fail closed

Equivalent behavior should preserve fail-closed escalation for programs that try to blur the boundary between safe text inspection and arbitrary shell mutation.

That escalation should include:

- commands that persist output to files or request in-place mutation
- commands that execute shell payloads or smuggle execution through rewrite flags
- addressed or compound forms that are harder to reason about safely than the narrow allow path
- tricky syntax such as non-ASCII lookalikes, multiline bodies, negation, step-addressing, brace-heavy grouping, or delimiter tricks that make the command harder to classify confidently

## Why this native oracle matters

The important upstream signal is not that `sed` has one parser helper or another. It is that Claude Code treats `sed` as a special case where:

- some clearly inspection-oriented usage is cheap enough to auto-allow
- some clearly bounded rewrite usage can stay narrower than full shell permission
- everything ambiguous or persistence-capable should fail closed

Without this oracle, a rebuild will usually be either too permissive or too annoying.

## Failure modes

- **inspection collapse**: harmless line-printing commands no longer fit through the low-risk path
- **rewrite overgrant**: in-place or file-writing programs inherit the same trust as stdout-only inspection
- **syntax blind spot**: tricky `sed` forms sneak past because the allow path only checks the happy case
- **parser overfitting**: the rebuild copies one implementation's helper functions but misses the behavioral safety boundary they were defending
