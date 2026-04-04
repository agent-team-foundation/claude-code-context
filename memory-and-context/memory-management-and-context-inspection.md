---
title: "Memory Management and Context Inspection"
owners: []
soft_links: [/product-surface/command-surface.md, /memory-and-context/instruction-sources-and-precedence.md, /memory-and-context/context-cache-and-invalidation.md, /memory-and-context/compact-path.md, /integrations/clients/sdk-control-protocol.md, /ui-and-experience/system-feedback-lines.md]
---

# Memory Management and Context Inspection

Claude Code does not treat memory and context as invisible backend state. Users get one surface for editing the memory files that shape future turns and another for inspecting what the model is actually carrying right now. A faithful rebuild needs both surfaces to reuse the canonical loaders and analyzers; otherwise the editable memory list, the visible context budget, and the real prompt prefix will quietly drift apart.

## Scope boundary

This leaf covers:

- the interactive `/memory` command that opens or creates editable memory entrypoints
- the `/context` inspection surface in interactive and non-interactive modes
- the shared data-collection path reused by the SDK-style `get_context_usage` control request
- the toggle, notification, and suggestion behaviors that connect memory upkeep to visible user guidance

It intentionally does not re-document:

- memory discovery precedence, include expansion, and trust rules already covered in [instruction-sources-and-precedence.md](instruction-sources-and-precedence.md)
- cache invalidation semantics already covered in [context-cache-and-invalidation.md](context-cache-and-invalidation.md)
- compaction internals already covered in [compact-path.md](compact-path.md)

## Shared design rule

Equivalent behavior should preserve:

- `/memory` and `/context` being thin user-facing shells over the same canonical memory-discovery and context-analysis backends used elsewhere in the product
- those shells surfacing the state that actually affects future turns, rather than re-parsing a simplified shadow model for UI convenience
- the same relative-path formatting and breadcrumb language being reused across completion messages, status notices, and inline notifications so memory guidance feels like one feature instead of several disconnected hints

## `/memory` command contract

Equivalent behavior should preserve:

- `/memory` being an interactive local dialog rather than a headless or text-only command
- the command clearing and prewarming memory-file caches before first render so the selector opens with live data instead of flashing through an empty suspense state
- the selector listing all discovered editable memory files except auto-memory and team-memory entrypoint files, because those are exposed as folder actions instead of redundant file rows
- synthetic entries for the canonical user memory file and canonical project memory file even when those files do not exist yet, so users can create the main entrypoints from an empty repo
- the canonical user memory living at `~/.claude/CLAUDE.md`
- the canonical project memory living at `./CLAUDE.md` in the original working directory
- imported memory children and dynamically loaded nested memory files remaining visible in the selector with provenance-aware labeling instead of being flattened into one anonymous list
- nested include relationships rendering as indented child rows
- imported children being marked as include-derived while nested rule loads are marked as dynamically loaded
- the project-memory description changing based on repo state, so checked-in project memory is described differently from an unversioned local project file
- the last selected file path being remembered across repeated openings when that path still exists in the available options

## `/memory` toggle and folder actions

Equivalent behavior should preserve:

- the top of the `/memory` dialog containing inline controls for auto-memory and auto-dream, not just file rows
- auto-memory and auto-dream updates being written immediately to user settings so the UI does not wait for a later save step
- local optimistic state making those toggles feel immediate even though they persist through the normal settings layer
- auto-dream status preferring live task state from the current session when a consolidation job is already running
- auto-dream otherwise falling back to the last known consolidation timestamp from cross-process state, so the dialog can still say whether dream has never run or ran recently
- the dream row only appearing when auto-memory was enabled at dialog entry, so the interface does not collapse underneath the cursor mid-navigation if the user toggles auto-memory off
- the dream row pointing users toward `/dream` when dream is enabled but not currently running
- additional folder actions appearing when auto-memory is enabled: open auto-memory storage, open team-memory storage when team memory is active, and open per-agent memory directories for agents that declare dedicated memory scopes
- those folder actions ensuring the target directory exists and then opening it through the OS path opener, while swallowing directory-creation failures so the action remains best-effort instead of turning into a hard modal error

## `/memory` interaction and editor handoff

Equivalent behavior should preserve:

- keyboard navigation treating file selection and toggle confirmation as distinct contexts, so moving through the list does not accidentally flip settings
- moving upward from the first selectable file row handing focus into the toggle rows, and moving downward from the toggles returning control to the file list
- toggle-focused mode temporarily disabling the file selector so confirm keys only act on the focused toggle row
- Ctrl-C following the normal keyed exit path instead of leaving the dialog in a half-dismissed state
- selecting a real memory file creating the parent config directory first when the target lives under the user config home
- selecting a not-yet-created memory file creating it with an exclusive create step that preserves existing content if the file already appeared between discovery and selection
- file editing handing off to the external editor instead of embedding a custom inline markdown editor inside the terminal
- editor selection preferring `$VISUAL`, then `$EDITOR`, then the default editor path
- completion output naming the opened file with the shortest sensible path form, choosing between home-relative and cwd-relative display rather than always printing an absolute path
- completion output also explaining which editor setting was used and how to change it
- canceling the dialog producing a normal system-style completion message rather than failing silently

## Memory breadcrumbs outside the dialog

Equivalent behavior should preserve:

- memory update notifications using the same relative-path formatter as `/memory`
- those notifications explicitly pointing the user back to `/memory` for follow-up edits
- saved-memory transcript messages remaining compact summaries that keep the written paths visible instead of collapsing into a generic "memory updated" line
- oversized memory-file notices warning that large files hurt performance and using `/memory` as the remediation path

## `/context` surface topology

Equivalent behavior should preserve:

- one command name, `/context`, being exposed through two different user-facing renderers depending on session mode
- interactive sessions getting a local terminal visualization rather than a plain text dump
- non-interactive sessions getting a text/markdown report instead of terminal-grid UI
- a third consumer, the SDK-style `get_context_usage` control request, reusing the same shared collector but returning structured data rather than either human renderer
- these three surfaces sharing one canonical collection pipeline so a user, a script, and an SDK host all inspect the same logical context state

## `/context` pre-API normalization rule

Equivalent behavior should preserve:

- `/context` showing what the model is actually about to receive, not the raw transcript buffer as stored in the REPL
- context analysis first dropping any history that lives before the most recent compact boundary
- context-collapse mode projecting the transcript into the same collapsed view used for real API submission before token analysis runs
- microcompaction being applied before analysis so the displayed token count reflects post-transform messages instead of overcounting already-compressed history
- the collector still retaining access to the original messages so API-reported token usage can be extracted from the last response and kept aligned with the status line

## Shared context accounting contract

Equivalent behavior should preserve:

- runtime model selection inside the analyzer honoring both the requested main model and the currently effective permission mode
- system-prompt accounting using the same effective system-prompt builder as real turns, including custom system prompts and append-only prompt text when provided by a client surface
- memory-file accounting reusing injected memory discovery and excluding memory-file reporting entirely in simple mode, because simple mode does not inject those files into live context
- built-in tool accounting separating generic built-in tool cost from skills so skill frontmatter is shown in its own category without double-counting tool-schema overhead
- skill accounting using frontmatter-level estimates for discoverable skills rather than pretending full skill bodies are preloaded into every turn
- MCP accounting distinguishing tools already loaded into the turn from tools that are merely available on demand when tool-search-style deferral is active
- custom-agent accounting flowing through the existing agent-definition loader rather than rescanning agent files inside the command
- message usage being estimated for category breakdown but replaced with API-derived input totals when a real usage record is available, so `/context` and the status line agree about how full the conversation is

## Context category model

Equivalent behavior should preserve this logical ordering:

- system prompt
- built-in system tools
- MCP tools
- deferred MCP tools when applicable
- deferred built-in tools when applicable
- custom agents
- memory files
- skills
- messages
- reserved compaction space when applicable
- free space

Equivalent behavior should also preserve:

- deferred categories being visible for explanation purposes but excluded from the live-usage percentage, because they do not occupy prompt budget until activated
- auto-compaction reserve showing up as a dedicated reserved category when proactive autocompaction is the active strategy
- a smaller manual compact reserve appearing when proactive autocompaction is off
- reactive-only compaction modes not showing a fake reserved buffer at all
- context-collapse mode also suppressing the reserved-buffer visualization because collapse, not autocompact, owns the active pressure strategy

## Interactive `/context` visualization contract

Equivalent behavior should preserve:

- the interactive view rendering as a colored grid plus legend instead of only tables
- grid size scaling with both model class and terminal width
- ordinary-width 200k-class models using a 10x10 grid
- narrow terminals using a 5-wide grid
- million-token-class models expanding to 20x10 on ordinary terminals and 5x10 on narrow terminals
- free space, reserved compaction space, and ordinary filled categories using different marker styles so users can see both occupancy and buffer policy at a glance
- the legend showing effective model, total used tokens, max tokens, and percentage in one compact header
- context-collapse mode injecting a strategy line into that legend, including summarized spans, staged spans, failure counts, or repeated idle runs when those states exist
- the interactive view rendering sections for MCP tools, custom agents, memory files, and skills beneath the grid
- MCP sections splitting loaded tools from merely available tools when on-demand loading is active
- custom agents and skills being grouped by source class instead of one flat mixed list
- memory files being listed with display paths and token counts so users can see which files are crowding out message history
- some deeper breakdowns remaining optional or internal-only rather than cluttering the ordinary user-facing visualization

## Suggestions and remediation hints

Equivalent behavior should preserve:

- `/context` generating actionable suggestions from the analyzed data instead of only showing raw numbers
- near-capacity warnings pointing users toward `/compact` and explaining whether autocompaction will or will not step in
- large tool-result warnings specializing by tool family, with stronger guidance for shell output, file reads, grep-heavy scans, and web fetches
- memory-bloat suggestions pointing back to `/memory` and naming the largest contributing memory files
- suggestions being sorted with warnings before informational hints, then by estimated savings potential

## Non-interactive and SDK output contracts

Equivalent behavior should preserve:

- non-interactive `/context` returning a markdown-style report rather than ANSI grid UI
- that report including overall model and usage, category tables, MCP tool tables, custom agent tables, memory-file tables, and skills tables when data exists
- context-collapse status also appearing in the non-interactive report, including failure or idle information when relevant
- source labels in the report being normalized into human categories such as project, user, local, policy, plugin, or built-in
- richer internal/debug builds being able to include extra sections such as system prompt or message-breakdown details without changing the ordinary shared collector
- the SDK `get_context_usage` request receiving the raw structured context object rather than preformatted human text, so host clients can build their own visualizations without reverse-parsing markdown

## Failure modes

- **memory/editor drift**: `/memory` lists or edits a different set of files than the actual instruction loader uses, so the user changes one thing while live turns keep reading another
- **missing entrypoints**: empty projects cannot create canonical user or project memory because the selector only lists already-existing files
- **provenance loss**: imported or nested memory files flatten into one unlabeled list and users can no longer tell whether a file is root memory, include-derived, or dynamically loaded
- **toggle surprise**: auto-memory or auto-dream settings update only after dialog exit, or rows vanish while focus is still on them
- **folder/file confusion**: auto-memory or team-memory storage appears as both a folder action and a redundant file row, leading users to edit the wrong artifact
- **context overcount**: `/context` analyzes raw transcript history instead of the post-compact, post-collapse, microcompacted API view and therefore exaggerates actual prompt usage
- **surface split-brain**: interactive `/context`, headless `/context`, and `get_context_usage` each implement their own accounting path and disagree about the same session
- **deferred-tool inflation**: available-on-demand MCP or built-in tools are counted as already loaded, making the context budget look fuller than the model actually sees
- **status mismatch**: `/context` percentages and the main status line diverge because one uses API usage totals while the other only uses local estimates
