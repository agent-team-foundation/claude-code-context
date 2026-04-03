---
title: "Background Task Summary Labels"
owners: []
soft_links: [/ui-and-experience/background-task-status-surfaces.md, /ui-and-experience/background-task-row-and-progress-semantics.md, /ui-and-experience/interaction-feedback.md, /runtime-orchestration/task-model.md]
---

# Background Task Summary Labels

Claude Code does not let each surface invent its own wording for background work. The live footer pill and the turn-duration transcript summary both compress visible background tasks through one shared label generator, then layer their own surface-specific suffixes on top. A faithful rebuild needs the same compression rules and CTA gates or the footer, transcript history, and task list will disagree about what is still running and what requires attention.

## Shared producer and surface contract

Equivalent behavior should preserve:

- one shared label generator feeding both the generic tasks footer and the turn-duration transcript summary so task nouns and remote-work terminology stay aligned
- the footer recomputing from the current visible background-task set, while the transcript summary captures the label once when the system message renders and then preserves it as historical context
- the transcript summary adding only a passive `still running` suffix to that captured label rather than reusing the footer's interactive call-to-action
- homogeneous task sets taking the specialized per-type path below instead of falling back immediately to a generic count
- mixed task-type sets collapsing to `N background task(s)` rather than attempting to concatenate unrelated task nouns into one unstable label

## Per-type compression rules

Equivalent behavior should preserve:

- local shell summaries splitting ordinary shells from monitor shells, omitting zero-count buckets, singularizing each remaining bucket independently, and joining the surviving buckets with a comma
- in-process teammate summaries counting distinct team identities rather than raw teammate rows, so multiple visible teammates from the same team still compress to one team label
- local background-agent summaries pluralizing strictly as local-agent counts
- local workflow summaries pluralizing strictly as background-workflow counts
- monitor MCP summaries pluralizing strictly as monitor counts
- dream summaries collapsing every count or phase combination into one fixed dreaming label instead of leaking touched-file counts or workflow phase into the compact summary surface
- non-planning remote-session summaries pluralizing as cloud-session counts with an open-diamond prefix
- generic remote-session summaries keeping that open-diamond prefix even though individual remote rows may render terminal icons elsewhere, because the summary pill is signaling remote work presence rather than mirroring row-level status

## Single remote-planning special case

Equivalent behavior should preserve:

- exactly one remote planning session taking over the summary contract with a dedicated planning brand instead of the generic cloud-session wording
- default planning state showing that branded label with an open diamond and no attention call-to-action
- input-required planning state keeping the open diamond but swapping in an explicit user-input-needed tail
- plan-ready planning state switching to a filled diamond plus a ready tail, so the compact summary becomes more urgent than ordinary running remote work
- only this single-session planning path specializing by phase, while multiple remote sessions or non-planning remote work always fall back to generic cloud-session counts

## CTA gating

Equivalent behavior should preserve:

- the dimmed `↓ to view` style call-to-action appearing only in the live footer, never in the turn-duration transcript snapshot
- that call-to-action appearing only when there is exactly one remote planning session and it has entered an explicit attention phase
- plain running planning sessions without an attention phase showing only the branded planning label and no CTA
- every other task mix, including single non-planning tasks, showing no CTA even when the pill is selected or the visible task count is 1

## Failure modes

- **transcript drift**: historical turn summaries change after later background tasks start or finish because the transcript label is treated as live state instead of a snapshot
- **team overcount**: teammate-only summaries count visible rows instead of distinct teams and overstate swarm breadth
- **shell-monitor collapse**: monitoring work gets hidden inside generic shell counts so users cannot tell whether the background system is executing commands or watching long-lived processes
- **remote urgency leak**: every single remote session gets a planning-style CTA even when no user action is required
- **surface wording split**: footer and transcript summarize the same task set with different nouns or icon conventions
