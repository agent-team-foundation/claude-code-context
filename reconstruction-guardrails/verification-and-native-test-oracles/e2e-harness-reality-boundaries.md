---
title: "E2E Harness Reality Boundaries"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-lane-coverage-map.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-seams-reset-hooks-and-injected-dependencies.md
  - /tools-and-permissions/permissions/e2e-permission-testing-contracts.md
  - /ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md
  - /integrations/clients/ssh-remote-session-and-auth-proxy.md
  - /integrations/mcp/federated-auth-conformance-and-idp-test-seeding.md
  - /runtime-orchestration/sessions/session-artifacts-and-sharing.md
---

# E2E Harness Reality Boundaries

The observed Claude Code snapshot uses several harnesses that shorten setup cost without abandoning the real runtime path. That distinction matters: a clean-room rebuild should preserve which parts of end-to-end verification are allowed to be synthetic and which parts still need to exercise production-like orchestration.

## Approval harnesses must still use the real permission path

Equivalent behavior should preserve:

- a narrow approval-oriented harness that can force the permission flow to appear on demand
- that harness still entering through the normal tool catalog, permission-decision pipeline, and permission-prompt shell
- grant, deny, cancel, queue-advance, and worker-forwarding behavior being validated through the same UI and callback machinery users actually see

An e2e approval test that injects dialog state directly is no longer testing the product contract that matters.

## Remote transport harnesses may skip deployment, not orchestration

Equivalent behavior should preserve:

- a local harness mode that can avoid real SSH deployment when the test only needs to verify split local-UI and remote-execution plumbing
- the auth proxy, transcript adaptation, permission relay, and session-lifecycle machinery still being exercised
- failures and reconnect behavior still traveling through the real remote-session contract rather than a fake one-shot shell wrapper

The shortcut is allowed to reduce environment setup. It is not allowed to erase the transport boundary being tested.

## Federated-auth harnesses may skip browser setup, not credential semantics

Equivalent behavior should preserve:

- a deterministic way to seed federated credentials when a mock identity provider does not expose the full interactive browser surface
- seeded credentials landing in the same secure cache slot the ordinary login and refresh paths later read
- downstream exchange, refresh, and revocation behavior still using the normal federated auth path

Otherwise the test stops proving interoperability and starts proving only that a bypass slot was written successfully.

## Session-state harnesses may seed artifacts, not invent a separate resume model

Equivalent behavior should preserve:

- targeted setters or seed helpers for session artifact state when bootstrapping a full prior session would be too expensive
- those helpers still feeding the same transcript, artifact, and resume semantics production uses
- test convenience never becoming a second, incompatible persistence model

## Failure modes

- **fake dialog coverage**: permission tests manipulate UI state directly and stop covering the real approval pipeline
- **transport collapse**: a local remote-session harness stops exercising proxying, relay, or transcript adaptation
- **credential bypass**: federated auth tests seed a token into a cache path the real login flow never reads
- **shadow persistence**: test setters create a second resume model unrelated to the live session artifact system
