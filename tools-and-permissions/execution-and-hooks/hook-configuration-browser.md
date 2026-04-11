---
title: "Hook Configuration Browser"
owners: []
soft_links: [/product-surface/command-execution-archetypes.md, /product-surface/command-surface.md, /tools-and-permissions/execution-and-hooks/tool-hook-control-plane.md, /platform-services/settings-change-detection-and-runtime-reload.md, /ui-and-experience/dialogs-and-approvals/focused-dialog-and-overlay-arbitration.md]
---

# Hook Configuration Browser

Claude Code's `/hooks` surface is not another hook editor and not a transcript turn. It is an immediate local browser over the live hook catalog: supported events, matcher groupings, source provenance, plugin attribution, policy restrictions, and read-only per-hook details. A faithful rebuild needs that browsing contract to stay distinct from both hook execution internals and settings-file editing or users will either lose visibility into effective hooks or be offered edit affordances the product no longer honors.

## Scope boundary

This leaf covers:

- the `/hooks` local command as a read-only browser over the current hook configuration
- how the browser assembles event, matcher, hook-list, and hook-detail views from the live runtime and settings snapshot
- how source labels, plugin attribution, matcher metadata, and event descriptions are surfaced to the user
- how disabled-hooks and policy-restricted states replace or narrow the normal browser

It intentionally does not re-document:

- hook execution semantics, structured outputs, or lifecycle insertion points already covered in [tool-hook-control-plane.md](tool-hook-control-plane.md)
- transcript or spinner feedback during actual hook execution already covered in [../../ui-and-experience/feedback-and-notifications/hook-execution-feedback.md](../../ui-and-experience/feedback-and-notifications/hook-execution-feedback.md)
- generic command loading and lookup rules already covered in [../../product-surface/command-surface.md](../../product-surface/command-surface.md) and [../../product-surface/command-execution-archetypes.md](../../product-surface/command-execution-archetypes.md)

## Entry posture and local-only behavior

Equivalent behavior should preserve:

- `/hooks` being an immediate local JSX command rather than a prompt-backed command that re-enters the model turn loop
- the surface opening a focused local dialog stack and dismissing back into the current session instead of creating a normal user-message or assistant-turn exchange
- the command deriving its view from the current live session state, not from a static documentation table or a bundled schema snapshot
- the browser covering the broader hook-event catalog rather than only tool-execution hooks, even though many users first encounter hooks through tool events

The reconstruction-critical point is that `/hooks` is an observability and inspection surface for the effective hook system, not another way to author hook configuration inline.

## Catalog assembly and visibility

Equivalent behavior should preserve:

- the browser aggregating hooks from editable settings sources, session hooks, and registered runtime hooks such as plugin-provided hooks
- source provenance staying visible throughout the browser so users can tell whether a hook came from user, project, local, session, plugin, or built-in registration paths
- plugin-backed hooks preserving plugin attribution instead of collapsing all registered hooks into one anonymous source bucket
- tool-name matcher metadata being derived from the currently admitted tool set and extended with live MCP tool names, so matcher guidance reflects the active session rather than a hard-coded tool list
- the event list being driven from the shared hook-event metadata used elsewhere, including each event's human summary and any matcher-field description

This browser is about the effective hook graph the session can currently see, not merely about what one settings file contains.

## Hierarchical browse model

Equivalent behavior should preserve a four-level browse flow:

### 1. Event selection

- the top-level view listing supported hook events with per-event configured-hook counts when any hooks exist for that event
- each event row carrying a short summary so users can distinguish similar lifecycle points before drilling in
- events whose metadata declare no matcher dimension jumping directly to the hook list rather than forcing an empty matcher screen

### 2. Matcher selection when applicable

- events with matcher metadata opening a matcher view first
- matcher rows representing the merged effective matcher set for that event, not just one source file at a time
- matcher rows showing source badges and hook counts so users can see mixed-source matchers before drilling in
- empty matcher keys being rendered as an explicit catch-all bucket rather than disappearing
- the matcher screen also surfacing the event's longer description, including input-shape and exit-code semantics where relevant

### 3. Hook selection within one event plus matcher bucket

- the hook list showing every configured hook in the chosen bucket, regardless of whether the hook is command, prompt, agent, HTTP, session, plugin, or internal registration flavored
- each row exposing hook type plus the primary human-facing content string for that hook
- plugin-provided rows retaining plugin-name attribution instead of appearing identical to settings-backed hooks
- the same event description remaining visible here so users do not lose the event contract when they move from matcher selection into specific hooks

### 4. Read-only hook detail

- the detail screen showing event, optional matcher, hook type, source description, and plugin name when applicable
- the detail screen showing the hook's primary content field by hook kind, such as command text, prompt text, or URL
- optional status-message text being displayed as supplemental metadata rather than replacing the underlying command, prompt, or URL value
- detail rendering staying read-only even for simple command hooks

## Read-only editing boundary

Equivalent behavior should preserve:

- `/hooks` offering browsing only, with no add, edit, delete, or source-switching affordances
- the UI explicitly telling users to edit `settings.json` directly or ask Claude when they want to add, modify, or remove hooks
- the read-only posture applying because the effective hook catalog spans hook types and sources that no longer fit the old command-only editing flow
- plugin hooks, session hooks, and other runtime-registered entries remaining inspectable without pretending they can be edited in the same surface

The rebuild should not regress this surface into a half-editor that only works for one hook type and silently ignores the rest.

## Policy-restricted and disabled states

Equivalent behavior should preserve two special top-level states:

### Policy-restricted browsing

- when managed policy allows only managed hooks, the browser showing an explicit restriction banner instead of pretending user-defined hooks are still runnable
- the user, project, and local settings hook inventory being removed from the displayed settings-backed catalog in that posture
- managed-settings hooks not being re-exposed here as an editable list just because policy is active
- the banner copy making clear that the restriction comes from policy rather than from a missing config file

### Globally disabled hooks

- when `disableAllHooks` is active, `/hooks` switching from the normal event browser into an informational disabled-state dialog
- that dialog reporting how many hooks are configured but currently dormant
- the disabled view explaining user-visible consequences such as no hook commands running, no status-line hook display, and tool operations proceeding without hook validation
- the dialog distinguishing policy-driven disablement from user-configured disablement where evidence allows
- non-policy disablement still pointing the user back toward `settings.json` or Claude for re-enable guidance

These states are not cosmetic banners layered on top of the ordinary browser. They change what the command is allowed to expose and what action the user can reasonably take.

## Relationship to live settings and runtime state

Equivalent behavior should preserve:

- `/hooks` reflecting the current live settings and runtime registration state rather than requiring a full process restart before policy or hook-source changes become legible
- policy-sensitive copy and disabled-state messaging updating through the same live settings-change machinery the rest of the runtime uses
- matcher metadata staying coupled to the active tool surface, including MCP tools, so tool-related hook inspection does not drift after capability changes
- the browser remaining an observer of hook configuration, not the owner of reload, reconciliation, or hook execution

## Failure modes

- **phantom editor**: the surface exposes add, edit, or delete controls that only work for a subset of hook kinds or sources and mislead users about what changed
- **source erasure**: mixed-source hooks collapse into anonymous rows, making it impossible to tell which file or runtime registration path is responsible
- **tool-universe drift**: matcher guidance ignores live MCP tools or gated tool changes and shows a stale matcher vocabulary
- **policy lie**: disabled or managed-only hook postures still look runnable or editable from the browser
- **catalog collapse**: `/hooks` is rebuilt as a thin settings-file viewer and loses session hooks, plugin hooks, or other registered runtime entries
- **execution coupling**: the browser starts owning hook runtime semantics instead of reusing the separate hook control-plane contract

## Test Design

In the observed source, execution and hook behavior is verified through explicit state-machine regressions, queue-aware integration coverage, and real tool-invocation scenarios.

Equivalent coverage should prove:

- batching, streaming, hook admission, cancellation, and completion events preserve the sequencing guarantees documented in this leaf
- runtime context shaping, side-effect control, and hook-triggered follow-up work compose correctly with real registries, timers, and reset hooks
- the visible progress, notification, and post-tool behavior remains stable when the runtime executes tools through ordinary paths
