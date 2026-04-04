---
title: "Background Task Detail Dialogs"
owners: []
soft_links: [/ui-and-experience/background-task-status-surfaces.md, /runtime-orchestration/foregrounded-worker-steering.md, /runtime-orchestration/task-output-persistence-and-streaming.md, /runtime-orchestration/remote-agent-restoration-and-polling.md, /runtime-orchestration/review-path.md, /runtime-orchestration/resume-path.md, /runtime-orchestration/dream-task-visibility.md, /runtime-orchestration/workflow-script-runtime.md, /runtime-orchestration/monitor-task-families-and-watch-lifecycle.md]
---

# Background Task Detail Dialogs

Background-task status surfaces only tell the user that work exists. Once the user opens a task, Claude Code switches into task-type-specific detail dialogs with different controls, readback limits, and return behavior. A faithful rebuild needs the dialog stack to preserve how entry, back, stop, foreground, teleport, and disappearing tasks interact, or the same task will behave one way in the list and another way once inspected.

## Entry, return, and disappearance contract

Equivalent behavior should preserve:

- list view auto-skipping straight into detail when the caller targets a specific task or when only one selectable background task exists
- selectable detail targets using the same background-task filter as the summary surfaces while excluding any named local agent that is already foregrounded in the main transcript
- detail dialogs receiving a back action that returns to list view unless the dialog auto-skipped on mount and there are still zero or one selectable items, in which case back closes the whole modal
- auto-skip state being cleared once the user manually returns to the list, so later back presses do not keep closing unexpectedly
- detail mode watching live task state and bailing out when the selected task disappears or no longer qualifies as background work
- non-workflow tasks that disappear from detail either closing the dialog or falling back to list view according to that auto-skip provenance
- workflow detail getting a grace path so users can inspect the completed terminal state before eviction removes the task record
- list selection clamping whenever the selectable task count shrinks, so returning from detail never leaves the cursor beyond the end of the list
- detail dispatch staying type-specific: shell tasks use a shell dialog, local background agents use an async-agent dialog, in-process teammates use a teammate dialog, remote sessions use a remote-session dialog, dreams use a dream dialog, and feature-gated workflow or monitor tasks branch into their own build-only dialogs

## Shared local-task dialog conventions

Equivalent behavior should preserve:

- local task details living in focused modal overlays that consume their own key handling instead of leaking navigation back to the chat surface
- Escape and Enter participating in the shared dialog close flow, with Space added as a task-local dismissal shortcut
- Left arrow meaning "go back" only when the detail surface was opened from a list that still exists
- `x` acting as a running-only stop affordance across shell, local-agent, in-process-teammate, and dream detail dialogs
- running-only controls disappearing as soon as a task becomes terminal while the terminal record remains inspectable
- elapsed runtime subtracting paused duration where the task model tracks it and freezing at the stored end time once the task finishes
- token and tool counters preferring final result totals after completion and live progress totals while running, while zero or missing counts stay hidden
- recent-activity sections appearing only when the task is still running and there is concrete recent activity to summarize, with the newest item visually emphasized over older ones

## Local agent and teammate detail content

Equivalent behavior should preserve:

- local background-agent detail titling the dialog with the chosen agent type plus its human description instead of only a task identifier
- teammate detail titling the dialog with the teammate handle in its assigned color plus a short live activity label derived from teammate state
- local background-agent detail preferring a rendered plan view when the prompt contains an embedded plan block and only falling back to a truncated prompt preview when no such block exists
- local background-agent prompt previews capping at roughly 300 characters when no structured plan view is available
- teammate detail always showing a truncated prompt preview rather than attempting plan extraction
- teammate detail prompt previews using the same roughly-300-character cap as local background-agent previews
- both dialogs surfacing recent tool activity, prompt context, terminal error text, and runtime stats in one place
- teammate detail offering a running-only foreground action so inspection can escalate into full steering without backing out through the list
- teammate detail remaining inspectable after completion, failure, or stop instead of disappearing immediately after the worker becomes terminal

## Shell and dream inspection contract

Equivalent behavior should preserve:

- shell detail distinguishing ordinary shell work from monitor-style shell work in both the title and the command label even though they reuse the same base dialog
- shell detail reading only a bounded tail of the persisted output file rather than loading full task output into memory
- the output tail being limited to about 8 KB of disk readback and refreshed on a one-second cadence only while the shell is still running
- shell detail preserving the previously rendered output until the next tail read resolves so the pane does not flicker through a loading state every refresh
- shell output rendering only the last 10 non-empty lines from the tailed content and explicitly disclosing when the dialog is showing only part of a larger file
- shell output staying height-bounded to a compact viewport rather than trying to become a full scrollable transcript inside the modal
- dream detail behaving as a lightweight inspection surface for memory-consolidation work: it shows elapsed time, sessions under review, optional touched-file count, task status, and only the newest text-bearing turns
- dream detail filtering out tool-only turns from the visible transcript body while still showing per-turn tool-use counts beside text turns
- dream detail capping visible history to the newest 6 text-bearing turns and replacing older material with a single earlier-turn count
- dream detail showing a startup placeholder while the task is running but has not emitted text yet, and a distinct empty-state message when it ends without textual output

## Remote-session detail variants

Equivalent behavior should preserve:

- remote session detail branching three ways: ordinary remote sessions, remote planning sessions, and remote review sessions each get a different inspection and control contract
- ordinary remote-session detail staying effectively read-only aside from teleport: it shows status, runtime, truncated title, a shared progress renderer, a session URL, and a bounded recent-message view, but no in-dialog stop action even if the parent list could still stop that task
- ordinary remote-session status mapping raw pending state to a user-facing starting state instead of exposing backend terminology directly
- ordinary remote recent-message inspection normalizing the full remote log first, dropping pure progress entries, and then showing only the last 3 substantive messages so a tail full of progress chatter does not hide meaningful output
- ordinary remote detail keeping teleport as an explicit task-local action with in-dialog teleporting and error states instead of silently jumping out to another surface
- remote planning detail summarizing work in terms of current phase, agents involved, total tool calls, last meaningful tool call, and a web review link instead of raw transcript lines
- planning detail deriving "agents working" as the lead planner plus any spawned remote agents, not merely the number of tool calls
- planning detail translating certain tool calls into human-oriented summaries, especially browser-answer prompts for user questions and web-review prompts for plan-ready exits
- planning detail translating internal phase state into user-facing status words such as input-required or ready rather than dumping raw phase identifiers
- planning detail exposing stop only through a confirmation menu that makes clear the web session itself will be terminated
- remote review detail replacing the generic progress label with an explicit Setup -> Find -> Verify -> Dedupe pipeline, with Setup highlighted until the first remote progress snapshot exists
- remote review detail using the same stage-count formatter as the footer pill so found, verified, refuted, and deduping wording cannot drift between the compact and expanded surfaces
- completed remote review detail switching from a back-oriented menu to an open-or-dismiss menu, while running review detail keeps open, optional stop, and back choices
- remote review mapping terminal success to a ready state rather than showing a generic completed label
- review-stop confirmation making clear that stopping archives the remote session, halts local tracking, and discards any partial findings gathered so far
- both planning and review detail surfaces preserving the browser session link after terminal state so the web session remains a durable artifact

## Failure modes

- **auto-skip trap**: back closes the whole dialog even after multiple tasks now exist, or incorrectly returns to list when the modal should simply close
- **dead detail view**: a removed task leaves the user staring at an empty or stale detail surface instead of returning cleanly to a valid parent state
- **control mismatch**: list view and detail view disagree about which task types can be stopped, foregrounded, or teleported
- **unbounded readback**: shell or remote detail tries to load whole logs instead of bounded tails or message windows and freezes the terminal
- **review wording drift**: compact remote-review progress and full review detail disagree about stage names or count semantics
- **transcript-noise regression**: remote detail or dream detail lets progress noise or tool-only turns crowd out the newest meaningful human-readable output
