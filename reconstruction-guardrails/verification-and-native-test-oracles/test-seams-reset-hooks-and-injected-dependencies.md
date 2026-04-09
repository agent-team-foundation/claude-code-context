---
title: "Test Seams, Reset Hooks, and Injected Dependencies"
owners: [bingran-you]
soft_links:
  - /tools-and-permissions/tool-catalog/tool-families.md
  - /tools-and-permissions/tool-catalog/tool-pool-assembly.md
  - /tools-and-permissions/permissions/permission-decision-pipeline.md
  - /ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md
  - /integrations/clients/ssh-remote-session-and-auth-proxy.md
  - /integrations/clients/structured-io-and-headless-session-loop.md
  - /integrations/mcp/federated-auth-conformance-and-idp-test-seeding.md
  - /platform-services/settings-change-detection-and-runtime-reload.md
  - /runtime-orchestration/sessions/session-artifacts-and-sharing.md
---

# Test Seams, Reset Hooks, and Injected Dependencies

The current Claude Code build does not rely only on coarse top-down black-box tests. It also exposes narrow, product-owned seams that make stateful or transport-sensitive behavior testable without turning the runtime into a generic debug shell.

## Seam families visible in the snapshot

The snapshot shows several recurring seam patterns:

- targeted dependency injection where module-spy boilerplate would otherwise be brittle or cyclic
- module-boundary indirection that keeps replacement, spying, or late binding viable across cyclic or feature-gated imports
- helper functions explicitly exported for testing, especially around parsing, serialization, cache placement, and runtime edge behavior
- reset or clear hooks for stateful services and caches
- admission-sensitive helper surfaces that only exist under test posture
- local harness modes that exercise real remote or auth plumbing without requiring the full external environment

## Why the seams matter

These seams are not random internal conveniences. They reveal the kinds of behavior the product itself considers hard to validate otherwise:

- permission prompts and approval surfaces
- auth-proxy or transport wiring
- stateful caches and watchers
- parser and serializer edge cases
- resume- and transcript-sensitive flows

## Import and module-boundary discipline is part of testability

Equivalent behavior should preserve:

- narrow dependency seams where a core flow would otherwise force repetitive per-module spying
- import structures that keep live bindings or late binding available when cycles, feature gates, or mock replacement would otherwise make tests brittle
- the ability to replace or observe one collaborator without changing the rest of the production topology

This is an architectural testing rule, not just a style preference. In the visible snapshot, import indirection and targeted DI are both used to keep real modules testable under modern ESM-style mocking constraints.

## Resettable singleton state is part of the seam contract

The source snapshot repeatedly exposes reset or seed helpers for long-lived runtime state. That is part of the test framework, not merely local cleanup style.

Equivalent behavior should preserve:

- explicit reset or teardown hooks for sticky services such as telemetry clients, settings watchers, session artifacts, registries, probe caches, and async startup promises
- awaitable cleanup where filesystem watchers, polling timers, or delayed work could otherwise outlive the test that created them
- the ability to seed controlled state through those hooks when the ordinary startup path would be too expensive, too flaky, or feature-gated away under the test runner
- reset boundaries that are narrow enough to isolate one subsystem without forcing a whole-process restart for every regression lane

Without this layer, the same product architecture becomes much harder to test deterministically because singleton state starts leaking across cases and shards.

## Production-like harnesses beat bypass-only fakes

The strongest seams in the snapshot still drive the real downstream contract instead of writing into a disposable mock-only side channel.

Equivalent behavior should preserve:

- approval-oriented harnesses that still surface the normal permission dialog and permission-decision pipeline
- transport-oriented harnesses that can exercise remote auth proxying and session plumbing without requiring a real remote host for every run
- federated-auth harnesses that can inject deterministic credentials into the same secure-storage slots the ordinary login and refresh paths later read
- resume- and transcript-oriented setters that operate on the same session artifact model and ingress plumbing production uses

This is the important distinction between a useful seam and a fake e2e shortcut: the seam shortens setup cost, but it should still validate the real runtime path on the other side.

## Feature-gated flows still need narrow test entrypoints

Some runtime capabilities are gated away in ordinary test posture or non-production builds. The visible framework compensates with small, purpose-built hooks rather than by widening those product features permanently.

Equivalent behavior should preserve:

- narrow helper entrypoints for feature-gated services whose normal boot path is unavailable under the test runner
- test access that restores just enough state to exercise the downstream behavior, rather than globally disabling capability gates everywhere
- a clear difference between test harness admission and end-user feature exposure

## Scope discipline

Equivalent behavior should preserve the discipline of the current seams:

- they should stay narrow and purpose-built
- they should still exercise the real runtime contract
- they should not become broad backdoors that bypass ordinary policy or orchestration logic

One visible example of this discipline is the difference between a test-only permission probe and an ordinary user-facing tool family. The former is a verification harness, not a product capability surface.

## Reconstruction rule

A clean-room rebuild should keep:

- some form of dependency seam for core flows that would otherwise require invasive module spying
- explicit reset hooks for sticky state
- at least one approval-oriented end-to-end harness
- at least one transport-oriented local harness for remote or federated flows
- harness entrypoints that reuse production storage, permission, and session channels instead of writing into bypass-only test slots

## Failure modes

- **black-box rigidity**: everything must be tested through the very top of the product, so failures become slow and hard to isolate
- **seam sprawl**: helper hooks grow into broad escape hatches that stop validating the real runtime
- **hidden state bleed**: caches, watchers, or registries persist across tests with no reliable reset path
- **gate blindness**: a rebuild turns off product gates globally in tests and stops exercising the real admission logic
- **fake e2e**: remote or approval flows are "tested" only through mocks and stop covering real orchestration
