---
title: "Command Surface"
owners: []
soft_links: [/integrations, /platform-services/auth-config-and-policy.md]
---

# Command Surface

Claude Code has one shared command catalog, but users do not see that catalog through one flat, identical list everywhere. A faithful rebuild needs the presentation contract around command discoverability to stay stable across local help, machine-readable init payloads, and narrowed remote or bridge inventories.

## Scope boundary

This leaf covers:

- how the shared command catalog is presented to humans and client surfaces
- which commands are hidden, deduplicated, or narrowed before a user-facing inventory is shown
- how built-in versus custom command inventories diverge in the help surface

It intentionally does not re-document:

- command loading order, precedence, and lookup rules already covered in [command-dispatch-and-composition.md](command-dispatch-and-composition.md)
- execution semantics for specific command families already covered in the more specific command leaves in this domain
- bridge-specific narrowing and remote-safe overlays already covered in [../collaboration-and-agents/bridge-session-state-projection-and-command-narrowing.md](../collaboration-and-agents/bridge-session-state-projection-and-command-narrowing.md)

## One registry feeds several inventories

Equivalent behavior should preserve:

- one assembled command catalog being the source for both interactive and machine-readable command inventories
- user-facing inventories treating command discoverability as a presentation layer over that shared catalog rather than each surface inventing its own command implementation tree
- some surfaces exposing command names only, while richer local surfaces also show descriptions and argument hints
- deeper command leaves owning behavior, while this leaf owns how those commands become browsable affordances

## The local help surface splits built-in and custom commands

Equivalent behavior should preserve:

- `/help` opening a local JSX inventory instead of starting a model turn
- the help dialog separating the visible command set into built-in commands and custom commands
- hidden commands staying out of those lists
- same-named custom commands being deduplicated by command name before rendering, so overlapping scopes do not create repeated rows in the help picker
- each visible list being sorted alphabetically by command name rather than by load order
- displayed descriptions using source-aware formatting so plugin, bundled, and other non-builtin origins can still be understood from the inventory row
- build-specific internal-only commands being excluded from the ordinary public help surface even if they exist in the underlying registry

## Machine-readable command inventories are narrower than the raw registry

Equivalent behavior should preserve:

- `system/init`-style and SDK control payloads exporting only user-invocable slash commands rather than every hidden or model-only entry in the raw command catalog
- those machine-readable inventories carrying enough metadata for clients to render command pickers without exposing the full local UI implementation
- command and skill inventories staying related but not identical, because skills can also be surfaced through separate skill-specific lists
- narrower remote or bridge surfaces further filtering those same inventories instead of redefining command existence from scratch

## Commands stay as affordances over deeper subsystems

Equivalent behavior should preserve:

- commands acting as discoverable entry points into deeper runtime, integration, and policy subsystems
- command inventories helping users find the right affordance without duplicating the entire subsystem architecture inside the command list
- rebuilds treating command presentation, command execution, and subsystem ownership as separate concerns so the tree stays clean as new command families appear

## Failure modes

- **help/runtime mismatch**: the help dialog advertises commands that the active surface later hides or blocks
- **catalog flattening**: every surface exposes the raw registry directly, leaking hidden or non-user-invocable commands
- **duplicate custom rows**: same-named commands from multiple scopes render multiple help entries instead of one browseable row
- **source-blind inventory**: plugin or bundled commands lose their origin cues in help and machine-readable inventories
