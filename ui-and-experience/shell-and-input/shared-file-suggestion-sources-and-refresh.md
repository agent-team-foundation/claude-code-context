---
title: "Shared File Suggestion Sources and Refresh"
owners: []
soft_links: [/ui-and-experience/shell-and-input/prompt-composer-and-queued-command-shell.md, /ui-and-experience/shell-and-input/workspace-search-and-open-overlays.md, /integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md, /collaboration-and-agents/peer-addressing-discovery-and-routing.md, /tools-and-permissions/filesystem-and-shell/path-and-filesystem-safety.md]
---

# Shared File Suggestion Sources and Refresh

Claude Code's quick-open dialog and inline `@` file suggestions do not each walk the workspace independently. They share one file-suggestion data plane: one optional command override, one built-in repo-aware file inventory, one fuzzy file index, and one progressive refresh path. A faithful rebuild needs that shared contract, or the same query will surface different files depending on which UI happens to ask first.

## Scope boundary

This leaf covers:

- the shared file-suggestion engine reused by quick-open and prompt-shell `@` flows
- the command-based override that can fully replace the built-in file inventory
- the built-in source inventory, cache lifecycle, and progressive refresh model
- how file suggestions feed the broader unified `@` suggestion surface without owning MCP or agent identity logic

It intentionally does not re-document:

- quick-open and workspace-search dialog chrome already covered in [workspace-search-and-open-overlays.md](workspace-search-and-open-overlays.md)
- the broader prompt-shell suggestion arbitration already covered in [prompt-composer-and-queued-command-shell.md](prompt-composer-and-queued-command-shell.md)
- MCP resource state assembly already covered in [../../integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md](../../integrations/mcp/mcp-surface-state-assembly-and-live-refresh.md)
- peer-name or local-agent routing already covered in [../../collaboration-and-agents/peer-addressing-discovery-and-routing.md](../../collaboration-and-agents/peer-addressing-discovery-and-routing.md)
- explicit path-like directory completion for literals such as `@./`, `@~/`, or `@/`, which is a separate path-completion lane rather than this fuzzy file-suggestion lane

## One file-suggestion engine serves multiple surfaces

Equivalent behavior should preserve:

- quick-open asking the shared file-suggestion engine for file matches instead of owning a separate filesystem crawler
- inline `@` suggestion flows treating file results as one source inside a broader unified suggestion list that can also include MCP resources and agent identities
- file suggestions carrying stable `file-...` identities plus optional ranking metadata, so refreshed lists can preserve selection rather than jumping to a different row
- the shared engine being able to return both file paths and synthesized directory-like paths, while individual consumers decide whether directories are valid rows
- quick-open filtering directory-style entries back out before rendering, because its contract is file-centric even though the underlying file-suggestion engine is more general

## A configured command override is authoritative

Claude Code allows one explicit file-suggestion override in settings: a command-backed `fileSuggestion` source.

Equivalent behavior should preserve:

- the override being opt-in and command-shaped, not a generic plugin callback registry
- the override receiving structured hook-style input plus the current query string
- the override returning pre-ranked newline-delimited paths that the UI accepts as authoritative ordering
- the built-in file inventory not being mixed into those command results, because the override owns ranking and source selection when present
- command failure, trust denial, or hook-policy suppression yielding no file results rather than silently falling back to the built-in index
- managed-policy behavior still mattering: when ordinary hooks are disabled by non-managed settings, a managed `fileSuggestion` command can still run, but a managed disable-all-hooks posture blocks this lane entirely
- interactive workspace trust gating applying before the override command runs, so file suggestions cannot become an accidental command-execution bypass

## The built-in inventory is repo-aware and config-aware

When no command override is configured, the shared engine assembles one built-in inventory for fuzzy search.

Equivalent behavior should preserve:

- preferring `git ls-files --recurse-submodules` in git repos, with results normalized relative to the current working directory instead of always the repository root
- returning tracked files first, then fetching untracked files in the background and merging them later into the same normalized cache
- applying `.ignore` and `.rgignore` filters consistently to both tracked and untracked git-derived paths
- honoring the `respectGitignore` setting when deciding whether untracked-file discovery and ripgrep fallback should obey VCS ignore rules
- falling back to a ripgrep-based file walk when git enumeration is unavailable, while still excluding obvious VCS control directories
- adding Claude config markdown files into the searchable inventory, not only project files, across the known config families such as `commands`, `agents`, `output-styles`, `skills`, and `workflows` plus feature-gated families like `templates`
- synthesizing parent-directory entries with trailing separators so directory-oriented completions can reuse the same index instead of scanning the tree again
- an empty query or `.`-style query returning immediate top-level cwd entries while still kicking the background cache refresh path

## Refresh is progressive, shared, and intentionally throttled

The file-suggestion engine is designed to warm incrementally instead of blocking the shell on a cold full-tree scan.

Equivalent behavior should preserve:

- one lazy singleton fuzzy index shared by all file-suggestion consumers
- session-clear or resume-style cache resets fully invalidating that file-suggestion state, including cached tracked files, cached config files, ignore-pattern caches, and completion signals
- prompt-shell typeahead pre-warming the shared index on mount so the user's first `@` does not always pay the full cold-start cost
- quick-open and inline suggestion queries both being able to kick the same background refresh path instead of creating competing refresh loops
- refresh requests being coalesced while one build is already in progress
- a normal time throttle of roughly five seconds once a cache exists, so the product does not spawn git enumeration on every keystroke
- tracked-file changes bypassing that time floor when `.git/index` mtime moves, so checkouts or staged file updates refresh more eagerly than untracked-file churn
- path-list signatures skipping rebuilds when the tracked or merged path sets did not meaningfully change, even if git state churned
- async index construction yielding to the event loop in small time slices, allowing search to run against the ready prefix while the rest of the index is still building
- completion subscribers being notified when the background build finishes, so inline typeahead can rerun its last search and upgrade partial results to full results without losing selection state

## Shared ranking and consumer boundaries

Equivalent behavior should preserve:

- one shared fuzzy ranking model for built-in file suggestions rather than separate ad hoc scoring in quick-open and inline `@` flows
- smart-case matching semantics for the built-in index instead of one permanently case-insensitive matcher
- a stable top-N cap for file suggestions, so downstream overlays can rely on bounded row counts and bounded refresh churn
- file suggestions carrying their own score metadata when they are merged with MCP-resource or agent suggestions, so the broader unified `@` menu does not discard the file ranking just because other sources are scored differently
- slight de-prioritization of otherwise similar `test` paths inside the built-in ranking model, so production files win ties more often without hiding test files entirely
- quick-open preview loading, editor opening, mention insertion, and workspace text grep all staying consumer behaviors layered on top of this shared file-suggestion source rather than becoming part of the file inventory contract itself

## Failure modes

- **surface drift**: quick-open and inline `@` suggestions enumerate different file universes because they no longer share one inventory
- **override dilution**: a configured file-suggestion command is mixed with built-in results or silently falls back to them, destroying admin-owned ranking
- **trust bypass**: the command override runs even when workspace trust or managed hook policy should block it
- **stale cache**: git or untracked-file changes never reach suggestions until process restart
- **directory confusion**: consumers that expect file-only rows accidentally expose raw directory entries from the shared index
- **partial-result stall**: the background build completes, but inline typeahead never re-runs the search and stays stuck on an early partial prefix
- **ignore mismatch**: tracked and untracked paths obey different ignore filters and flicker in or out as the cache warms

## Test Design

In the observed source, shell-and-input behavior is verified through deterministic key-sequence regressions, store-backed integration coverage, and interactive terminal end-to-end checks.

Equivalent coverage should prove:

- input reducers, keybinding resolution, history state, and prompt composition preserve the invariants documented above
- queue, history, suggestion, and terminal-runtime coupling behave correctly with real stores, temp files, and reset hooks between cases
- multiline entry, fullscreen behavior, pickers, and suggestion surfaces work through the packaged interactive shell instead of only through isolated render helpers
