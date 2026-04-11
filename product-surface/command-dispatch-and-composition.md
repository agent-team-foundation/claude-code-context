---
title: "Command Dispatch and Composition"
owners: []
soft_links: [/runtime-orchestration/turn-flow/turn-assembly-and-recovery.md, /runtime-orchestration/automation/workflow-script-runtime.md, /integrations/plugins/skill-loading-contract.md, /integrations/plugins/skill-discovery-and-listing-surfaces.md, /integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md, /integrations/clients/sdk-control-protocol.md]
---

# Command Dispatch and Composition

Claude Code's slash surface is assembled in stages, not declared once. A faithful rebuild needs the stable local source order, the late dynamic-skill insertion rule, the separate live-session MCP merge, and the ordered lookup contract. If those pieces drift, the wrong command wins on collision, plugins get modeled as a second command system when they are not, some skills become unreachable, and different clients stop agreeing on what `/name` means.

## Scope boundary

This leaf covers:

- the command-entry families that the runtime dispatches differently
- the staged assembly order for the local command catalog
- how dynamic skills and MCP-provided commands join that surface later
- runtime visibility filters that run after loading
- the lookup rule that decides which command actually wins
- how skill-oriented consumers derive filtered projections and invocation inputs from the composed catalog

It intentionally does not re-document:

- skill-source discovery details already covered in [../integrations/plugins/skill-loading-contract.md](../integrations/plugins/skill-loading-contract.md)
- model-facing and human-facing skill listing surfaces already covered in [../integrations/plugins/skill-discovery-and-listing-surfaces.md](../integrations/plugins/skill-discovery-and-listing-surfaces.md)
- prompt-command and model skill invocation semantics already covered in [prompt-command-and-skill-execution.md](prompt-command-and-skill-execution.md)
- workflow execution semantics already covered in [../runtime-orchestration/automation/workflow-script-runtime.md](../runtime-orchestration/automation/workflow-script-runtime.md)
- MCP connection and refresh behavior already covered in [../integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md](../integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md)

## Dispatch begins from one unified command catalog

Equivalent behavior should preserve one composed slash-command catalog whose entries may still dispatch differently at runtime:

- **prompt commands** expanding into model-visible instructions and re-entering the ordinary turn loop
- **local commands** running non-UI local logic and returning text, compact actions, or skip results
- **local modal commands** opening richer terminal UI flows before optionally feeding results back into the shared session
- per-command metadata changing visibility or dispatch without inventing a second orchestration system, including:
  - canonical names, display names, and aliases
  - account or provider eligibility
  - live runtime enablement gates
  - hidden versus user-visible posture
  - queue-bypassing immediate execution
  - prompt-specific constraints such as extra allowed tools, model overrides, hooks, worker-routing hints, and user-versus-model invocation controls

The important invariant is that composition does not create separate dispatch engines for skills, workflows, plugins, or MCP. It produces ordered command records that later dispatch through the same core command-handling paths.

## The local base catalog is assembled in a fixed order

Equivalent behavior should preserve one workspace-local command catalog assembled per working directory in this order:

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
- dynamic skills being filtered through the same eligibility and enablement checks as ordinary commands
- dynamic skills being inserted after plugin skills but before built-in commands
- dynamic skills only being added when their exact internal command name is not already present in the visible base catalog
- dynamic discovery therefore never overriding an already visible bundled, plugin, workflow, disk-backed, or built-in command by name

This means dynamic skills are not a higher-precedence patch over the registry. They are a gap-filling overlay on top of an already ordered local base.

## Loading may be cached, but visibility must stay live

Equivalent behavior should preserve:

- expensive source loading being memoized by working directory because disk and plugin discovery are costly
- account/provider eligibility checks re-running on every command refresh instead of being frozen in the memoized load result
- live enablement gates also re-running on refresh so login, entitlement, feature-flag, or environment changes take effect without restarting the session
- static eligibility filtering running before live enablement, so a command that is build-enabled but unavailable for the current account still stays hidden
- command caches and skill-search indexes being invalidatable separately when late skill activation changes visibility without changing the underlying shipped command set

The clean-room requirement is that loading order is stable, but visibility remains live.

## MCP joins only at the session surface

Equivalent behavior should preserve:

- the workspace-local catalog builder returning only the local assembled catalog described above, never MCP prompts or MCP skills
- MCP commands being held separately in live session state and merged only by the interactive, bridge, or headless client surface that needs the current command view
- the session command surface therefore being:
  - workspace-local assembled commands
  - MCP commands from live session state
- no separate session-stage plugin command merge beyond what the local catalog builder already loaded
- interactive and headless turn-entry paths handing that merged command list into slash parsing and query execution rather than consulting only the local base catalog
- exact-name deduplication, when a client surface applies it after the merge, preserving the earlier local entry rather than re-arbitrating by source

This boundary is important because MCP commands are live connection state, not file-backed local command definitions.

## MCP prompts and MCP skills stay merged together only partway

Equivalent behavior should preserve:

- plain MCP prompts participating in the general slash-command surface as prompt-backed commands
- MCP skills also arriving through the same live session MCP command set, but being filtered back out as a distinct subset for skill-oriented consumers
- skill-listing and skill-budget surfaces building narrower views from filtered local prompt commands plus a separately threaded MCP-skill subset
- model-side skill name resolution reusing a broader composed local catalog plus that separately threaded MCP-skill subset, then applying explicit prompt-only and model-invocation gates afterward
- plain MCP prompts therefore not becoming model-invocable skills merely because they are prompt-shaped
- these skill-oriented projections and invocation paths reusing composed records and ordering rather than separate loaders with their own precedence model

## Lookup is ordered and first-match

Equivalent behavior should preserve:

- command lookup scanning one ordered command list and stopping at the first matching entry
- matching checking, in order of the same command entry:
  - canonical command name
  - user-facing display name override
  - aliases
- no late global arbitration by provenance, plugin identity, or skill channel once lookup begins
- local-first precedence against MCP collisions because session surfaces merge local commands before MCP commands
- any downstream deduplication by exact internal command name preserving first occurrence, so it still reinforces the same local-first precedence instead of changing winners

User-facing names are display affordances, not a second namespace that bypasses precedence.

## User slash lookup and model skill lookup reuse composition but not identical filters

Equivalent behavior should preserve:

- user slash invocation being able to target only commands present in the merged session command list
- prompt assets marked as model-only being removed from user-facing slash inventories and producing an explicit refusal on direct user slash invocation, while still allowing model-side skill use when model invocation itself remains enabled
- prompt assets marked as user-only being blockable from model-side skill invocation even if they are still callable as slash commands
- model-side skill invocation resolving through the broader composed command surface plus the MCP-skill subset rather than only through the eagerly listed skill inventory
- model-facing skill lists being narrower filtered projections over the composed command surface instead of independent load paths
- model-only skills rendering different loading metadata from ordinary slash commands instead of pretending the user invoked them directly

## Remote and bridge clients narrow the catalog again

Equivalent behavior should preserve:

- remote-mode startup being able to pre-filter the command surface to a narrow safe set before the full interactive session warms
- bridge-delivered slash commands applying a stricter per-kind policy:
  - prompt commands are allowed by type
  - local commands need an explicit allowlist
  - local modal commands remain blocked because they assume a local terminal UI
- these remote or bridge filters being overlays on the same command catalog rather than a separate command implementation tree

## Failure modes

- **precedence drift**: rebuilds change the source order and make a later built-in or plugin command win where the observed product lets an earlier skill win
- **dynamic override bug**: late-discovered skills replace already visible commands instead of only filling absent names
- **plugin double-counting**: plugin commands are modeled as a second session-layer overlay even though they were already loaded into the local base catalog
- **surface collapse**: MCP prompts and MCP skills are treated as if they came from the local catalog builder, erasing the session-state merge boundary
- **stale visibility**: auth or feature changes do not refresh eligibility and enablement checks, so the slash surface lags behind the real runtime
- **invocation confusion**: user-only and model-only invocation controls are treated as the same flag, breaking the split between user slash use and model skill use
- **bridge UI leak**: local modal commands remain callable over bridge or remote clients that cannot satisfy their UI assumptions

## Test Design

In the observed source, product-surface behavior is verified through command-focused integration tests and CLI-visible end-to-end checks.

Equivalent coverage should prove:

- parsing, dispatch, flag composition, and mode selection preserve the public contract for this surface
- downstream runtime, tool, and session services receive the correct shaping when this surface is used from interactive and headless entrypoints
- user-visible output, exit behavior, and help or error routing remain correct through the packaged CLI path rather than only direct module calls
