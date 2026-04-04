---
title: "IDE Connectivity and Diff Review"
owners: []
soft_links: [/integrations/clients/surface-adapter-contract.md, /integrations/plugins/lsp-plugin-and-diagnostics.md, /ui-and-experience/permission-prompt-shell-and-worker-states.md, /ui-and-experience/terminal-ui.md]
---

# IDE Connectivity and Diff Review

Claude Code treats IDE integration as a first-class client surface rather than a one-off helper. A faithful rebuild needs the full loop: discovery of eligible editor endpoints, startup auto-connect and extension bootstrap, live `/ide` selection and teardown, and the IDE-backed diff approval path that feeds edited content back into permission decisions.

## Scope boundary

This leaf covers:

- how the CLI discovers, validates, and selects IDE extension or plugin endpoints
- how startup chooses whether to auto-connect or auto-install IDE support
- how the `/ide` command connects, disconnects, opens the current repo, and manages auto-connect preferences
- how file-edit approvals can be offloaded into an IDE diff tab and then reconciled back into permission flow
- how onboarding, hints, disconnect notices, and lightweight IDE status surfaces are driven

It intentionally does not re-document:

- generic MCP transport and client lifecycle rules already captured in [structured-io-and-headless-session-loop.md](structured-io-and-headless-session-loop.md)
- generic plugin-provided LSP diagnostics already captured in [lsp-plugin-and-diagnostics.md](../plugins/lsp-plugin-and-diagnostics.md)
- the broader companion bootstrap surfaces for web, desktop, mobile, browser, and bridge already captured in [remote-setup-and-companion-bootstrap.md](remote-setup-and-companion-bootstrap.md)
- the generic permission dialog shell beyond the IDE-specific diff handoff already captured in [permission-prompt-shell-and-worker-states.md](../../ui-and-experience/permission-prompt-shell-and-worker-states.md)

## IDE presence is inferred from local endpoint files and workspace matching

Equivalent behavior should preserve:

- IDE discovery reading endpoint lockfiles from the standard local Claude config area, while also probing Windows-oriented locations when the CLI is running under WSL
- discovery accepting both richer JSON lockfiles and older plain path-list lockfiles so newer and older extension formats stay compatible
- lockfiles being sorted newest first and cleaned up before polling-driven auto-connect, so dead editors do not dominate discovery
- stale lockfiles being removed when they are unreadable, when their owning process is gone, or when their advertised port no longer answers
- validation preferring the current working directory or worktree context as the ownership test, not just "an IDE is running somewhere"
- path comparison normalizing macOS Unicode form, Windows drive-letter case, and WSL Windows-path conversion so the same workspace still matches across platform boundaries
- WSL-to-Windows matching rejecting IDE paths from a different distro instead of blindly assuming every Windows-reported path belongs to the current environment
- an explicit environment-port override being allowed to mark one IDE valid even when workspace matching would otherwise fail
- supported built-in terminal sessions doing an extra ancestor-PID check so overlapping workspace windows do not all look equally valid
- discovered IDE records carrying transport kind, auth token, Windows-hosting hint, stable display name, workspace folders, and reachable URL so later connection code does not need a second probe pass

## Startup auto-connect and extension bootstrap are gated, asynchronous, and preference-aware

Equivalent behavior should preserve:

- IDE discovery starting in the background without blocking the main REPL bootstrap
- auto-connect being enabled by a merged set of signals: saved preference, explicit CLI flag, supported built-in terminal, inherited extension port environment, explicit install target, or dedicated environment opt-in
- an explicit falsy environment override being able to disable auto-connect even when one of the positive signals is present
- startup only writing a dynamic IDE MCP config when an IDE is found and no IDE config is already active for the session
- the dynamic config preserving whether the endpoint uses SSE or WebSocket, along with IDE name, auth token, and Windows-hosting metadata
- polling-based "find one IDE for me" behavior searching for up to about half a minute, pausing while scroll-drain pressure is high, and only auto-selecting when exactly one eligible IDE survives validation
- extension auto-install defaulting on for supported VS Code-family editors, but remaining skippable through config or environment guards
- successful VS Code-family install setting the diff tool to auto when the user has not chosen another diff posture yet
- JetBrains support refusing to pretend that native auto-install exists, while still detecting the plugin and showing downstream onboarding or status affordances
- onboarding being tracked per terminal identity so one editor integration can be introduced once without suppressing onboarding for a genuinely different terminal or IDE path later
- internal or privileged builds being allowed to use a different extension-distribution path or a richer bidirectional SDK channel without changing the ordinary public connection contract

## `/ide` is a live selector over one dynamic MCP endpoint, not a separate runtime

Equivalent behavior should preserve:

- `/ide` without arguments presenting one selector over currently valid IDE endpoints plus a `None` choice for disconnect
- multiple instances of the same IDE family annotating selector rows with workspace-folder context, while single instances stay compact
- unmatched running IDEs being shown separately as "running but not for this cwd" rather than silently disappearing
- selecting an IDE from an external terminal being able to prompt for one-time auto-connect opt-in when that preference has never been decided
- selecting `None` while auto-connect is enabled being able to ask whether the preference should also be disabled, without forcing that global choice on every disconnect
- successful selection rewriting only the session's dynamic IDE MCP entry instead of spawning a second parallel integration subsystem
- connection monitoring skipping the first stale state check after config dispatch, then succeeding or failing based on the IDE MCP client's actual transition out of pending
- connection timeout remaining explicit so the command can fail even if the MCP state never resolves
- disconnect from an active IDE clearing the client-side cache, removing IDE-specific tools and commands, and suppressing reconnect-on-close behavior before dropping the dynamic config
- `/ide open` targeting the current worktree when one is active and otherwise the current cwd, so project handoff follows the same repo selection the REPL is already using
- VS Code-family editors attempting direct CLI open, while JetBrains or unsupported launch surfaces degrade to a manual-open instruction instead of falsely claiming handoff succeeded
- terminals that see running IDEs but no installed Claude integration being able to route into extension-install selection instead of dead-ending at "nothing found"

## IDE diff review is part of permission resolution, not a separate side workflow

Equivalent behavior should preserve:

- IDE diff review only activating when a connected IDE advertises the needed diff feature, the user diff preference is auto, and the operation is a file-edit-style change rather than an unsupported notebook write
- opening a diff by materializing the proposed edited file contents and sending them to one uniquely named IDE tab tied to the approval event
- converting file paths for WSL-hosted CLI to Windows-hosted IDEs before opening the diff, so the editor receives a path it can actually open
- treating IDE save, IDE tab close, explicit IDE reject, terminal accept, terminal reject, process exit, and tool-call abort as first-class completion paths that all reconcile through one cleanup model
- a saved IDE diff recomputing edits from old and new file contents so user amendments in the editor become the authoritative approval payload
- a closed diff tab without explicit rejection accepting the proposed patch contents as-is, while an explicit reject maps back to an ordinary permission rejection
- best-effort tab cleanup running on abort and process exit so orphaned IDE review tabs do not linger after the corresponding permission decision is gone
- the terminal-side "opened in IDE" approval prompt preserving symlink warnings, accept or reject feedback entry, and the same final permission options as the non-IDE file dialog
- starting a new prompt while an IDE is connected closing any lingering Claude-managed diff tabs first, so stale reviews do not accumulate across turns
- editor-facing file-update notifications remaining separate from diff review: normal file write, file edit, and snapshot updates can still notify an eligible IDE integration that files changed outside the special approval-tab loop

## Onboarding, hints, and status notices are conservative and context-aware

Equivalent behavior should preserve:

- IDE onboarding being dismissible with the normal confirmation keys and showing editor-specific tips rather than a generic feature list
- onboarding surfacing the connected or installed IDE name and, when known, the installed extension or plugin version
- external-terminal sessions without a connected IDE showing a delayed low-priority `/ide` hint only a small bounded number of times across sessions
- remote-mode sessions suppressing local IDE hints and disconnected-install warnings, because those notices are meaningless when the local editor is not the active control surface
- disconnected IDE status using the last known IDE name when available, so users see which editor lost connectivity
- JetBrains plugin-not-connected and install-failure notices being distinct from ordinary disconnect notices, because those states imply different next actions
- lightweight status consumers deriving `connected`, `pending`, `disconnected`, or absent state directly from the IDE MCP client wrapper rather than inferring status from unrelated UI conditions

## Failure modes

- **workspace false match**: IDE discovery ignores Unicode normalization, Windows case rules, WSL path conversion, or parent-process checks and connects to the wrong editor window
- **stale lockfile capture**: dead lockfiles or dead ports survive cleanup and keep auto-connect pinned to a non-existent IDE
- **auto-connect surprise**: startup connects even though the user or environment explicitly disabled IDE auto-connect
- **disconnect residue**: dropping an IDE leaves stale IDE tools, commands, or reconnect handlers alive in session state
- **diff orphaning**: approval tabs remain open or become authoritative after the corresponding permission request was canceled
- **edit-loss acceptance**: saved IDE changes are accepted without recomputing the final edit set, so user amendments disappear
- **launch false positive**: `/ide open` reports success even though the editor CLI never opened the project or worktree
- **notice spam**: `/ide` hints, install failures, or disconnect messages keep reappearing in contexts where the user cannot act on them
