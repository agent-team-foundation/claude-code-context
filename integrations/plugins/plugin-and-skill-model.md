---
title: "Plugin and Skill Model"
owners: []
soft_links: [/integrations/plugins/plugin-runtime-contract.md, /integrations/plugins/skill-loading-contract.md, /integrations/plugins/plugin-management-and-marketplace-flows.md]
---

# Plugin and Skill Model

Claude Code exposes plugins and skills through overlapping user-visible surfaces, but they are not two names for the same extension type. A faithful rebuild needs both layers: plugins are installable operational bundles that extend the running product, while skills are named task-guidance assets that steer a turn or subtask through the prompt-command surface. Collapsing them into one abstraction breaks lifecycle, trust, policy, and discoverability.

## Scope boundary

This leaf covers:

- the conceptual boundary between plugins and skills
- which responsibilities belong to plugin identity versus skill identity
- how shipped defaults fit into each layer
- what it means when a plugin contributes one or more skills

It intentionally does not re-document:

- plugin discovery, validation, cache, dependency, and reload mechanics already covered in [plugin-runtime-contract.md](plugin-runtime-contract.md) and adjacent plugin leaves
- skill loading, provenance, dynamic activation, and listing behavior already covered in [skill-loading-contract.md](skill-loading-contract.md) and the skill discovery leaves
- slash-command and model-side skill execution after a skill has been chosen, already covered in [../../product-surface/prompt-command-and-skill-execution.md](../../product-surface/prompt-command-and-skill-execution.md)

## Plugins are installable extension bundles

Equivalent behavior should preserve:

- plugin identity being lifecycle-oriented rather than turn-oriented: a plugin is something the runtime can install, enable, disable, update, uninstall, cache, or block independently of any single conversation
- plugins being the unit for source trust, marketplace policy, version pinning, dependency resolution, and scope-aware management
- a plugin being able to contribute multiple operational surfaces at once, including:
  - prompt commands
  - agents
  - skills
  - hooks
  - output styles
  - MCP servers or bundles
  - LSP servers
  - plugin-scoped settings or user configuration
- a plugin remaining a plugin even when it contributes only one surface, and even when that surface happens to be a skill
- the plugin model supporting shipped-by-default variants that still retain plugin semantics such as enablement state and policy control

The important invariant is that plugins are the operational extension container. They are the thing an operator or user manages when deciding whether a capability family is present in the product at all.

## Skills are task-guidance assets

Equivalent behavior should preserve:

- a skill being a named unit of instructions plus invocation metadata that enters the prompt-command and model-side skill surface
- skill identity being invocation-oriented: what the skill is called, when it should be used, what tools or model behavior it expects, and where it came from matter more than package lifecycle
- skills being loadable from multiple channels rather than from one plugin-style install system, including:
  - bundled core skills
  - managed, user, or project file-backed skills
  - plugin-delivered skills
  - MCP-delivered skills
  - dynamically discovered nested skills
  - legacy command-directory compatibility paths
- skills shaping how a task is carried out inside a turn without becoming independently installable extension bundles
- skill availability being able to change with discovery, path activation, feature gates, or session state even when no plugin lifecycle event occurs

The important invariant is that skills are the task-selection layer. They answer "what guidance should steer this work right now?" rather than "what extension package is installed into the runtime?"

## Plugin-delivered skills do not erase the boundary

Equivalent behavior should preserve:

- a plugin being able to contribute zero, one, or many skills as just one part of its payload
- plugin-delivered skills joining the broader skill surface once loaded, so they participate in ordinary skill discovery and invocation instead of inventing a second execution model
- disabling, uninstalling, or policy-blocking a plugin removing its contributed skills together with its other components
- the converse not being true: invoking or loading a skill must not create plugin installation state, dependency state, update state, or marketplace identity on its own
- plugin trust, source policy, and configuration belonging to the plugin container, while task-facing metadata such as descriptions, usage guidance, tool constraints, and execution posture belong to the individual skill records exposed by that container

This is the sharpest boundary in the observed product shape: plugins may carry skills, but skills are not merely lightweight plugins.

## Shipped defaults use both layers

Equivalent behavior should preserve:

- bundled skills existing outside the plugin-management lifecycle and remaining part of the core skill surface even when no plugin installation flow runs
- separately, the runtime supporting built-in plugins as toggleable shipped extensions rather than as immutable core skills
- built-in plugins being able to contribute skills that behave like ordinary skills once enabled, while their availability still depends on plugin enablement and policy rather than on standalone skill registration
- rebuilds not collapsing all shipped capabilities into one bucket called either "bundled skills" or "built-in plugins"

A faithful rebuild should therefore allow two distinct kinds of shipped default capability:

- core skills that exist because the product ships them as skills
- default plugins that exist because the product ships them as plugin bundles

## Trust, policy, and UX attach to different layers

Equivalent behavior should preserve:

- plugin management surfaces reasoning in terms of installability, scope, policy, and update lifecycle
- skill discovery surfaces reasoning in terms of task relevance, invocation affordances, and prompt budget
- plugin trust decisions happening at extension-admission time because plugins can add ongoing runtime behavior beyond prompt text
- skill-channel safety rules still varying by provenance even after skills are loaded into one shared surface, rather than assuming every skill source is equally trusted
- users being able to think "enable this plugin" and "invoke this skill" as two different actions with different consequences

## Failure modes

- **extension flattening**: every skill is treated like an installable plugin, which destroys bundled, local, MCP, and dynamically activated skill paths
- **prompt flattening**: plugins are reduced to markdown guidance and lose hooks, servers, agents, settings, dependency, and policy semantics
- **default-capability conflation**: shipped bundled skills and shipped built-in plugins are merged into one undifferentiated default-extension bucket
- **policy drift**: plugin-delivered skills survive after the containing plugin is disabled or blocked, or plugin trust checks are bypassed because the payload is mislabeled as "just a skill"
- **surface conflation**: plugin-management UX and skill-discovery UX are treated as one inventory even though one manages capability containers and the other selects task guidance

## Test Design

In the observed source, plugin behavior is verified through registry regressions, loading-boundary integration tests, and management-surface end-to-end scenarios.

Equivalent coverage should prove:

- discovery, precedence, dependency resolution, feature gating, and skill exposure preserve the plugin contracts documented here
- hot reload, settings coupling, packaged servers, and cache invalidation behave correctly with resettable registries and on-disk plugin state
- the visible install, list, enablement, and runtime-exposure behavior stays aligned with the public plugin surfaces rather than private helper APIs
