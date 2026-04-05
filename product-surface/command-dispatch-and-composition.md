---
title: "Command Dispatch and Composition"
owners: []
soft_links: [/runtime-orchestration/turn-assembly-and-recovery.md, /runtime-orchestration/workflow-script-runtime.md, /integrations/plugins/skill-loading-contract.md, /integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md, /integrations/clients/sdk-control-protocol.md]
---

# Command Dispatch and Composition

Claude Code's slash surface is assembled in stages, not declared once. A faithful rebuild needs the exact local assembly order, the late dynamic-skill insertion rule, the separate session-scoped MCP merge, and the ordered lookup contract. If those pieces drift, the wrong command wins on collision, plugin commands get modeled as a separate layer when they are not, some skills become unreachable, and different clients stop agreeing on what `/name` means.

## Scope boundary

This leaf covers:

- the command object kinds that the runtime dispatches differently
- the staged assembly order for the local command catalog
- how dynamic skills and MCP-provided commands join that surface later
- runtime visibility filters that run after loading
- the lookup rule that decides which command actually wins
- how skill-oriented consumers derive filtered projections from the composed catalog

It intentionally does not re-document:

- skill-source discovery details already covered in [../integrations/plugins/skill-loading-contract.md](../integrations/plugins/skill-loading-contract.md)
- prompt-command and SkillTool execution semantics already covered in [prompt-command-and-skill-execution.md](prompt-command-and-skill-execution.md)
- workflow execution semantics already covered in [../runtime-orchestration/workflow-script-runtime.md](../runtime-orchestration/workflow-script-runtime.md)
- MCP connection and refresh behavior already covered in [../integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md](../integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md)

## Dispatch begins from one unified command type system

Equivalent behavior should preserve one `Command` surface whose entries may still dispatch differently at runtime:

- **prompt commands** expanding into model-visible instructions and re-entering the ordinary turn loop
- **local commands** running non-UI local logic and returning text, compact actions, or skip results
- **local JSX commands** opening richer terminal UI flows before optionally feeding results back into the shared session
- command metadata changing dispatch without inventing a second orchestration system, including:
  - aliases and user-facing names
  - auth or provider `availability`
  - runtime `isEnabled` gates
  - hidden versus user-visible posture
  - `immediate` execution for queue-bypassing commands
  - prompt-only metadata such as `allowedTools`, `model`, `hooks`, `context: fork`, `disable-model-invocation`, and `user-invocable`

The important invariant is that command composition does not create separate dispatch engines for skills, workflows, plugins, or MCP. It produces ordered command records that later dispatch through the same core command-handling paths.

## The local base catalog is assembled in a fixed order

Equivalent behavior should preserve one memoized local command catalog assembled per cwd in this order:

- bundled skills registered at startup
- skills contributed by currently enabled built-in plugins
- disk-backed skill and legacy command-directory prompt commands
- workflow-backed commands
- plugin commands
- plugin skills
- built-in commands from the static command definition set

This ordering is reconstruction-critical. It is not cosmetic. Earlier entries can shadow later ones because lookup is order-sensitive.

Two details matter here:

- plugin commands and plugin skills are already part of this local base catalog; the session layer does not add a second separate plugin-command overlay later
- workflow-backed commands are ordinary entries in the same catalog, not a separate slash namespace or separate registry

## Dynamic skills are a late local overlay, not a separate registry

Equivalent behavior should preserve:

- the base registry being built first without dynamic skills
- dynamic skills being discovered outside ordinary startup loading and inserted only afterward
- dynamic skills being filtered through the same availability and enablement checks as ordinary commands
- dynamic skills being inserted after plugin skills but before built-in commands
- dynamic skills only being added when their exact internal command name is not already present in the visible base catalog
- dynamic discovery therefore never overriding an already visible bundled, plugin, workflow, disk-backed, or built-in command by name

This means dynamic skills are not a higher-precedence patch over the registry. They are a gap-filling overlay on top of an already ordered local base.

## Visibility is recomputed after expensive loading

Equivalent behavior should preserve:

- expensive source loading being memoized by cwd because disk and plugin discovery are costly
- provider or auth `availability` checks re-running on every command refresh instead of being frozen in the memoized load result
- runtime `isEnabled` gates also re-running on refresh so login, entitlement, feature-flag, or environment changes take effect without restarting the session
- provider gating running before feature enablement, so a command that is build-enabled but unavailable for the current account still stays hidden
- command caches and skill-search indexes being invalidatable separately when late skill activation changes visibility without changing the underlying shipped command set

The clean-room requirement is that loading order is stable, but visibility remains live.

## MCP joins only at the session surface

Equivalent behavior should preserve:

- `getCommands(cwd)` returning only the local assembled catalog described above, never MCP prompts or MCP skills
- MCP commands being held separately in session state and merged only by the interactive, bridge, or headless client surface that needs the current live command view
- the session command surface therefore being:
  - local assembled commands from `getCommands(cwd)`
  - MCP commands from live session state
- no separate session-stage plugin command merge beyond what `getCommands(cwd)` already loaded
- interactive and headless turn-entry paths handing that merged command list into slash parsing and query execution rather than consulting only the local base catalog

This boundary is important because MCP commands are live connection state, not file-backed local command definitions.

## MCP prompts and MCP skills stay merged together only partway

Equivalent behavior should preserve:

- plain MCP prompts participating in the general slash-command surface as prompt-backed commands
- MCP skills also arriving through `mcp.commands`, but being filtered back out as a distinct subset for skill-oriented consumers
- SkillTool and other skill-only consumers building their view from:
  - filtered local commands from `getCommands(cwd)`
  - separately threaded MCP skills from session MCP state
- plain MCP prompts therefore not becoming SkillTool-invocable merely because they are prompt-shaped
- these skill-oriented projections being filtered views over the composed catalog rather than separate loaders with their own precedence model

## Lookup is ordered and first-match

Equivalent behavior should preserve:

- command lookup scanning one ordered command list and stopping at the first matching entry
- matching checking, in order of the same command entry:
  - internal command name
  - user-facing display name override
  - aliases
- no late global arbitration by provenance, plugin identity, or skill channel once lookup begins
- local-first precedence against MCP collisions because session surfaces merge local commands before MCP commands
- any downstream deduplication by exact command name preserving first occurrence, so it still reinforces the same local-first precedence instead of changing winners

User-facing names are display affordances, not a second namespace that bypasses precedence.

## User slash lookup and model skill lookup reuse composition but not identical filters

Equivalent behavior should preserve:

- user slash invocation being able to target only commands present in the merged session command list
- `user-invocable: false` preventing direct user slash execution while still allowing model use through SkillTool when model invocation itself remains enabled
- prompt commands with `disable-model-invocation` being blockable from SkillTool even if they are still user-invocable as slash commands
- model-facing skill lists being filtered projections over the composed command surface instead of independent load paths
- model-only skills rendering different loading metadata from ordinary slash commands instead of pretending the user invoked them directly

## Remote and bridge clients narrow the catalog again

Equivalent behavior should preserve:

- remote-mode startup being able to pre-filter the command surface to a narrow safe set before the full interactive session warms
- bridge-delivered slash commands applying a stricter per-kind policy:
  - prompt commands are allowed by type
  - local commands need an explicit allowlist
  - local JSX commands remain blocked because they assume a local Ink UI
- these remote or bridge filters being overlays on the same command catalog rather than a separate command implementation tree

## Failure modes

- **precedence drift**: rebuilds change the source order and make a later built-in or plugin command win where the observed product lets an earlier skill win
- **dynamic override bug**: late-discovered skills replace already visible commands instead of only filling absent names
- **plugin double-counting**: plugin commands are modeled as a second session-layer overlay even though they were already loaded into the local base catalog
- **surface collapse**: MCP prompts and MCP skills are treated as if they came from `getCommands(cwd)`, erasing the session-state merge boundary
- **stale visibility**: auth or feature changes do not refresh availability and enablement checks, so the slash surface lags behind the real runtime
- **invocation confusion**: `user-invocable` and `disable-model-invocation` are treated as the same flag, breaking the split between user slash use and model skill use
- **bridge UI leak**: local JSX commands remain callable over bridge or remote clients that cannot satisfy their terminal UI assumptions
