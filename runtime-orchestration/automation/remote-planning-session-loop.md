---
title: "Remote Planning Session Loop"
owners: []
soft_links: [/ui-and-experience/dialogs-and-approvals/plan-mode-approval-surfaces.md, /runtime-orchestration/sessions/remote-agent-restoration-and-polling.md, /runtime-orchestration/tasks/task-model.md, /product-surface/interaction-modes.md, /integrations/clients/direct-connect-session-bootstrap-and-environment-selection.md]
---

# Remote Planning Session Loop

The feature-gated remote-planning flow is not just a long-running remote task. It is a planning-specific remote loop that begins from a local prompt or approval surface, launches a remote plan-mode session, polls for approval artifacts, and then splits into either remote execution or local handoff.

## Trigger and prelaunch contract

Equivalent behavior should preserve:

- a bare dedicated remote-planning command acting as a usage query rather than a launch attempt
- non-empty dedicated-command invocations and keyword-triggered prompts funneling into the same launch path
- keyword detection ignoring quoted text, path-like strings, slash-command bodies, and question-style mentions so talking about the feature does not launch it
- forwarded keyword-triggered prompts rewriting the trigger word into plain planning language so the remote session does not recursively retrigger the same feature
- prelaunch UI being mounted in the focused-input dialog layer rather than as top-of-transcript content

The important contract is that the remote-planning feature begins as a live control surface, not just a slash-command text expansion.

## Singleton launch guard and immediate feedback

Equivalent behavior should preserve:

- a singleton guard that blocks launch when a remote-planning session is already active or already launching
- a synchronous `launching` latch set before any remote round-trip so duplicate clicks or repeated keyword detection cannot spawn two sessions
- an immediate local launch message so the terminal never looks hung during the multisecond remote bootstrap
- distinct "already launching" and "already polling" user messages

## Remote session bootstrap

Equivalent behavior should preserve:

- dedicated remote-agent eligibility checks before session creation
- model selection coming from feature config with a safe fallback rather than a hardcoded one-off string
- the initial remote message combining hidden scaffolding with optional seed-plan text and visible user blurb
- scaffolding deliberately avoiding the private launch keyword itself so the remote CLI's keyword detector does not self-trigger
- remote session creation running in plan mode, preferring the default cloud environment, and surfacing bundle-style launch failures separately from generic session-creation failure

This is why the feature cannot be reconstructed as "remote plan command" alone. Its bootstrap payload is feature-specific.

## Shadow-task registration and URL state

Equivalent behavior should preserve:

- storing one active session URL in app state for status surfaces and duplicate-launch protection
- registering the remote session as a local shadow task typed specifically as a remote-planning job rather than as an ordinary remote agent
- a secondary "session ready" message once the web URL exists, so the user can keep working locally while the remote planner runs
- clearing the `launching` latch on both success and failure, without clearing a newer session's URL from a stale older attempt

## Polling scanner and phase state machine

Equivalent behavior should preserve:

- a detached poll loop with a long planning timeout, bounded retry on transient network failures, and explicit caller-driven stop
- event scanning with stable precedence: approved plan beats termination, termination beats rejection, rejection beats pending, and pending beats unchanged
- three user-visible remote-planning phases derived from remote events plus session status: `running`, `plan_ready`, and `needs_input`
- `needs_input` requiring a quiet idle or requires-action state rather than any momentary idle blip in the middle of an active turn
- rejection bookkeeping that skips older rejected ExitPlanMode attempts and keeps following the newest live one

Without this classifier, the local terminal cannot tell "waiting for browser input" from "still planning" or "already approved."

## Approval artifacts and execution-target split

Equivalent behavior should preserve:

- approved plans being extracted from explicit markers in the tool result rather than guessed from ordinary assistant prose
- local-teleport approval being encoded as a sentinel-bearing rejection result that still carries the approved plan text
- ordinary rejection remaining distinct from teleport-back approval, so browser-side revision loops continue instead of prematurely ending the run
- browser approval being able to choose between two execution targets: keep executing remotely in the web session, or return the approved plan to the local terminal for execution there

## Local handoff, remote continuation, and cleanup

Equivalent behavior should preserve:

- remote-execution approval completing the local shadow task, clearing the active session URL, and notifying the user that results will arrive later as a remote artifact such as a pull request
- local-teleport approval keeping the shadow task alive long enough to mount a local choice dialog with the approved plan and session identity
- stop semantics archiving the remote session, killing the local task, clearing pending-choice and URL state, and posting both a user-visible stop notice and a meta reminder not to answer the stop notification
- unexpected errors after session creation archiving the orphaned remote session so a launched planner is not left running invisibly for the full timeout

## Failure modes

- **self-trigger recursion**: the remote prompt contains the feature keyword and relaunches itself inside the remote session
- **double launch**: the launching latch is set too late and rapid retries create multiple remote planners
- **idle false-positive**: a transient idle snapshot is treated as browser-input-needed or completion while the remote plan is still working
- **teleport misclassification**: ordinary rejection is mistaken for "send the plan back locally" because sentinel parsing is missing
- **stale cleanup**: an older failed poll clears the URL or state for a newer relaunched remote-planning session
- **orphaned planner**: local failure after bootstrap leaves the remote session running with no poller or stop path
