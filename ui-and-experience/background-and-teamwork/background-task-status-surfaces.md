---
title: "Background Task Status Surfaces"
owners: []
soft_links: [/ui-and-experience/background-and-teamwork/teammate-surfaces-and-navigation.md, /runtime-orchestration/tasks/local-agent-task-lifecycle.md, /runtime-orchestration/tasks/foregrounded-worker-steering.md, /runtime-orchestration/tasks/task-model.md, /runtime-orchestration/tasks/monitor-task-families-and-watch-lifecycle.md]
---

# Background Task Status Surfaces

Claude Code does not expose all background work through one generic footer pill. It partitions background state across a generic summary pill, a teammate pill strip, an optional coordinator panel in eligible builds, and the swarm banner. A faithful rebuild needs those surfaces to share filters, ordering, and steering state so the same worker never appears duplicated, disappears too early, or receives focus in one place while another surface points somewhere else.

## Surface partitioning and visibility

Equivalent behavior should preserve:

- the coordinator panel rendering only in eligible coordinator-style builds, below the prompt footer rather than inside the footer line itself
- coordinator rows being reserved for panel-managed `local_agent` tasks, defined as `local_agent` records whose `agentType` is not `main-session`
- one shared visible-row predicate for every coordinator consumer: filter panel-managed tasks with `evictAfter !== 0`, then sort them by `startTime`
- coordinator selection bounds being derived from that same filtered list, plus one synthetic `main` row whenever at least one visible agent row exists
- running named agents and retained viewed agents leaving `evictAfter` unset so they stay visible without a deadline
- released terminal named agents setting `evictAfter` to a future timestamp so they linger briefly before garbage collection
- explicit dismiss bypassing time-based linger by setting `evictAfter = 0`, which hides the row immediately even before the next clock-based expiry check
- the coordinator panel owning the once-per-second tick that both refreshes elapsed time and evicts rows whose `evictAfter` deadline has passed
- the generic `BackgroundTaskStatus` footer using the broader background-task filter but excluding the same panel-managed local agents whenever the coordinator panel is active, so named agents never appear in both the summary pill and the coordinator panel
- spinner-tree mode suppressing the generic footer entirely when every visible background task is an in-process teammate, because the teammate tree above already exposes that state
- the footer switching from a generic summary pill to a horizontally scrollable strip of `main` plus teammate pills whenever all visible background work is teammate-only, or whenever the user is already viewing a teammate while the spinner tree is collapsed
- both footer and panel collapsing fully when no surface has anything left to show, instead of leaving dead focus targets behind

## Ordering, identity, and naming

Equivalent behavior should preserve:

- coordinator panel rows staying chronological by agent `startTime`, so launch order remains visible
- teammate pill strips always placing `main` first and sorting teammate pills alphabetically by `identity.agentName`
- idle teammates being pushed to the end of the pill strip only when the user is not actively selecting pills, avoiding reorder-under-cursor glitches
- teammate-strip ordering remaining stable during keyboard navigation even if an agent flips between active and idle
- named local-agent rows and named-agent banners reverse-looking up `task.id` through `agentNameRegistry` to recover the human-facing agent handle
- named-agent banner text falling back to the task description when no registry entry exists, instead of showing an empty badge
- teammate pills and named-agent banners mapping stored agent colors only when the color is part of the allowed agent palette, with unknown colors degrading to neutral fallback styling
- the leader return affordance staying present as `main` whenever the teammate strip or coordinator panel is active, so steering back to the leader never requires leaving the task surface first

## Selection, steering, and actions

Equivalent behavior should preserve:

- one global `viewingAgentTaskId` driving the viewed state across coordinator rows, teammate pills, prompt routing, and banner text
- `coordinatorTaskIndex` using `-1` as a sentinel meaning the tasks footer item is selected but no coordinator row is selected yet
- the minimum selectable coordinator index becoming `0` whenever the generic tasks pill is absent, so focus never lands on an invisible summary pill
- coordinator selection clamping whenever visible rows shrink, so finished or dismissed agents do not leave the cursor past the end of the list
- up and down inside the selected tasks surface first moving within coordinator rows instead of immediately leaving the tasks surface
- down never advancing past the last visible coordinator row while that task surface is active
- left and right in teammate-strip mode cycling only within `main` plus running in-process teammates, rather than jumping to unrelated footer items
- opening the selected tasks surface branching by subtype: `main` returns to leader view, a teammate pill foregrounds that teammate, a coordinator row foregrounds that named local agent, and the generic summary pill opens the broader background-task dialog
- `x` on a selected coordinator row being context-sensitive: running rows abort the agent, terminal unviewed rows dismiss immediately, and the currently viewed row is not dismissed because `x` must still be available as ordinary typed input in the steering transcript
- dismissing a viewed named local agent also exiting transcript view back to the leader, so the UI never points at a transcript whose visible row has already been removed

## Row and pill content contract

Equivalent behavior should preserve:

- coordinator rows showing a view marker, preserved agent name, truncated activity text, running-versus-terminal iconography, elapsed time, optional token totals, optional queued follow-up count, and a stop-or-clear hint only when the row is selected but not already viewed
- elapsed time subtracting accumulated paused duration, with terminal rows freezing at their recorded end time instead of continuing to tick forever
- coordinator activity text preferring the live progress summary over the original static description so the row reflects current work rather than spawn-time intent
- row truncation reserving width for the steering handle and trailing metrics first, so the agent name remains readable in narrow terminals
- token-direction hints following recent activity state, and queued follow-up messages being called out separately from ordinary token metrics
- teammate pills using three independent cues: selection or hover inverts the pill, viewed state bolds it, and idle state dims it when it is neither selected nor actively viewed
- the generic summary pill reusing one label generator across footer and transcript-summary surfaces so shell, monitor, local-agent, workflow, dream, and remote-session terminology stays aligned
- local shell summaries splitting monitor tasks from ordinary shells instead of collapsing them into one generic count
- in-process teammate summaries counting distinct teams rather than raw teammate rows when the generic summary pill is used
- single remote planning sessions specializing their label by phase, while multi-session or non-planning remote work collapsing back to generic cloud-session counts
- the generic footer adding an explicit call-to-action only for single remote planning sessions that need user attention, rather than prompting for every background task
- the teammate pill strip retaining a keyboard hint for expanding back into the full teammate tree, so the strip and spinner tree stay two entry points into one navigation model
- a foregrounded named local agent replacing leader or team banner context with that agent's own badge text and color

## Failure modes

- **double surfacing**: the same named local agent appears in both the summary pill and the coordinator panel
- **invisible selection**: footer focus lands on a non-rendered summary-pill sentinel
- **row-order drift**: keyboard focus, viewed state, and Enter actions disagree about which worker is selected
- **premature disappearance**: a terminal named agent row vanishes before its linger window or before the user can steer back to the leader
- **stale steering affordance**: a dismissed or evicted named agent still appears foregrounded in the banner or footer
