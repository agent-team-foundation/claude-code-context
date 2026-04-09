---
title: "Test Lane Coverage Map"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-framework-overview.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/e2e-harness-reality-boundaries.md
  - /platform-services/settings-schema-compatibility-and-invalid-field-preservation.md
  - /platform-services/settings-change-detection-and-runtime-reload.md
  - /ui-and-experience/transcript-and-history/transcript-search-and-less-style-navigation.md
  - /runtime-orchestration/sessions/session-artifacts-and-sharing.md
  - /tools-and-permissions/permissions/e2e-permission-testing-contracts.md
  - /integrations/clients/ssh-remote-session-and-auth-proxy.md
  - /integrations/mcp/federated-auth-conformance-and-idp-test-seeding.md
---

# Test Lane Coverage Map

The current snapshot does not expose a full runner manifest, but it does show that Claude Code protects different behavior families with different verification lanes. A clean-room rebuild should preserve that mapping even if the exact filenames, commands, or CI layout differ.

## Fast regression and unit-like lanes

The visible fast lanes protect narrow, local contracts such as:

- parser and serializer edge cases
- shell and permission safety heuristics
- transcript-search render-fidelity boundaries, where the index must track visible transcript text closely enough to avoid phantom hits
- sticky singleton cleanup and helper-state reset behavior

These lanes should stay cheap, isolated, and able to run without the full product startup graph.

## Integration lanes

The visible integration-oriented lanes protect cross-component runtime behavior such as:

- startup sequencing and async service readiness
- managed settings cache visibility, including first-visibility invalidation of stale merged settings in headless or early-read paths
- watcher and promise state that can be poisoned by one subsystem and observed by another
- resume-sensitive session artifacts and related persistence boundaries

These lanes need more real runtime wiring than a pure regression test, but they still stop short of a full user-facing end-to-end environment.

## End-to-end harness lanes

The visible end-to-end lanes protect workflows where the real orchestration path matters, including:

- permission prompt routing and user decision flow
- worker or remote approval forwarding
- SSH or remote-control plumbing where local UI and remote execution are split
- auth-proxy and transcript-adaptation behavior that spans transport boundaries

These lanes matter because mock-only verification would miss the very orchestration contracts users experience.

## Conformance lanes

The visible conformance-sensitive lanes protect interoperability contracts where a server, provider, or standard expects one particular wire behavior.

The clearest current example is federated MCP auth, where token-exchange method, credential reuse, and seeded test credentials must still match the real downstream exchange path.

## Compatibility lanes

The visible compatibility lanes protect durable public formats rather than transient runtime internals.

The clearest current example is settings evolution, where additive schema change, invalid-field preservation, and backward compatibility must remain guarded even as the runtime evolves.

## Reconstruction rule

A faithful rebuild should preserve:

- different lane families for different risk profiles
- the mapping from lane family to subsystem contract
- stronger realism for approval, transport, and provider-sensitive flows than for narrow parser or serializer regressions

It does not need to preserve the exact upstream command names when those were not directly visible in the source snapshot.

## Evidence boundary

The lane purposes above are more certain than the hidden runner inventory.

The tree can safely describe what kinds of behavior each lane family protects. It should be more careful when claiming the exact top-level command matrix, exhaustive test file layout, or CI sharding strategy.
