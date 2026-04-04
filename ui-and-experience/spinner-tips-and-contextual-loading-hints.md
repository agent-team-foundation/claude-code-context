---
title: "Spinner Tips and Contextual Loading Hints"
owners: []
soft_links: [/ui-and-experience/system-feedback-lines.md, /ui-and-experience/status-line-and-footer-notification-stack.md, /ui-and-experience/prompt-composer-and-queued-command-shell.md, /memory-and-context/turn-end-auto-memory-extraction.md]
---

# Spinner Tips and Contextual Loading Hints

Claude Code's spinner hint line is a small policy engine, not a static "tip of the day". It combines per-session tip history, turn-local deduping, context-derived relevance, and elapsed-time overrides so guidance appears when it is most useful without spamming the user.

## Scope boundary

This leaf covers:

- how spinner tips are selected, cooled down, and recorded across startups
- how the REPL ensures at most one tip-pick operation per completed turn
- how render-time contextual hints can temporarily override the scheduled tip
- how spinner hint rows compete with "next task" preview text

It does not re-document:

- spinner animation, teammate tree rows, or token counters
- footer notification arbitration

## Tip candidate pipeline

Equivalent behavior should preserve:

- one spinner-tip scheduler entrypoint that can be called with runtime context (theme, recently-read files, and observed shell command names)
- a global setting gate that can disable spinner tips entirely
- tip registries where each candidate provides:
  - a stable tip id
  - dynamic content generation
  - a relevance predicate
  - a cooldown measured in **startup sessions**, not wall-clock time
- optional user-defined custom tips with an override mode that can exclude built-in tips

## Cooldown and selection model

Equivalent behavior should preserve:

- persisted tip history keyed by tip id and last-shown startup index
- cooldown checks computed as `current numStartups - lastShownStartups`
- relevance filtering before cooldown filtering
- deterministic selection that favors the tip unseen for the longest number of sessions
- single-candidate and zero-candidate fast paths

## Turn-level dedup and state updates

Equivalent behavior should preserve:

- a turn-scoped guard so the tip picker runs only once per user submit cycle
- resetting that guard on new submit
- picking a tip as part of turn-end loading-state reset, not on every spinner frame
- writing selected tip text into shared app state for spinner rendering
- clearing spinner-tip state when no tip qualifies
- recording shown-tip history and analytics only when a tip was actually selected

## Render-time contextual overrides

Equivalent behavior should preserve:

- spinner hints being suppressed when a concrete "next pending task" line is available
- timeout-based contextual hints that can override scheduled tips:
  - short-running nudge for side-question workflow if the user has never used that path
  - long-running nudge to clear context when a turn runs for an unusually long time
- these overrides remaining gated by spinner-tip enablement
- hint rendering in one dim line that chooses either:
  - `Next: ...` (task preview), or
  - `Tip: ...` (scheduled or contextual hint)

## Failure modes

- **double-pick regressions**: tip selection runs twice per turn-finalization path and over-records history
- **cooldown drift**: cooldowns accidentally switch from startup-session units to time units
- **context loss**: relevance checks no longer receive read-file or shell-command context, reducing precision
- **override starvation**: long-running contextual hints never take precedence over stale scheduled tips
- **state leak**: previous tip text remains visible even after no tip qualifies for later turns
