---
title: "Test Framework Overview"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/verification-and-native-test-oracles/real-cli-e2e-scenario-corpus.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-runtime-mode-and-determinism.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-environment-fixtures-and-ci-fail-closed-policy.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-lane-coverage-map.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/e2e-harness-reality-boundaries.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-seams-reset-hooks-and-injected-dependencies.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/native-test-derived-asset-provenance-and-acceptance-rules.md
  - /platform-services/mock-rate-limit-scenarios-and-test-contracts.md
  - /tools-and-permissions/filesystem-and-shell/sed-command-validation-contracts.md
  - /tools-and-permissions/permissions/e2e-permission-testing-contracts.md
  - /tools-and-permissions/permissions/yolo-classifier-contracts.md
  - /platform-services/settings-schema-compatibility-and-invalid-field-preservation.md
  - /integrations/mcp/federated-auth-conformance-and-idp-test-seeding.md
---

# Test Framework Overview

The current Claude Code snapshot does not expose one self-contained `tests/` directory or runner manifest that answers everything. What it does expose is a layered testing architecture that spans runtime posture, fixtures, dedicated end-to-end harnesses, conformance-sensitive auth flows, and domain-owned contract oracles.

This domain also keeps a live-observed black-box oracle set in [real-cli-e2e-scenario-corpus.md](real-cli-e2e-scenario-corpus.md). That corpus complements the source-snapshot-derived framework view here by recording what a real working CLI actually does when exercised through its public entrypoints.

## Confirmed layers

The snapshot provides direct signals for all of these verification layer families, even though it does not expose every upstream runner entrypoint:

- a script-wrapped suite entry layer, because at least one compatibility contract is tied to a named `npm run test:file ...` path rather than to a raw helper invocation
- ordinary module-level regression lanes, including `.test.ts`-style coverage
- integration lanes, including `.int.test.ts` behavior for cross-component runtime state
- end-to-end coverage for permission prompts and remote-control plumbing
- conformance-sensitive auth coverage for federated MCP and XAA-style flows
- a supported test runtime posture via `NODE_ENV=test`
- fixture and VCR-style replay for API-dependent scenarios
- module-state isolation through exported reset, seed, and cleanup helpers for caches, watchers, registries, and other sticky services
- domain-owned contract assets derived from upstream-native tests

## Visible entry and layout anchors

Even without the hidden top-level manifest, the snapshot still exposes several concrete anchors for the test framework:

- a script-wrapped single-file compatibility path, which names `test/utils/settings/backward-compatibility.test.ts` directly
- a Bun-flavored test environment for at least part of the suite, because product-owned comments describe behavior under `bun test`
- a shared `test/preload.ts` setup layer that clears memoized hooks, plugin registries, and other sticky caches between tests that share one process or shard
- a visible mix of family naming conventions: `test/utils/...`, `.test.ts`, `.test.tsx`, `.int.test.ts`, and non-`test/utils` families such as daemon, shell, task, and registry-focused contracts

These anchors do not reveal the full upstream file tree, but they do prove that the framework is not one undifferentiated runner with ad hoc cases.

## Stable tier model

A faithful rebuild should preserve these tiers as distinct concerns:

- fast unit and regression feedback
- integration tests for service sequencing, settings state, and resume-sensitive runtime interactions
- end-to-end coverage for transport, auth proxy, permission UI, and remote-local handoff
- conformance coverage where wire-level or provider-level expectations matter
- compatibility tests for durable public file formats such as settings

Collapsing all of those into one broad suite would lose one of the main architectural signals in the current product: different behaviors are protected by different oracles.

The subsystem mapping behind those tiers is spelled out in [test-lane-coverage-map.md](test-lane-coverage-map.md).

## Runner boundary

The tree can safely claim:

- there is a script-oriented entry layer, including at least one single-file lane
- the product code is written to coexist with a Bun-flavored module-mocking environment
- the visible framework depends on more than a generic "run tests" command
- a shared preload or reset layer exists to clean module state between same-shard tests
- sharded execution exists, including at least one Windows-specific shard
- coverage output exists as a generated artifact, even though the exact coverage driver and thresholds remain hidden
- the end-to-end harnesses that are visible are designed to preserve real approval, transport, and credential paths rather than UI-only fakes

The tree should not overclaim:

- the exact full upstream runner manifest
- the exhaustive upstream lane inventory
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
