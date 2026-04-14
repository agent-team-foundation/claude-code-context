---
title: "Permissions"
owners: []
---

# Permissions

This subdomain captures how approval posture is loaded, transformed, and resolved across local, delegated, and remote tool execution.

Relevant leaves:

- **[permission-model.md](permission-model.md)** — Safety, sandboxing, and approval behavior.
- **[permission-mode-transitions-and-gates.md](permission-mode-transitions-and-gates.md)** — Startup precedence, centralized mode transitions, async auto-mode gates, and dangerous-rule stripping/restoration.
- **[permission-decision-pipeline.md](permission-decision-pipeline.md)** — The layered rule, mode, classifier, worker, and dialog flow behind each tool approval.
- **[permission-rule-loading-and-persistence.md](permission-rule-loading-and-persistence.md)** — How permission rules are loaded, normalized, stripped for auto mode, restored, and persisted.
- **[permission-resolution-races-and-forwarding.md](permission-resolution-races-and-forwarding.md)** — Single-winner ask-resolution races across dialog, bridge, mailbox, channel relay, hooks, classifier, and abort paths.
- **[sandbox-selection-and-bypass-guards.md](sandbox-selection-and-bypass-guards.md)** — How sandbox selection, excluded commands, policy-gated overrides, and Windows refusal paths interact.
- **[config-permission-and-sandbox-admin-surfaces.md](config-permission-and-sandbox-admin-surfaces.md)** — Registry-backed config mutation on eligible builds, plus permission browser, denied-command retry, and sandbox admin surfaces.
- **[yolo-classifier-contracts.md](yolo-classifier-contracts.md)** — Acceptance oracles for automatic-approval transcript shaping, fail-safe classifier verdicts, staged review, and environment-specific deny overlays.
- **[auto-mode-introspection-cli-surfaces.md](auto-mode-introspection-cli-surfaces.md)** — How version-sensitive `claude auto-mode defaults/config/critique` expose default rules, effective merged rules, and critique-only review without mutating live permission posture.
- **[e2e-permission-testing-contracts.md](e2e-permission-testing-contracts.md)** — How a test-only approval probe reuses the normal permission dialog path without widening the public tool surface.
