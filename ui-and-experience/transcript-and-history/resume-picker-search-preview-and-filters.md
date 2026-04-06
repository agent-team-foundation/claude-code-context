---
title: "Resume Picker Search, Preview, and Filters"
owners: []
soft_links: [/runtime-orchestration/sessions/resume-path.md, /runtime-orchestration/sessions/session-discovery-and-lite-indexing.md, /product-surface/session-utility-commands.md]
---

# Resume Picker Search, Preview, and Filters

Claude Code's interactive resume surface is a session browser, not a raw transcript file list. It layers filters, search, preview, rename, fork-group expansion, and cross-project safeguards over a lightweight discovery feed so users can recover the right conversation without loading every transcript up front.

## Scope boundary

This leaf covers:

- the interactive resume picker itself
- local filters, search mode, preview mode, and rename mode
- grouped session presentation and progressive loading behavior
- how the picker responds when a chosen session belongs to another project or worktree

It intentionally does not re-document transcript rehydration, file-history restoration, or remote-teleport resume internals once a session has already been selected.

## The picker starts from a curated discovery feed

Equivalent behavior should preserve:

- the picker receiving a prefiltered set of resumable top-level sessions rather than discovering raw transcript files on every keystroke
- subordinate or sidechain transcripts already being removed before the picker renders them as first-class choices
- current-session exclusion living above the picker, so the interactive list never offers "resume the session you are already in"
- same-repository scope, including sibling worktrees, being the default load posture
- optional entrypoint shaping from flags such as PR-only resume or an initial search term when a title-based CLI request was ambiguous
- progressive loading from lightweight session summaries first, with additional candidates fetched as focus approaches the end of the visible list
- full transcript bodies staying unloaded until preview or actual selection needs them

## One browser, multiple modes

Equivalent behavior should preserve:

- one resume surface switching among list, search, rename, and preview modes instead of opening unrelated dialogs for each task
- type-to-search from list mode immediately entering search mode and seeding the query with the typed character
- `/` explicitly entering search mode even when the user has not typed a seed character yet
- search-edit mode temporarily owning the keyboard so list navigation does not consume the same keystrokes
- leaving search-edit mode returning focus to the result list while preserving the current filtered query
- preview mode replacing the picker with a read-only transcript view plus session metadata and resume or cancel affordances
- rename mode replacing the list with a focused single-field editor rather than attempting in-row inline editing

## Search and filters are layered, not mutually exclusive

Equivalent behavior should preserve:

- tag tabs appearing when tags exist, with an `All` tab plus per-tag tabs that cycle with `Tab` and `Shift+Tab`
- current-branch filtering being independently toggleable from text search
- current-worktree filtering being independently toggleable when multiple worktrees are available
- current-project versus all-projects scope being a separate toggle that reloads the backing discovery feed rather than merely hiding rows client-side
- active branch and worktree filters surfacing as a secondary byline whenever search-edit mode is not currently using that header space
- text search matching at least displayed title, branch, tag, and PR metadata without requiring full transcript reads
- search mode being able to start from a caller-provided initial query, which is especially important when a CLI title lookup fell back to interactive disambiguation
- empty filtered states rendering a clear "no matching sessions" outcome instead of a blank picker

## Grouping, focus, and preview are session-aware

Equivalent behavior should preserve:

- builds with custom-title support grouping rows by stable session lineage, with the newest branch head as the parent row and older forks as expandable children
- single-session lineages remaining flat instead of paying tree chrome for no benefit
- group expansion state being user-controlled in normal list mode, but auto-expanded while branch filtering or live search-edit mode would otherwise hide relevant descendants
- the picker tracking both the focused row and a one-based visible index so header counts and progressive loading stay synchronized
- async result refreshes, such as loaded search results or newly fetched pages, reestablishing focus on a sensible first visible candidate instead of leaving focus dangling on a removed row
- preview lazily upgrading lite rows into full transcripts and then rendering the transcript with a read-only transcript presentation, relative modified time, message count, and branch metadata

## Rename and selection respect session identity

Equivalent behavior should preserve:

- rename only being offered when custom-title support is enabled for the install
- rename saving a non-empty custom title against the selected session lineage and then reloading the browser so the updated title is immediately visible in grouped results
- `Esc` cancelling rename without mutating the stored session title
- selection always targeting the full session object, even when the visible row came from a grouped tree node or a lite summary record
- actual resume beginning only after a concrete row is chosen, not while the user is still moving focus or previewing

## Cross-project safety is part of the picker contract

Equivalent behavior should preserve:

- same-repository worktree sessions being resumable directly even when they came from another checkout path
- truly different-project sessions, when surfaced through all-projects mode, refusing silent directory mutation
- that cross-project refusal producing an explicit `cd ... && claude --resume ...` style handoff command and copying it to the clipboard so the user can continue in the correct checkout
- all-projects mode annotating rows with project paths so cross-project surprises are understandable before selection, not only after failure

## Failure modes

- **filter blindness**: all-projects, current-branch, and current-worktree toggles conflict and hide the reason a session disappeared
- **fork collapse loss**: grouped lineage rows hide descendants that should stay visible under active filters or search
- **eager preview load**: the picker loads every full transcript just to render the list, destroying the lightweight discovery model
- **mode leakage**: search or rename keystrokes keep triggering list actions underneath the active submode
- **cross-project misresume**: selecting a session from another project silently resumes in the wrong checkout instead of forcing an explicit handoff
