---
title: "Command Dispatch and Composition"
owners: []
soft_links: [/runtime-orchestration/turn-assembly-and-recovery.md, /runtime-orchestration/workflow-script-runtime.md, /integrations/plugins/skill-loading-contract.md, /integrations/clients/sdk-control-protocol.md]
---

# Command Dispatch and Composition

Claude Code's command surface is not a static slash-command list. It is a composed registry that merges multiple command sources into one user-visible surface and then filters that surface per session.

## Command kinds

The runtime needs three distinct command behaviors:

- **prompt commands** that expand into model-visible instructions and then re-enter the ordinary turn loop
- **local commands** that run local logic and return text, compact actions, or no visible output
- **interactive local UI commands** that open dialogs or other rich terminal flows before optionally feeding results back into the shared session

This split matters because many user actions look like "commands" but do not all enter the runtime the same way.

## Registry composition

One command registry should assemble commands from several layers:

- built-in commands shipped with the product
- bundled skills that behave like command-shaped prompt expansions
- built-in plugin commands and skills
- project or user skill directories
- installable plugin commands
- workflow-backed commands discovered from dedicated workflow definitions and inserted into the same catalog
- dynamic skills discovered only after the runtime touches relevant files or context

A correct rebuild should load these sources into one catalog rather than making users think in separate extension silos.

## Filtering and reshaping

The visible command set is narrower than the full catalog.

Important filtering steps:

- command-source loading may be memoized because disk and plugin discovery are expensive
- availability checks must run on each refresh so login, provider, or entitlement changes take effect immediately
- feature gates and environment checks can disable commands without deleting the underlying runtime path
- some commands are hidden from typeahead or model invocation even if they exist
- dynamic skills should be inserted into the catalog in a stable position instead of appended arbitrarily
- remote or constrained surfaces may remove commands that assume a local terminal or a different execution substrate

The architectural principle is that command visibility is a runtime decision, not a compile-once list.

## Composition rules

Commands should describe how they plug into the runtime instead of re-implementing runtime behavior.

Useful command metadata includes:

- a stable command name and aliases
- whether the command is user-invocable, model-invocable, or hidden
- whether it should execute immediately or wait for a safe stop point
- any narrowed tool set, model preference, or context mode it needs
- whether heavy logic should be lazy-loaded only on invocation

This lets the product grow without turning the command layer into a second orchestration system.

## Failure modes

- **catalog drift**: plugin, skill, and built-in sources disagree on naming or precedence
- **stale availability**: auth or entitlement changes happen, but the command list does not refresh
- **surface mismatch**: a command appears on a surface that cannot satisfy its UI or execution assumptions
- **extension hard-failure**: one plugin or skill load error takes down the entire command catalog instead of degrading locally
- **queue bypass confusion**: immediate and queued commands are mixed without clear ordering guarantees
