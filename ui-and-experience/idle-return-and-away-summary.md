---
title: "Idle Return and Away Summary"
owners: []
soft_links: [/ui-and-experience/prompt-composer-and-queued-command-shell.md, /ui-and-experience/system-feedback-lines.md, /memory-and-context/session-memory.md, /runtime-orchestration/app-state-and-input-routing.md]
---

# Idle Return and Away Summary

Claude Code has two separate "you were away" interventions in the main REPL. One runs when the user comes back and tries to submit into a large stale conversation. The other runs after the terminal has been unfocused long enough to warrant a short recap. A faithful rebuild needs both flows, because they solve different problems: one steers the user toward a fresh conversation before expensive reuse, while the other helps them re-enter an ongoing task without rereading the full transcript.

## Scope boundary

This leaf covers:

- the submit-time idle-return gate that can block, nudge, or ignore a new prompt after a long idle gap
- the persistent "don't ask again" preference and the one-shot bypass used after the user makes an explicit choice
- the blur-timer away-summary generator that appends a recap only after the session has been out of focus long enough
- the contract for how those recaps are generated, deduplicated, and canceled

It intentionally does not re-document:

- generic system-line rendering already captured in [system-feedback-lines.md](system-feedback-lines.md)
- the broader prompt shell, queue recovery, and history behavior already captured in [prompt-composer-and-queued-command-shell.md](prompt-composer-and-queued-command-shell.md)
- general session-memory upkeep beyond the specific recap input contract already captured in [session-memory.md](../memory-and-context/session-memory.md)

## Two idle interventions, not one

Equivalent behavior should preserve:

- one return-time intervention keyed to the next foreground submit after a completed turn has gone idle long enough
- one blur-time recap intervention keyed to terminal focus loss rather than to the next submit
- independent feature gating for those two mechanisms, so builds or experiments can enable one without the other
- a shared product intent: reduce wasted context reuse while making it easy to resume real in-progress work

## Submit-time idle-return gate

The return prompt is not a passive banner. It is a submit interceptor layered into the main REPL send path.

Equivalent behavior should preserve:

- one remembered timestamp for the last completed foreground query, updated when the turn really finishes and not when the user merely starts typing again
- user-canceled or still-running turns not advancing that idle baseline
- idle-return checks running only on ordinary prompt submission, not on slash commands, speculative accept flows, or empty remote-mode no-op submits
- gating by total accumulated input-token volume for the conversation rather than by message count alone
- default thresholds of 75 idle minutes and 100,000 accumulated input tokens, with environment overrides available for both thresholds
- the gate only considering conversations that have at least one previously completed query
- a one-shot skip flag so an explicit user choice can resubmit the same prompt without immediately reopening the same gate
- a persistent dismissal preference so "Don't ask me again" suppresses later idle-return interventions across sessions

## Experiment modes and thresholds

Equivalent behavior should preserve:

- one dynamic mode switch with at least `off`, `dialog`, `hint`, and `hint_v2` treatments
- `off` fully disabling idle-return nudges
- `dialog` intercepting the attempted submit and routing the user through a blocking choice surface
- `hint` and `hint_v2` using a notification-style nudge instead of blocking the submit path
- threshold checks happening before dialog or hint presentation, so small or recently active conversations never see this machinery

## Blocking dialog contract

When the dialog mode triggers, Claude Code pauses the submit rather than immediately sending it.

Equivalent behavior should preserve:

- stashing the exact pending input plus the computed idle duration into dialog-local state when the gate trips
- clearing the live prompt buffer and cursor immediately after stashing that input, so the dialog owns the next decision instead of leaving the original text active underneath it
- presenting the dialog through the shared focused-input dialog lane, with the same modal priority behavior as other high-priority blocking surfaces
- dialog copy that explains both the away duration and the current conversation size in tokens, then frames `/clear`-style restart as the cheaper and faster path for a new task
- three explicit user actions: continue in the current conversation, resend as a fresh conversation, or stop asking in the future
- cancel or Escape mapping to a fourth semantic outcome: dismiss the dialog without submitting anything

## Dialog action semantics

Equivalent behavior should preserve:

- `dismiss` restoring the stashed input into the editor and stopping there, so the user can keep editing or decide later
- `dismiss` not setting the one-shot skip flag, allowing a later submit of that same stale prompt to reopen the gate if the user has not changed course
- `continue` setting the one-shot skip flag and then resubmitting the stashed input into the existing conversation unchanged
- `clear` first resetting the foreground conversation state, conversation identifier, title helpers, and shell-tool tracking that belong to the old session, then resubmitting the same stashed input into the fresh conversation
- `never` persisting the dismissal preference before following the same resubmit path as `continue`
- the one-shot skip flag clearing again after the next completed turn, so it bypasses exactly one resubmission decision instead of permanently disabling the feature

## Non-blocking hint mode

The hint modes steer without intercepting the submit path.

Equivalent behavior should preserve:

- scheduling the hint only after a completed turn, once the conversation is idle, large enough, and the user has remained away past the idle threshold
- keeping the hint out of the way while a turn is still loading or while the conversation has not yet crossed the token threshold
- a persistent notification keyed as one logical hint instance rather than piling up repeated reminders
- two visual variants with the same meaning: a direct warning-flavored `/clear` suggestion and a softer styled variant, both emphasizing that clearing saves tokens on a likely new task
- dismissing the hint when the effect is cleaned up, when the conversation becomes active again, or when the relevant state changes enough that the hint no longer applies
- tracking whether a hint is currently shown so a later `/clear` action can be recognized as an idle-return conversion rather than as an unrelated clear

## Analytics and persistence

Equivalent behavior should preserve:

- one durable config flag recording the user's "don't ask again" decision for idle-return dialog treatment
- analytics events that distinguish at least hint display, conversion of a shown hint into `/clear`, and each dialog outcome
- analytics payloads carrying the idle duration, message volume, and accumulated input-token size of the conversation at the time of the action
- no durable state change for ordinary `continue`, `clear`, or `dismiss` choices beyond the one-shot skip used to finish the immediate interaction

## Away-summary trigger contract

The away summary is a separate focus-driven recap path, not another flavor of the idle-return dialog.

Equivalent behavior should preserve:

- a build-time feature gate plus a runtime experiment gate before any away-summary behavior activates
- terminal focus subscription driving the feature from actual focus changes rather than from prompt inactivity alone
- a five-minute blur delay before attempting summary generation
- `unknown` terminal-focus support behaving as a no-op instead of guessing whether the user is away
- mounting while already blurred immediately starting the same blur-timer logic instead of waiting for an extra focus transition
- refocus canceling any pending timer, aborting any in-flight recap generation, and clearing any deferred "generate when loading ends" state

## Away-summary generation and deduplication

Equivalent behavior should preserve:

- generating a recap only when there is transcript history to summarize
- suppressing duplicate away summaries until the user sends another real non-meta, non-compact-summary message
- if the blur timer expires during an active turn, deferring generation until that turn finishes and then generating only if the terminal is still blurred
- using a small fast model in non-streaming mode for recap generation instead of reusing the full foreground response path
- summarizing only recent transcript history, with the current build bounding that window to roughly the last 30 messages instead of replaying the full session every time
- supplementing that recent transcript window with current session-memory content so the recap can name the broader task even if the last few turns are implementation-heavy
- a recap instruction that forces short output, starts with the high-level task, then states the concrete next step, and avoids status-report or commit-recap phrasing
- recap generation running with no tools, no visible thinking, and no cache-write side effects
- silently dropping aborted, empty, or API-error recap attempts rather than surfacing a second error experience on top of the away state
- appending a dedicated `away_summary` system message only after successful recap generation

## Surface contract

Equivalent behavior should preserve:

- away summaries entering the transcript as their own dedicated system-message subtype rather than as generic assistant text
- those summaries being treated as low-drama recap context, not as warnings or errors
- idle-return dialog state participating in the same focused-dialog arbitration as other blocking REPL overlays, so it cannot half-open alongside a competing approval surface

## Failure modes

- **repeat nagging**: dialog choices do not respect the persistent dismissal flag or the one-shot skip, so the same prompt immediately triggers another idle-return interruption
- **false stale prompt**: canceled or still-running turns update the idle baseline and cause the product to act as if the user finished a turn they never actually completed
- **duplicate recap spam**: every blur event appends another away summary even though no new real user turn has happened since the last one
- **focus race leakage**: refocusing the terminal fails to abort an in-flight summary, so a stale recap lands after the user is already back and working
- **expensive recap path**: away summaries use the full transcript, tools, or a heavyweight model and turn a lightweight recap into a costly background query
- **action collapse**: `dismiss`, `continue`, and `clear` all converge to the same behavior, removing the deliberate distinction between edit-first, keep-context, and restart-fresh flows
