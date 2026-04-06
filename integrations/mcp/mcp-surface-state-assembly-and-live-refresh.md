---
title: "MCP Surface State Assembly and Live Refresh"
owners: []
soft_links: [/integrations/mcp/server-contract.md, /integrations/mcp/connection-and-recovery-contract.md, /integrations/plugins/skill-loading-contract.md, /product-surface/command-dispatch-and-composition.md, /tools-and-permissions/tool-catalog/tool-pool-assembly.md]
---

# MCP Surface State Assembly and Live Refresh

Connecting an MCP server is only the first half of the contract. Claude Code keeps a separate MCP session-state surface for connected clients, tools, commands, and resources, then merges that surface into commands and tools later. Rebuilding the product faithfully means preserving that state store, its per-server replacement rules, and its live-refresh behavior, rather than treating MCP as a one-shot "connect and append some tools" step.

## Scope boundary

This leaf covers:

- the MCP-specific session-state partitions for clients, tools, commands, and resources
- how one connected server populates and replaces its own slices of that state
- how prompts, skills, and resources differ even though some are all stored under `mcp.commands`
- how `list_changed` notifications refresh live state and invalidate caches
- how stale plugin-backed MCP servers are removed and reconnected safely

It intentionally does not re-document:

- config layering, trust, and approval rules already covered in [config-layering-policy-and-dedup.md](config-layering-policy-and-dedup.md)
- transport classes and session-expiry recovery already covered in [connection-and-recovery-contract.md](connection-and-recovery-contract.md)
- the broader skill-loading model already covered in [../plugins/skill-loading-contract.md](../plugins/skill-loading-contract.md)

## MCP state is stored as a separate session surface

Equivalent behavior should preserve one MCP-specific session partition containing:

- connected or pending or failed or disabled client records
- MCP tools
- MCP commands
- MCP resources keyed by server name
- a reconnect trigger that lets plugin reloads force MCP effects to rerun without pretending the session itself restarted

This state is not the same thing as the local command registry or local tool registry. Those local registries are assembled elsewhere and then merged with the MCP state at the client surface.

## Per-server updates replace slices instead of blindly appending

Equivalent behavior should preserve:

- batching multiple incoming MCP updates into one short-window state flush rather than thrashing the UI store on every callback
- updating one server by name
- tools being replaced by server-prefix match, not appended forever
- commands being replaced by server-specific command matching, not appended forever
- resources being replaced by server-name map entry, with empty resource sets removing that server's resource bucket entirely
- failed or disabled server states automatically clearing their tools, commands, and resources instead of leaving stale capabilities behind

## Commands in MCP state use two different naming schemes

Equivalent behavior should preserve:

- MCP prompts and MCP skills sharing the same `mcp.commands` array
- MCP prompts using an MCP-prefixed wire-safe slash-command name shape
- MCP skills using a `server:skill` style name that matches the broader skill surface rather than the MCP prompt wire format
- cleanup and per-server replacement logic understanding both naming schemes
- MCP skill consumers being able to distinguish skills from prompts by metadata rather than by assuming every MCP prompt is a skill

## Initial population fetches more than tools

Equivalent behavior should preserve:

- disabled servers entering session state without opening a connection
- recent or known needs-auth servers surfacing an auth-recovery tool while withholding ordinary MCP tools and commands
- connected servers fetching, in parallel when supported:
  - MCP tools
  - MCP prompts
  - MCP skills
  - MCP resources
- MCP skills being attempted only on servers with resource support, because skill discovery depends on a resource-backed surface in this snapshot
- the merged command contribution for one connected server being prompt commands plus MCP skills, not prompts alone
- resource-backed sessions adding generic resource browsing tools only once across the overall connected set rather than re-adding duplicates for every resource-capable server

## One known clean-room gap must stay explicit

This snapshot shows the registration points, caches, and consumers for MCP skills, but the concrete `mcpSkills` synthesis module itself is absent. Rebuilds should therefore preserve the visible contract around MCP skill discovery and invalidation without inventing hidden implementation details for the missing builder path.

## Live refresh is list-specific and cache-aware

Equivalent behavior should preserve:

- tool-list change notifications clearing only the per-server tool cache, refetching tools, and replacing that server's tool slice
- prompt-list change notifications clearing the per-server prompt-command cache, refetching prompt commands, reusing the current MCP-skill result, and replacing that server's command slice
- resource-list change notifications clearing the per-server resource cache and also refreshing MCP skills, because skills are discovered from resources in this snapshot
- resource-list change notifications also clearing the prompt-command cache before rewriting commands, so a concurrent prompt refresh cannot later overwrite the newer resource-triggered command set with stale cached data
- MCP-skill changes invalidating the skill-search index so later skill discovery reflects the updated remote set
- refresh failures staying local to the affected server and slice instead of tearing down unrelated MCP servers

## Stale plugin-backed servers are removed before reconnecting

Equivalent behavior should preserve:

- plugin reload or config refresh being able to identify stale MCP clients when:
  - a dynamic plugin-backed server no longer exists in config
  - any server's effective config hash changed
- stale clients having reconnect timers cancelled before cleanup
- only connected stale clients being actively cleaned up, so purely pending or disabled entries do not trigger pointless new connection work on removal
- stale clients having their tools, commands, and resources removed from session state before a fresh pending entry for the new config is added back

## Cache clearing must cover both connections and derived surfaces

Equivalent behavior should preserve:

- reconnect or cleanup invalidating not only the connection cache but also the per-server caches for:
  - tools
  - prompt commands
  - resources
  - MCP skills
- cleanup attempting to disconnect a currently connected wrapped client before dropping caches
- the next reconnect therefore rebuilding fresh client state and fresh derived command or tool or resource surfaces instead of reviving stale cached slices

## Consumers merge MCP state differently depending on the surface

Equivalent behavior should preserve:

- interactive session command surfaces merging local commands with `mcp.commands`
- interactive session tool surfaces merging local tools with `mcp.tools`
- skill-only consumers pulling only the MCP-skill subset from `mcp.commands`, not plain MCP prompts
- prompt-count or capability UIs being able to count MCP prompts separately from MCP skills even though both live in the same state bucket

## Failure modes

- **append-only drift**: reconnects and refreshes keep stacking old MCP tools or commands instead of replacing the affected server slice
- **name-shape blind spot**: cleanup only understands prompt-style MCP names and leaves `server:skill` commands behind after a server refresh or removal
- **resource-skill desync**: resource changes refresh resources but not skills, so deleted or renamed MCP skills remain visible until restart
- **cache race overwrite**: prompt and resource refreshes reuse stale per-server caches and let an older refresh clobber a newer command set
- **ghost plugin server**: disabled or removed plugin-backed MCP servers leave tools or commands in state after `/reload-plugins`
- **surface conflation**: MCP prompts are treated as SkillTool-invocable skills everywhere instead of staying distinct from the MCP-skill subset
