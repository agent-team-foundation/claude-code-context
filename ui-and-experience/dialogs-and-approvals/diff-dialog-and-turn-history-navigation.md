---
title: "Diff Dialog and Turn History Navigation"
owners: []
soft_links: [/product-surface/command-execution-archetypes.md, /integrations/clients/ide-connectivity-and-diff-review.md, /tools-and-permissions/filesystem-and-shell/path-and-filesystem-safety.md]
---

# Diff Dialog and Turn History Navigation

Claude Code's `/diff` command is not just a wrapper around `git diff`. It opens a modal terminal overlay that can show two classes of change sources at once: the current working tree versus the file edits produced by earlier turns in the active conversation. A faithful rebuild needs that source model, the list/detail navigation contract, and the special rendering branches for untracked, binary, large, truncated, and history-derived diffs.

## Scope boundary

This leaf covers:

- the `/diff` command opening a local JSX dialog instead of producing a model prompt
- how the dialog combines current uncommitted changes with per-turn edit history extracted from the conversation
- list-mode and detail-mode navigation, source switching, pagination, and dismissal behavior
- how the dialog classifies and renders ordinary, untracked, binary, large, truncated, and over-limit diff states
- how detail rendering enriches hunks with current file contents from disk when available

It intentionally does not re-document:

- generic command archetypes and local-JSX command loading already captured in [command-execution-archetypes.md](../product-surface/command-execution-archetypes.md)
- the separate IDE-backed diff approval flow already captured in [ide-connectivity-and-diff-review.md](../integrations/clients/ide-connectivity-and-diff-review.md)
- lower-level filesystem and path safety rules beyond the fact that detail view reads the file under the current workspace root, already captured in [path-and-filesystem-safety.md](../tools-and-permissions/filesystem-and-shell/path-and-filesystem-safety.md)
- the internals of patch parsing or syntax-highlighted structured diff rendering, now captured in [structured-diff-rendering-and-highlight-fallback.md](structured-diff-rendering-and-highlight-fallback.md)

## `/diff` opens a modal overlay, not a query or background task

Equivalent behavior should preserve:

- `/diff` being a local-JSX command that lazy-loads a dialog component instead of asking the model to describe a diff
- the command passing the current session message list into the dialog so history-derived turn diffs can be computed locally
- the dialog registering as an overlay so normal chat-oriented keybindings and cancel routing are suppressed while the diff modal is active
- the dialog exposing two view modes, `list` and `detail`, rather than combining file selection and hunk rendering in one scrolling surface
- dismissing the dialog from detail mode stepping back to list mode first, while dismissing from list mode closes the modal and returns a small system message instead of silently disappearing
- the footer guidance switching with dialog state, including the shared "press key again to exit" pending-dismiss hint from the common dialog shell

## Source selection merges live working-tree changes with conversation turn history

Equivalent behavior should preserve:

- the first diff source always representing the current working tree relative to `HEAD`
- additional diff sources being derived from earlier turns that performed file writes or edits during this session, labeled as turn-specific history rather than as git commits
- turn history being built incrementally from the message stream and cached across renders for efficiency
- the cache resetting when the message list shrinks, so conversation rewind or restore does not leave stale turn-diff entries behind
- a new turn starting only on a real user prompt, not on meta messages or tool-result envelopes
- file-edit tool results and file-write tool results both contributing to the current turn's diff set
- newly created files without a structured patch synthesizing an all-added hunk from the created file content so turn history still shows something meaningful
- repeated edits to the same file inside one turn accumulating hunks and line counts instead of overwriting earlier hunks from that turn
- completed turns and the current turn both computing aggregate file, added-line, and removed-line counts before display
- turn sources being shown most-recent-first, with current working-tree changes still pinned as the dedicated first source
- source changes resetting the selected file index to the first file and clamping the source index when the available source set shrinks

## Header and empty-state text depend on which source is active

Equivalent behavior should preserve:

- the current working-tree source showing a title equivalent to "uncommitted changes" with a `(git diff HEAD)` style subtitle
- turn-history sources showing a `Turn N` title plus a short preview of the originating user prompt when text content exists
- the source selector appearing only when more than one source is available and using simple current-versus-turn labels rather than full prompt text as tab labels
- loading the live git diff showing a dedicated loading message instead of momentarily pretending the tree is clean
- a turn source with no file edits reporting that the turn made no file changes
- current diff sources whose stats indicate changes but whose detailable file list is empty surfacing a dedicated "too many files to display details" style state rather than the ordinary clean-tree message
- live diff fetch failure degrading to the same empty-state branch as a clean tree instead of opening a separate error dialog

## Live working-tree diff data is fetched once and classified into display-specific file states

Equivalent behavior should preserve:

- the dialog fetching live diff stats and detailed hunks in parallel on mount rather than serially
- late responses being ignored after unmount so the modal does not update dead state
- file rows being constructed from per-file stats rather than from hunks alone, which allows files with omitted hunk detail to remain visible in the list
- a file being treated as untracked when the diff stats mark it that way, even if no normal hunk detail exists yet
- a file being treated as binary when the diff stats mark it as binary, which suppresses line-level diff rendering
- a file being treated as "large file modified" when it appears in per-file stats but has no hunk detail and is neither binary nor untracked
- a non-large, non-binary file being marked truncated when its total changed lines exceed the line-count ceiling used for detail rendering
- file rows being sorted by path before display so navigation order is stable

## List mode and detail mode have different navigation contracts

Equivalent behavior should preserve:

- list mode using up and down navigation to move among files, with selection clamped inside the available list
- list mode allowing entry into detail mode only when a file is actually selected
- left and right navigation in list mode switching between diff sources when multiple sources exist, while left in detail mode means "back to list" rather than "previous source"
- the visible file window being capped to a small fixed number of rows and centered around the selected file when possible
- pagination hints above and below the visible window showing how many files exist off-screen
- file paths truncating from the start to fit the terminal width while preserving the tail of the path, since the filename is usually the most informative part
- selected rows using a pointer plus inverted styling, while unselected rows remain plain text with side statistics
- side statistics branching by file type: `untracked`, `Binary file`, `Large file modified`, added and removed line counts, and an explicit truncated marker when applicable

## Detail view specializes heavily by file class and uses current on-disk content for enrichment

Equivalent behavior should preserve:

- opening detail view reading the currently resolved workspace file path only for the selected file, rather than preloading every file in the diff
- detail rendering using the file's current on-disk contents and first line as enrichment context for structured diff rendering when that file can be read
- turn-history detail using that current on-disk content as enrichment instead of storing historical file snapshots separately
- untracked files showing a dedicated explanation that the file is new and unstaged, plus a concrete hint to stage the file before expecting line counts
- binary files showing a dedicated non-renderable message instead of fake text diff output
- large files showing a dedicated "diff exceeds size limit" message instead of attempting to render partial hunks
- ordinary files rendering each structured patch hunk in sequence with no internal scrolling surface beyond the overall dialog
- truncated ordinary files carrying both a title marker and a footer note that the diff was cut off at the configured line ceiling
- files with no hunks but otherwise ordinary metadata showing an explicit "no diff content" message rather than rendering an empty screen

## Failure modes

- **history-cache drift**: turn diff entries survive a conversation rewind and show edits from turns that are no longer in the active transcript
- **create-file blind spot**: newly created files with empty structured patches disappear from turn history because no synthetic hunk is generated
- **source-switch selection leak**: changing sources leaves the old file index in place and lands on an out-of-range or unrelated file
- **state misclassification**: untracked, binary, large, and truncated files collapse into the same generic row and lose the product's type-specific guidance
- **clean-tree false positive**: live diff fetch failure is surfaced as a clean working tree even when the repository is not actually clean
- **historical-context mismatch**: rebuilds assume stored per-turn file snapshots exist, but the real product enriches turn diffs from the file's current on-disk contents
- **navigation flattening**: left and right keys stop meaning different things in list versus detail mode, making source switching and back-navigation feel wrong
