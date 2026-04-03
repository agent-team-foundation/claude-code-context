---
title: "Background Task Local Detail Metadata"
owners: []
soft_links: [/ui-and-experience/background-task-detail-dialogs.md, /ui-and-experience/background-task-row-and-progress-semantics.md, /runtime-orchestration/local-agent-task-lifecycle.md, /collaboration-and-agents/in-process-teammate-lifecycle.md]
---

# Background Task Local Detail Metadata

The local-agent and in-process-teammate detail dialogs share more than modal controls. They use a common metadata scaffold for titles, runtime stats, progress activity, prompt previews, and terminal errors, while still diverging on plan rendering and foreground controls. A faithful rebuild needs those shared sections and divergences to stay intact or users will see different diagnostics depending on which local worker type they inspect.

## Shared metadata scaffold

Equivalent behavior should preserve:

- both dialogs composing the body from up to three stacked sections in this order: running-only progress, prompt or plan context, then terminal error text
- both dialogs building the subtitle from an optional terminal-state prefix followed by elapsed time and optional token or tool counters
- terminal-state prefixes appearing only after the worker leaves `running`, mapping terminal success to a success-colored completed label, failure to an error-colored failed label, and kills to a warning-colored stopped label
- elapsed runtime subtracting paused duration through the shared elapsed-time hook and continuing to tick only while the worker is actively running
- token and tool counters preferring final result totals when available and otherwise falling back to live progress totals
- zero or missing token and tool counts staying hidden so sparse dialogs do not fill with meaningless `0 tokens` or `0 tools` noise

## Progress section semantics

Equivalent behavior should preserve:

- the `Progress` section appearing only while the worker is running and only when `recentActivities` exists with at least one item
- progress entries rendering in stored order, with the newest entry treated as the final item in the list
- older progress lines staying dimmed and using a neutral indent prefix, while the newest line remains emphasized and gains a leading chevron marker
- every progress line truncating at the end rather than wrapping into a multiline transcript block
- tool activity labels being resolved through the current tool registry rather than printed as raw serialized tool payloads

## Tool-activity naming fallback

Equivalent behavior should preserve:

- progress rendering first looking up the tool by internal name; if no matching tool exists, the dialog falling back immediately to the raw internal tool name
- known tools attempting a schema-safe parse of the recorded input and treating parse failure as an empty parsed object rather than crashing the detail view
- tool activity then asking the tool for a user-facing name from that parsed input; if the tool cannot provide one, the dialog falling back to the raw internal tool name
- when a tool can also render concise argument text, the progress line showing `UserFacingName(args)` with the renderer forced into non-verbose mode and themed output
- when the tool returns a user-facing name but no concise arguments, the progress line showing only that name
- any exception during tool-name or argument rendering degrading gracefully to the raw internal tool name instead of breaking the dialog

## Local-agent-specific composition

Equivalent behavior should preserve:

- local background-agent titles using the selected agent type when known, falling back to a generic agent label, then joining that type to the human description with a visible divider
- local background-agent titles falling back to a generic async-agent description when no human description is present
- prompt rendering for local background agents first attempting to extract an embedded plan block from the original prompt
- when a plan block exists, the dialog replacing the raw prompt preview with the structured plan renderer instead of showing both
- when no plan block exists, the dialog showing a raw prompt section capped to about 300 characters with an ellipsis
- local background-agent detail exposing stop while running when a kill callback exists, but never exposing a foreground shortcut from this dialog

## Teammate-specific composition

Equivalent behavior should preserve:

- teammate titles rendering the `@agent` handle in that teammate's assigned color and appending the shared activity summary in dimmed parentheses
- teammate prompt previews always staying in raw text form instead of attempting plan extraction
- teammate prompt previews truncating by display width at roughly 300 columns rather than by plain character count
- teammate detail exposing both stop and foreground shortcuts while running when the corresponding callbacks exist
- teammate detail reusing the same recent-activity renderer and subtitle stats contract as local background-agent detail so the two surfaces differ mainly in title, prompt handling, and foreground affordances

## Failure modes

- **raw-tool leakage**: the dialog dumps serialized tool payloads or internal schema noise instead of a readable tool name and compact args
- **newest-progress inversion**: older progress items are emphasized while the newest activity is dimmed, making the dialog feel stale while work is still running
- **stats drift**: completed workers keep showing stale live counters instead of final result totals
- **plan-preview duplication**: local background-agent detail shows both a structured plan view and the raw prompt preview for the same prompt
- **foreground affordance mismatch**: teammate detail loses its foreground action or local background-agent detail incorrectly gains one
