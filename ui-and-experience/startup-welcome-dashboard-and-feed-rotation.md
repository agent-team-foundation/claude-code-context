---
title: "Startup Welcome Dashboard and Feed Rotation"
owners: []
soft_links: [/ui-and-experience/terminal-ui.md, /ui-and-experience/system-feedback-lines.md, /ui-and-experience/interactive-setup-and-onboarding-screens.md, /product-surface/init-command-and-claude-md-setup.md, /memory-and-context/turn-end-auto-memory-extraction.md]
---

# Startup Welcome Dashboard and Feed Rotation

Claude Code's startup header is a composed dashboard with mode gating, layout adaptation, and feed arbitration. A clean-room rebuild should treat it as a small state machine, not a fixed banner.

## Scope boundary

This leaf covers:

- startup-time counters and gates that influence first render
- the welcome header's condensed vs full dashboard modes
- right-column feed selection and width normalization
- startup notice rendering adjacent to the welcome panel

It does not re-document:

- transcript-row rendering after normal conversation messages begin
- the pre-REPL onboarding and trust/setup screens that happen before this dashboard exists
- detailed release-notes fetching internals

## Startup timing contract

Equivalent behavior should preserve:

- startup-session count incremented **before** first interactive render so first-render consumers read the updated value
- logo/notices rendering as the header block at the top of the transcript region
- startup notices rendered through a separate notice registry surface, not embedded into the logo component itself

## Display-mode gating

Equivalent behavior should preserve:

- a condensed startup mode when:
  - onboarding feed is not required
  - no new release-notes payload is pending display
  - no force-full-logo override is active
- a full dashboard mode otherwise
- layout mode switching by terminal width:
  - compact layout on narrow terminals
  - horizontal split layout on wider terminals

## Welcome card composition

Equivalent behavior should preserve:

- welcome copy that optionally includes account display name
- model/billing/session-path context shown under the mark
- width-aware truncation for long path and identity strings
- supplemental startup notice bands (voice/channel/debug/sandbox/ops notices) rendered below the card

## Feed rotation and precedence

Equivalent behavior should preserve one right-column feed pair with deterministic precedence:

1. project-onboarding feed + recent-activity feed (when onboarding gate is active)
2. recent-activity feed + guest-passes feed (when eligible and onboarding is inactive)
3. recent-activity feed + overage-credit feed (when eligible, no onboarding, and guest-passes feed is not taking the slot)
4. recent-activity feed + "what's new" feed (default path)

Feed rotation here is state-driven selection between these variants, not random shuffling.

## Feed rendering contract

Equivalent behavior should preserve:

- all visible feeds in one column using a shared computed width
- feed width based on the widest required content among title, rows, timestamps, footer, or custom block width
- divider rows between feeds
- empty-state messaging for feeds with no lines
- per-line timestamp alignment using a shared timestamp column width
- text truncation to stay within computed width

## Onboarding and seen-count side effects

Equivalent behavior should preserve:

- project onboarding visibility gate that short-circuits when:
  - onboarding already completed
  - onboarding has already been shown enough times
  - demo mode suppresses it
- onboarding feed steps derived from current workspace state and CLAUDE.md presence
- onboarding seen-count incremented when onboarding feed is shown on startup
- startup render marking release notes as seen for current version

## Other startup counters

Equivalent behavior should preserve:

- company announcement selection that is deterministic on first startup and randomized thereafter
- guest-passes and overage-upsell seen counters incremented only when their feed is actually shown in full dashboard mode

## Failure modes

- **startup-order race**: `numStartups` increments after first render, causing first-render gates to use stale counters
- **mode collapse**: condensed and full dashboard branches stop honoring release-notes/onboarding gating
- **feed priority inversion**: upsell feed displaces onboarding feed when onboarding is still active
- **layout drift**: right-column feeds compute independent widths and visually jitter
- **notice coupling**: startup notices are hardcoded into logo rendering instead of coming from active notice definitions
