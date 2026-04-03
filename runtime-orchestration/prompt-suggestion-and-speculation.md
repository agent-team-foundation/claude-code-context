---
title: "Prompt Suggestion and Speculation"
owners: []
soft_links: [/runtime-orchestration/query-loop.md, /runtime-orchestration/foregrounded-worker-steering.md, /ui-and-experience/interaction-feedback.md, /tools-and-permissions/permission-model.md]
---

# Prompt Suggestion and Speculation

Claude Code treats next-prompt suggestion as a leader-only sidecar, not as ordinary autocomplete. When enabled, the runtime may also speculatively execute the suggested follow-up in an isolated fork so acceptance can inject already-computed results. A faithful rebuild needs both halves of that contract: conservative eligibility and filtering on the front end, plus a tightly sandboxed overlay execution path that fails open back to the normal query loop.

## Eligibility and suppression

Equivalent behavior should preserve:

- prompt suggestion enablement being decided before session state initialization from a layered gate: explicit env override first, then feature flag, then interactive-session requirement, then teammate exclusion, and finally the persisted user setting
- suggestions being disabled for non-interactive sessions, print or SDK-style flows, and swarm teammates so only the leader can surface them
- generation being attempted only from the main interactive query path, not from arbitrary worker or auxiliary hooks
- suppression when the generation request has already been aborted, when the conversation is still too early to infer a next step, or when the latest assistant turn is an API-error message
- suppression when the parent turn is too cache-expensive to fork safely, based on a budget that includes uncached parent input plus output replay cost
- runtime suppression when permission prompts, sandbox prompts, or other elicitation queues are active, so a speculative suggestion never competes with a pending approval decision
- suppression in plan mode and under external-user rate limiting, because both states make a confident next-input guess misleading or unusable
- worker transcript foregrounding not surfacing leader suggestions even if one already exists in app state, because suggestion ownership stays with the leader context

## Suggestion generation and filtering

Equivalent behavior should preserve:

- suggestion generation using a forked agent with one synthetic "predict the user's natural next input" prompt instead of asking the main model thread directly
- the fork reusing the parent's cache-safe envelope as closely as possible, skipping transcript writes and cache writes, and denying all tools rather than changing model or effort parameters that would bust cache sharing
- extraction of the suggestion from the first non-empty assistant text produced by that fork, while also retaining the generation request ID for later telemetry joins
- storage of the raw candidate in app state as `promptSuggestion` with `shownAt = 0` and `acceptedAt = 0`, so visibility and acceptance are tracked separately from generation
- rejection of empty or meta-output suggestions, including model restatements of "stay silent" style instructions, wrapped meta comments, bare error strings, or label-prefixed outputs
- rejection of suggestions that are too short, too long, multi-sentence, visibly formatted, evaluative, or phrased in assistant voice instead of user voice
- allowance for slash commands and a small hand-picked set of single-word affirmative or action commands, while still rejecting arbitrary one-word filler
- speculation starting immediately after a valid suggestion is produced when speculation is globally enabled, instead of waiting for the user to accept it first

## Display and acceptance semantics

Equivalent behavior should preserve:

- the prompt-suggestion hook exposing suggestion text only while the assistant is idle and the visible input buffer is empty
- actual display being further gated on prompt mode, absence of typeahead suggestions, and leader view, so the suggestion behaves like an empty-input affordance rather than competing with richer completions
- the first real render of a suggestion stamping `shownAt` once, while separately remembering whether the terminal was focused when it appeared
- tracking of the first user keystroke after display so telemetry can distinguish glance-and-accept from hesitation or ignore behavior
- suggestions that were generated but never became renderable in leader view being logged as timing-suppressed and cleared instead of lingering invisibly in state
- any ordinary user typing aborting both an in-flight suggestion-generation request and any active speculation, because the user has already chosen a different path
- right-arrow or Tab on an empty input accepting the visible prompt suggestion when no higher-priority autocomplete surface is active
- Enter accepting the suggestion when the input is empty or already equals the suggested text, unless images are attached or a worker transcript is currently foregrounded
- acceptance logging distinguishing Tab versus Enter, measuring time-to-accept or time-to-ignore, and recording focus state plus first-keystroke timing

## Speculation execution envelope

Equivalent behavior should preserve:

- speculation being separately gated from suggestion generation and enabled only for the ant-style build plus a user-configurable speculation toggle
- starting a new speculation run aborting any previous active speculation first, so only one overlay fork is ever authoritative
- each speculation run owning a unique overlay directory under a temp-root path keyed by process and short speculation ID
- active speculation state carrying an abort handle, shared message buffer, set of overlay-written paths, completion boundary, tool-use count, saved context reference, and optional pipelined next suggestion
- speculation using a forked agent with the suggested text as synthetic user input, a bounded turn count, and a bounded message buffer so it cannot drift into an unbounded background simulation
- write-capable tools being limited to a small explicit set, with speculation stopping at the first edit boundary unless the current permission mode would already auto-accept edits
- read-only file tools being allowed under a separate allowlist, while all other tools default to an explicit denied-tool boundary
- bash being allowed only when it passes the same read-only validation used elsewhere, so speculation never executes mutating shell commands or directory-changing flows
- writes outside the current working root being denied outright, while reads outside the root remain possible without rewriting so speculation can still inspect referenced external paths
- copy-on-write overlay handling for in-root file edits: create an overlay copy before the first speculative write, redirect later reads of those same files to the overlay, and keep untouched reads pointed at the main workspace
- speculation boundaries being recorded as `complete`, `edit`, `bash`, or denied-tool checkpoints so acceptance can later decide whether a normal follow-up query is still required

## Acceptance, injection, and pipelining

Equivalent behavior should preserve:

- accepting speculation injecting the user's accepted prompt into the visible transcript immediately, before any async overlay-copy or cleanup work finishes
- acceptance stripping incomplete tool pairs, thinking blocks, interruption markers, and whitespace-only leftovers from speculative messages before they are merged into the real transcript
- incomplete speculation truncating trailing assistant output so any fallback normal query still ends on a user message instead of illegal assistant prefill
- overlay file changes being copied back into the main workspace only for the set of paths the speculation run actually wrote
- successful acceptance updating cumulative session time-saved accounting and, when any time was saved, appending a transcript-side speculation-accept event instead of exposing the whole speculative fork transcript as durable history
- ant-only feedback messages being synthesized from accepted speculative work so the user can see tools, token count, and saved time without exposing the hidden fork directly
- extracted read-file cache state from accepted speculative messages being merged back into the main read cache, so later turns inherit the same read knowledge the fork already acquired
- fully completed speculation promoting its precomputed pipelined next suggestion into the visible prompt-suggestion slot and immediately starting a new speculation run against the augmented accepted transcript
- incomplete or failed acceptance falling back to the normal query path with `queryRequired = true`, rather than swallowing the user's accepted input

## Abort, cleanup, and telemetry

Equivalent behavior should preserve:

- explicit abort on typing or idle Escape clearing speculation state, deleting the overlay best-effort, and logging the run as user-aborted instead of as an execution failure
- task-state changes or suggestion resets being allowed to abort speculation proactively when later output would otherwise reference stale state
- overlay cleanup remaining best-effort and non-blocking even when deletion fails
- speculation analytics recording outcome, duration, suggestion length, executed-tool count, completion-boundary type, and relevant detail about the stop point
- acceptance-path errors being logged but treated as fail-open events, with the system resetting speculation state and processing the user's message through the ordinary query loop

## Failure modes

- **cache bust regression**: forked suggestion generation changes parent cache-key parameters and turns a cheap sidecar into an expensive extra model pass
- **leader or worker bleed**: a teammate or foregrounded worker sees and accepts a leader-context suggestion
- **unsafe speculative mutation**: a mutating bash command or out-of-root write executes during speculation instead of stopping at a boundary
- **hidden stale suggestion**: a generated suggestion never becomes renderable but remains in state and later appears out of context
- **speculation dead-end**: incomplete speculative output is injected without trimming, leaving the fallback query path with an invalid assistant-ended transcript
