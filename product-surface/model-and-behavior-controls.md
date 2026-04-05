---
title: "Model and Behavior Controls"
owners: []
soft_links: [/product-surface/command-surface.md, /product-surface/command-execution-archetypes.md, /platform-services/auth-config-and-policy.md, /platform-services/policy-and-managed-settings-lifecycle.md, /platform-services/settings-change-detection-and-runtime-reload.md, /ui-and-experience/voice-mode-and-hold-to-talk-dictation.md]
---

# Model and Behavior Controls

Claude Code exposes a cluster of commands that look lightweight on the surface but actually control how the runtime chooses models, budgets reasoning effort, enables premium speed paths, and styles session behavior. A faithful rebuild should treat `/model`, `/effort`, `/fast`, `/theme`, `/color`, and `/output-style` as one control plane over session and settings state, not as unrelated toggles.

## Scope boundary

This leaf covers:

- user-facing model and behavior control commands and their visible command contracts
- the model-resolution stack that decides which main model the session actually uses
- fast-mode and effort precedence rules that can override or reshape user requests
- theme, prompt-color, and output-style behavior controls that sit in the same command family

It intentionally does not re-document:

- the full command registry or family taxonomy already covered in [command-surface.md](command-surface.md)
- the full settings reload pipeline already covered in [settings-change-detection-and-runtime-reload.md](../platform-services/settings-change-detection-and-runtime-reload.md)
- deeper auth, entitlement, or policy backends beyond the ways they gate these controls

## Shared control-plane rule

Equivalent behavior should preserve:

- these commands acting as thin affordances over real session state and settings state rather than each shipping their own hidden configuration layer
- command results describing both the requested change and any automatic adjustments caused by policy, fast-mode support, billing posture, or session overrides
- some controls taking effect immediately in the live session while others intentionally defer until the next session
- behavior-control commands surfacing the effective runtime state, not merely echoing the last persisted setting

## `/model` surface and session semantics

Equivalent behavior should preserve:

- `/model` supporting three user-visible modes: inline status or info, inline set-by-name, and an interactive picker when called without arguments
- help-style arguments returning guidance for picker versus inline usage instead of opening the picker
- info-style arguments reporting the real current model
- a plan-mode session override being shown separately from the base model when one is active
- inline status also surfacing the current effort value when effort has been explicitly set
- choosing a new base model clearing any session-only model override, so the next turn does not keep an older plan-mode override alive under the hood
- `/model default` clearing the explicit base-model setting and returning to the built-in default

## Model resolution priority and runtime remapping

Equivalent behavior should preserve:

- the user-specified model setting resolving in this precedence order:
  1. session override from a live `/model`-style runtime mutation
  2. startup override such as `--model`
  3. `ANTHROPIC_MODEL`
  4. persisted settings
  5. built-in default
- built-in defaults depending on subscriber tier and provider family rather than being one fixed constant for everyone
- internal builds being allowed to pin a different default through dedicated override config
- Max and Team Premium style users defaulting to an Opus-class model, with optional merged `[1m]` behavior when that capability is enabled
- other standard users defaulting to a Sonnet-class model
- third-party providers such as Bedrock, Vertex, or Foundry being allowed to lag first-party defaults
- runtime remapping for special aliases in specific contexts, including a plan-oriented alias that becomes an Opus default in plan mode under the smaller context budget and a Haiku-oriented alias that upgrades to a Sonnet default in plan mode

## Aliases, allowlists, and custom-model validation

Equivalent behavior should preserve:

- known family aliases such as Sonnet, Opus, Haiku, and a small set of special aliases being accepted without remote validation
- `default` being treated as its own special value rather than a literal model ID
- organization model allowlists being enforced before custom validation proceeds
- allowlists supporting broad family aliases, narrowed family aliases, version-prefix matches, and exact IDs
- family aliases behaving as wildcards only when the allowlist does not also include more specific entries for that family
- custom model names being validated case-sensitively instead of being normalized through an alias parser that lowercases everything
- validation failures returning user-facing model-not-found or validation-error messaging instead of silently falling back

## 1M context gating and billing messaging

Equivalent behavior should preserve:

- Opus and Sonnet million-context variants being gated separately from ordinary aliases
- subscriber accounts needing the right extra-usage posture to access those million-context variants
- non-subscriber or pay-as-you-go style accounts being able to use those variants when the global 1M feature is not disabled
- million-context access errors surfacing as explicit command failures rather than letting the session drift into an invalid configuration
- model-selection results appending premium-billing messaging when the chosen model or chosen model plus fast-mode combination is billed as extra usage

## Fast-mode coupling

Equivalent behavior should preserve:

- fast mode being a separately gated feature rather than a generic boolean that is always available
- model changes clearing any fast-mode cooldown state before evaluating the new combination
- switching to a model that does not support fast mode automatically turning fast mode off for the live session when it was on
- that automatic fast-mode downgrade not being treated as an explicit user settings edit
- switching to a model that does support fast mode retaining fast mode when the feature is enabled, available, and already on
- model-selection results explicitly telling the user when fast mode stayed on or was forced off
- enabling fast mode from the fast-mode command being able to auto-switch the base model to the fast-capable model if the current one does not support it

## `/fast` command contract

Equivalent behavior should preserve:

- the `/fast` command disappearing entirely when the enclosing build or environment disables fast mode
- prefetch of organization fast-mode status before opening the picker so org-level disablement is known up front
- support for explicit shortcut arguments such as `on` and `off` as well as a toggle dialog
- separate tracking of user preference versus runtime availability, so fast mode can be enabled in principle but temporarily in cooldown or blocked by org state
- user-facing unavailable reasons covering unpaid accounts, org disablement, extra-usage disablement, network failures, third-party provider incompatibility, and SDK-specific restrictions
- the picker surfacing cooldown state, overload versus rate-limit reasons, reset timing, premium pricing language, and separate rate-limit posture
- canceling the picker while org policy says fast mode is unavailable forcing the live state back to off if needed
- API-side rejection and overage-side rejection being able to permanently turn off persisted fast mode when the backend proves the feature is not actually available

## `/effort` precedence and visibility

Equivalent behavior should preserve:

- `/effort` supporting explicit levels, current or status queries, help, and auto or unset clearing
- `auto` and `unset` clearing the persisted effort setting rather than storing a literal pseudo-level
- an environment override through `CLAUDE_CODE_EFFORT_LEVEL` taking precedence over the session's chosen effort at resolve time
- user-facing warning text about that environment override appearing only when it changes the effective outcome, not when the requested value already matches the override
- some effort values being persistable while others remain session-only depending on build and capability
- external users being prevented from persisting certain premium effort modes even though those modes may still be usable for the current session
- current or status output reporting the effective effort, including auto mode resolving to the model-specific default level currently in force
- the effective effort being resolved through this precedence chain:
  1. `CLAUDE_CODE_EFFORT_LEVEL`
  2. live app-state effort value
  3. model default
- unsupported `max` effort being clamped down to a supported level rather than being passed through blindly

## Model-specific effort defaults

Equivalent behavior should preserve:

- some Opus-class models defaulting to medium effort for specific subscriber tiers
- feature-flag-controlled defaults being allowed to change that recommendation for other premium tiers
- ultrathink-enabled builds defaulting effort-capable models to medium so higher-effort escalation can remain a distinct step
- internal builds being allowed to use richer default-effort overrides, including numeric internal-only effort values
- absence of an explicit effort parameter still corresponding to a higher implicit API behavior, so the visible default and the sent parameter are not the same thing

## Theme, session color, and output style controls

Equivalent behavior should preserve:

- `/theme` being a thin picker wrapper that applies the chosen theme immediately and reports dismissal cleanly
- `/color` controlling the standalone session's prompt or agent color rather than the whole team palette
- teammates being forbidden from setting their own color because their colors are assigned by the leader
- `/color` requiring an allowed palette entry and returning a concrete list on invalid input
- reset aliases such as default, reset, none, gray, or grey mapping to one persistent reset operation
- that reset using a `"default"` sentinel rather than an empty value so the reset survives session restarts
- color changes being persisted with the transcript-backed session artifact and also reflected immediately in live app state

## `/output-style` deprecation and custom-style loading

Equivalent behavior should preserve:

- the `/output-style` slash command no longer acting as the primary mutator
- that command redirecting users to `/config` or settings-file editing instead of pretending to apply a live change
- output-style changes taking effect on the next session rather than mid-turn
- custom output styles still loading from both project and user `output-styles` directories
- project-level styles overriding user-level styles when the same style name exists in both places
- frontmatter supporting human-friendly name, description, and keep-coding-instructions metadata
- description fallback being derived from markdown content when frontmatter does not provide one
- plugin-only forcing metadata on a non-plugin style being ignored with a warning instead of corrupting the style contract

## Failure modes

- **base-versus-session confusion**: the UI reports only the base model and hides the active plan-mode session override, so users cannot tell what the runtime will actually use
- **allowlist drift**: aliases, version prefixes, and exact IDs are not enforced with the same narrowing semantics as the real product
- **invalid custom fallback**: a failed custom-model validation silently falls back to another model and makes the control surface lie
- **1M false availability**: million-context variants appear selectable even when the account lacks the required extra-usage posture
- **fast-mode impossible combo**: the session keeps fast mode on for an unsupported model, or fails to auto-switch when enabling fast mode from an unsupported base model
- **effort override invisibility**: `CLAUDE_CODE_EFFORT_LEVEL` wins, but the command surface still claims the user's requested effort is active
- **state-loss on churn**: unrelated settings reload wipes a session-only effort or fast-mode nuance that should have remained live
- **teammate color leak**: swarm teammates can self-assign colors and diverge from leader-managed identity
- **output-style split-brain**: the deprecated slash command pretends to mutate the current session even though the runtime only honors output-style changes on the next launch
