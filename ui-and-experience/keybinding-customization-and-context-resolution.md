---
title: "Keybinding Customization and Context Resolution"
owners: []
soft_links: [/product-surface/command-surface.md, /ui-and-experience/terminal-ui.md, /ui-and-experience/interaction-feedback.md]
---

# Keybinding Customization and Context Resolution

Claude Code's keybinding system is not just a static shortcut table. A faithful rebuild needs the full loop: a gated `/keybindings` entry point, an editable JSON contract at `~/.claude/keybindings.json`, default-plus-user merge rules, validation and warning surfacing, hot reload, context-priority resolution, and a chord interceptor that claims multi-step shortcuts before text inputs can accidentally consume the second key.

## Scope boundary

This leaf covers the customization and runtime-resolution system for keyboard shortcuts, from the `/keybindings` command through action dispatch and warning surfaces.

It intentionally does not cover:

- the entire slash-command catalog already summarized in [command-surface.md](../product-surface/command-surface.md)
- broader terminal composition already summarized in [terminal-ui.md](terminal-ui.md)
- the full `/doctor` screen beyond the keybinding-specific warning surfaces
- the full voice or speech pipeline beyond the binding constraints that affect `voice:pushToTalk`

## Entry point and availability

Equivalent behavior should preserve:

- a dedicated `/keybindings` command that exists as a discoverable product-surface affordance rather than a hidden config file convention
- the command only being enabled when the keybinding-customization release gate is on, with disabled users falling back to built-in defaults and no editable customization path
- direct command execution returning a preview-style "not enabled" message instead of failing if the gate is off
- the command resolving the config path as `~/.claude/keybindings.json`
- creating the parent config directory before writing the file
- first-write behavior using exclusive create semantics so an existing file is never silently overwritten
- opening the file in the user's editor whether it was newly created or already present
- command responses distinguishing between "created and opened" versus "opened existing file"

## User-facing configuration contract

Equivalent behavior should preserve:

- one JSON object wrapper rather than a bare array
- optional metadata keys such as `$schema` and `$docs` being allowed alongside the actual bindings payload
- the real payload living under a top-level `bindings` array
- each array element being a block with one `context` string and one `bindings` object
- each `bindings` object mapping keystroke strings such as `ctrl+k`, `shift+tab`, or multi-step chords such as `ctrl+x ctrl+e` to either a built-in action identifier, a `command:<name>` slash-command binding, or `null` for explicit unbind
- validation treating missing wrapper structure or malformed blocks as config errors while still falling back to defaults

## Supported versus internal contexts

Equivalent behavior should preserve:

- a public, validated context list for user configuration rather than exposing every internal handler context
- public contexts covering the major terminal surfaces such as `Global`, `Chat`, `Autocomplete`, `Confirmation`, `Help`, `Transcript`, `HistorySearch`, `Task`, `ThemePicker`, `Settings`, `Tabs`, `Attachments`, `Footer`, `MessageSelector`, `DiffDialog`, `ModelPicker`, `Select`, and `Plugin`
- internal runtime contexts continuing to exist even when they are not accepted by the user-facing schema
- internal-only contexts such as `Scroll` or feature-gated `MessageActions` participating in runtime dispatch without becoming part of the stable customization contract
- command authors and UI builders registering the right active context at mount time so local bindings can outrank `Global`

## Default catalog and merge semantics

Equivalent behavior should preserve:

- a built-in default binding catalog being parsed first and treated as the baseline behavior of the product
- that catalog being dynamic rather than hardcoded once forever: some defaults change by platform, terminal capability, or feature flag
- examples of dynamic defaults including image-paste keys varying by platform and mode-cycle keys varying by Windows VT-mode support
- feature-gated defaults still participating in the same keybinding pipeline instead of bypassing it
- user-defined bindings being parsed into the same flattened binding structure as defaults
- merged bindings being ordered as defaults first and user entries last so later entries win
- explicit `null` overrides being preserved in the merged list so users can shadow a default without reassigning a replacement key
- that same last-write-wins rule applying to single keys and full chords, not only to simple one-stroke bindings
- template generation starting from the default catalog but filtering out non-rebindable shortcuts so the generated starter file is valid by default

## Parsing and validation rules

Equivalent behavior should preserve:

- keystroke parsing supporting modifier aliases such as `ctrl` or `control`, `alt` or `opt` or `option`, and `cmd` or `command` or `super` or `win`
- key-name normalization for aliases like `esc`, `return`, `space`, and arrow glyphs
- chord parsing treating whitespace as step separators, except for a lone literal space key
- structure validation rejecting non-array `bindings` payloads, missing `context`, missing `bindings`, or non-string-or-null actions
- context validation rejecting unknown user-configurable contexts even if other internal contexts exist in code
- command bindings being syntactically limited to `command:` names that only use alphanumerics, colons, hyphens, and underscores
- command bindings being warned into the `Chat` context only, because they behave like slash commands typed into the prompt
- `voice:pushToTalk` warning against bare letter keys, since hold detection warms up slowly enough that plain letters leak into the input buffer
- raw-JSON duplicate-key detection running before normal parsing because `JSON.parse` would silently discard earlier values inside the same object
- normalized duplicate-binding warnings also running across user blocks within the same context so visually different spellings of the same shortcut still conflict
- reserved-shortcut validation catching OS, terminal, and hardcoded shortcuts that either never reach the app or are intentionally not rebindable
- the non-rebindable set including `ctrl+c`, `ctrl+d`, and `ctrl+m`
- warning deduplication preventing the same issue from being repeated multiple times for one key and context

## Loading, caching, and hot reload

Equivalent behavior should preserve:

- a synchronous load path for initial render so the app can start with resolved bindings immediately
- cached bindings and cached warnings being reused after the first successful load
- an asynchronous load path for reloads that returns both merged bindings and validation warnings together
- missing config files being treated as "use defaults" rather than an error state
- malformed or unreadable config files also falling back to defaults while retaining warning details for diagnostics
- a file watcher only being initialized when customization is actually enabled
- watcher startup first confirming that the parent config directory exists and is a directory
- add, change, and delete events all being handled
- reload notifications being emitted to subscribers after file changes
- deleting `keybindings.json` resetting the runtime back to default bindings with cleared warnings
- cleanup logic disposing the watcher and subscriptions when the app shuts down

## Provider state and context registration

Equivalent behavior should preserve:

- a top-level keybinding provider that wraps the terminal app and owns the resolved binding set
- provider state containing the merged bindings, current warnings, pending chord state, active contexts, and a registry of action handlers
- pending-chord state existing in both a ref and React state so the resolver can read the newest value synchronously while the UI still re-renders
- active contexts being tracked in a mutable set for immediate priority resolution
- components being able to register and unregister active contexts as they mount and unmount
- that registration happening in a layout-timed effect so a newly opened surface participates in input resolution immediately
- handler registration being keyed by action name and paired with a context so the runtime can dispatch a resolved action to the right mounted component

## Resolution order and propagation

Equivalent behavior should preserve:

- local hooks resolving against three ordered sources: currently active contexts, the hook's own declared context, and `Global`
- deduplication preserving first-seen order so the highest-priority context keeps precedence
- action lookup within the flattened binding list honoring last-write-wins semantics, which gives user overrides precedence over defaults
- display-text lookup for help labels or UI chrome searching in reverse order for the same reason
- context-specific bindings being able to override global ones only while their surface is active
- handler return values being able to signal fallthrough by returning `false`, allowing later handlers to process the same event when a no-op shortcut should not consume it
- non-React callers having a separate shortcut-display helper that shares the same resolved binding lookup without pulling React into the dependency graph
- both React and non-React display helpers falling back to hardcoded text only as a migration safety net and logging analytics when that fallback path is used

## Chord behavior and early interception

Equivalent behavior should preserve:

- multi-step chords being modeled as sequences of parsed keystrokes rather than ad hoc string comparisons
- a one-second chord timeout after the first step, after which the pending chord is cancelled automatically
- escape canceling a pending chord immediately
- a later invalid second key also canceling the chord instead of being reinterpreted as an unrelated standalone shortcut
- longer chord prefixes taking precedence over exact one-key matches, so the first step of a longer chord can reserve the sequence before a single-key action fires
- null-unbound chords still shadowing defaults correctly, including the case where a user disables a default multi-step chord prefix
- an early `ChordInterceptor` input handler running before child input handlers so the second step of a chord never leaks into prompt text entry
- that interceptor swallowing started chords, canceled chords, unbound matches, and completed multi-step chords
- single-keystroke matches still being handled by the normal per-hook handlers so existing input ordering and component-local behavior keep working
- chord completion dispatching through the action-handler registry so only mounted handlers in currently relevant contexts are invoked
- escape-key matching ignoring Ink's legacy meta flag quirk for escape itself
- alt and meta being treated as one logical terminal modifier during matching, while `super` remains distinct and only works on terminals that forward it

## Warning and diagnostic surfaces

Equivalent behavior should preserve:

- validation warnings being carried alongside the loaded bindings instead of being dropped after parse time
- a foreground notification summarizing the number of keybinding errors and warnings and explicitly pointing users to `/doctor`
- notification severity, color, and priority changing based on whether any errors exist
- that notification being removable when warnings clear
- a persistent `/doctor` section dedicated to keybinding configuration issues
- the `/doctor` section showing the config file location and each warning's suggestion text when available
- reloads updating the warning surfaces, not just the active binding map

## Failure modes

- **gate drift**: the `/keybindings` command appears for users who still cannot load custom bindings, or hidden users accidentally stop receiving the default catalog
- **contract mismatch**: the loader accepts internal-only contexts or bare arrays and the public configuration surface becomes impossible to validate consistently
- **override loss**: user bindings merge incorrectly, so defaults still win over later user entries or `null` unbinds fail to shadow built-in shortcuts
- **chord leakage**: the second keystroke of a chord reaches prompt input, autocomplete, or another handler before the chord resolver claims it
- **priority inversion**: a modal or focused surface fails to register its context in time and `Global` shortcuts fire when local ones should win
- **diagnostic invisibility**: parse or reserved-shortcut warnings fall back to defaults silently, leaving users with broken customizations and no `/doctor` breadcrumb
- **label drift**: UI help text keeps showing fallback shortcut labels after customization, so displayed instructions no longer match the keys that actually fire
