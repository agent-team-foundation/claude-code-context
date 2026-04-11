---
title: "Shared Task Control Plane and Lifecycle Events"
owners: []
soft_links: [/runtime-orchestration/tasks/task-model.md, /runtime-orchestration/tasks/task-registry-and-visibility.md, /runtime-orchestration/tasks/task-output-persistence-and-streaming.md, /runtime-orchestration/tasks/background-shell-task-lifecycle.md, /runtime-orchestration/tasks/local-agent-task-lifecycle.md, /runtime-orchestration/sessions/background-main-session-lifecycle.md, /runtime-orchestration/sessions/remote-agent-restoration-and-polling.md, /integrations/clients/sdk-control-protocol.md, /tools-and-permissions/agent-and-task-control/control-plane-tools.md]
---

# Shared Task Control Plane and Lifecycle Events

Claude Code has one shared runtime layer underneath bash backgrounding, local agents, backgrounded main sessions, remote shadow tasks, workflows, and other task families. That layer does not decide what each family means, but it does decide how tasks are born, replaced, polled, stopped, evicted, and mirrored into SDK lifecycle events.

## Scope boundary

This leaf covers:

- the shared task birth contract: IDs, terminal-state rules, `notified` state, and initial output binding
- the common app-state helpers for registration, replacement, mutation, offset advancement, and terminal eviction
- the generic stop dispatch path and the rules for suppressing duplicate closeout notifications
- the typed SDK task-lifecycle event channel and its stream-ordering guarantees

It intentionally does not re-document:

- family-specific completion heuristics and summaries already captured in the task-family leaves
- task-output storage, buffering, and polling mechanics already captured in [task-output-persistence-and-streaming.md](task-output-persistence-and-streaming.md)
- file-backed team task-list CRUD and swarm queue semantics already captured outside the runtime task model

## Shared task universe versus control-plane registry

Equivalent behavior should preserve:

- a finite runtime task universe with stable family namespaces, stable terminal states, a `notified` barrier, and one canonical output binding created at task birth
- birth-time initialization of start time, zero output offset, and `notified = false` before any family-specific progress or completion logic runs
- generic runtime code treating terminality as a hard invariant, so terminal tasks no longer accept new writes, injections, or stale cleanup mutations
- the generic control-plane registry being narrower than the conceptual task universe: some families appear only behind feature gates, and some task-like runtimes may stay outside generic stop dispatch even though the UI can still represent them

## Registration and replacement semantics

Equivalent behavior should preserve:

- one shared registration path writing task records into app state
- first registration emitting exactly one `task_started` SDK event with task ID, description, coarse type, and any family-specific optional metadata such as workflow name or initial prompt
- replacement reusing the same registry slot and intentionally skipping a second start event
- replacement carrying forward user-held UI or transcript state, such as retain posture, loaded messages, queued local follow-ups, and stable ordering metadata, when a family swaps in a fresh runtime handle for the same task ID
- shared update helpers returning the same object on true no-op changes so subscribers do not re-render from meaningless task copies

## Shared poll, offset, and eviction pass

Equivalent behavior should preserve:

- one generic polling pass that owns only shared housekeeping: reading output deltas, advancing output offsets, and identifying terminal tasks that are now safe to evict
- task families owning completion detection and completion-notification payloads, so the shared poller does not invent a second terminal closeout path
- async output reads being allowed to work from a stale pre-await snapshot, but offset patches and evictions merging back against fresh state so completed, resumed, or replaced tasks are not zombified or wrongly deleted
- terminal eviction requiring both terminal status and the `notified` barrier, with family- or UI-specific grace windows still able to block actual removal
- eager eviction helpers following the same fresh-state checks as the slower poll path, because direct cleanup and background polling race the same mutable registry

## Shared stop dispatch

Equivalent behavior should preserve:

- stop-by-ID validating that a task exists, is still running, and has a registered kill handler before any family-specific stop logic runs
- generic stop dispatch calling the task family's registered kill implementation instead of re-encoding per-family shutdown rules in the caller
- shell-task stop premarking `notified` before the eventual process-exit path lands, so exit-noise closeouts do not produce a second completion notification
- direct SDK terminal emission whenever a stop or cleanup path suppresses the ordinary structured task-notification channel, so external clients still see balanced lifecycle bookends
- richer task families being free to keep their own partial-result or specialized stop summaries, but still following one clear rule for who closes the SDK lifecycle when ordinary notification is bypassed

## SDK lifecycle event channel and ordering

Equivalent behavior should preserve:

- a typed side queue for task lifecycle events instead of relying on terminal scraping alone
- shared start and progress events being drained incrementally, not delayed until the end of the whole turn
- terminal closeouts being allowed to arrive through either direct internal emitters or parsing of structured task-notification payloads, while still representing one logical task-ending event
- terminal notification parsing only yielding an SDK close event when a real terminal status is present, so statusless progress pings never get reinterpreted as completion
- headless drain order flushing queued task lifecycle events before final turn result and again before the runtime goes idle, so external clients observe start, progress, and close bookends in stable order
- session-idle events firing only after internal flush and any late task closeouts, making idle a trustworthy "turn is over" boundary for SDK consumers

## Failure modes

- **duplicate start**: replacement or background handoff re-registers a task as if it were new and emits a second `task_started`
- **stale clobber**: post-await offset or eviction writes overwrite a newer terminal or resumed task state
- **double closeout**: stop and completion paths both emit terminal notifications because `notified` was not treated as the atomic barrier
- **unsupported-stop lie**: callers report that a task was stopped even though no registered handler existed for that family
- **premature parse close**: a nonterminal task-status payload is misread as terminal and closes the task too early
- **terminal drift**: a task that already reached terminal state still accepts writes, injected prompts, or fresh progress updates

## Test Design

In the observed source, task behavior is verified through lifecycle regressions, registry-backed integration tests, and concurrency-sensitive foreground or background scenarios.

Equivalent coverage should prove:

- state transitions for launch, running, streaming, cancellation, completion, and failure remain deterministic and resettable between cases
- task registries, monitor families, shared-control events, and persisted output compose correctly across main-session and worker contexts
- users can still observe, foreground, stop, and inspect task output through the same surfaces they use in normal interactive or automated runs
