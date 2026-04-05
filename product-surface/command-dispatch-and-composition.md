---
title: "Command Dispatch and Composition"
owners: []
soft_links: [/runtime-orchestration/turn-assembly-and-recovery.md, /runtime-orchestration/workflow-script-runtime.md, /integrations/plugins/skill-loading-contract.md, /integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md, /integrations/clients/sdk-control-protocol.md]
---

# Command Dispatch and Composition

Claude Code's slash surface is assembled, not declared once. A faithful rebuild needs the exact composition order, the first-match resolution rule, and the split between local command discovery and separately merged MCP command state. If those pieces drift, the wrong command wins on collision, some skills become unreachable, and different clients stop agreeing on what `/name` means.

## Scope boundary

This leaf covers:

- the command object kinds that the runtime dispatches differently
- the base command-catalog assembly order for local, bundled, workflow, and plugin sources
- how dynamic skills and MCP-provided commands join that surface later
- runtime visibility filters that run after loading
- the lookup rule that decides which command actually wins

It intentionally does not re-document:

- skill-source discovery details already covered in [../integrations/plugins/skill-loading-contract.md](../integrations/plugins/skill-loading-contract.md)
- prompt-command and SkillTool execution semantics already covered in [prompt-command-and-skill-execution.md](prompt-command-and-skill-execution.md)
- workflow execution semantics already covered in [../runtime-orchestration/workflow-script-runtime.md](../runtime-orchestration/workflow-script-runtime.md)
- MCP connection and refresh behavior already covered in [../integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md](../integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md)

## Dispatch starts from three command kinds

Equivalent behavior should preserve:

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

## The base local catalog has a fixed precedence order

Equivalent behavior should preserve one local command registry assembled in this order:

- bundled skills
- built-in plugin skills
- disk-backed skill-directory commands
- workflow-backed commands
- plugin commands
- plugin skills
- built-in commands

This ordering is reconstruction-critical. It is not cosmetic. Earlier entries can shadow later ones because command lookup is first-match, not an abstract merge by name.

## Dynamic skills join late and can only fill gaps

Equivalent behavior should preserve:

- the base registry being built first without dynamic skills
- dynamic skills being discovered outside ordinary startup loading and inserted only afterward
- dynamic skills being filtered through the same availability and enablement checks as ordinary commands
- dynamic skills being inserted after plugin skills but before built-in commands
- dynamic skills only being added when their exact command name is not already present in the visible base catalog
- dynamic discovery therefore never overriding an already visible bundled, plugin, workflow, disk-backed, or built-in command by name

## Visibility filters run after expensive loading

Equivalent behavior should preserve:

- expensive source loading being memoized by cwd because disk and plugin discovery are costly
- provider or auth `availability` checks re-running on every command refresh instead of being frozen in the memoized load result
- runtime `isEnabled` gates also re-running on refresh so login, entitlement, feature-flag, or environment changes take effect without restarting the session
- provider gating running before feature enablement, so a command that is build-enabled but unavailable for the current account still stays hidden
- command caches and skill-search indexes being invalidatable separately when late skill activation changes visibility without changing the underlying shipped command set

## MCP commands live outside the base local registry

Equivalent behavior should preserve:

- `getCommands(cwd)` returning only the local assembled catalog described above, not MCP-provided prompts or MCP skills
- MCP commands being held separately in session state and merged by the interactive or headless client surface after local command loading
- the merged session command surface therefore being:
  - local assembled commands
  - plugin state commands that the surface layer contributes separately
  - MCP commands from live session state
- slash-command handling using that merged session surface rather than consulting only the local base registry
- skill-only consumers treating MCP skills specially:
  - MCP prompts participate in the general slash-command surface
  - MCP skills are pulled from session MCP state and unioned into skill-specific indexes separately
  - plain MCP prompts must not accidentally appear as SkillTool-invocable skills just because they are prompt-shaped

## Resolution is first-match and order-dependent

Equivalent behavior should preserve:

- command lookup scanning the merged list in order and stopping at the first match
- matching checking, in order of the same command entry:
  - internal command name
  - user-facing display name override
  - aliases
- no second-stage global dedup or conflict arbitration after lookup
- earlier command layers therefore winning collisions with later layers
- user-facing names being display affordances, not a separate namespace that bypasses precedence

## Manual slash invocation and model invocation are not the same surface

Equivalent behavior should preserve:

- user slash invocation being able to target only commands present in the merged session command list
- `user-invocable: false` preventing direct user slash execution while still allowing model use through SkillTool when model invocation itself remains enabled
- prompt commands with `disable-model-invocation` being blockable from SkillTool even if they are still user-invocable as slash commands
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
- **surface collapse**: MCP prompts and MCP skills are treated as if they came from `getCommands(cwd)`, erasing the session-state merge boundary
- **stale visibility**: auth or feature changes do not refresh availability and enablement checks, so the slash surface lags behind the real runtime
- **invocation confusion**: `user-invocable` and `disable-model-invocation` are treated as the same flag, breaking the split between user slash use and model skill use
- **bridge UI leak**: local JSX commands remain callable over bridge or remote clients that cannot satisfy their terminal UI assumptions
