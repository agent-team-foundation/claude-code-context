---
title: "Remote Trigger Control Tool Contracts"
owners: []
soft_links: [/runtime-orchestration/remote-scheduled-agents-and-trigger-management.md, /tools-and-permissions/control-plane-tools.md, /platform-services/auth-config-and-policy.md]
---

# Remote Trigger Control Tool Contracts

Claude Code also exposes a separate control-plane tool for managing remote triggers. This is not the same subsystem as local cron scheduling: it is a policy-gated, organization-scoped remote API surface for listing, inspecting, creating, updating, and manually running cloud-side triggers.

## Remote trigger control is a backend-facing tool surface

Equivalent behavior should preserve:

- remote trigger management using authenticated remote APIs rather than local schedule files
- organization-scoped auth and policy gates being mandatory before the tool can act
- read-only verbs such as list and inspect being classified separately from mutating verbs such as create, update, and run
- stable trigger identifiers being required before inspect, update, or run operations can proceed

## Request and response boundary

Equivalent behavior should preserve:

- a narrow action enum for list, inspect, create, update, and run
- create and update passing a backend-owned request body shape rather than trying to normalize every trigger field into local tool-specific arguments
- responses preserving enough raw backend structure for higher-level orchestration or diagnostics instead of prematurely flattening every trigger into one local summary format
- timeouts and cancellation respecting the current tool-execution abort path

## Relationship to remote scheduled agents

Equivalent behavior should preserve:

- the tool acting as the control surface over cloud-side trigger records while the runtime separately models remote scheduled agents and their lifecycle
- manual `run` behavior remaining distinct from schedule creation, so a trigger can be fired on demand without redefining its schedule
- feature rollout and policy withdrawal being able to remove this surface entirely without affecting local scheduling tools

## Failure modes

- **local-remote flattening**: remote triggers are treated like local cron jobs and lose organization auth, policy, and backend ownership boundaries
- **schema overfitting**: the tool hardcodes one guessed trigger payload shape instead of passing through the backend-owned body contract
- **unsafe read/write blur**: list and inspect are permissioned like writes, or writes slip through a read-only classification path
- **fire-without-id**: update or manual-run operations can proceed without a stable trigger identifier
