---
title: "Custom Status Line Setup and Execution"
owners: []
soft_links:
  - /product-surface/auxiliary-local-command-surfaces.md
  - /ui-and-experience/feedback-and-notifications/status-line-and-footer-notification-stack.md
  - /ui-and-experience/shell-and-input/terminal-ui.md
  - /tools-and-permissions/execution-and-hooks/tool-hook-control-plane.md
  - /platform-services/settings-change-detection-and-runtime-reload.md
  - /platform-services/workspace-trust-dialog-and-persistence.md
  - /runtime-orchestration/sessions/worktree-session-lifecycle.md
---

# Custom Status Line Setup and Execution

Claude Code's status line is not just one extra footer string. It is a user-configurable command surface with a dedicated `/statusline` setup lane, a persisted `statusLine` settings object, a structured stdin payload, trust and managed-settings gates, and layout-aware rendering beneath the input box. A faithful rebuild needs that whole contract, not only the final text row.

## Scope boundary

This leaf covers:

- the `/statusline` setup entrypoint and its dedicated built-in setup-agent handoff
- the persisted `statusLine` settings shape and how it participates in hot reload
- the structured runtime payload passed to custom status-line commands
- the visibility, trust, timeout, and rendering rules for the live status line

It intentionally does not re-document:

- generic hook matching, aggregation, or post-tool feedback behavior already covered in [../../tools-and-permissions/execution-and-hooks/tool-hook-control-plane.md](../../tools-and-permissions/execution-and-hooks/tool-hook-control-plane.md)
- the broader footer arbitration stack already covered in [status-line-and-footer-notification-stack.md](status-line-and-footer-notification-stack.md)
- the generic settings watcher and reload fan-out already covered in [../../platform-services/settings-change-detection-and-runtime-reload.md](../../platform-services/settings-change-detection-and-runtime-reload.md)
- full worktree semantics beyond the fact that worktree metadata is exposed to the status-line command input

## `/statusline` is a prompt-backed setup flow, not a raw config editor

Equivalent behavior should preserve:

- `/statusline` being a prompt-style command rather than a direct local-JSX config menu or a built-in settings mutator
- the command being interactive-only instead of a non-interactive CLI helper
- the command delegating into one dedicated built-in setup agent rather than asking the main session to improvise shell-integration edits ad hoc
- that setup agent staying narrowly scoped to read/edit style authority over shell config and Claude settings, not broad shell execution
- user-supplied arguments becoming the setup brief, while the default brief asks Claude to derive the status line from the user's shell prompt configuration

## Shell-prompt import is a setup convenience, not the runtime contract

Equivalent behavior should preserve:

- a guided setup path that can inspect common shell rc files in a stable preference order and derive a starter status-line command from an existing `PS1`-style prompt
- translation of common prompt escapes such as user, host, cwd, time, newline, and prompt-marker tokens into explicit shell expressions or literals rather than copying raw prompt syntax verbatim
- preservation of ANSI color output when converting a shell prompt into a status-line command
- removal of trailing shell-prompt markers such as bare `$` or `>` when those would render the status line as a misleading second prompt
- escalation for longer commands into a dedicated script under the user's Claude config directory, with the settings entry pointing at that script
- symlink-aware updates so a symlinked `~/.claude/settings.json` updates the real target file instead of breaking the link
- future status-line edits continuing through the same dedicated setup-agent lane instead of fragmenting into unrelated one-off mutations

## Persisted configuration is small, but it is still policy-shaped

Equivalent behavior should preserve:

- one optional `statusLine` settings object with a command-backed shape that includes the command string and optional horizontal padding
- ordinary editable settings sources being able to supply the status-line definition
- managed settings being able to become the only active status-line source when the runtime is in a managed-hooks-only posture
- hook-wide disable switches being able to suppress status-line execution without silently deleting the saved status-line configuration
- status-line presence counting as hook-like customization for trust and onboarding logic rather than bypassing those systems as a separate extension path

## Runtime command input is a structured session snapshot over stdin

Equivalent behavior should preserve one JSON object on stdin that includes at least these families:

- shared hook-base metadata such as session identity and transcript path
- optional human-readable session naming when the user renamed the session
- current model ID plus display name
- workspace current directory, original project directory, and added working directories
- Claude Code version and current output-style name
- cumulative cost, duration, and added/removed-line totals
- context-window totals plus current-call usage and precomputed used/remaining percentages
- optional Claude.ai rate-limit windows when those are actually known
- optional Vim mode, explicit agent identity, remote-session metadata, and main-session worktree metadata

The clean-room point is that the status-line command is not scraping terminal text. It receives structured runtime state that should stay aligned with the rest of the product.

## Execution, refresh, and display rules are deliberately narrow

Equivalent behavior should preserve:

- status-line execution reusing the hook-style command runner with JSON stdin, abortability, and a short timeout budget
- workspace trust gating before any configured status-line command runs in interactive mode
- blank or whitespace-only command output collapsing to "no visible status line" instead of reserving meaningless noise
- non-zero exits or runtime errors degrading quietly to no status line instead of crashing the footer
- per-line trimming and blank-line removal before multi-line output is rejoined, so users can emit more than one line without preserving accidental shell whitespace
- update triggers being tied to meaningful runtime state changes such as the latest assistant message, permission mode, Vim mode, current model, and hot-reloaded status-line command config rather than rerunning on every keystroke
- debounced refresh so the footer does not thrash while transcript state is still moving
- a first-mount warning notification when a status-line command exists but workspace trust prevented execution, so the surface does not look permanently broken with no explanation

## Visibility is layout-aware and mode-aware

Equivalent behavior should preserve:

- custom status-line presence suppressing some generic footer hints because that space is now owned by the custom surface
- assistant or proactive daemon posture hiding the custom status line when it would describe the parent REPL process rather than the child agent's effective runtime
- fullscreen short terminals dropping the optional status line before more essential prompt-footer UI
- fullscreen layouts reserving a blank footer row while the status-line command is still loading so scrollback height does not jump when output appears
- non-fullscreen layouts being allowed to show the custom status line whenever it is configured, because terminal scrollback can absorb the extra row more safely than fullscreen can

## Discovery and ongoing editing stay user-visible

Equivalent behavior should preserve:

- a low-frequency tip nudging users toward `/statusline` only when no custom status line is configured
- the prompt footer staying able to tell the user that custom status-line setup exists without forcing it during normal onboarding
- the setup flow teaching the user that later status-line changes should continue through Claude rather than leaving them with a one-time opaque script

## Failure modes

- **prompt-copy corruption**: shell-prompt import copies raw `PS1` syntax or trailing prompt glyphs into the status line and produces unreadable output
- **trust-blind execution**: a configured status-line command still runs before workspace trust is accepted
- **managed/local inversion**: local settings keep winning even when the runtime should be honoring managed-hooks-only posture
- **footer thrash**: the status line reruns on every tiny UI change and makes the footer flicker
- **parent-process lie**: assistant-mode sessions keep showing a status line that reflects the parent REPL process instead of the active child agent posture
- **silent blocked config**: trust or hook-wide disablement suppresses the status line with no visible clue, making the feature look broken rather than gated

## Test Design

In the observed source, this behavior is guarded through settings-aware integration paths, hook-runner execution seams, and real interactive footer rendering.

Equivalent coverage should prove:

- `/statusline` setup preserves the narrow handoff into the dedicated setup-agent lane and writes a command-backed settings shape without clobbering unrelated user config
- trust gates, managed-settings precedence, timeout handling, and hot reload all shape the live status-line execution path correctly
- the real interactive footer preserves the same update cadence, layout fallback, and user-visible warning behavior instead of only testing the command runner in isolation
