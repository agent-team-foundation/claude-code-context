---
title: "Command Surface"
owners: []
soft_links: [/integrations, /platform-services/auth-config-and-policy.md, /collaboration-and-agents/bridge-session-state-projection-and-command-narrowing.md]
---

# Command Surface

Claude Code should not be reconstructed as one flat user-visible command list. The product keeps a composed command record set for the current environment, but each surface projects a different subset, name form, and metadata bundle. A faithful rebuild needs those projections to stay distinct across `/help`, `/skills`, bootstrap payloads, SDK control responses, and narrowed remote or bridge clients.

## Scope boundary

This leaf covers:

- how the admitted command and skill record set is projected into human-facing and machine-readable inventories
- which records are hidden, deduplicated, reformatted, or narrowed before a surface exposes them
- how help, skill browsing, SDK bootstrap payloads, and bridge-safe inventories diverge from one another

It intentionally does not re-document:

- command loading order, precedence, and lookup rules already covered in [command-dispatch-and-composition.md](command-dispatch-and-composition.md)
- execution semantics for specific command families already covered in the more specific command leaves in this domain
- bridge-specific narrowing and remote-safe overlays already covered in [../collaboration-and-agents/bridge-session-state-projection-and-command-narrowing.md](../collaboration-and-agents/bridge-session-state-projection-and-command-narrowing.md)

## Presentation starts after admission

Equivalent behavior should preserve:

- provider, auth, policy, and feature gates deciding whether a command is admitted to the local catalog before any inventory is rendered
- presentation surfaces showing only the command set that is currently available in this environment, not the product's theoretical full capability set
- remote or bridge clients applying additional narrowing after that admission step instead of inventing a separate command-definition system

## Local inventories are not interchangeable

Equivalent behavior should preserve:

- `/help` opening a local UI surface instead of starting a model turn
- the help dialog separating visible entries into default commands and custom commands
- hidden commands staying out of help, and build-specific internal entries staying out of ordinary external help
- same-named custom commands being deduplicated by internal slash name before rendering, so overlapping scopes do not create repeated help rows
- each visible help list being sorted alphabetically by slash name rather than by load order
- help rows using raw slash names plus source-aware descriptions, so origin cues survive without exposing implementation layout
- `/skills` being a separate local UI surface over prompt-backed skills rather than another tab in help
- `/skills` grouping skills by source family and using a skill-centric row format instead of the help description list
- `/skills` not being treated as the user-invocable slash-command list; it is a source-grouped skill view, so its inclusion rules can differ from ordinary slash discoverability

## Machine-readable projections differ by client contract

Equivalent behavior should preserve:

- `system/init` exporting slash commands and skills as separate arrays instead of one mixed inventory
- the `slash_commands` array being a narrow name-only projection for user-invocable slash commands, while `skills` is its own separate name-only projection
- those name-only init arrays preserving the command record's slash token rather than the richer display formatting used in some local client pickers
- SDK initialize and plugin-reload control responses exporting richer command objects for client pickers, including user-visible name, source-aware description, and argument hint
- those richer SDK control responses being based on the local catalog state rather than assuming the same merged view as every live session
- bridge `system/init` being narrower still: only bridge-safe slash commands should be advertised, and local tool, plugin, or MCP wiring should stay redacted from companion clients

## Live session surfaces can merge later overlays

Equivalent behavior should preserve:

- active session execution surfaces being able to append live MCP-provided commands after the local catalog has already been assembled
- that MCP merge happening as a late session overlay, with exact-name deduplication where needed, rather than rewriting the local catalog contract
- inventories tied to local configuration refresh, such as plugin-reload responses, not being mistaken for the full live session command set

## Naming and discoverability are surface-specific

Equivalent behavior should preserve:

- one command record potentially having different name forms across surfaces: raw slash token in help or init-style lists, richer display name in some SDK picker payloads, and alias or display-name matching in command resolution
- `user-invocable: false` removing entries from slash-command inventories even if the underlying skill remains model-usable
- skill discoverability, slash-command discoverability, and command resolution staying modeled as separate concerns rather than one universal visibility flag
- source-aware descriptions being attached only where the surface actually renders descriptions; compact bootstrap arrays should stay lean

## Failure modes

- **one-list fallacy**: rebuilds reuse one universal inventory for help, skills, init, SDK control, and bridge clients
- **name-form drift**: local help, SDK pickers, and init payloads disagree about which slash token or display name they serialize
- **skill/slash conflation**: skill browsing is treated as just another slash-command tab, erasing its separate grouping and export contract
- **overlay amnesia**: MCP commands are either baked permanently into the local catalog or omitted from live session surfaces that should receive them
- **bridge overshare**: companion clients learn about local-only commands or local integration wiring that the bridge runtime would later block
