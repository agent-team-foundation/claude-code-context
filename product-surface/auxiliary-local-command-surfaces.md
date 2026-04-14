---
title: "Auxiliary Local Command Surfaces"
owners: []
soft_links: [/product-surface/command-dispatch-and-composition.md, /product-surface/command-execution-archetypes.md, /runtime-orchestration/state/build-profiles.md, /runtime-orchestration/turn-flow/query-loop.md, /runtime-orchestration/automation/prompt-suggestion-and-speculation.md, /integrations/plugins/plugin-management-and-marketplace-flows.md, /ui-and-experience/dialogs-and-approvals/focused-dialog-and-overlay-arbitration.md, /ui-and-experience/feedback-and-notifications/status-line-and-footer-notification-stack.md]
---

# Auxiliary Local Command Surfaces

Claude Code includes a small class of commands that are user-facing but do not behave like ordinary transcript turns. They may open a self-contained local JSX surface, execute a sidecar query without mutating the main conversation, hand off to a gated plugin-backed local experience with hidden helper steps, or run a narrow local-support action that never becomes a normal chat turn.

## Scope boundary

This leaf covers:

- local-only command surfaces that intentionally stay outside the ordinary transcript-turn contract
- quick side-question flows that reuse the current context without interrupting the main conversation
- gated experiential or celebratory commands that may bootstrap plugin or artifact state before rendering locally
- one-shot local handoff commands that open an external destination or helper surface without creating transcript content
- hidden or support-only local actions that may ship in some builds while staying outside the ordinary product promise

It intentionally does not re-document:

- the generic command catalog and dispatch order already covered in [command-dispatch-and-composition.md](command-dispatch-and-composition.md)
- the full plugin-management contract beyond the ways plugin state affects these local surfaces
- ordinary prompt-backed slash commands that simply re-enter the main query loop

## Not every slash command is a model turn

Equivalent behavior should preserve:

- some user-visible slash commands resolving to purely local or local-JSX surfaces instead of appending a normal user message and running the standard transcript query loop
- those surfaces being allowed to render modal or alternate-screen UI, perform readiness checks, or produce a local dismissal result without leaving transcript noise behind
- local-only surfaces still being first-class product commands with discoverability, help metadata, and feature gates, not ad hoc debug entrypoints

## Side-question flows preserve main-conversation continuity

Equivalent behavior should preserve a quick side-question surface with these properties:

- it can ask a focused follow-up question against the current context without consuming or rewriting the main transcript
- it uses a sidecar execution path that stays cache-safe and bounded rather than forking into an untracked free-form session
- the answer is rendered locally and dismissed locally, leaving the main prompt state and conversation continuity intact
- the surface remains subordinate to the main session: typing a new real prompt or leaving the surface should return the user to the unchanged primary conversation

The key reconstruction point is that "ask something on the side" is a distinct product affordance, not just another alias for a regular model turn.

## Gated experiential commands can depend on plugin-backed assets

Equivalent behavior should preserve:

- a feature-gated local command surface being able to appear only for specific builds, rollout windows, or user classes
- the visible command being responsible for checking that any required marketplace, plugin, skill, or local artifact prerequisites exist before the experience runs
- prerequisite repair staying local and user-visible instead of silently mutating session state in the background
- the end-user entry command remaining stable even when fulfillment requires hidden helper steps such as playback or artifact handoff

This keeps optional or seasonal experiences cleanly separable from the baseline coding runtime without making them feel like broken stubs.

## Some local commands are one-shot handoff helpers

Equivalent behavior should preserve:

- a user-visible local command being allowed to do one narrow local action such as opening a browser destination or another OS-level handoff target
- that handoff remaining explicit and user-visible instead of silently backgrounding side effects
- success and failure returning concise local confirmation text rather than creating a fake assistant turn
- these helpers staying in the same auxiliary-command family as side-question and experiential surfaces, not being misclassified as generic web or shell automation

The clean-room point is that some command names exist to bridge the user into another local or browser surface, not to run a model workflow.

## Hidden helper steps stay hidden

Equivalent behavior should preserve:

- support-only local commands remaining excluded from ordinary help and slash inventories even when they are installed
- helper steps being callable only through the parent experience or another narrow trusted path, not as public first-class surfaces
- rebuilds modeling the public experience contract rather than promoting every helper name into the product surface

The tree should capture the existence of hidden helper stages, not their implementation trivia.

## Support-only local actions can stay shipped but non-promoted

Equivalent behavior should preserve:

- some local commands existing primarily for support, diagnostics, or build-specific operator workflows rather than routine end-user discovery
- hidden support actions being allowed to produce a narrow local result without implying that the same surface must appear in help, onboarding, or SDK-visible inventories
- disabled or stubbed command names remaining explicitly non-promissory: a rebuild should not invent behavior merely because a hidden directory or registration point exists

This lets the product carry operational helper surfaces and inert stubs without collapsing them into the public compatibility contract.

## Local surfaces may still hand off to external artifacts

Equivalent behavior should preserve:

- a local experience being able to render in an alternate screen, then hand off an exported artifact to a browser or other OS-level viewer
- artifact generation, playback, and external viewing remaining one user-visible flow even when they cross several local execution steps
- prerequisite or playback failures surfacing as explicit local guidance instead of polluting the main transcript or leaving the session in a half-switched UI state

## Failure modes

- **transcript pollution**: a local side-question or experiential command writes ordinary transcript turns even though it should remain a local surface
- **gate bypass**: a gated local surface becomes reachable in builds or accounts where the parent capability should not exist
- **helper overshare**: support-only commands become visible in help, SDK bootstrap, or bridge inventories
- **fake public promise**: hidden stubs or support-only locals are rebuilt as ordinary supported commands even though the observed product kept them non-promoted
- **half-installed experience**: a plugin-backed local experience is exposed before its prerequisites can be checked or repaired coherently
- **dismissal breakage**: leaving the local surface mutates the main conversation state instead of returning the user to the unchanged primary shell

## Test Design

In the observed source, product-surface behavior is verified through command-focused integration tests and CLI-visible end-to-end checks.

Equivalent coverage should prove:

- parsing, dispatch, flag composition, and mode selection preserve the public contract for this surface
- downstream runtime, tool, and session services receive the correct shaping when this surface is used from interactive and headless entrypoints
- user-visible output, exit behavior, and help or error routing remain correct through the packaged CLI path rather than only direct module calls
