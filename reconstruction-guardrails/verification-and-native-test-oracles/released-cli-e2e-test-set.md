---
title: "Released CLI E2E Test Set"
owners: [bingran-you]
soft_links:
  - /integrations/clients/structured-io-and-headless-session-loop.md
  - /platform-services/workspace-trust-dialog-and-persistence.md
  - /platform-services/session-cost-accounting-and-restoration.md
  - /platform-services/auth-config-and-policy.md
  - /runtime-orchestration/sessions/resume-path.md
  - /ui-and-experience/startup-and-onboarding/startup-welcome-dashboard-and-feed-rotation.md
  - /ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md
  - /ui-and-experience/dialogs-and-approvals/structured-diff-rendering-and-highlight-fallback.md
  - /tools-and-permissions/permissions/e2e-permission-testing-contracts.md
  - /integrations/plugins/plugin-management-and-marketplace-flows.md
  - /integrations/mcp/config-layering-policy-and-dedup.md
  - /collaboration-and-agents/remote-control-entrypoints-and-startup-preferences.md
  - /product-surface/interaction-modes.md
---

# Released CLI E2E Test Set

Source-derived contracts are still the primary clean-room evidence for this tree, but they are not enough on their own for end-to-end rebuild work. A released CLI can be exercised directly, and its public runtime behavior becomes a second kind of oracle: not hidden implementation, but what a real user actually experiences.

This leaf captures that public-runtime oracle set from a local macOS run of the shipped `claude` CLI on April 9, 2026.

## Snapshot and evidence boundary

Final authoritative evidence in this leaf comes from the native Mach-O binary at `~/.local/bin/claude`, which reported version `2.1.96 (Claude Code)`.

An earlier pass on this machine discovered an older `2.1.89` rewrite-backed shim in `~/.local/share/claude/versions/2.1.89`. That shim is not the right oracle for the shipped native CLI. Do not treat shim-era results as authoritative for released behavior.

The test set below records only public behavior that was directly observed from the shipped CLI:

- public command-line flags and subcommands
- public terminal UI flows
- files the CLI itself wrote into local user state
- session recovery behavior visible through later CLI invocations
- browser-login and subscription boundaries visible from the CLI surface

It should not become a transcript dump. Keep raw logs local, and normalize them here into assertions, scenario shapes, and failure modes.

## Machine-specific provider boundary

This machine does support provider-backed local Claude CLI use without a Claude account login, but the working provider state is not purely ambient.

Observed machine-specific rules:

- the working provider path was `authMethod: third_party` with `apiProvider: foundry`
- `claude auth status --text` reported `API provider: Microsoft Foundry` and resource `knowhiz-service-openai-backup-2`
- a fresh isolated `HOME` without copied Claude settings reported `loggedIn: false` and headless prompt mode failed with `Not logged in · Please run /login`
- copying only `~/.claude/settings.json` into the isolated `HOME` restored provider-backed prompt success

The practical reconstruction rule is that provider-backed local testing on this machine must seed the Claude settings layer that carries Foundry configuration. A blank home directory is not enough.

## Coverage legend

- `PASS`: directly exercised and externally visible
- `PASS (nuanced)`: exercised, but the observed contract has caveats that a rebuild must preserve
- `PARTIAL`: the flag or command was accepted or partially observed, but its full effect needs external setup not present in this lane
- `ACCOUNT-BOUND`: Azure or Foundry credentials alone were insufficient; the path clearly required first-party Anthropic account state
- `NOT MEANINGFUL HERE`: the flag is real, but this machine or session posture could not surface a distinct runtime effect without a different precondition

## Provider-backed local root-flag matrix

The table below is the practical E2E matrix for the `claude --help` root surface as observed on native `2.1.96`.

| Root surface | Status | Observed contract |
| --- | --- | --- |
| `--help` | `PASS` | Enumerated the public root flags and command families. |
| `--version` | `PASS` | Reported `2.1.96 (Claude Code)`. |
| `-p, --print` | `PASS` | Headless one-shot prompt path worked in both text and JSON envelopes. |
| `--bare` | `PASS` | Reduced startup surface and still worked with Foundry-backed prompts. |
| `--model` | `PASS` | `--model sonnet` resolved and returned successful prompts. |
| `--output-format text` | `PASS` | Returned plain assistant text. |
| `--output-format json` | `PASS` | Returned a metadata envelope with `type`, `subtype`, `result`, `session_id`, `total_cost_usd`, and usage metadata. |
| `--json-schema` | `PASS` | Returned success with `structured_output` separated from the human-readable `result`. |
| `--max-budget-usd` | `PASS` | Low budgets could fail before useful text; both the plain-text error path and JSON `error_max_budget_usd` envelope were observed. |
| `--output-format stream-json` | `PASS` | In `--print` mode it required `--verbose`; the stream started with a `system/init` event and ended with a final `result` event. |
| `--verbose` | `PASS` | Enabled streamed event output and surfaced additional assistant-side event blocks. |
| `--input-format stream-json` | `PASS` | Accepted inbound NDJSON user events and drove a streaming response loop. |
| `--replay-user-messages` | `PASS` | Re-emitted the inbound user event back to stdout as a replayed user message. |
| `--include-partial-messages` | `PASS` | Surfaced fine-grained stream events such as `content_block_delta` before the final message. |
| malformed `--input-format stream-json` input | `PASS` | Invalid JSON lines failed closed with a parse error instead of silent fallback. |
| `--session-id` | `PASS` | Forced a deterministic session ID for later resume. |
| `-r, --resume` | `PASS` | Resumed a prior headless session by explicit session ID and preserved earlier context. |
| `--fork-session` | `PASS` | Created a new session ID while resuming previous context. |
| `-c, --continue` | `PASS (nuanced)` | In native `2.1.96` print mode it did not reliably resume the prior headless print session on this machine; it created a fresh session in the tested workspaces. A rebuild should not assume older snapshot behavior here. |
| `--no-session-persistence` | `PASS (nuanced)` | In native `2.1.96` on this machine, no per-project transcript directory for the no-persist workspace was created. This differs from older observed behavior and should be treated as a version-sensitive contract. |
| `--add-dir` | `PASS` | Reading `../extra/context.txt` outside the workspace was denied without `--add-dir`, then succeeded with `--add-dir ../extra`. |
| `--system-prompt` | `PASS` | A system-only keyword could be injected and retrieved later in the same one-shot session. |
| `--append-system-prompt` | `PASS` | An appended system-only keyword could be injected and retrieved later in the same one-shot session. |
| `--agents` plus `--agent` | `PASS` | A custom JSON-defined agent could be injected and selected for a headless turn. |
| `--tools` | `PASS` | Tool surface could be constrained to `Read` or `Bash` and the session adapted accordingly. |
| `--allowed-tools` | `PASS` | A narrowed allow rule such as `Bash(pwd:*)` still executed the intended command successfully. |
| `--disallowed-tools` | `PASS (nuanced)` | Disallowing `Bash` did not return a hard CLI error; the assistant instead answered in text with a pseudo-command block. Rebuilds should test for this externally visible fallback behavior, not only an internal deny bit. |
| `--permission-mode bypassPermissions` | `PASS` | Suppressed ordinary tool approval prompts in headless mode for Bash and MCP lanes. |
| `--settings <path>` | `PASS` | File-backed settings injected environment visible to Bash. |
| `--settings <inline-json>` | `PASS` | Inline JSON settings injected environment visible to Bash. |
| `--setting-sources` | `PASS` | `user,project` loaded a project-only environment marker; `user` alone filtered it out. |
| `--plugin-dir` | `PASS` | Session-only plugin loading worked; its slash command appeared in streamed init output and executed via `/local-plugin:plugin-test`. |
| `--disable-slash-commands` | `PASS` | Disabled plugin-loaded slash commands; the same plugin command became `Unknown skill`. |
| `--mcp-config` | `PASS` | Both file-backed and inline JSON MCP config loaded into the live headless tool surface. |
| `--strict-mcp-config` | `PASS` | Restricted the session to only the explicitly supplied MCP config. |
| `--debug-file` | `PASS` | Wrote startup and runtime debug logs to the requested file. |
| `-w, --worktree` | `PASS` | Created a git worktree under `.claude/worktrees/<name>` and executed the turn from that worktree path. |
| `--tmux` | `PASS (nuanced)` | In a headless non-terminal run it created the worktree, then failed with `open terminal failed: not a terminal`. The pre-terminal worktree side effect is part of the public behavior. |
| `--ide` | `PARTIAL` | Accepted in headless prompt mode and did not block the turn, but no separate externally visible IDE-attachment effect surfaced in this lane. |
| `--chrome` | `PARTIAL` | Accepted in headless prompt mode and did not block the turn, but no separate externally visible Chrome-attachment effect surfaced in this lane. |
| `--no-chrome` | `PASS` | Parsed and ran successfully as the inverse startup toggle. |
| `--effort low` | `PASS` | Parsed and ran successfully in the provider-backed headless lane. |
| `-n, --name` | `PASS` | Parsed and ran successfully as a session display-name override. |
| `--mcp-debug` | `PASS` | Deprecated alias still parsed and ran in the provider-backed headless lane. |
| `--brief` | `PASS` | Parsed and ran in headless prompt mode, though this lane did not surface a distinct SendUserMessage interaction. |

## Root flags that exist but were not fully meaningful in this provider-backed lane

| Root surface | Status | Why it was not a complete local provider-backed oracle on this machine |
| --- | --- | --- |
| `--allow-dangerously-skip-permissions` | `NOT MEANINGFUL HERE` | The externally visible permission-bypass contract was already exercised through `--permission-mode bypassPermissions`. |
| `--dangerously-skip-permissions` | `NOT MEANINGFUL HERE` | Same as above; no distinct E2E contract beyond the bypass posture already observed. |
| `-d, --debug` | `NOT MEANINGFUL HERE` | `--debug-file` already exercised the public debug-log side effect without flooding the terminal transcript. |
| `--fallback-model` | `NOT MEANINGFUL HERE` | Only matters under model overload or failure; that condition was not naturally present during this run. |
| `--file` | `NOT MEANINGFUL HERE` | Depends on prior first-party file-upload state and `file_id` handles, which were not part of this Azure-backed local lane. |
| `--from-pr` | `NOT MEANINGFUL HERE` | Depends on PR-linked session metadata rather than a purely local provider-backed workspace. |
| `--include-hook-events` | `NOT MEANINGFUL HERE` | Hook streaming is only meaningful when hooks are configured and firing. |
| `--betas` | `NOT MEANINGFUL HERE` | The help text explicitly scopes this to API-key users; this machine's authoritative lane was Foundry third-party auth. |
| `--remote-control-session-name-prefix` | `ACCOUNT-BOUND` | Only meaningful when Remote Control itself is available, which it was not under Azure-only credentials. |

## Provider-backed local command-family matrix

| Command family | Status | Observed contract |
| --- | --- | --- |
| `claude auth status --json` | `PASS` | Returned `loggedIn: true`, `authMethod: third_party`, `apiProvider: foundry`. |
| `claude auth status --text` | `PASS` | Returned Microsoft Foundry human-readable status. |
| `claude auth logout` | `PASS (nuanced)` | Logged out of Anthropic account state, but did not disable the working Foundry third-party provider path; `auth status` still returned `third_party/foundry`. |
| `claude agents` | `PASS` | Listed built-in agents from a top-level command. |
| `claude auto-mode config` | `PASS` | Returned effective JSON config. |
| `claude auto-mode defaults` | `PASS` | Returned the default allow, soft-deny, and environment rule set. |
| `claude auto-mode critique` | `PASS` | Returned the explicit empty-state message when no custom rules existed. |
| `claude doctor` in non-TTY | `PASS (nuanced)` | Failed closed with Ink raw-mode errors, proving this is not a plain pipe-friendly command. |
| `claude doctor` in TTY | `PASS` | Returned diagnostics including running version, stable version, latest version, PATH warning, and keychain warning. |
| `claude install stable` | `PASS (nuanced)` | In an isolated `HOME`, installed a native build and launcher successfully, but the installed stable version was `2.1.89`, not the actively used `2.1.96` binary. |
| `claude update` | `PASS (nuanced)` | In the isolated install root, reported `2.1.89` as up to date on the stable channel. |
| `claude plugin validate` | `PASS` | Validated local plugin manifests and returned warnings without failing. |
| `claude plugin marketplace add/list/update/remove` | `PASS` | Worked end to end against a local git-backed marketplace repo. |
| `claude plugin install/list/disable/enable/uninstall` | `PASS` | Worked end to end against a local plugin from that marketplace. |
| `claude plugin update` | `PASS (nuanced)` | Required the full plugin ID `plugin@marketplace`; after update it said restart was required, `plugin list --json` still showed the old version, but a new session executed the updated plugin command content. |
| `claude mcp add/list/get/remove/reset-project-choices` | `PASS` | Worked for local stdio servers and project or user scope. |
| `claude mcp add-json` | `PASS` | Added a stdio server from inline JSON. |
| `claude mcp add-from-claude-desktop` in non-TTY | `PASS (nuanced)` | Failed with Ink raw-mode requirements, showing it is interactive UI rather than a plain pipe command. |
| `claude mcp add-from-claude-desktop` in TTY | `PASS` | Imported a synthetic Claude Desktop server after an interactive checklist UI. |
| `claude mcp serve` | `PASS` | Exposed Claude Code's own MCP server surface and returned a large tool catalog over JSON-RPC. |
| MCP tool use inside headless session | `PASS (nuanced)` | MCP tools loaded correctly, but by default their use still triggered permission denials; the same tool call passed under `--permission-mode bypassPermissions`. |

## Interactive startup and coding lane

The interactive REPL still matters more than many synthetic headless loops because it captures what a real coding user actually feels.

### Fresh-start startup contract

Observed on a fresh isolated `HOME`:

- the first launch did not go straight to a prompt
- it first showed theme selection onboarding
- it then showed security notes
- it then showed the workspace trust gate with a binary trust or exit choice
- after trust, it entered the richer welcome dashboard with project identity, tips, and shortcut affordances

Observed on the second launch in the same trusted workspace:

- the trust gate was skipped
- startup went straight to the welcome dashboard

That makes trust persistence and first-run onboarding explicit E2E surfaces, not optional polish.

### Real coding turn contract

In a tiny temporary git workspace containing a broken Python function and test:

- Claude first proposed `npm test`, which triggered a Bash permission prompt
- the resulting `ENOENT` failure was summarized in a compact UI block instead of dumping full scrollback
- it searched the workspace and pivoted to `python -m pytest`, which triggered another permission prompt
- the failing Python assertion was summarized in the UI
- it read `mathlib.py`
- it proposed an edit and rendered a structured diff approval dialog
- after approval, it reran tests and summarized the passing result
- it ended with a one-sentence root-cause explanation

One subtle behavior was especially important:

- selecting `Yes, and don't ask again for: python:*` on the first Python test run did **not** suppress the later Python rerun prompt in the same session

A rebuild should therefore test the remembered-approval scope exactly, not just whether approvals exist in principle.

### Interactive transcript artifact shape

The resulting interactive transcript was stored under `~/.claude/projects/<sanitized-path>/...jsonl`.

The observed `2.1.96` transcript for the coding lane included these top-level record families:

- `assistant`
- `user`
- `attachment`
- `file-history-snapshot`
- `permission-mode`
- `last-prompt`

Structured `toolUseResult` payloads inside `user` records captured at least these public result shapes:

- Bash stdout and stderr for command runs
- workspace file listings from search or glob-style actions
- full text test failure output
- structured file reads with `filePath`, `content`, and line metadata
- edit records with `structuredPatch`, `oldString`, `newString`, and `userModified`

That stored-shape contract matters for replay and parity tests even if a rebuild uses a different internal implementation.

## Account-bound and first-party-only matrix

The user request for this leaf was explicit: separate provider-backed local flows from flows that Azure credentials alone do not unlock.

The matrix below records the observed boundary.

| Surface | Status | Exact observed boundary |
| --- | --- | --- |
| ordinary headless prompts via Foundry | `PASS` | Worked with Azure-backed Foundry settings and no Claude account login. |
| `claude auth status` | `PASS` | Correctly reflected the third-party provider path. |
| `claude auth login` | `ACCOUNT-BOUND` | Opened a browser flow against `https://claude.com/...`; Azure credentials alone did not satisfy it. |
| `claude auth login --console` | `ACCOUNT-BOUND` | Opened a browser flow against `https://platform.claude.com/...`; still required first-party Anthropic account login, not Azure-only state. |
| `claude setup-token` | `ACCOUNT-BOUND` | Warned that environment or helper auth already existed, then still opened a browser sign-in flow and prompted for an OAuth code. Azure credentials alone were insufficient. |
| `claude remote-control` | `ACCOUNT-BOUND` | Failed immediately with `You must be logged in to use Remote Control` and explicitly said the feature is only available with `claude.ai` subscriptions. |
| `claude auth logout` | `PASS (nuanced)` | Only removed Anthropic account state; it did not log out the third-party Foundry provider path. |

The reconstruction rule is straightforward:

- Azure or Foundry credentials are enough for local prompt, tool, plugin, MCP, and ordinary REPL flows on this machine
- Azure or Foundry credentials are **not** enough for first-party browser-login flows, long-lived OAuth token setup, or Remote Control subscription flows

## Cases a reconstruction still misses if it stops at the earlier local test set

The current clean-room rewrite and earlier oracle leaves already covered useful structured and local harness lanes. They still miss several released-CLI cases that this native `2.1.96` run made concrete.

These are the highest-value missing or version-sensitive cases to add:

- first-run theme onboarding before trust acceptance
- trust persistence causing the second interactive launch to skip the trust gate
- provider-backed local auth depending on Claude settings bootstrap, not only shell environment
- native-versus-stable maintenance drift: active native binary `2.1.96`, isolated stable install `2.1.89`, doctor-reported latest `2.1.98`
- non-TTY failure behavior for `doctor` and `mcp add-from-claude-desktop`
- stream-json init, replay, partial deltas, and malformed-input failure paths
- explicit JSON `error_max_budget_usd` envelopes
- `--continue` behavior drift in native `2.1.96` headless print mode
- `--no-session-persistence` drift in native `2.1.96` on this machine
- `--disable-slash-commands` disabling plugin-loaded slash commands
- `--worktree` side effects and `--tmux` failing only after the worktree already exists
- MCP strict-config loading plus permission-denied tool calls
- plugin update requiring restart, full `plugin@marketplace` addressing, and post-update version-report drift
- remembered-approval scope not suppressing a later Python rerun prompt even after choosing `don't ask again for: python:*`
- account-bound browser and subscription flows being distinct from provider-backed local prompts

If the rebuild test suite does not assert these, it is still missing released-CLI parity, even if its internal golden tests look healthy.

## Reconstruction rule

Use this leaf as the public-runtime complement to the source-derived verification leaves:

- source-derived leaves explain what the product architecture must preserve
- this leaf explains what a shipped build actually feels like when exercised end to end on a real machine

A faithful rebuild should keep both. If they disagree, prefer the narrower claim and investigate. Public-runtime behavior is excellent for E2E oracles, but it does not by itself reveal why the product was built that way.

## Failure modes

- **headless false confidence**: the rebuild passes local JSON tests but its public envelope and error modes do not match a released CLI
- **provider bootstrap blind spot**: the rebuild assumes provider auth is ambient and misses the settings-layer bootstrap required on real machines
- **startup flattening**: the rebuild starts in a bare prompt and skips theme onboarding, trust, or dashboard cues users actually see
- **maintenance-lane drift**: install, update, and doctor behaviors are untested, so version-channel mismatches go unnoticed
- **permission-memory drift**: approvals exist, but the remembered-scope behavior does not match a real coding session
- **integration-toggle overclaim**: flags like `--tmux`, `--ide`, `--chrome`, `--plugin-dir`, or `--mcp-config` are parsed but their real side effects are not asserted
- **account-bound confusion**: Azure-backed local success is mistakenly treated as proof that Remote Control, setup-token, or browser login flows are covered
