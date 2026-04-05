---
title: "Workspace Search and Open Overlays"
owners: []
soft_links: [/ui-and-experience/prompt-composer-and-queued-command-shell.md, /product-surface/command-surface.md, /tools-and-permissions/path-and-filesystem-safety.md]
---

# Workspace Search and Open Overlays

Claude Code's quick-open and workspace-search popups are not generic autocomplete menus. They are modal retrieval overlays that let the user either jump into an external editor or inject structured file references back into the live prompt without losing the current draft.

## Scope boundary

This leaf covers:

- the file-oriented quick-open overlay
- the text-oriented workspace search overlay
- how those overlays take over prompt focus, preview the focused result, and hand inserted references back into the composer

It intentionally does not re-document:

- ordinary inline slash-command or file-completion dropdowns already covered in [prompt-composer-and-queued-command-shell.md](prompt-composer-and-queued-command-shell.md)
- resume-style browsing surfaces that work over sessions rather than workspace files
- low-level filesystem permission policy beyond the fact that both overlays preview files under the active workspace root

## One gated overlay family hangs off the prompt shell

Equivalent behavior should preserve:

- quick-open and workspace-search existing only in builds that enable the quick-search feature family
- their global shortcuts activating only when another modal overlay is not already active
- opening either overlay dismissing the help surface first so the keyboard is owned by only one modal layer
- each overlay registering itself as a modal owner so ordinary prompt editing, footer navigation, and cancel handling do not leak underneath it
- insertion actions routing through the prompt shell's normal cursor-aware insert path instead of replacing the whole draft
- insertions automatically adding a separating space when the cursor is adjacent to non-whitespace text, so injected references do not collide with surrounding tokens

## Quick-open is file-centric, not grep-centric

Equivalent behavior should preserve:

- quick-open searching the workspace's file suggestions rather than scanning transcript history or session metadata
- an empty query showing an explicit "start typing" empty state instead of dumping the current directory contents
- directory rows being filtered out so the result list always represents selectable files
- displayed paths being normalized into one portable slash-based form before rendering or insertion, so cross-platform path formatting stays stable
- focused results loading a short preview from the beginning of the file rather than from an arbitrary cached excerpt
- moving focus aborting the previous preview read so slow file I/O cannot overwrite the newer selection's preview
- unreadable or unpreviewable files degrading to a small explicit fallback instead of leaving the preview pane stuck in a loading state
- primary selection opening the chosen file in the user's external editor
- secondary actions supporting both mention-style insertion and plain-path insertion into the prompt

## Workspace text search is incremental and match-centric

Equivalent behavior should preserve:

- workspace text search using a debounced external grep-style search instead of blocking the UI on one synchronous full-tree scan
- changing the query cancelling both the prior search job and any pending debounce timer for it
- clearing the query resetting the result list, truncation state, and searching indicator instead of leaving stale matches on screen
- narrowing a query being allowed to filter already visible matches immediately while the new backend search is still warming up, so the dialog does not flash blank between keystrokes
- streamed search chunks appending unique file-and-line matches instead of replacing the list on every chunk, which keeps counts and focus stable during long searches
- result accumulation staying memory-bounded and surfacing that truncation happened when the total-match ceiling is reached
- focused matches previewing a few lines of surrounding file context centered on the match location
- primary selection opening the external editor directly at the matched line
- secondary actions supporting both mention-style line references and plain `path:line` style insertion into the prompt

## Layout, preview, and status adapt to the terminal

Equivalent behavior should preserve:

- both overlays shrinking their visible result count on short terminals so dialog chrome and hints do not clip
- the preview pane moving to the right on wide terminals and below the list on narrower ones
- rows truncating long paths in a filename-preserving way, while preview lines and match text are width-capped for stable rendering
- the current query being highlighted in both list rows and preview text
- the empty state, loading state, match count, and truncation state being explicit parts of the dialog chrome rather than implied by a blank area

## Failure modes

- **overlay leakage**: quick-open or workspace-search is visible, but prompt-shell keybindings still fire underneath it
- **preview race**: a slower file read overwrites the preview for the row the user has already moved away from
- **directory confusion**: quick-open shows directory rows that cannot actually be previewed or opened as files
- **search flicker**: incoming workspace-search chunks replace the entire list and make counts or focus jump around during typing
- **reference drift**: insert actions replace the whole prompt or omit needed spacing, corrupting the user's in-progress draft
- **silent truncation**: the workspace-search backend caps results, but the UI fails to indicate that more matches existed
