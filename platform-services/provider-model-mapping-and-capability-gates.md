---
title: "Provider Model Mapping and Capability Gates"
owners: []
soft_links: [/platform-services/provider-specific-api-clients-and-auth-routing.md, /product-surface/model-and-behavior-controls.md, /runtime-orchestration/turn-flow/api-request-assembly-retry-and-prompt-cache-stability.md, /runtime-orchestration/turn-flow/advisor-and-thinking-lifecycle.md, /platform-services/claude-ai-limits-and-extra-usage-state.md, /tools-and-permissions/execution-and-hooks/agent-runtime-context-and-tool-shaping.md, /integrations/plugins/skill-loading-contract.md]
---

# Provider Model Mapping and Capability Gates

Claude Code keeps one canonical model catalog, but it does not send those canonical IDs directly everywhere. Each provider gets its own model strings, overrides, validation rules, and feature gates. A clean-room rebuild needs that mapping layer or user-facing model choices will not survive provider switches.

## Scope boundary

This leaf covers:

- canonical model catalog versus provider-specific runtime strings
- provider-specific model discovery and override behavior
- provider-aware validation and fallback behavior
- capability gates that depend on both model family and active provider

It intentionally does not re-document:

- the user-facing `/model`, `/fast`, and `/effort` command surface already covered in [../product-surface/model-and-behavior-controls.md](../product-surface/model-and-behavior-controls.md)
- raw provider-client auth construction already covered in [provider-specific-api-clients-and-auth-routing.md](provider-specific-api-clients-and-auth-routing.md)
- turn assembly and retry policy already covered in [../runtime-orchestration/turn-flow/api-request-assembly-retry-and-prompt-cache-stability.md](../runtime-orchestration/turn-flow/api-request-assembly-retry-and-prompt-cache-stability.md)

## One canonical catalog, many runtime IDs

Equivalent behavior should preserve one canonical internal catalog keyed by Anthropic-style model identities, with each entry mapping to provider-specific runtime IDs for:

- `firstParty`
- `bedrock`
- `vertex`
- `foundry`

The canonical catalog is the stable reasoning surface. Provider strings are the transport layer.

## Default strings depend on provider

Equivalent behavior should preserve provider-aware built-in defaults:

- first-party defaults may move to the newest family launch sooner
- third-party providers may intentionally lag those first-party defaults
- the same friendly choice such as Sonnet or Opus may therefore resolve to different runtime strings depending on provider

This is not a bug or rollout artifact. It is part of the supported contract.

## Effective capability resolution is layered

Equivalent behavior should preserve a precedence order rather than one generic
"does this model support X?" table.

That layered resolution includes:

- explicit local or operator-declared capability overrides winning over family
  heuristics when a provider has pinned one exact runtime string for a public
  tier
- explicit user posture such as a `[1m]` selection or a local hard context cap
  taking precedence for local context-window decisions
- cached live capability metadata, when the current provider and build expose
  it, being allowed to raise or lower max input or max output ceilings without
  changing the user-facing canonical model choice
- static provider-family defaults and experiment-driven expansion filling the
  gap when no stronger signal exists

Without this layering, rebuilds either ignore hard local intent or act as if a
live capability probe can overrule an explicit model selection.

## Bedrock model discovery is live and asynchronous

Bedrock has an extra discovery layer.

Equivalent behavior should preserve:

- starting from hardcoded Bedrock fallback IDs
- asynchronously discovering available system-defined Anthropic inference profiles
- replacing fallback IDs with discovered profile IDs when the canonical model substring matches
- keeping the hardcoded fallback when discovery fails or no matching profile exists
- not blocking startup on that profile fetch

A rebuild that requires discovery to finish before any model resolution will change startup behavior.

## Third-party capability support can be operator-declared per pinned tier

Equivalent behavior should preserve a narrow override path for third-party
providers:

- one provider can pin exact runtime IDs for its public Opus, Sonnet, or Haiku
  defaults
- those pinned IDs can carry explicit declarations for capability classes such
  as thinking, adaptive thinking, effort, max effort, or interleaved thinking
- those declarations override the usual provider-family heuristic for that
  exact pinned tier only
- custom deployment IDs that do not match one of those pinned tiers still fall
  back to canonical-family and provider heuristics unless another stronger
  normalization signal exists

This is how a third-party operator can expose a capability earlier or later than
the generic family rule without forking the whole model catalog.

## Settings overrides target canonical IDs

Equivalent behavior should preserve model overrides keyed by canonical Anthropic IDs, not by whichever provider string happened to be active at the time.

That means:

- overrides are applied after provider defaults are chosen
- override values may be arbitrary provider-local deployment strings such as inference-profile identifiers or ARNs
- the runtime can also reverse-resolve an override value back to its canonical ID when later logic needs a family-level understanding

Without reverse resolution, allowlists and capability gates become tied to deployment strings and drift from the user-facing model semantics.

## Validation stays provider-aware

Equivalent behavior should preserve layered validation:

- empty model names fail immediately
- organization allowlists run before any live validation call
- known aliases and approved custom options are accepted without remote probing
- unknown custom strings validate through a minimal live API call against the active provider path
- cached validation results avoid repeated probe calls for the same model string

Validation is therefore not just syntax checking; it is a live provider-aware availability test.

## Allowlists narrow by family, version, and exact ID

Equivalent behavior should preserve allowlists with these semantics:

- family aliases such as `opus`, `sonnet`, or `haiku` act as wildcards only when not narrowed by more specific entries
- version-prefix entries match one release line without matching similarly named later releases
- exact model IDs match only themselves
- alias resolution happens in both directions so canonical aliases and resolved provider strings can still be compared meaningfully

This narrowing behavior matters because admins may allow a family broadly or intentionally pin users to one exact release line.

## Provider-aware fallback suggestions

Equivalent behavior should preserve provider-specific fallback messaging when a newer model is unavailable on a third-party backend.

That includes:

- suggesting an older supported Opus when a newer third-party Opus fails validation
- suggesting an older supported Sonnet when a newer third-party Sonnet fails validation
- not showing those fallback suggestions for true first-party sessions

The runtime should help the user recover within the provider they are already using, not only tell them that the chosen model was missing.

## Capability gates depend on canonical name plus provider

Equivalent behavior should preserve capability checks that depend on both:

- the canonical model family or release line
- the currently active provider

Important examples include:

- interleaved thinking
- context-management features
- structured outputs
- auto mode
- web-search compatibility

The same family name is not enough. A capability may exist on first-party and Foundry, but still be unavailable on Bedrock or Vertex.

## Context and output ceilings accept stronger live hints, but keep canonical identity

Equivalent behavior should preserve:

- explicit `[1m]` selection immediately opting into the larger local context
  posture when the chosen family supports it
- global or operator hard caps still being able to reduce that effective window
- live capability metadata, when available, being consulted before
  experiment-only expansions for max input and max output ceilings
- context-window and max-output calculations staying keyed to canonical family
  identity even when the live runtime string is an override, inference profile,
  ARN, or custom deployment identifier

The runtime therefore keeps two truths at once: one canonical identity for
product behavior and one provider-local runtime string for transport.

## Beta and header selection is also provider-aware

Equivalent behavior should preserve provider-specific beta/header choices, including:

- first-party or Foundry using one tool-search beta name
- Bedrock and Vertex using a different tool-search beta name
- some experimental betas staying first-party-only
- global prompt-cache scope remaining stricter than general feature support

Capability and header routing must agree. Advertising a feature without the matching provider header is an incomplete migration.

## Model-resolution consumers must normalize back to canonical identity

Equivalent behavior should preserve downstream consumers doing feature checks, UI descriptions, pricing hints, and compatibility logic from canonical names even when the actual request string is:

- a provider-local deployment identifier
- a Bedrock inference profile
- a custom override string
- a region-prefixed Bedrock model ID

Otherwise the same model behaves differently depending on whether it came from a built-in mapping or an override.

## Subagents and skills inherit the resolved tier, not just the family alias

Equivalent behavior should preserve:

- `inherit` reusing the parent thread's effective runtime model after any
  mode-specific remapping, rather than re-running ordinary provider defaults
- bare child aliases such as `opus`, `sonnet`, or `haiku` reusing the parent's
  exact runtime string when the parent is already on that tier
- skill-level model overrides carrying the parent's `[1m]` suffix forward only
  when the target family actually supports 1M context
- Bedrock child aliases inheriting the parent's cross-region inference-profile
  prefix so subagents stay in the same allowed region
- explicit child model strings that already encode a different region or
  provider-local runtime ID being respected instead of silently overwritten by
  parent inheritance

Without this contract, child work can downgrade to a provider default, lose 1M
posture, or jump to a different Bedrock region even though the parent never
changed tiers.

## Failure modes

- **catalog drift**: provider strings become the source of truth and the runtime loses its canonical family model
- **blocking discovery**: Bedrock startup waits for profile enumeration before any model can resolve
- **override blindness**: custom provider deployment IDs cannot be mapped back to canonical IDs, so allowlists and capability checks stop working
- **allowlist widening**: a family alias remains wildcarded even though the admin added a specific narrowing entry
- **false capability claims**: a feature gate checks only model family and ignores provider, exposing unsupported features on Bedrock or Vertex
- **fallback mismatch**: validation fails on third-party backends without suggesting the provider-appropriate older model line
