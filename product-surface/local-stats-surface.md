---
title: "Local Stats Surface"
owners: []
soft_links: [/product-surface/command-execution-archetypes.md, /runtime-orchestration/sessions/session-discovery-and-lite-indexing.md, /platform-services/usage-analytics-and-migrations.md, /platform-services/claude-ai-limits-and-extra-usage-state.md, /ui-and-experience/dialogs-and-approvals/focused-dialog-and-overlay-arbitration.md]
---

# Local Stats Surface

`/stats` is a local historical analytics surface over Claude Code's own transcript store. It is not the same product surface as `/usage` or `/extra-usage`, which are account, quota, and billing flows tied to Claude.ai entitlements. A faithful rebuild needs this separation because one surface answers "how have I been using Claude Code locally across sessions?" while the others answer "what is my account allowed to spend right now?"

## Scope boundary

This leaf covers:

- `/stats` as a local dialog command rather than a transcript turn
- the user-visible tabs, date ranges, keyboard affordances, and copy behavior of the stats UI
- the data contract between that UI and the local session-log aggregation layer
- the boundary between transcript-derived history and in-process runtime metrics

It intentionally does not re-document:

- shared command dispatch and local-UI execution archetypes already covered in [command-execution-archetypes.md](command-execution-archetypes.md)
- transcript discovery and session storage layout already covered in [../runtime-orchestration/sessions/session-discovery-and-lite-indexing.md](../runtime-orchestration/sessions/session-discovery-and-lite-indexing.md)
- quota, `/usage`, and `/extra-usage` state machines already covered in [../platform-services/claude-ai-limits-and-extra-usage-state.md](../platform-services/claude-ai-limits-and-extra-usage-state.md)
- startup warming, analytics sinks, and migration mechanics already covered in [../platform-services/usage-analytics-and-migrations.md](../platform-services/usage-analytics-and-migrations.md)
- generic dialog focus arbitration already covered in [../ui-and-experience/dialogs-and-approvals/focused-dialog-and-overlay-arbitration.md](../ui-and-experience/dialogs-and-approvals/focused-dialog-and-overlay-arbitration.md)

## `/stats` is a local analytics dialog, not a quota surface

Equivalent behavior should preserve:

- `/stats` opening a local JSX dialog instead of appending a user message and re-entering the main query loop
- dismissal staying local, with a compact system-style result such as a dialog-dismissed summary rather than a synthetic conversation turn
- `/stats` remaining separate from `/usage`, which opens the Usage tab inside Settings, and from `/extra-usage`, which runs an auth- and billing-sensitive action flow that may open Claude.ai pages or request admin intervention
- the important user-facing distinction that `/stats` reports historical Claude Code activity from local transcripts, while `/usage` and `/extra-usage` are entitlement and quota surfaces tied to account state

## The data source is cross-project transcript history, not just the current workspace

Equivalent behavior should preserve:

- stats aggregating across all stored project buckets, not only the current cwd or the currently open conversation
- the aggregation walking both main session transcripts and subordinate subagent transcript files from the same session store
- subordinate transcripts contributing token usage, tool-call activity, and feature-gated shot counts without becoming independent user sessions or extra session starts
- ordinary session metadata such as duration, message count, and session start time being derived from the main non-sidechain conversation stream, while synthetic model traffic stays excluded from model-usage totals
- the aggregated result including daily activity, per-model token totals, longest session, streaks, peak day, peak hour, total messages, and speculation-time-saved style rollups derived from transcript evidence rather than from a pre-authored report
- all-time stats using a persisted historical cache merged with today's still-changing live data, while narrower `7d` and `30d` ranges reprocess transcript files for the requested window instead of trusting the all-time cache blindly

## The UI preserves an all-time baseline plus filterable views

Equivalent behavior should preserve:

- the initial load suspending on all-time aggregation so the activity heatmap always represents the full known history
- a date-range cycle containing `all`, `7d`, and `30d`, with the overview heatmap remaining all-time while summary cards and charts can reflect the active range
- two top-level tabs, `Overview` and `Models`, instead of collapsing everything into one quota-like summary page
- the Overview tab surfacing favorite model, total tokens, sessions, longest session, active days, longest streak, current streak, peak hour, and a computed usage factoid
- the Models tab surfacing tokens-per-day charting plus model breakdown rather than only a single aggregate total
- keyboard affordances for dismiss, cycling date ranges, and copying a rendered ANSI snapshot to the clipboard staying first-class instead of being hidden in an external export flow

## Optional shot statistics stay feature-gated

Equivalent behavior should preserve:

- shot-distribution details appearing only when the `SHOT_STATS` build gate is enabled and the underlying transcript scan found compatible evidence
- shot counts deduplicating at the parent-session level so subordinate transcripts do not inflate the same session's shot total multiple times
- the optional Overview addendum preserving the coarse buckets (`1-shot`, `2-5 shot`, `6-10 shot`, `11+ shot`) and average-shots-per-session framing instead of presenting an unrelated histogram

## Runtime instrumentation and user-facing history must not collapse together

Equivalent behavior should preserve:

- the in-process `StatsProvider` store remaining a runtime instrumentation layer for counters, gauges, histograms, and set-cardinality values
- that instrumentation flushing a `lastSessionMetrics` snapshot on process exit without pretending those raw metrics are the same thing as the transcript-derived `/stats` history
- rebuilds not implementing `/stats` merely by exposing current-process counters, because the observed product surface is a cross-session historical view over persisted transcripts

## Failure modes

- **quota conflation**: `/stats` is rebuilt as a thin wrapper around `/usage`, erasing the boundary between local behavior analytics and account spending state
- **workspace tunnel vision**: the stats view only reports the current repo or current session instead of aggregating across the full local Claude Code session store
- **subagent skew**: subordinate transcripts are either ignored completely or double-counted as standalone sessions, distorting session counts and model totals
- **cache-range drift**: filtered ranges reuse stale all-time aggregates or the heatmap incorrectly changes with the selected range instead of preserving the observed all-time baseline
- **metrics confusion**: runtime counters flushed at exit are mistaken for the primary `/stats` backend, so the rebuilt surface loses historical transcript fidelity
- **copy regression**: the ANSI snapshot path disappears, forcing users into raw logs or external exports instead of the observed quick-copy workflow

## Test Design

In the observed source, product-surface behavior is verified through command-focused integration tests and CLI-visible end-to-end checks.

Equivalent coverage should prove:

- parsing, dispatch, flag composition, and mode selection preserve the public contract for this surface
- downstream runtime, tool, and session services receive the correct shaping when this surface is used from interactive and headless entrypoints
- user-visible output, exit behavior, and help or error routing remain correct through the packaged CLI path rather than only direct module calls
