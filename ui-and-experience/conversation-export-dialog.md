---
title: "Conversation Export Dialog"
owners: []
soft_links: [/product-surface/session-utility-commands.md, /product-surface/command-execution-archetypes.md, /runtime-orchestration/session-artifacts-and-sharing.md]
---

# Conversation Export Dialog

Claude Code treats transcript export as a user-facing delivery surface, not as permission to dump internal session artifacts. The `/export` flow first prepares one plain-text conversation artifact, then either copies it to the clipboard or saves it to a workspace-local text file through a small modal chooser.

## Scope boundary

This leaf covers:

- the local dialog shown by `/export` when no explicit filename argument is supplied
- the clipboard-versus-file branch inside that dialog
- filename editing, back-navigation, and completion feedback

It intentionally does not re-document:

- the lower-level renderer that turns structured conversation state into exportable plain text
- transcript sharing or remote handoff flows that have different consent and artifact rules
- generic local-JSX command loading beyond the fact that `/export` stays local instead of becoming a model prompt

## Export prepares one plain-text artifact before delivery

Equivalent behavior should preserve:

- `/export` producing one user-facing plain-text conversation artifact before either clipboard or file delivery happens
- the same rendered export artifact being reused for both delivery branches, so copy and save do not diverge in content
- an explicit filename argument bypassing the interactive chooser and writing directly to disk after normalizing the output extension
- success or failure from either path being reported back as a concise session-visible status message

## The dialog is a two-stage chooser, not a mixed form

Equivalent behavior should preserve:

- the default `/export` surface opening as a small modal chooser with clipboard and file options
- choosing clipboard acting immediately and closing the dialog instead of asking for extra confirmation
- choosing file transitioning into a dedicated filename-entry submode rather than trying to mix option navigation and filename typing on one screen
- the default filename being prefilled before that submode opens, so export is one Enter away in the common case
- the default filename deriving from a sanitized first user prompt when available and otherwise falling back to a timestamped generic conversation name
- saved files always normalizing to a plain-text extension even when the user typed a different or missing suffix

## Filename entry must behave like real text input

Equivalent behavior should preserve:

- filename editing exposing a real cursor-aware text field rather than a fixed prompt string with append-only typing
- `Esc` from filename-entry mode stepping back to the option chooser instead of cancelling export outright
- `Esc` from the option chooser cancelling the whole export flow
- generic confirmation shortcuts not stealing ordinary characters from the filename field while the user is typing
- file output being rooted in the current workspace directory rather than some detached global export folder

## Clipboard and file completion paths are both best-effort

Equivalent behavior should preserve:

- clipboard export using the terminal's clipboard handoff channel and then closing with a success message when the handoff succeeds
- file export attempting a synchronous write of the prepared plain-text artifact and surfacing the concrete filesystem error if writing fails
- both completion paths collapsing back into one small status-line style acknowledgement instead of leaving the dialog open after work is done

## Failure modes

- **artifact drift**: clipboard and file export are rendered through different code paths and produce different transcript content
- **cancel confusion**: pressing escape inside filename entry aborts the entire export instead of stepping back one level
- **shortcut theft**: filename entry is active, but global confirmation bindings still consume ordinary typing
- **raw-artifact leakage**: export writes internal transcript envelopes rather than the user-facing plain-text rendering
- **naming mismatch**: direct-argument export and dialog-driven export normalize filenames differently and surprise users
