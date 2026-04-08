---
title: "Build Profiles"
owners: []
soft_links: [/integrations/clients/client-surfaces.md, /reconstruction-guardrails/source-boundary.md, /platform-services/provider-model-mapping-and-capability-gates.md, /platform-services/startup-service-sequencing-and-capability-gates.md, /product-surface/auxiliary-local-command-surfaces.md, /runtime-orchestration/turn-flow/advisor-and-thinking-lifecycle.md, /runtime-orchestration/automation/proactive-assistant-loop-and-brief-mode.md, /ui-and-experience/shell-and-input/voice-mode-and-hold-to-talk-dictation.md, /ui-and-experience/background-and-teamwork/companion-surface.md]
---

# Build Profiles

Claude Code is not one monolithic binary with a few cosmetic experiments on
top. It is a baseline runtime surrounded by many capability families whose
presence, startup cost, command surface, and UI affordances all depend on a
layered gate stack.

## Scope boundary

This leaf covers:

- how the product distinguishes baseline behavior from optional capability
  families
- the layers of gating that shape whether a capability can exist at all versus
  merely whether it is currently active
- the registration seams a rebuild must preserve so optional families can be
  compiled in, rolled out, or withheld without destabilizing the baseline
  runtime

It intentionally does not re-document:

- provider-specific model mapping already covered in
  [../../platform-services/provider-model-mapping-and-capability-gates.md](../../platform-services/provider-model-mapping-and-capability-gates.md)
- assistant-mode runtime behavior already covered in
  [../automation/proactive-assistant-loop-and-brief-mode.md](../automation/proactive-assistant-loop-and-brief-mode.md)
- voice, companion, and other individual feature families beyond the way they
  illustrate the gating model

## One baseline runtime, many optional capability families

Reconstruction should assume:

- one core local coding runtime exists across builds
- optional capability families may be compiled out, compiled in but inactive,
  or fully active depending on layered gates
- non-public or internal-only families can materially shape architecture
  without defining the public baseline
- capability registration must be modular enough that advanced families can be
  added or removed without forking the main turn loop, tool model, or session
  model

Representative capability families include:

- persistent assistant and proactive postures
- companion or side-surface rendering
- local-only or celebratory side surfaces that stay outside the main
  transcript contract
- voice dictation and push-to-talk handling
- remote planning, review, and viewer-attached flows
- richer transcript actions and classifier-driven posture changes
- deferred-tool search, cache-editing, and other prompt-budget features
- notification or channel-style integrations

The important clean-room point is the taxonomy, not the internal flag names.

## Gating is layered, not single-source

Equivalent behavior should preserve at least five distinct gate classes:

1. **Build-time capability inclusion**
   Some families are compiled in only for certain builds. If a family is absent
   at this layer, later runtime settings, experiments, or entitlements must not
   magically resurrect it.
2. **Runtime rollout and experiment config**
   A compiled family may still be off by default, partially rolled out, or
   assigned different defaults through experiment/config services.
3. **Provider/model capability gates**
   Some behavior depends on the active provider or selected model rather than on
   product entitlement alone.
4. **Trust, auth, policy, and environment gates**
   Workspace trust, account state, managed policy, and environment selection may
   suppress or downgrade a capability even when it is otherwise compiled in.
5. **Session- and prompt-level activation**
   Some families exist only after an explicit command, startup flag, user
   setting, prompt keyword, or remote-control attachment activates them.

If a rebuild collapses these layers into one boolean flag, it will mis-handle
both public and internal-only capability families.

## Build-time gates shape code inclusion and registration

Equivalent behavior should preserve:

- build-time gates behaving as capability constants, not as ordinary runtime
  state that every render path must keep rechecking
- code paths for optional families being importable or initializable only when
  their enclosing capability exists, so unsupported builds do not pay startup
  or bundle cost for dead features
- hidden commands, startup flags, keybindings, overlays, and tool surfaces
  being admitted only when the enclosing family is actually present
- headless, interactive, and remote-capable entrypoints sharing the same
  capability envelope rather than each inventing different notions of what the
  build supports

This matters because some gates are meant to disappear whole UI branches, whole
command families, or even whole background services from certain builds.

## Runtime rollout only reshapes compiled families

Equivalent behavior should preserve:

- rollout config being able to change defaults, recommendations, or narrow
  eligibility inside a compiled family
- rollout config not being trusted to stand in for missing code paths
- feature refresh after login, logout, or managed-settings changes being able
  to update runtime availability without forcing a full restart when the family
  already exists in the current build
- cached decisions not leaking across identity or policy changes when those
  changes materially affect capability exposure

## Capability families register across several seams at once

A rebuild should preserve the fact that one optional family often touches
multiple registries together:

- startup flags and command admission
- tool catalog and permission routing
- accepted settings keys, settings descriptions, and permission-mode choices
- app-state fields and background services
- bundled skills and prompt-layer assets
- prompt-keyword attachments and turn assembly
- keybindings, overlays, notifications, and focused dialogs
- remote metadata and headless/session-state reporting

For example, a planning or assistant family is not just one hidden slash
command. It typically also changes task types, focused-dialog routing, prompt
attachments, remote metadata, and background polling behavior.

## Public reconstruction should normalize, not mirror

Equivalent public documentation should:

- describe gated capability classes and their cross-domain effects
- preserve the extension seams another implementation would need
- avoid copying internal codenames, rollout keys, or build identifiers when a
  behavior-level description is sufficient
- document internal-only families as gated branches of the architecture rather
  than pretending they never existed

## Failure modes

- **gate collapse**: build inclusion, rollout, model support, and policy are
  collapsed into one boolean and the runtime exposes impossible combinations
- **phantom capability**: runtime config claims a family is enabled even though
  the build never compiled in its command, UI, or service surface
- **registration skew**: a capability appears in one registry, such as commands
  or keybindings, but its related tool, dialog, or app-state wiring is missing
- **refresh blindness**: login or policy changes do not refresh capability
  exposure, so the session keeps stale gated behavior
- **source-mirroring drift**: internal flag names are documented instead of the
  architectural seams and user-visible consequences they control
