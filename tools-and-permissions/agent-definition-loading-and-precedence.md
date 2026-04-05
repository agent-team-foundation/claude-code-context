---
title: "Agent Definition Loading and Precedence"
owners: []
soft_links: [/tools-and-permissions/agent-tool-launch-routing.md, /collaboration-and-agents/worker-execution-boundaries.md, /integrations/plugins/plugin-and-skill-model.md, /memory-and-context/durable-memory-recall-and-auto-memory.md]
---

# Agent Definition Loading and Precedence

Before the Agent tool can choose a launch route, Claude Code first builds an agent catalog. That catalog is not one flat directory read. It is a multi-source assembly pipeline with source-class precedence, source-specific schema limits, and several soft-failure paths. Rebuilding worker behavior accurately requires reproducing that catalog phase, because later permission filtering and route selection assume the catalog was assembled the same way.

## Scope boundary

This leaf covers:

- which agent-definition sources participate in catalog assembly
- how active agents are chosen when several sources define the same `agentType`
- which fields materially change runtime behavior
- where plugin, markdown, and JSON-defined agents are intentionally treated differently

It intentionally does not re-document:

- the later launch-routing branches already covered in [agent-tool-launch-routing.md](agent-tool-launch-routing.md)
- worker execution boundaries after an agent has already been selected, already covered in [../collaboration-and-agents/worker-execution-boundaries.md](../collaboration-and-agents/worker-execution-boundaries.md)

## Catalog assembly is multi-source and mode-dependent

Equivalent behavior should preserve:

- built-in agents providing the baseline catalog
- enabled plugin agents joining that baseline from the plugin system
- custom markdown agents loading from managed, user, and project `.claude/agents` directories
- JSON-defined agents being injectable later through flag or SDK-style startup inputs instead of requiring filesystem authoring
- simple or bare baseline mode collapsing the on-disk catalog back to built-ins only, while still allowing later injected JSON agents to be layered on afterward
- catastrophic loader failure degrading to built-ins only instead of failing the whole session startup

## Source precedence is by `agentType`, not by filename

Equivalent behavior should preserve:

- the active set being deduplicated by logical `agentType`
- source-class precedence of:
  - built-in
  - plugin
  - user settings
  - project settings
  - flag or SDK settings
  - managed policy settings
- later source classes replacing earlier ones when they define the same `agentType`
- same-source collisions still being order-dependent rather than having a separate merge algorithm
- project markdown discovery walking upward from cwd toward the repo boundary, which means parent project directories can override nearer project definitions if they reuse the same `agentType`
- managed "plugin-only" policy suppressing user and project disk-backed agents without deleting the rest of the catalog

## The loader distinguishes baseline catalog from later launch-time filters

Equivalent behavior should preserve:

- the loader returning both the full discovered list and the deduplicated active list
- color and other display metadata being initialized only after the active set is known
- later launch-time filtering still being able to remove otherwise-active agents based on caller restrictions such as allowed agent types, denied tools, or required MCP-server availability
- runtime support for `requiredMcpServers` style filtering existing even when the authoring path for that field is only partially visible in this snapshot

## Markdown and JSON agents share the same core behavioral fields

Equivalent behavior should preserve:

- markdown agents requiring frontmatter `name` plus `description`, with the markdown body acting as the agent prompt
- JSON agents requiring descriptive text plus an explicit prompt body in the injected object
- common optional fields that materially affect runtime:
  - `tools`
  - `disallowedTools`
  - `skills`
  - `model`
  - `effort`
  - `permissionMode`
  - `maxTurns`
  - `initialPrompt`
  - `background`
  - `memory`
  - `isolation`
  - `hooks`
  - per-agent MCP server specs for custom agents
- `model: inherit` being a real normalized setting rather than freeform text
- tool semantics preserving the difference between:
  - missing `tools`, which means ordinary tool availability
  - empty `tools`, which means intentionally no tools
  - explicit `tools`, which means an allowlist that later permission filters can still narrow further

## Memory is active behavior, not decorative metadata

Equivalent behavior should preserve:

- memory opt-in changing both prompt content and tool availability
- memory-enabled agents receiving extra memory instructions in their effective system prompt
- memory-enabled agents automatically gaining read, write, and edit tool access when that memory path would otherwise be unusable
- user-scoped memory being able to initialize from a snapshot or carry a pending snapshot-update marker when the loader detects newer memory state

## Isolation and background flags are catalog-level intent

Equivalent behavior should preserve:

- `background` being an agent-definition hint that can force async launch behavior later even when the caller did not explicitly request backgrounding
- `isolation` being part of the definition, with ordinary public authoring limited to worktree isolation while remote isolation remains internal-only in this snapshot
- explicit launch input still being able to override a definition's default isolation at spawn time

## Plugin agents are intentionally less powerful than user-authored agents

Equivalent behavior should preserve:

- plugin agents being namespaced from the plugin name and nested path rather than treated as globally raw filenames
- plugin prompts being able to substitute plugin-root-relative paths and non-sensitive user configuration values before execution
- plugin agents being allowed to define tools, disallowed tools, skills, model, effort, background, memory, worktree isolation, and max-turns behavior
- plugin agent frontmatter not being allowed to silently add per-agent `permissionMode`, `hooks`, or `mcpServers`
- those forbidden plugin-agent fields being ignored with warnings instead of escalating plugin authority at agent-file granularity

## Validation is usually soft, but injected JSON is stricter

Equivalent behavior should preserve:

- markdown files without agent-looking frontmatter being skipped quietly so reference notes can live beside agents
- markdown files that look like agent attempts surfacing parse failures through a `failedFiles` style result instead of crashing the catalog
- invalid optional fields such as memory, isolation, effort, permission mode, hooks, or individual MCP-server entries usually being logged and dropped field-by-field rather than rejecting the whole agent
- plugin-agent load failures staying local to the affected file or plugin path
- injected JSON agent payloads being validated as structured objects, so one schema error can invalidate the whole injected batch instead of partially loading it

## Known source gap

This source snapshot shows runtime and UI references that anticipate additional agent-source shapes, but it does not show an active disk-backed `localSettings` agent ingestion path. Rebuilds should therefore treat that source as unconfirmed rather than required until stronger evidence appears.

## Failure modes

- **catalog flattening**: all agent sources are treated as one folder read, erasing source-class precedence and plugin restrictions
- **nearest-dir assumption**: project agent collisions are resolved by an invented "closest directory wins" rule even though the observed catalog is order-dependent instead
- **plugin escalation**: plugin agent files are allowed to add per-agent hooks, MCP servers, or permission modes that user-authored agents alone were meant to control
- **memory dead-end**: memory-enabled agents do not gain the file tools needed to make that memory path usable
- **loader fragility**: one malformed agent file tears down the whole catalog instead of degrading to built-ins or surviving definitions
