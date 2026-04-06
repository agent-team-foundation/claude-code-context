---
title: "Low-Priority Recommendation and Upsell Dialogs"
owners: []
soft_links: [/collaboration-and-agents/repl-remote-control-lifecycle.md, /integrations/plugins/lsp-plugin-and-diagnostics.md, /integrations/plugins/plugin-management-and-marketplace-flows.md, /ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md]
---

# Low-Priority Recommendation and Upsell Dialogs

Claude Code has a late-stage focused-dialog band for educational nudges, plugin recommendations, and product upsells that matter, but should lose to active work. These surfaces are not treated like permission prompts, cost acknowledgements, or idle-return interruptions. A faithful rebuild needs their shared priority rules, show-once persistence, timeout behavior, and handoff contracts, or the product will either nag users repeatedly or surface recommendations at the wrong time.

## Scope boundary

This leaf covers:

- the shared low-priority focused-dialog lane inside the REPL
- IDE onboarding, effort onboarding, remote-control first-use callout, LSP recommendation, generic plugin hint, and desktop upsell behavior
- the shared recommendation helper used by the plugin-related dialogs
- timeout, show-once, and follow-up action contracts for those surfaces

It intentionally does not re-document:

- the deeper `/remote-control` lifecycle already covered in [../collaboration-and-agents/repl-remote-control-lifecycle.md](../collaboration-and-agents/repl-remote-control-lifecycle.md)
- the deeper LSP recommendation matching, server capability checks, and install/runtime path already covered in [../integrations/plugins/lsp-plugin-and-diagnostics.md](../integrations/plugins/lsp-plugin-and-diagnostics.md)
- generic plugin install and marketplace flows beyond the dialog handoff already covered in [../integrations/plugins/plugin-management-and-marketplace-flows.md](../integrations/plugins/plugin-management-and-marketplace-flows.md)
- higher-priority approvals, permission dialogs, idle-return prompts, and cost acknowledgements already covered elsewhere in `ui-and-experience/`

## Shared low-priority dialog lane

Equivalent behavior should preserve:

- one shared `focusedInputDialog` selector deciding whether any low-priority dialog is allowed to mount at all
- these dialogs only competing after higher-priority surfaces such as message selection, permission prompts, ask-user prompts, worker permission prompts, elicitation, cost acknowledgement, idle-return, and remote-planning launch choices have had their chance
- prompt typing suppressing this whole band, so low-priority dialogs do not steal focus from an actively composing user
- the low-priority band still respecting the shared `allowDialogsWithAnimation` gate, so tool-owned animation surfaces can block or allow dialog mounting consistently with the rest of the REPL
- only one low-priority dialog being mounted at a time, with later candidates waiting behind the current winner instead of rendering concurrently
- a stable ordering in the shipped external build: IDE onboarding first, then effort onboarding, then remote-control first use, then LSP recommendation, then generic plugin hint, and finally desktop upsell
- reserved positions for internal-only model-switch and public-repo redaction explainers ahead of effort onboarding, while external builds compile those slots away and effectively skip them

## Shared plugin-recommendation helper

Equivalent behavior should preserve:

- one reusable async recommendation helper shared by the LSP and generic plugin-hint dialogs rather than each hook inventing its own visibility and in-flight rules
- recommendation resolution refusing to start while a remote session is active, while another recommendation is already visible, or while a previous recommendation lookup is still in flight
- clearing a shown recommendation reopening the lane for later recommendation sources instead of wedging the shared helper permanently
- install flows for both recommendation types reusing one shared success and failure notification helper
- successful install notifications using immediate, high-visibility feedback and explicitly telling the user that a restart is required to apply the plugin

## IDE onboarding dialog

Equivalent behavior should preserve:

- IDE onboarding being requested by the IDE integration bootstrap only after a supported IDE path is detected or an extension install succeeds, rather than appearing as an unconditional startup tip
- once requested, the actual welcome card still entering through the same low-priority dialog lane as the other dialogs in this leaf
- the shown bit being keyed by terminal identity, so one terminal integration can show onboarding without suppressing every other terminal family forever
- marking the dialog as shown as soon as it renders, not after explicit confirmation
- Enter and Escape both dismissing the card cleanly
- the dialog adapting its wording between "plugin" and "extension" for JetBrains versus non-JetBrains IDEs
- the subtitle including the installed IDE integration version when that information is available
- the copy teaching the concrete IDE benefits Claude Code expects from this integration: open-file context, selected-line context, diff review in the IDE, quick launch, and shortcut-based file or line mentioning

## Effort onboarding callout

Equivalent behavior should preserve:

- effort onboarding only targeting Opus 4.6 sessions rather than every model
- a one-time v2 dismissal bit suppressing repeat display across sessions
- brand-new users and permanently out-of-scope audiences being auto-marked as dismissed so they are not reconsidered forever
- Pro users skipping the v2 callout if they already saw the older v1 effort dialog, while Max and Team users remain controlled by the newer rollout config
- the dialog marking its v2 dismissal bit on mount, so even a passive dismissal or timeout still counts as "shown once"
- a thirty-second auto-dismiss path that behaves like a dismiss rather than like a settings change
- selecting an effort level both updating persisted user settings and updating the current REPL session state
- choosing the model's default effort clearing back to an implicit default instead of persisting a redundant explicit value

## Remote-control first-use callout

Equivalent behavior should preserve:

- this callout not being a passive startup upsell; it only enters the dialog lane when `/remote-control` preflight decides the first-use explainer should intercept the command
- eligibility requiring an unseen state, bridge support, and a valid Claude.ai OAuth access token before the callout can be armed
- the command path recording the requested bridge session name before setting the callout-visible flag, so later consent can still connect with that original intent
- once armed, the callout waiting its turn in the shared low-priority lane rather than bypassing focus arbitration
- the dialog marking itself seen on mount, so dismissal still counts as having consumed the one-time explainer
- `enable` immediately flipping the session into explicit bridge-enabled mode for the current REPL session by setting the same bridge state fields that ordinary command activation uses
- `dismiss` only clearing the dialog, leaving the deeper `/remote-control` lifecycle and later explicit command use intact

## LSP recommendation dialog

This leaf covers only the surface contract. Matching and installability rules live in [../integrations/plugins/lsp-plugin-and-diagnostics.md](../integrations/plugins/lsp-plugin-and-diagnostics.md).

Equivalent behavior should preserve:

- at most one LSP recommendation surfacing per session, even if many tracked files would qualify
- only newly tracked files being checked, so the recommendation hook does not rescan the same file paths every render
- the chosen dialog, when it exists, coming from the already-ranked marketplace match list rather than rerunning UI-local ranking logic
- a thirty-second auto-dismiss path that feeds the same `no` response channel as a manual decline
- timeout detection using elapsed wall time, so only near-timeout dismissals increment the ignored counter that can eventually disable the feature globally
- `never` blacklisting only this plugin, while `disable` turns off all future LSP recommendations globally
- `yes` both installing the plugin and enabling it in user settings so the plugin will actually load after restart

## Generic plugin-hint dialog

Equivalent behavior should preserve:

- this dialog being driven by pending `<claude-code-hint />` plugin hints emitted on CLI or SDK stderr, not by file-edit heuristics
- synchronous hint capture already filtering out unsupported, already-shown, already-installed, policy-blocked, and non-official-marketplace plugins before the UI hook does its async marketplace lookup
- official marketplace filtering being hardcoded in the current v1 path
- the async resolver only clearing the global pending-hint slot if that slot still holds the same hint it just resolved, so a newer hint is not accidentally clobbered
- show-once persistence for a plugin being written when the user-facing dialog receives a response, not at raw hint-detection time, so blocked dialogs do not consume the one-shot budget prematurely
- a thirty-second auto-dismiss path resolving as `no`
- `disable` muting all future plugin-install hints, not just the current plugin
- `yes` installing from marketplace in user scope using the hint trigger path

## Desktop upsell startup dialog

Equivalent behavior should preserve:

- desktop upsell being the lowest-priority dialog in this whole band
- platform gating limiting the startup prompt to supported desktop environments instead of showing an impossible handoff everywhere
- a dynamic-config gate controlling whether the startup dialog is active at all
- two separate persistence controls: a dismiss-forever bit and a capped seen-count budget
- the dialog incrementing its seen count on mount and logging that show event even if the user closes it immediately
- a hard cap of three startup impressions before the dialog suppresses itself permanently
- `try` transitioning into the desktop handoff subflow instead of merely closing the dialog
- `not now` simply closing the current dialog without any durable dismissal
- `never` persisting the permanent dismissal bit before closing

## Failure modes

- **priority inversion**: a low-priority recommendation or upsell steals focus ahead of permissions, prompts, or other blocking decisions
- **repeat nagging**: show-once dialogs only write their persistence after explicit confirmation, so dismissals or timeouts cause the same surface to reappear every launch
- **remote intercept loss**: the first-use remote callout fails to preserve the requested session name or flips bridge state through a separate code path that drifts from `/remote-control`
- **timeout misclassification**: every decline is treated like a timeout, inflating ignore counters and prematurely disabling LSP recommendations
- **stale hint clobbering**: resolving one pending plugin hint clears a newer hint that arrived while the first marketplace lookup was still in flight
- **dead-end install success**: a recommendation reports success but fails to enable or register the plugin for the next startup
- **impossible upsell**: desktop or remote callouts surface on unsupported or unauthenticated sessions where the recommended action cannot succeed
