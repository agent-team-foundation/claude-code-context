---
title: "Test Framework Overview"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-environment-fixtures-and-ci-fail-closed-policy.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-seams-reset-hooks-and-injected-dependencies.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/native-test-derived-asset-provenance-and-acceptance-rules.md
  - /platform-services/mock-rate-limit-scenarios-and-test-contracts.md
  - /tools-and-permissions/filesystem-and-shell/sed-command-validation-contracts.md
  - /tools-and-permissions/permissions/yolo-classifier-contracts.md
  - /platform-services/settings-schema-compatibility-and-invalid-field-preservation.md
  - /integrations/mcp/federated-auth-conformance-and-idp-test-seeding.md
---

# Test Framework Overview

The current Claude Code snapshot does not expose one self-contained `tests/` or runner manifest that answers everything. What it does expose is a layered testing architecture that spans runtime posture, fixtures, dedicated end-to-end harnesses, conformance-sensitive auth flows, and domain-owned contract oracles.

## Confirmed layers

The snapshot clearly shows all of these verification layers:

- a script-wrapped suite entry layer, because at least one compatibility contract is tied to a named `npm run test:file ...` path rather than to a raw helper invocation
- ordinary module-level regression lanes, including `.test.ts`-style coverage
- integration lanes, including `.int.test.ts` behavior for cross-component runtime state
- end-to-end coverage for permission prompts and remote-control plumbing
- conformance-sensitive auth coverage for federated MCP and XAA-style flows
- runtime test posture via `NODE_ENV=test`
- fixture and VCR-style replay for API-dependent scenarios
- module-state isolation through exported reset, seed, and cleanup helpers for caches, watchers, registries, and other sticky services
- domain-owned contract assets derived from upstream-native tests

## Stable tier model

A faithful rebuild should preserve these tiers as distinct concerns:

- fast unit and regression feedback
- integration tests for service sequencing, settings state, and resume-sensitive runtime interactions
- end-to-end coverage for transport, auth proxy, permission UI, and remote-local handoff
- conformance coverage where wire-level or provider-level expectations matter
- compatibility tests for durable public file formats such as settings

Collapsing all of those into one broad suite would lose one of the main architectural signals in the current product: different behaviors are protected by different oracles.

## Runner boundary

The tree can safely claim:

- there is a script-oriented entry layer
- the product code is written to coexist with a Bun-flavored module-mocking environment
- the visible framework depends on more than a generic "run tests" command

The tree should not overclaim:

- the exact full upstream runner manifest
- the complete CI orchestration or sharding plan
- the full top-level command matrix for every lane

Those details remain partially hidden in this snapshot and are tracked separately in [evidence-levels-and-missing-artifacts.md](evidence-levels-and-missing-artifacts.md).

## Reconstruction rule

Equivalent implementations should preserve the verification architecture itself:

- separate tiers with different speed and realism tradeoffs
- deterministic test posture rather than production side effects leaking into automated runs
- fixture-backed replay where live external dependencies would otherwise make tests flaky
- narrow seams for stateful or transport-sensitive code
- reliable reset and teardown for singleton or watcher state that would otherwise bleed across lanes
- domain-owned acceptance oracles for nuanced behavior contracts

## Failure modes

- **tier collapse**: all behaviors are tested through one slow or one shallow lane
- **runner overclaim**: the rebuild hardcodes unconfirmed upstream runner plumbing as if it were observed fact
- **fixture blindness**: API-dependent flows lose deterministic replay and become network-coupled
- **state bleed**: caches, timers, registries, or persistent singleton state leak across tests and make failures order-dependent
- **oracle drift**: domain-specific edge-case contracts stop being represented after the broad framework is documented
