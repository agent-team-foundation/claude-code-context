---
title: "Agent Management Surface"
owners: []
soft_links: [/product-surface/command-dispatch-and-composition.md, /tools-and-permissions/tool-catalog/agent-definition-loading-and-precedence.md, /tools-and-permissions/execution-and-hooks/agent-runtime-context-and-tool-shaping.md, /memory-and-context/durable-memory-recall-and-auto-memory.md, /collaboration-and-agents/multi-agent-topology.md, /ui-and-experience/dialogs-and-approvals/focused-dialog-and-overlay-arbitration.md]
---

# Agent Management Surface

Claude Code's agent surface is not just one interactive file browser over agent markdown. The observed product family includes a local `/agents` management UI and, in the analyzed source snapshot plus released CLI evidence, a separate top-level `claude agents` listing command. They share one underlying agent catalog, but they do not share the same mutation affordances or presentation contract.

A faithful rebuild needs to preserve the distinction between "all discovered agent definitions the operator can inspect," "the smaller active set that currently wins at runtime," and "which entrypoint is allowed to mutate anything at all."

## Scope boundary

This leaf covers:

- `/agents` as a local UI surface rather than an ordinary transcript turn
- the version-sensitive top-level `claude agents` read-only listing surface exposed by the analyzed source snapshot and validation corpus
- the user-visible list, detail, create, edit, and delete flows for agent definitions
- which source classes are surfaced, which ones are view-only, and which ones are valid creation targets in the observed UI
- how the interactive and non-interactive agent entrypoints share catalog semantics but diverge on presentation and mutation affordances

It intentionally does not re-document:

- catalog assembly and runtime precedence already covered in [../tools-and-permissions/tool-catalog/agent-definition-loading-and-precedence.md](../tools-and-permissions/tool-catalog/agent-definition-loading-and-precedence.md)
- runtime tool shaping after an agent is launched, already covered in [../tools-and-permissions/execution-and-hooks/agent-runtime-context-and-tool-shaping.md](../tools-and-permissions/execution-and-hooks/agent-runtime-context-and-tool-shaping.md)
- general modal focus arbitration already covered in [../ui-and-experience/dialogs-and-approvals/focused-dialog-and-overlay-arbitration.md](../ui-and-experience/dialogs-and-approvals/focused-dialog-and-overlay-arbitration.md)

## The entrypoint is local and tool-context-aware

Equivalent behavior should preserve:

- `/agents` opening a local JSX management dialog instead of appending a user message and re-entering the main query loop
- the surface receiving its tool inventory from the current permission-context tool set plus the live MCP merge, so tool-related detail views and editors reflect the current session rather than a frozen global registry
- dismissal returning a local result summary such as "dialog dismissed" or a compact list of agent changes, rather than polluting the transcript with synthetic turns

## The top-level listing command is read-only and version-sensitive

The analyzed source snapshot and the current reconstruction validation corpus expose a top-level `claude agents` command that is distinct from the interactive `/agents` surface. The local `claude 2.1.19` help output on this machine does not advertise that command, so the safest clean-room claim is that this is a **version-sensitive public surface**, not a universal guarantee for every released build.

Equivalent behavior should preserve:

- when present, `claude agents` staying a plain CLI listing command instead of opening the local JSX manager
- that command remaining read-only: it lists agent state, but does not create, edit, or delete agent definitions
- the top-level command sharing the same discovered-versus-active catalog semantics as the interactive surface instead of inventing a second narrower agent inventory
- source grouping and alphabetical ordering staying consistent between the top-level command and the interactive manager
- the text surface leading with an active-agent count, then printing grouped source sections
- shadowed entries remaining visible in that text output, annotated by the winning source instead of disappearing from the listing entirely
- an explicit `No agents found.` empty state instead of a silent success exit
- source filtering options such as settings-source narrowing affecting this top-level list before it renders, not being ignored just because the output is non-interactive

The key reconstruction lesson is that the product can expose the same agent catalog through both a modal operator UI and a simple text command without collapsing them into one UX.

## Listing preserves source and override semantics

Equivalent behavior should preserve:

- the list being built from the broader discovered agent catalog, not only from the smaller runtime-winning subset
- the default view grouping non-built-in agents by source family while still showing built-in agents in a separate always-available section
- the surfaced source classes including user, project, local, managed, plugin, CLI-argument, and built-in agents, even though not every source class supports the same mutations
- built-in agents remaining visible for inspection but excluded from ordinary keyboard selection and mutation flows
- shadowed agents remaining visible instead of disappearing, with explicit override labels naming the winning source
- list rows surfacing quick behavioral cues such as model and memory status so users can compare competing agent definitions without opening every detail view

The reconstruction-critical point is that `/agents` is an operator view over both active and inactive definitions. It is not just a view over whichever agent currently wins by precedence.

Those same grouping and override semantics should also be the baseline for any top-level `claude agents` listing surface that the targeted version exposes.

## Detail view exposes definition-shaping fields without flattening sources

Equivalent behavior should preserve:

- selecting an editable entry opening an agent menu with view, edit, delete, and back actions, while non-editable entries keep only view and back
- the detail view showing source-aware location labels, including relative file paths for file-backed agents plus special labels for built-in, plugin, and CLI-injected entries
- the detail view exposing description, resolved tool list, model, permission mode, memory, hooks, skills, and color as first-class user-visible fields
- non-built-in agents showing their system prompt body in the detail view, while built-ins stay inspectable without pretending their prompt body is user-editable content
- invalid or unresolved tools being surfaced as warnings in the detail view instead of being silently normalized away

## Creation is a guided file-authoring workflow

Equivalent behavior should preserve:

- "Create new agent" being a first-class action inside the `/agents` surface rather than a separate hidden admin entrypoint
- the observed public create flow first choosing between project and personal destinations, not exposing built-in, plugin, CLI-argument, local, or managed destinations as ordinary creation targets
- the next step choosing between manual configuration and model-assisted generation
- model-assisted generation accepting a freeform description, supporting external-editor handoff for that prompt, allowing escape-driven cancellation while generation is in flight, and then continuing with the generated identifier, description, and prompt prefilled
- the manual path skipping generation and continuing through explicit type, prompt, and description entry
- both paths ultimately flowing through tools, model, color, and conditional memory steps before confirmation
- the confirmation step saving a markdown-backed agent file and optionally opening that file in the external editor immediately after creation

The create contract is intentionally narrower than the full source taxonomy. The surface acknowledges more source classes than it offers as public write targets.

## Editing is intentionally split between structured tweaks and editor handoff

Equivalent behavior should preserve:

- inline edit and delete actions being available only for file-backed sources the observed menu treats as editable: user, project, local, and managed agents when present
- built-in, plugin, and CLI-argument agents remaining view-only in this menu path
- the inline edit menu offering a small structured set of mutations: open in editor, edit tools, edit model, and edit color
- prompt-body and description rewrites being routed through external-editor handoff instead of a large in-dialog text editor
- file-backed save, update, and delete operations targeting source-specific paths rather than one universal agent directory
- delete remaining a two-step destructive action with explicit yes/no confirmation and visible source context

## Failure modes

- **surface conflation**: `claude agents` is rebuilt as an alias for the interactive `/agents` manager, or `/agents` loses its richer local mutation UI and collapses into a text dump
- **source flattening**: rebuilds show only active agents and hide shadowed definitions, erasing the operator-facing distinction between discovered and winning entries
- **mutation overreach**: built-in, plugin, or CLI-argument agents are treated as ordinary editable records even though the observed surface keeps them view-only
- **creation drift**: the public wizard offers unsupported creation targets for every source class instead of preserving the narrower project/personal authoring contract
- **editor collapse**: structured edits and external-editor edits are merged into one generic form, losing the observed split between small safe tweaks and full file editing
- **stale tool picker**: tool detail and editing surfaces ignore the live merged tool inventory and therefore drift from the session's real permission and MCP state

## Test Design

In the observed source, product-surface behavior is verified through command-focused integration tests and CLI-visible end-to-end checks.

Equivalent coverage should prove:

- parsing, dispatch, flag composition, and mode selection preserve the public contract for this surface
- the top-level listing command, when the targeted version exposes it, preserves grouped source ordering, active counts, and shadowed-entry labeling without requiring the interactive UI
- downstream runtime, tool, and session services receive the correct shaping when this surface is used from interactive and headless entrypoints
- user-visible output, exit behavior, and help or error routing remain correct through the packaged CLI path rather than only direct module calls
