---
title: "Command Dispatch and Composition"
owners: []
soft_links: [/runtime-orchestration/turn-flow/turn-assembly-and-recovery.md, /runtime-orchestration/automation/workflow-script-runtime.md, /integrations/plugins/skill-loading-contract.md, /integrations/plugins/skill-discovery-and-listing-surfaces.md, /integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md, /integrations/clients/sdk-control-protocol.md]
---

# Command Dispatch and Composition

Claude Code does not own one static slash-command table. It builds a local command catalog from several sources, applies live visibility gates, and only then lets each session add MCP-delivered commands on top. A faithful rebuild must preserve four things together: the local source order, the late dynamic-skill insertion rule, the fact that MCP joins only at the live session surface, and the first-match lookup contract. If any of those drift, collisions resolve differently, skills disappear from some surfaces, and different clients stop agreeing on what `/name` means.

## Scope boundary

This leaf covers:

- the shared command record model and the kinds that dispatch differently
- the fixed assembly order for the local command catalog
- how dynamic skills and MCP-provided commands join that catalog later
- the visibility filters that run after expensive loading
- the lookup rule that decides which entry wins on collision
- how user slash invocation and model skill invocation derive different projections from the same composed records

It intentionally does not re-document:

- skill-source discovery details already covered in [../integrations/plugins/skill-loading-contract.md](../integrations/plugins/skill-loading-contract.md)
- model-facing and human-facing skill listing surfaces already covered in [../integrations/plugins/skill-discovery-and-listing-surfaces.md](../integrations/plugins/skill-discovery-and-listing-surfaces.md)
- prompt-command and SkillTool execution semantics already covered in [prompt-command-and-skill-execution.md](prompt-command-and-skill-execution.md)
- workflow execution semantics already covered in [../runtime-orchestration/automation/workflow-script-runtime.md](../runtime-orchestration/automation/workflow-script-runtime.md)
- MCP connection and refresh behavior already covered in [../integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md](../integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md)

## One shared command model, multiple dispatch kinds

Equivalent behavior should preserve one ordered command surface whose entries still dispatch differently at runtime:

- **prompt commands** that expand into instructions and re-enter the normal turn loop
- **local commands** that run local logic and return text, compact actions, or no visible transcript output
- **local interactive commands** that open terminal UI flows before optionally feeding results back into the shared session
- metadata that changes display, availability, or routing without creating a separate orchestration system, including:
  - canonical name, user-facing name, and aliases
  - auth/provider availability requirements
  - runtime enablement gates
  - hidden versus user-visible posture
  - immediate execution for queue-bypassing commands
  - prompt-only controls such as allowed tools, model override, hooks, forked execution, user visibility, and model-invocation disablement

The invariant is that command composition does not create separate dispatch engines for skills, workflows, plugins, and ordinary slash commands. It produces ordered command records that later enter the same parsing and dispatch machinery.

## The local base catalog is assembled in a fixed order

Equivalent behavior should preserve one cached local catalog assembled per working directory in this order:

- bundled skills registered at startup
- skills contributed by currently enabled built-in plugins
- disk-backed skill and legacy command-directory prompt commands
- workflow-backed commands
- plugin commands
- plugin skills
- built-in commands from the static command definition set

This ordering is reconstruction-critical. It is not cosmetic. Earlier entries can shadow later ones because lookup is order-sensitive.

Two details matter here:

- plugin commands and plugin skills are already part of this local base catalog; the session layer does not add a second plugin overlay later
- workflow-backed commands are ordinary entries in the same catalog, not a separate slash namespace

## Dynamic skills are late gap-fillers inside the local layer

Equivalent behavior should preserve:

- the base local catalog being built first without dynamic skills
- dynamic skills being discovered outside ordinary startup loading and inserted only afterward
- dynamic skills being filtered through the same availability and enablement checks as ordinary commands
- dynamic skills being inserted after plugin skills but before built-in commands
- dynamic skills only being added when the visible local catalog does not already contain that command name
- dynamic discovery therefore filling gaps instead of overriding already visible bundled, plugin, workflow, disk-backed, or built-in commands

This means dynamic discovery is not a high-precedence patch over the registry. It is a late gap-filling step on top of an already ordered local base.

## Loading is cached, but visibility remains live

Equivalent behavior should preserve:

- expensive disk and plugin discovery being cached by working directory
- provider/auth availability checks re-running on every command refresh instead of being frozen into the cached load result
- runtime enablement gates also re-running on refresh so login, entitlement, feature-flag, or environment changes take effect without restarting the session
- provider gating running before feature enablement, so a command that is build-enabled but unavailable for the current account still stays hidden
- command caches and skill-search indexes being invalidatable separately when late skill activation changes visibility without changing the underlying shipped command set

The clean-room requirement is that source loading order stays stable while visibility remains live.

## MCP joins only at the live session surface

Equivalent behavior should preserve:

- the reusable local catalog excluding MCP prompts and MCP skills
- MCP commands being held in live session state and merged only by the interactive, bridge, or headless surface that needs the current command view
- no separate session-stage plugin merge beyond what the local catalog already loaded
- turn-entry paths consulting the merged local-plus-MCP list rather than consulting only the local catalog
- exact-name deduplication after the merge preserving the earlier local entry instead of re-arbitrating by source type

This boundary matters because MCP commands are live connection state, not local file-backed definitions.

## MCP prompts and MCP skills share ingress, then split again

Equivalent behavior should preserve:

- plain MCP prompts participating in the general slash-command surface as prompt-backed commands
- MCP skills arriving through the same live session merge, but being filtered back out as a distinct subset for skill-oriented consumers
- skill-listing and skill-budget surfaces building narrower views from filtered local prompt commands plus a separately threaded MCP-skill subset
- model skill resolution reusing the broader composed prompt-command surface plus that separately threaded MCP-skill subset, then applying prompt-only and model-invocation gates afterward
- plain MCP prompts therefore not becoming model-invocable skills merely because they are prompt-shaped
- these skill-oriented projections reusing the same composed records and ordering rather than separate loaders with their own precedence model

## Lookup is ordered and first-match

Equivalent behavior should preserve:

- command lookup scanning one ordered command list and stopping at the first matching entry
- matching checking, within the same command entry, the canonical name first, then any user-facing display name override, then aliases
- no late global arbitration by provenance, plugin identity, or skill channel once lookup begins
- local-first precedence against MCP collisions because session surfaces merge local commands before MCP commands
- any downstream deduplication by exact internal command name preserving first occurrence, so it still reinforces the same local-first precedence instead of changing winners

User-facing names are display affordances, not a second namespace that bypasses precedence.

## User slash invocation and model skill invocation reuse composition, but not the same filters

Equivalent behavior should preserve:

- user slash invocation being able to target only commands present in the merged session command list
- `user-invocable: false` removing a command from user-facing slash inventories and producing an explicit refusal on direct user slash invocation, while still allowing model use when model invocation itself remains enabled
- prompt commands with `disable-model-invocation` being excluded from model skill invocation even if they remain user-invocable as slash commands
- model skill invocation resolving through the broader composed prompt-command surface plus the MCP-skill subset rather than only through the eagerly listed skill inventory
- model-facing skill lists being narrower filtered projections over the composed command surface instead of independent load paths
- model-only skills rendering different loading metadata from ordinary slash commands instead of pretending the user invoked them directly

## Remote and bridge surfaces narrow the catalog again

Equivalent behavior should preserve:

- remote-mode startup being able to pre-filter the command surface to a narrow safe set before the full interactive session warms
- bridge-delivered slash commands applying a stricter per-kind policy:
  - prompt commands are allowed by type
  - local commands need an explicit allowlist
  - local interactive commands remain blocked because they assume local terminal UI
- these remote or bridge filters being overlays on the same command catalog rather than a separate command implementation tree

## Failure modes

- **precedence drift**: rebuilds change the source order and make a later built-in or plugin command win where the observed product lets an earlier skill win
- **dynamic override bug**: late-discovered skills replace already visible commands instead of only filling absent names
- **plugin double-counting**: plugin commands are modeled as a second session-layer overlay even though they were already loaded into the local base catalog
- **surface collapse**: MCP prompts and MCP skills are treated as if they belonged to the reusable local catalog, erasing the session-state merge boundary
- **stale visibility**: auth or feature changes do not refresh availability and enablement checks, so the slash surface lags behind the real runtime
- **invocation confusion**: `user-invocable` and `disable-model-invocation` are treated as the same flag, breaking the split between user slash use and model skill use
- **bridge UI leak**: local interactive commands remain callable over bridge or remote clients that cannot satisfy their terminal UI assumptions
