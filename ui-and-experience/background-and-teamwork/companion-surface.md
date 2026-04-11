---
title: "Companion Surface"
owners: []
soft_links: [/ui-and-experience/shell-and-input/prompt-composer-and-queued-command-shell.md, /ui-and-experience/feedback-and-notifications/status-line-and-footer-notification-stack.md, /runtime-orchestration/state/app-state-and-input-routing.md, /runtime-orchestration/turn-flow/turn-attachments-and-sidechannels.md, /ui-and-experience/shell-and-input/terminal-ui.md]
---

# Companion Surface

The feature-gated companion is not just a decorative sprite. It is a small persistent side-surface with deterministic identity, prompt-shell entrypoints, footer focus, notification-based discovery, reaction bubbles, and a hidden model-facing attachment that teaches the main assistant when to stay out of the companion's way.

## Deterministic identity with persisted persona

Equivalent behavior should preserve:

- a distinction between no companion, a hatched companion, and a muted companion
- only the companion's persona-like fields persisting across sessions, while visible presentation traits are regenerated from stable user identity on every read
- regeneration preventing config edits from spoofing presentation rarity or identity while still allowing stored companions to survive asset renames or roster changes
- rarity influencing visible styling and baseline stat quality without changing the shell's broader interaction model
- companion absence or mute suppressing the sprite, teaser affordances, and model-facing intro attachment together

The clean-room requirement is not the exact randomizer. It is that the visible companion remains identity-stable for one user while still being resistant to simple local config tampering.

## Entry affordances and footer integration

Equivalent behavior should preserve:

- a startup teaser notification for unhatched users during a limited rollout window, evaluated in local calendar time rather than one global UTC midnight
- teaser delivery going through the ordinary footer-notification stack with immediate priority and automatic expiry instead of a bespoke one-off renderer
- a dedicated companion keyword in the prompt receiving the same kind of distinctive trigger highlighting used by other special command keywords
- a companion footer pill appearing only when a non-muted companion exists, and participating in the same footer-selection state machine as tasks, bridge, and team pills
- activating that pill routing through ordinary prompt submission of the companion command rather than inventing a second command-dispatch path

This keeps the feature discoverable without breaking the rule that one prompt shell owns command entry.

## Sprite, bubble, and layout adaptation

Equivalent behavior should preserve:

- narrow terminals collapsing the companion into a one-line face-plus-label surface instead of trying to squeeze a full sprite and bubble into unreadable columns
- wider terminals rendering a full sprite column with a separate name row, plus an inline speech bubble only when the layout can actually afford the width
- prompt-input width being reduced only when the inline companion surface truly consumes horizontal space
- fullscreen layouts rendering the speech bubble in a floating overlay while leaving the sprite inline, so overflow clipping does not cut the bubble off
- focus state styling on the companion name row when the footer pill is selected
- idle animation, transient speaking state, reaction fade-out, and short pet-style heart bursts being represented as stateful visual phases rather than one static ASCII picture

Without this responsive split, the companion either trashes prompt layout on small terminals or becomes invisible in fullscreen where the bubble is clipped.

## Hidden model coordination and reaction pipeline

Equivalent behavior should preserve:

- a companion-intro attachment being injected only when a live, unmuted companion exists and only once per companion identity
- that attachment being transcript-invisible for the user while still becoming a hidden system-style reminder for the model
- the hidden reminder teaching the main assistant that the companion is a separate watcher and that direct user address should let the bubble answer instead of creating competing narration
- per-turn companion reactions being produced after the main query completes, then written into app state for the bubble renderer rather than printed as ordinary transcript messages
- scroll, timeout, or later updates being able to clear stale reactions without mutating the underlying companion identity

This is the load-bearing logic that makes the companion feel like a coherent participant instead of a random emoji stapled onto the prompt bar.

## Failure modes

- **rarity spoofing**: persisted config directly controls bones, letting users edit their way into a different species or rarity
- **teaser spam**: the startup teaser ignores hatch state, rollout window, or footer invalidation and keeps reappearing after it should stop
- **layout collision**: prompt width does not reserve space for the inline companion surface, so the input and bubble overlap or reflow constantly
- **bubble clipping**: fullscreen mode renders the bubble inside a clipped region and silently hides the companion's reaction text
- **assistant-companion cross-talk**: the model never receives the hidden companion intro and keeps narrating over direct companion interactions
- **mute split-brain**: the sprite disappears but the hidden companion attachment or footer affordance keeps acting as if the companion were still active

## Test Design

In the observed source, background and teamwork UI behavior is verified through state-to-view regressions, live-update integration tests, and multi-agent interaction scenarios.

Equivalent coverage should prove:

- row, detail, summary, and status-derivation logic render the same meaning from task and teammate state snapshots
- polling, mailbox updates, progress streaming, and navigation state stay coherent across live runtime changes and reset hooks between cases
- users can still follow work, inspect details, and switch teammate context through the real interactive surfaces without stale or duplicated UI state
