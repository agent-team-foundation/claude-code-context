---
title: "File Read, Write, Edit, and Notebook Consistency"
owners: []
soft_links: [/tools-and-permissions/path-and-filesystem-safety.md, /tools-and-permissions/tool-execution-state-machine.md, /runtime-orchestration/file-checkpointing-and-rewind.md, /integrations/clients/ide-connectivity-and-diff-review.md, /integrations/plugins/skill-loading-contract.md]
---

# File Read, Write, Edit, and Notebook Consistency

Claude Code's core file tools share one consistency model. Rebuilding them as independent utilities would lose stale-view protection, read dedup rules, notebook correctness, and downstream IDE or LSP updates.

## Shared consistency model

Equivalent behavior should preserve one shared read-state map that records:

- the last content the runtime showed the model
- when that content was read from disk
- whether the read was a full view or only a partial slice

Write-like tools must treat that map as a precondition, not just a cache.

## Read-before-write and stale-view rejection

Text edits, full-file writes, and notebook edits should all preserve these rules:

- the model may only write against content it has already read
- a file modified after the last read must be re-read before any mutation proceeds
- timestamp checks may use full-content equality as a fallback on platforms where mtime changes can be noisy without real content drift
- no awaited work may occur between the final staleness check and the actual disk write

That last rule is critical: yielding in the middle of the read-modify-write window reintroduces race conditions the stale check was meant to prevent.

## File-read branching

The read tool should not flatten all file types into one text path.

Equivalent behavior should preserve distinct handling for:

- ordinary text files with line-offset and line-limit support
- notebook files rendered as structured cell arrays
- image files rendered as native image payloads
- PDF files rendered either as full documents or extracted page-image groups
- generic binary files rejected unless they belong to one of the natively rendered media branches
- dangerous device paths rejected before blocking I/O occurs

Large-file protection should use both byte budgets and token budgets, with notebook and PDF-specific guidance when callers request too much at once.

## Repeated-read dedup

Equivalent behavior should preserve client-side dedup for repeated full-range reads:

- if the same text or notebook range was already read
- and the file's on-disk timestamp has not changed
- return a lightweight "file unchanged" stub instead of re-sending the same full content

Write-like tools must deliberately break this dedup match by updating read-state metadata in a way that prevents a stale pre-edit read from being reused after a mutation.

## Text edit semantics

Text editing is a read-modify-write operation, not a raw patch apply.

Equivalent behavior should preserve:

- locating the effective old string against current disk content
- quote-style preservation when the surrounding file already uses typographic variants
- explicit `replace_all` behavior rather than heuristic repeated replacement
- patch generation against the current file snapshot before the final write

This keeps edit semantics deterministic enough for downstream diff, history, and rewind features.

## Full-file write semantics

Full-file writes have a different contract from string edits:

- the supplied content is authoritative
- the supplied line endings are authoritative
- the runtime should not silently rewrite line endings to match the previous file or a repository sample

That distinction matters for shells, generated files, and cross-platform projects where the model may intentionally change line-ending policy.

## Notebook mutation rules

Notebook edits are cell-aware operations, not text edits over raw JSON.

Equivalent behavior should preserve:

- only allowing `.ipynb` targets
- requiring a prior read of the same notebook
- supporting `replace`, `insert`, and `delete` modes
- accepting either real cell IDs or stable numeric cell-index shorthands
- converting one-past-end replace into insert instead of failing unnecessarily
- resetting execution count and outputs when a code cell changes
- generating new cell IDs only when the notebook format expects them

Notebook implementations should parse into a fresh mutable structure for each call. Reusing a shared parsed-object cache would leak in-place mutations across validations and later edits.

## Side effects after mutation

File mutations carry downstream obligations beyond disk writes.

Equivalent behavior should preserve:

- pre-edit checkpoint capture for rewind
- LSP did-change and did-save notifications
- clearing already delivered diagnostics so fresh analysis can surface again
- IDE-facing file-update notifications for diff or review surfaces
- path-triggered skill discovery or activation that can happen in the background

These side effects are part of the product behavior, not optional integrations.

## Failure modes

- **stale overwrite**: the runtime edits a file whose disk contents changed after the model read it
- **dedup poisoning**: a post-edit read is mistaken for an unchanged pre-edit read and the model keeps stale context
- **branch collapse**: PDFs, notebooks, images, and binary files all fall through the same text pipeline
- **line-ending corruption**: full-file writes silently inherit old line endings instead of using the content the model actually sent
- **notebook data loss**: code-cell edits preserve stale outputs or mutate a shared parsed notebook object
