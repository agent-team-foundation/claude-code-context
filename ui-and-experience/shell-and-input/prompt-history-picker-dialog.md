---
title: "Prompt History Picker Dialog"
owners: []
soft_links: [/ui-and-experience/shell-and-input/prompt-history-persistence-and-paste-store.md, /ui-and-experience/shell-and-input/prompt-composer-and-queued-command-shell.md, /ui-and-experience/shell-and-input/vim-mode-and-modal-editing.md]
---

# Prompt History Picker Dialog

Claude Code's modal history picker is a browsing-oriented prompt-recall surface. It is distinct from both Up-arrow history stepping and inline reverse search: it opens a dedicated overlay, seeds itself from the current draft, shows timestamped candidates with previews, and restores full prompt state when the user picks one.

## Scope boundary

This leaf covers:

- the modal prompt-history picker dialog itself
- its loading, filtering, ranking, and preview behavior
- how selection hands a historical prompt back into the live composer

It intentionally does not re-document:

- durable history storage, paste-cache persistence, or picker projection rules already captured in [prompt-history-persistence-and-paste-store.md](prompt-history-persistence-and-paste-store.md)
- ordinary prompt editing and overlay arbitration already captured in [prompt-composer-and-queued-command-shell.md](prompt-composer-and-queued-command-shell.md)
- generic Vim editing semantics outside the fact that restoring a history item must restore the correct composer mode

## The picker is a separately gated modal recall surface

Equivalent behavior should preserve:

- the modal picker being independently feature-gated from inline reverse-search history
- its global trigger only activating when no other modal overlay already owns the prompt
- opening the picker dismissing the help surface first, so it becomes the sole keyboard owner
- the picker registering as an overlay and suspending ordinary prompt-shell input handling until the dialog closes
- the initial query being seeded from the user's current draft, allowing the picker to act as "search for something like what I was already typing"

## Loading and filtering are browse-oriented, not step-oriented

Equivalent behavior should preserve:

- the picker consuming a timestamped history projection rather than stepping one entry at a time through the Up-arrow cache
- entries loading asynchronously so large history logs can stream in without blocking the UI thread
- a visible loading state appearing until the initial candidate list is ready
- empty query showing the full picker projection, while non-empty query filters in memory
- ranking placing direct substring matches ahead of looser subsequence matches instead of treating all fuzzy hits as equal
- each candidate carrying both a one-line browsing label and enough hidden payload to resolve the full historical prompt only after selection

## Rows and preview optimize for scanning

Equivalent behavior should preserve:

- list rows showing the prompt's first visible line plus a compact relative-age column
- age labels being width-normalized so the text column remains visually aligned while browsing
- the focused row opening a wrapped multiline preview of the stored visible prompt text
- preview overflow being summarized explicitly instead of forcing an internal scroll region inside the preview pane
- the preview pane moving to the side on wider terminals and below the list on narrower ones
- empty results producing a clear "no matching prompts" state rather than a blank overlay

## Selection restores full composer state, not only text

Equivalent behavior should preserve:

- selecting a row first resolving the full history entry, including any separately stored pasted-content payloads
- the composer restoring the historical editing mode as well as the historical prompt value, so bash-style entries do not come back as ordinary chat text or vice versa
- the restored buffer using the clean prompt value rather than any internal decorated display form
- prompt-local pasted contents being restored alongside the visible text
- the cursor being placed at the end of the restored value for immediate editing or submission
- cancel closing the picker without mutating the live draft

## Failure modes

- **surface collapse**: the modal picker degenerates into the same semantics as Up-arrow replay and loses its browse-oriented ranking and preview behavior
- **mode amnesia**: selecting a historical bash-style entry restores only text and forgets the original composer mode
- **paste loss**: the picker shows the right visible prompt but fails to rehydrate the hidden pasted-content payload behind it
- **ranking noise**: loose fuzzy matches outrank obvious substring hits and make the picker feel unpredictable
- **overlay bleed**: the picker is on screen, but prompt or footer keybindings still react underneath it

## Test Design

In the observed source, shell-and-input behavior is verified through deterministic key-sequence regressions, store-backed integration coverage, and interactive terminal end-to-end checks.

Equivalent coverage should prove:

- input reducers, keybinding resolution, history state, and prompt composition preserve the invariants documented above
- queue, history, suggestion, and terminal-runtime coupling behave correctly with real stores, temp files, and reset hooks between cases
- multiline entry, fullscreen behavior, pickers, and suggestion surfaces work through the packaged interactive shell instead of only through isolated render helpers
