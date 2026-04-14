---
title: "Shared Test Preload and Shard Isolation"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-framework-overview.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-seams-reset-hooks-and-injected-dependencies.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-runtime-mode-and-determinism.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/evidence-levels-and-missing-artifacts.md
  - /platform-services/settings-change-detection-and-runtime-reload.md
  - /tools-and-permissions/permissions/e2e-permission-testing-contracts.md
native_source: test/preload.ts
verification_status: native_test_derived
---

# Shared Test Preload and Shard Isolation

The current Claude Code snapshot does not behave like every test gets a fresh process. Multiple comments and exported reset hooks show a different contract: a shared preload layer resets sticky runtime state between same-process tests and across shards, so the suite can stay fast without quietly letting one case poison the next.

## Scope boundary

This leaf covers:

- the role of the shared `test/preload.ts` layer
- what kinds of process-local state it must neutralize between tests
- how shard-sensitive and Windows-sensitive failure modes shape the testing contract

It intentionally does not re-document:

- every resettable seam family already summarized in [test-seams-reset-hooks-and-injected-dependencies.md](test-seams-reset-hooks-and-injected-dependencies.md)
- the full hidden contents of `test/preload.ts`, which the current snapshot still does not expose directly
- runner manifests or CI workflow wiring beyond what the visible source anchors prove

## One shared preload layer is part of the framework contract

Equivalent behavior should preserve:

- one shared preload or before-each reset layer for same-process test execution
- that preload clearing sticky state through product-owned reset hooks instead of relying only on whole-process restarts
- shard isolation being treated as a first-class requirement, not a lucky side effect

The important product signal is that Claude Code expects multiple tests in one process to be normal, and therefore invests in explicit reset machinery.

## The preload layer must clear product caches, not just mocks

Visible source anchors show the preload contract reaching real product caches and registries, including:

- bootstrap or app-wide state that exposes dedicated test-only reset entrypoints
- plugin command, agent, hook, output-style, and prompt caches
- registered hook state that would otherwise survive into later cases
- memoized path- or working-directory-resolution helpers that are exported specifically for shard-isolation cache clearing
- sticky attachment or skill-sending state that would otherwise make later cases depend on earlier history

Equivalent behavior should preserve a preload that clears product reality, not just one mocking framework's local spies.

## Reset hooks must stay test-gated

Equivalent behavior should preserve:

- reset hooks being callable only in test posture when they would be unsafe or misleading in production
- clear separation between "public runtime API" and "test-only reset path"
- explicit naming that signals testing intent when a helper exists only to repair process-local state between cases

This matters because the observed source treats reset hooks as framework tools, not as public recovery commands.

## Plugin and hook isolation has special rules

The visible source does not treat plugin-hook reset as a naive wipe-everything path.

Equivalent behavior should preserve:

- cache invalidation staying distinct from the live registered-hook set when immediate hook loss would change runtime behavior incorrectly
- prune-style cleanup for no-longer-enabled plugin hooks staying possible without prematurely erasing still-valid hooks
- the shared preload starting from a truly empty or reset hook state before later test-specific plugin loading occurs

The load-bearing rule is that test isolation must not accidentally change the production semantics the test is trying to verify.

## Shard-sensitive heavy modules need defensive handling

Visible source comments show that shard isolation is not only logical state cleanup. It also affects performance and timeout behavior.

Equivalent behavior should preserve:

- lazy loading of heavy modules when eager module evaluation would bloat the heap for every later test in the shard
- test-aware tuning or env overrides for platform-sensitive slow paths, especially Windows CI cases where repeated spawns or large lazy modules can push a shard into timeout territory
- platform-specific flakes being treated as framework issues, not only as one test's local problem

The important point is not one exact timeout value. It is that same-shard performance pressure is part of the observed test architecture.

## Windows and same-shard failures are part of the acceptance oracle

The visible source specifically anchors failures such as:

- later tests in the same Windows shard timing out after a heavy module was imported too early
- repeated PowerShell parse spawns on Windows CI exceeding the interactive-default timeout unless tests can override that limit

Equivalent behavior should preserve the idea that shard-local performance regressions are real correctness failures for the framework, not just CI noise to ignore.

## Relationship to higher-level seams

This leaf is narrower than the general seam docs:

- [test-seams-reset-hooks-and-injected-dependencies.md](test-seams-reset-hooks-and-injected-dependencies.md) explains why reset hooks and narrow seams exist at all
- this leaf explains the extra framework contract that one shared preload layer coordinates those resets to make same-process testing and sharding trustworthy

Both are needed. Without the seam doc, the preload feels incidental. Without this leaf, the seam doc does not explain how the framework actually keeps tests isolated at scale.

## Failure modes

- **same-process bleed**: one test leaves hooks, caches, settings overlays, or sent-skill markers behind and later tests inherit them
- **naive reset regression**: isolation wipes live hook state in a way that changes the behavior a test was meant to observe
- **path-cache contamination**: memoized working-directory or path-resolution helpers survive across tests and make permission or filesystem checks order-dependent
- **shard timeout spiral**: heavy modules load eagerly or slow-path defaults stay fixed, so later tests in the same shard start failing only under CI load
- **test-gate leak**: reset helpers intended only for `NODE_ENV=test` become callable from ordinary runtime paths
