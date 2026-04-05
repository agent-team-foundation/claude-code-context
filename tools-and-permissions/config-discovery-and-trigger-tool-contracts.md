---
title: "Config Discovery and Trigger Tool Contracts"
owners: []
soft_links: [/tools-and-permissions/control-plane-tools.md, /platform-services/settings-change-detection-and-runtime-reload.md, /tools-and-permissions/path-and-filesystem-safety.md]
---

# Config Discovery and Trigger Tool Contracts

Claude Code exposes several user- or model-facing control surfaces whose main job is to inspect or mutate runtime configuration. These surfaces are reconstruction-critical because they define which settings are safe to read, which writes need confirmation, and which admin actions are policy-gated. Local scheduling and remote trigger management are related control-plane families, but they have their own dedicated contracts in [local-scheduled-prompt-tool-contracts.md](local-scheduled-prompt-tool-contracts.md) and [remote-trigger-control-tool-contracts.md](remote-trigger-control-tool-contracts.md).

## Configuration tool contract

Equivalent config-tool behavior should preserve:

- a registry of supported settings rather than arbitrary key-path mutation
- read operations that are treated as read-only discovery
- write operations that request explicit approval
- runtime gating for settings whose existence should disappear when the feature is unavailable
- type coercion and option validation before persistence
- asynchronous validation for settings that depend on live provider or environment checks
- writes to the correct backing store, with nested-object updates for settings files and separate handling for global config

This keeps config discovery safe while still allowing narrow model-driven runtime control.

## Immediate runtime synchronization

Some config writes must take effect immediately rather than waiting for restart.

A faithful rebuild should preserve:

- app-state synchronization for settings that directly affect live UI or bridge behavior
- targeted cache invalidation or change-notification paths for settings that require post-write reload
- support for "reset to default" behavior by deleting an override rather than writing a literal default value

The important contract is that persistence and live runtime state stay aligned.

## Permission-rule browser and retry surface

Equivalent behavior should also include a read-mostly permission-management surface that:

- opens the current permission rules in an interactive browser
- can turn previously denied commands into explicit retry messages

This is not just a static viewer; it is a bridge from past denials back into the active conversation.

## Sandbox admin surface

The sandbox-management command surface should preserve early gating before any mutation:

- unsupported platform refusal
- policy-disabled platform refusal
- higher-priority policy lock refusal
- dependency-check reporting before interactive configuration

When mutation is allowed, equivalent behavior should support at least a narrow persisted exclusion path for commands that must bypass sandbox wrapping.

## Failure modes

- **unsupported-setting leak**: hidden or disabled features still expose writable config keys
- **write-without-reload**: persisted config changes do not update the live runtime
- **unsafe sandbox mutation**: users can change local sandbox behavior despite policy lock
- **retry dead-end**: denied permission history is visible but cannot be promoted back into a fresh attempt
