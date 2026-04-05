---
title: "Instruction Sources and Precedence"
owners: []
soft_links: [/memory-and-context/context-bootstrap.md, /memory-and-context/memory-layers.md, /memory-and-context/durable-memory-recall-and-auto-memory.md, /memory-and-context/session-memory.md, /platform-services/workspace-trust-dialog-and-persistence.md, /reconstruction-guardrails/source-boundary.md]
---

# Instruction Sources and Precedence

Claude Code does not have one monolithic "session prompt file." It assembles instruction-bearing memory from several sources, and the load order is part of the behavior contract.

## Instruction classes

Reconstruction should preserve the distinction between three classes of memory:

- **baseline instruction layers** that are loaded eagerly for the session
- **path-conditioned rules** that only apply when a target file or nested path is relevant
- **durable memory entrypoints** such as auto-memory or team memory that travel through the same discovery pass but should not be treated as ordinary instruction overrides

If these classes are flattened together, the rebuilt system will either over-inject or under-inject guidance.

## Relationship to other memory layers

Instruction precedence does not flatten every other memory type into the same stack.

- session memory should stay a session-scoped working note, not an overriding baseline instruction file
- durable-memory recall should be selected after discovery and injected as explicit recall context, not treated as a higher-priority project rule
- compaction summaries may replace older transcript context, but they should not silently rewrite the underlying instruction source order

## Baseline discovery and precedence

The default baseline instruction stack should be discovered in this order:

1. **managed global instructions**
2. **user global instructions**
3. **checked-in project instructions**
4. **private local project instructions**

Within that stack, later-loaded material has higher effective priority. The important consequences are:

- local project instructions outrank checked-in project instructions
- project instructions closer to the active working directory outrank ones from higher directories
- explicitly added project directories form an extra overlay after ordinary cwd-upward discovery when that feature is enabled
- managed instructions are the broadest, lowest-priority layer rather than a separate hard-coded prompt block

At each directory level, the rebuild should treat checked-in instruction files and checked-in rule directories as one project layer, then apply the local private file after them.

## Discovery surface

Equivalent implementations should support the same discovery model:

- a user-global instruction home
- a managed or enterprise-controlled instruction home
- cwd-upward traversal through ancestor directories
- checked-in project files in both the directory root and a hidden project config subdirectory
- rule files inside project, user, and managed rule directories
- optional instruction discovery for explicitly added working directories

The important invariant is not the exact source layout. It is that the runtime can merge broad global guidance, checked-in repo guidance, and private local guidance into one ordered instruction stream.

## Mode-specific discovery narrowing

Equivalent behavior should preserve that startup mode can narrow which instruction sources are considered without changing precedence among sources that remain eligible.

- bare/simple sessions suppress managed, user, and automatic cwd-upward project discovery by default
- explicit additional directories can still contribute project-style instruction layers when the caller intentionally enables that path
- local/private instruction files participate only when the local settings source is enabled; disabling that source removes the whole layer rather than leaving a ghost placeholder
- these mode- or policy-driven cuts change source eligibility, not the effective priority ordering of files that still load

## Include expansion and filtering

Instruction files are not just raw markdown blobs. They support a constrained include mechanism.

Important rules:

- includes are discovered from markdown text nodes, not from code blocks or code-like strings
- include paths resolve relative to the including file unless they are explicitly absolute or home-relative
- include recursion must be cycle-safe and depth-bounded
- non-text payloads should be rejected from include expansion instead of being injected as garbage
- excluded memory paths must stay excluded even if reached through symlinks or alternate path spellings

Included files should become their own instruction records with parent linkage for auditability, instead of being flattened into the parent without provenance.

## External include trust boundary

External includes are not all treated the same.

Reconstruction should preserve these distinctions:

- user-global instructions may include external files without extra workspace approval
- managed, project, and local instruction layers may reference external files, but those references should not be trusted until the workspace-level approval flow allows them
- the system needs a way to enumerate which external includes would become active if approved so the user can review them

This boundary is important because instruction loading is also a security surface.

## Selective rule loading

Not every rule file belongs in the eager baseline.

Some rule files are path-conditioned and should only enter context when their declared path globs match a target file or nested directory flow. A correct rebuild should therefore support:

- managed and user conditional rules that match against the active project-relative target path
- project conditional rules whose glob base is the project directory that owns the rule file
- nested directory expansion that can add more specific project and local instructions as the session focuses on a deeper path

This is how Claude Code stays specific without forcing every repo rule into every turn.

## Worktree and duplication guardrails

Instruction discovery must avoid accidental double-loading in git worktree setups.

When the active cwd is a nested worktree inside a larger canonical repository, checked-in project instructions from the outer checkout should not be duplicated just because the directory walk passes through both roots. Private local files may still need separate handling because they are not the same kind of checked-in artifact.

## Failure modes

- **priority inversion**: a broad global file ends up overriding a nearer local instruction
- **duplicate loading**: the same checked-in rule arrives twice through worktree or symlink paths
- **unsafe include activation**: external files become trusted before workspace approval
- **eager overreach**: path-conditioned rules are injected globally and drown out more relevant context
- **flattened provenance**: included material loses its parent relationship, making audits and reload hooks ambiguous
