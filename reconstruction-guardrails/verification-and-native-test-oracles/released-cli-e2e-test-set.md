---
title: "Released CLI E2E Test Set"
owners: [bingran-you]
soft_links:
  - /integrations/clients/structured-io-and-headless-session-loop.md
  - /platform-services/workspace-trust-dialog-and-persistence.md
  - /platform-services/session-cost-accounting-and-restoration.md
  - /runtime-orchestration/sessions/resume-path.md
  - /ui-and-experience/startup-and-onboarding/startup-welcome-dashboard-and-feed-rotation.md
  - /ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md
  - /ui-and-experience/dialogs-and-approvals/structured-diff-rendering-and-highlight-fallback.md
  - /tools-and-permissions/permissions/e2e-permission-testing-contracts.md
  - /product-surface/interaction-modes.md
---

# Released CLI E2E Test Set

Source-derived contracts are still the primary clean-room evidence for this tree, but they are not enough on their own for end-to-end rebuild work. A released CLI can be exercised directly, and its public runtime behavior becomes a second kind of oracle: not hidden implementation, but what a real user actually experiences.

This leaf captures that public-runtime oracle set from a local run of the shipped `claude` CLI on April 9, 2026. The observed build reported version `2.1.89`, authenticated successfully through a Foundry-backed account, and was exercised in both headless and interactive modes on a local macOS terminal.

## Why this leaf exists

A clean-room rebuild can easily pass its own local tests while still feeling unlike the real product at the edges that matter most:

- startup and trust gating
- headless envelope shape
- stream transport behavior
- permission prompts and remembered approvals
- session durability and cwd-based resume
- the rhythm of a real coding turn that reads, edits, reruns, and summarizes

Those are all externally visible contracts. They can and should become explicit E2E test targets.

## Evidence boundary

This leaf records only public behavior that was directly observed from the shipped CLI:

- public command-line flags and subcommands
- public terminal UI flows
- files the CLI itself wrote into the local user state directory
- session recovery behavior visible through subsequent CLI invocations

It should not become a transcript dump. Keep raw logs local, and normalize them here into assertions, scenario shapes, and failure modes.

## Mandatory scenario families

### 1. Discovery and health smoke lane

A rebuild should have a fast lane that exercises the released binary surface before any deeper coding workflow:

- `--help` and `--version` must succeed and expose the current command families
- auth health should be queryable without opening the TUI, including both machine-readable and human-readable status
- agent discovery should be externally visible from a top-level command, not only from inside an interactive session
- auto-mode or policy classification should expose an inspectable effective config, not just hidden defaults

The oracle is not one exact text block. The oracle is that these are real, scriptable health surfaces with stable exit behavior.

### 2. Headless `--print` lane

The released CLI exposed several parity-critical headless behaviors:

- a minimal one-shot prompt path in `--print` mode
- a cheaper `--bare` posture that suppresses much of the normal startup enrichment
- a budget cap path where a low `--max-budget-usd` can fail before any useful assistant text arrives
- a JSON envelope path whose result contains both metadata and a human-readable `result`, not only raw assistant text
- JSON-schema validation that reports structured output separately from the human result text
- cwd-local continue behavior, where `-c` or `--continue` can answer questions about the previous turn without manually passing a session ID

Equivalent tests should explicitly cover both success and failure envelopes. A rebuild that only checks plain-text success misses one of the most important public automation surfaces.

### 3. Stream-JSON transport lane

The released CLI's stream mode proved several externally visible rules:

- `--print` plus `--output-format=stream-json` requires `--verbose`
- the stream starts with a system init event before assistant output
- a valid user input event can be supplied over stdin as JSON
- `--replay-user-messages` re-emits the incoming user event on stdout
- partial assistant events and a final result event are separate concepts
- the current release may emit extra assistant-side content blocks in verbose stream mode beyond the final plain-text answer

The important rebuild rule is not to hardcode today's exact event inventory. It is to make the wire contract explicit and testable:

- init handshake
- per-event framing
- replay behavior
- partial-versus-final separation
- predictable error handling for malformed input

### 4. Interactive startup and trust lane

A fresh interactive session in a new local workspace did not drop straight into a plain prompt. It first asked the user whether the folder was trusted, then entered a richer startup dashboard with project identity, tips, and recent-session context.

Equivalent tests should protect:

- first-entry trust gating for an unapproved workspace
- persistence of that trust decision for later launches
- a startup dashboard rather than a bare REPL prompt
- a discoverable shortcut overlay
- predictable terminal-exit handling, including the observed double-`Ctrl-C` confirmation flow

If a rebuild only tests a plain line editor, it will miss the public startup contract users feel first.

### 5. Permissioned coding lane

The most important real-work oracle was a tiny bugfix session in a temporary git workspace:

- the assistant proposed a shell command to run tests and triggered a permission prompt
- the failing test output was summarized in the UI instead of dumping the entire log at full height
- file reads surfaced as small activity summaries
- an edit proposal rendered as a diff preview and required a separate approval
- remembered approval was scoped to the specific operation class, not globally to every later tool action
- after the edit, the assistant reran tests, observed success, and gave a short root-cause explanation

This lane matters more than many synthetic tool-loop tests because it captures the actual rhythm a coding user depends on:

- inspect
- execute
- approve
- edit
- verify
- summarize

### 6. Durable artifact and resume lane

The released CLI wrote per-project state under `~/.claude/projects/...`, using a sanitized project-path key. The durable transcript for the interactive session was stored as JSONL and included at least these user-visible event families:

- user turns
- assistant tool requests
- tool results
- edit records with structured patch information
- final assistant text

Two subtle but important persistence facts also showed up:

- `--no-session-persistence` still created the project-scoped directory and memory folder, even though it did not create a normal session transcript
- cwd-based continue could recover the last session's context without an explicit session ID

A rebuild should therefore test both positive persistence and negative persistence. "No session persistence" is not the same thing as "zero filesystem side effects."

## Current clean-room gap check

The current Python rebuild already protects several useful local lanes:

- local interactive prompt loop and slash commands
- prompt history and explicit session resume by ID
- structured NDJSON request-response control flow
- scenario goldens for review, init, tool loops, permission probes, and compaction
- basic interactive approval prompting

That is a strong local foundation. It is not yet the same thing as released-CLI E2E parity.

### Capability gaps still visible

The shipped CLI behaviors above imply product areas that the current rebuild does not yet expose as first-class runtime surfaces:

- trust gate and trust persistence
- startup dashboard and richer terminal startup shell
- public auth, doctor, plugin, MCP, install, update, and auto-mode command families
- released-style headless `--print` flag matrix and envelopes
- public cwd-based `--continue` / `--resume` entrypoint routing
- richer approval dialogs with remembered decisions scoped by tool or command class

Those are implementation gaps, not merely missing assertions.

### Test gaps even where adjacent features already exist

Even in the areas the rebuild has started, the following cases remain under-protected relative to the released CLI:

- headless budget-cap failure envelopes
- successful schema validation in the public CLI envelope shape, not only in an internal structured server response
- `--output-format=stream-json` gating on `--verbose`
- replayed user-message echoes and partial assistant events in stream mode
- negative persistence semantics for `--no-session-persistence`
- cwd-based continue after a prior coding turn
- remembered approval scopes for shell commands versus edit approvals
- deny-path behavior for shell or edit approvals in the same real-work session
- durable session-artifact assertions that inspect the stored transcript shape, not only in-memory summaries
- non-TTY behavior for commands that actually require raw terminal capabilities

These should become explicit parity tests before claiming a rebuild feels end-to-end correct.

## Reconstruction rule

Use this leaf as the public-runtime complement to the source-derived verification leaves:

- source-derived leaves explain what the product architecture must preserve
- this leaf explains what a shipped build actually feels like when exercised end to end

A faithful rebuild should keep both. If they disagree, prefer the narrower claim and investigate. Public-runtime behavior is excellent for E2E oracles, but it does not by itself reveal why the product was built that way.

## Failure modes

- **headless false confidence**: the rebuild passes local JSON tests but its public envelope and error modes do not match a released CLI
- **transport simplification drift**: stream mode works only for a request-response lab client and not for real event-stream consumers
- **startup flattening**: the rebuild starts in a bare prompt and skips trust, dashboard, or session-restoration cues users rely on
- **permission amnesia**: approvals exist, but remembered scopes and deny behavior do not match real coding sessions
- **resume illusion**: explicit session IDs work, but cwd-local continuation and durable transcript recovery do not
- **negative-path blind spot**: low-budget, malformed-input, non-TTY, and no-persistence behaviors are untested even though real users hit them first
