---
title: "Real CLI E2E Scenario Corpus"
owners: [bingran-you]
soft_links:
  - /platform-services/interactive-startup-and-project-activation.md
  - /platform-services/doctor-command-and-health-diagnostics.md
  - /product-surface/interaction-modes.md
  - /product-surface/session-utility-commands.md
  - /runtime-orchestration/sessions/resume-path.md
  - /integrations/clients/structured-io-and-headless-session-loop.md
  - /tools-and-permissions/permissions/permission-mode-transitions-and-gates.md
  - /tools-and-permissions/filesystem-and-shell/path-and-filesystem-safety.md
---

# Real CLI E2E Scenario Corpus

This leaf captures a black-box test corpus derived from running a real local Claude Code CLI, not from reconstructing its internals. The goal is to give a rebuild effort concrete end-to-end handles: which behaviors to probe first, which outputs should be treated as stable protocol, and which observations are real but too version-sensitive to use as hard golden assertions.

The corpus exists because the tree already described many subsystem contracts, but it still lacked one operator-facing document that answers a simpler question: if a faithful clone is "working," what should a real terminal session, a real headless run, and a real session-resume flow actually feel like from the outside?

## Observation boundary

Observed on macOS from a working local Claude Code CLI on April 9, 2026.

Observed surfaces:

- interactive `claude`
- headless `claude -p`
- `--output-format json`
- `--json-schema`
- `--input-format stream-json --output-format stream-json --verbose`
- `-c`, `-r`, and `--fork-session`
- `--no-session-persistence`
- `claude doctor` in both non-TTY and TTY contexts

Observed environment notes:

- an initial version check returned `2.1.27`
- interactive startup later auto-updated the installed CLI to `2.1.97`
- exact version numbers are not the contract; the load-bearing fact is that install and update state can visibly change the product surface between runs

Fixture shape used for these observations:

- one small main workspace containing `README.md`, `todo.txt`, and editable scratch files
- one sibling directory outside that workspace for path-boundary probing
- one isolated fresh directory for `--no-session-persistence` checks

## How to use this corpus

Treat each scenario as a product contract, not as a screenshot test.

Hard assertions should prefer:

- exit behavior
- whether a session is persisted or not
- presence of `session_id`, `structured_output`, or typed stream events
- whether the tool actually obtained live file contents
- whether a follow-up command can recover prior context

Soft assertions should avoid overfitting to:

- ASCII art, welcome-card layout, or ANSI paint
- exact prose wording of help or trust text
- exact ordering of non-essential diagnostic rows
- exact version numbers shown after auto-update

## Core scenarios

### R01. Interactive startup gates a new workspace behind trust

- Entry: run `claude` in a directory that has not yet been trusted interactively.
- Expect: the first interactive surface is a workspace-trust gate, not an immediate model turn.
- Expect: the gate explicitly tells the user that Claude Code will be able to read, edit, and execute files in the folder.
- Expect: accepting trust transitions into a persistent REPL-style shell rather than a one-shot response.
- Failure signal: a fresh workspace drops directly into tool-capable execution with no trust boundary.
- Why it matters: startup trust is part of the product, not just a local policy detail.

### R02. Interactive startup lands in a session shell, not a raw request runner

- Entry: accept the trust gate and let the interactive UI finish booting.
- Expect: a persistent shell appears with a prompt area, shortcut hinting, and session-scoped welcome state.
- Expect: the user is entering a conversation shell that can continue, not just sending a single request.
- Failure signal: the rebuild treats `claude` and `claude -p` as the same surface with different formatting.
- Why it matters: the interactive product is a session container first.

### R03. Headless `-p` is the minimum viability oracle

- Entry: run `claude -p "Reply with exactly READY"`.
- Expect: the process exits successfully with plain text output and no interactive shell.
- Failure signal: even the simplest one-shot prompt requires extra protocol framing or a TTY.
- Why it matters: this is the cheapest smoke test for auth, model reachability, and non-interactive execution.

### R04. `--output-format json` gives a result envelope, not a schema-stable answer body

- Entry: run `claude -p --output-format json` on a prompt that reads a local file and answers structurally.
- Expect: the final payload includes fields such as `result`, `session_id`, usage and cost metadata, and permission-denial reporting.
- Expect: the `result` field is still a human-facing answer string and may contain Markdown or code fences.
- Failure signal: a rebuild assumes `result` itself is the machine-safe contract.
- Why it matters: human-readable output and machine-readable output are separate concerns.

### R05. `--json-schema` creates a dedicated machine channel

- Entry: run `claude -p --output-format json --json-schema ...`.
- Expect: the final envelope still contains a prose `result`, but also carries a separate `structured_output` object that matches the schema.
- Expect: schema enforcement changes completion semantics, not just pretty-print formatting.
- Failure signal: a rebuild only rewrites the prose answer and never exposes a separately validated structured payload.
- Why it matters: this is the stable contract for downstream automation.

### R06. `-r <session_id>` restores remembered context

- Entry: create a saved session with a unique token, then resume it by explicit session ID.
- Expect: the resumed session can answer questions that depend on prior turns.
- Failure signal: resume reopens a transcript shell but loses the working conversational state that the next turn depends on.
- Why it matters: session restoration is more than log playback.

### R07. `-c` continues the most recent saved session for the current directory

- Entry: after a saved headless run in one workspace, run `claude -p -c ...` in that same workspace.
- Expect: the follow-up prompt continues the latest saved conversation for that directory rather than starting cold.
- Failure signal: `-c` ignores workspace-local session history or chooses an unrelated global session.
- Why it matters: directory-scoped continuation is one of the fastest everyday loops.

### R08. `--fork-session` keeps context but produces a new session identity

- Entry: resume a known session with `-r <session_id> --fork-session`.
- Expect: prior context is still available, but the returned `session_id` is new.
- Failure signal: fork either mutates the original session in place or loses the prior conversation context.
- Why it matters: branching a session is a different contract from simply reopening it.

### R09. `--no-session-persistence` must break later continuation

- Entry: in a brand-new directory, run one headless prompt with `--no-session-persistence`, then immediately run `claude -p -c ...`.
- Expect: the second command behaves like no saved session exists for that directory.
- Failure signal: ephemeral sessions still leak into the resume index or can be discovered by `-c`.
- Why it matters: automation-grade ephemeral runs need a true non-persistent mode.

### R10. Variadic tool flags need explicit option termination

- Entry: call `claude -p` with `--allowedTools` or `--tools` and a prompt argument.
- Expect: harnesses use `--` or `--flag=value` style when a variadic option is followed by the prompt.
- Observed reality: omitting that termination caused the CLI to report that no prompt had been provided, because the variadic tool flag consumed the remaining argv.
- Failure signal: the E2E harness itself feeds malformed argv and misreads the resulting error as a product failure.
- Why it matters: a real clone should match the public CLI grammar, and the test harness should call it correctly.

### R11. Tool allowlists must still permit real file reads when configured positively

- Entry: run `claude -p --allowedTools=Read -- "Read README.md and tell me its title only."`
- Expect: the answer reflects the actual file contents from the live workspace.
- Failure signal: the allowlist is ignored or the narrowed tool pool loses the ability to perform the admitted read.
- Why it matters: tool-shaping needs a positive-path oracle, not only denial tests.

### R12. Disabled tools must prevent real file access even if the session still completes

- Entry: run `claude -p --tools '' -- "Read README.md and tell me its title only."`
- Minimum contract: the session may still produce a final answer, but it must not have real filesystem access.
- Observed reality: the current build completed the session but emitted pseudo function-call markup and did not recover the actual file contents.
- Failure signal: disabled-tool runs still read the file successfully.
- Why it matters: capability loss and process failure are separate; a clone needs tests for both.

### R13. Structured stream output requires `--verbose`

- Entry: run `claude -p --input-format stream-json --output-format stream-json` without `--verbose`.
- Expect: the CLI fails closed and explains that stream-json output requires verbose mode.
- Failure signal: a rebuild silently downgrades to another output format or emits partial JSON without the documented gate.
- Why it matters: protocol surfaces need explicit mode gating.

### R14. Structured input begins with a live `system/init` frame

- Entry: send a valid NDJSON user message through `--input-format stream-json --output-format stream-json --verbose`.
- Expect: the first output frame is a `system/init` event containing the live `session_id`, tool inventory, model, permission mode, slash-command list, agents, and related bootstrap metadata.
- Failure signal: the rebuild hides startup catalog state inside an undocumented side channel or only emits a final answer.
- Why it matters: structured clients need an authoritative initialization record before the first turn completes.

### R15. Structured input validates top-level message types

- Entry: send a malformed stream message whose top-level `type` is not accepted.
- Expect: the CLI rejects it with a protocol error instead of silently coercing it into transcript text.
- Observed reality: `user_message` was rejected, and the accepted top-level types were reported as `user` or `control`.
- Failure signal: protocol drift is accepted quietly and later breaks session semantics.
- Why it matters: fail-closed protocol validation is part of the SDK-facing contract.

### R16. Replay and partial streaming produce typed lifecycle events

- Entry: run structured I/O with `--replay-user-messages --include-partial-messages`.
- Expect: the stream contains lifecycle events such as `message_start`, `content_block_start`, `content_block_delta`, `content_block_stop`, `message_delta`, and `message_stop`.
- Expect: replayed user messages are echoed back as typed user events with replay metadata rather than being folded into assistant text.
- Expect: a final `result` envelope still arrives after the stream events.
- Failure signal: clients must scrape terminal prose because lifecycle events never materialize.
- Why it matters: replica SDK clients need a typed stream, not a screen parser.

### R17. `claude doctor` is a TTY-sensitive operational surface

- Entry: run `claude doctor` once without a TTY and once with a TTY.
- Expect: non-TTY invocation can fail on terminal raw-mode requirements rather than pretending to be a plain text subcommand.
- Expect: TTY invocation opens an operational diagnostics view with install, updater, and version-lock information, then dismisses via a continue prompt.
- Failure signal: a rebuild treats `doctor` as a static text dump and loses its terminal-UI contract.
- Why it matters: operational health is part of the product surface, not just a hidden admin API.

## Drift-sensitive or investigative scenarios

These scenarios are still worth tracking, but they should not become brittle golden tests until the target build intentionally fixes their semantics.

### X01. Interactive startup can mutate the installed version between runs

- Observed reality: `claude -v` returned `2.1.27` before live usage and `2.1.97` after interactive startup triggered installer migration and auto-update messaging.
- Testing advice: assert that update state is surfaced and diagnosable, not that a specific version transition must happen.

### X02. `--add-dir` is not yet a reliable denial oracle for headless reads

- Observed reality: a sibling-directory file read succeeded in the current headless test even before `--add-dir` was supplied.
- Testing advice: keep `--add-dir` in the corpus as an exploratory lane, but do not assume a missing flag must always produce a denial until the rebuild defines its exact filesystem boundary policy.

### X03. Headless permission modes do not necessarily mirror interactive approval UX

- Observed reality: same-workspace file edits succeeded in `default`, `bypassPermissions`, and `dontAsk` headless runs once edit tools were admitted.
- Testing advice: keep separate E2E lanes for interactive approval prompts versus non-interactive automation, and do not assume permission modes differentiate every same-directory write in `-p`.

## Recommended implementation order for a clone

If the rebuild does not already exist, the fastest confidence-building order is:

1. `R03`, `R04`, and `R05` for one-shot headless viability and machine-readable output.
2. `R06`, `R07`, `R08`, and `R09` for real session persistence semantics.
3. `R13`, `R14`, `R15`, and `R16` for typed SDK or headless transport.
4. `R01`, `R02`, and `R17` for interactive shell reality and operational diagnostics.
5. `R10`, `R11`, and `R12` for CLI grammar and tool-surface shaping.
6. `X01`, `X02`, and `X03` as drift watchpoints once the core product is stable.

That order gives the rebuild an end-to-end test ladder that starts with cheap black-box commands and only later depends on full-screen terminal UX or ambiguous permission policy edges.
