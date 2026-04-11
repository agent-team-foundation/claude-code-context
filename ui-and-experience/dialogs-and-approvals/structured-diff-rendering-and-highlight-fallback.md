---
title: "Structured Diff Rendering and Highlight Fallback"
owners: []
soft_links: [/ui-and-experience/dialogs-and-approvals/diff-dialog-and-turn-history-navigation.md, /ui-and-experience/shell-and-input/terminal-runtime-and-fullscreen-interaction.md]
---

# Structured Diff Rendering and Highlight Fallback

Claude Code's diff detail view does not just print raw patch text. Each hunk is passed through a structured renderer that prefers a syntax-aware color-diff engine, but can fall back to a pure-JS formatter that still preserves line numbers, conservative word-level highlighting, wrapping, and selection-friendly gutter behavior. A faithful rebuild needs this renderer contract separately from `/diff` dialog navigation, because the same hunk can be rendered with materially different readability and copyability depending on these rules.

## Scope boundary

This leaf covers:

- how diff detail rendering chooses between the color-diff path and the fallback path
- which file metadata and content the renderer accepts as enrichment context for one hunk
- how line numbers, markers, wrapping, word-diff emphasis, and fullscreen gutter splitting behave once a hunk is being rendered

It intentionally does not re-document:

- `/diff` source selection, list-detail navigation, file-state classification, and turn-history sourcing already captured in [diff-dialog-and-turn-history-navigation.md](diff-dialog-and-turn-history-navigation.md)
- generic fullscreen capability negotiation already captured in [terminal-runtime-and-fullscreen-interaction.md](../shell-and-input/terminal-runtime-and-fullscreen-interaction.md)
- broader filesystem safety rules beyond the fact that the renderer consumer may pass current file contents from disk for enrichment

## Consumers pass one hunk plus current file metadata, not a historical snapshot

Equivalent behavior should preserve:

- detail consumers rendering one structured patch hunk at a time rather than flattening the whole file into one opaque ANSI blob
- the renderer contract accepting `filePath`, `firstLine`, optional `fileContent`, width, and dimness alongside the hunk itself
- current on-disk file contents being usable as enrichment context even when the hunk came from turn history rather than the current working tree
- multi-hunk detail views staying as a thin list wrapper that intersperses separators between hunk renders instead of inventing a second rendering path

## Renderer selection prefers color-diff unless highlighting was intentionally disabled

Equivalent behavior should preserve:

- structured diff first attempting a dedicated color-diff renderer instead of always formatting patch lines through ordinary Ink text nodes
- the richer renderer being bypassed when the call site explicitly sets `skipHighlighting`, when user settings disable syntax highlighting, or when `CLAUDE_CODE_SYNTAX_HIGHLIGHT` disables the color module
- a failed or unavailable color-diff render dropping to the fallback renderer instead of surfacing an error UI
- render width being clamped to at least `1` cell before either renderer runs so narrow layouts do not crash the renderer contract
- cached structured renders being keyed by hunk identity plus theme, width, dim state, gutter mode, `firstLine`, and `filePath`, so fullscreen remounts and resize churn do not force a fresh highlight every time

## Syntax detection is file-aware and conservative

Equivalent behavior should preserve:

- language detection first checking filename or stem-specific mappings such as `Dockerfile`, `Makefile`, and `CMakeLists`, then checking the file extension, and only then checking first-line hints
- first-line detection stripping a UTF-8 BOM before inspecting shebang or tag-style hints
- shebang hints mapping at least common shell, Python, Node, Ruby, and Perl entrypoints into their matching syntax families
- first-line detection also recognizing `<?php` and `<?xml` when filename and extension were not enough
- optional full-file content being accepted as enrichment input at the renderer boundary, even though the portable TypeScript path currently keeps that hook mainly for API parity instead of deep incremental syntax state

## Word-level emphasis is local, conservative, and whitespace-preserving

Equivalent behavior should preserve:

- word-level diffing only pairing adjacent runs of removed lines followed immediately by adjacent runs of added lines
- pair formation staying positional within each adjacent block, up to the smaller of the remove-line count and add-line count, instead of attempting fuzzy matching across the whole hunk
- tokenization preserving word runs, whitespace runs, and punctuation as separate units so spacing survives word-diff highlighting
- word-level emphasis being suppressed entirely in dim mode rather than combining dimmed output with loud inline highlights
- word-level emphasis also being suppressed when the changed-text ratio exceeds the renderer's `40%` threshold, forcing a normal line-level render for larger rewrites
- fallback word-level diffing preserving whitespace via `diffWordsWithSpace` semantics instead of collapsing spaces around punctuation

## Layout preserves markers, line numbers, and clean text selection

Equivalent behavior should preserve:

- content width being computed after subtracting the marker, padded line-number gutter, and surrounding layout chrome from the available terminal width
- changed lines padding their background color all the way to the right edge after wrapping, so wrapped additions and deletions still read as one colored band
- fullscreen rendering splitting the output into a non-selectable gutter column plus a content column when there is enough width, so copied text excludes the diff marker and line-number chrome
- narrow widths collapsing back to one combined column when the gutter would consume the whole render width
- the fallback renderer giving wrapped continuation lines blank gutter text aligned under the original numbered line instead of repeating or misaligning numbers

## The portable color-diff path preserves structure more than exact native token coloring

Equivalent behavior should preserve:

- a public `ColorDiff`-style API that callers can use without branching between native and portable implementations
- structural parity around markers, line numbers, backgrounds, wrapping, and word-diff placement even when the portable renderer uses different internals for syntax coloring
- the portable path using highlight.js-like language grammars rather than the native syntect-plus-bat stack, so some token colors may differ even when the rendered diff structure matches
- `BAT_THEME` acting as diagnostic-only input in the portable path rather than as a full alternate syntax-theme selector

## Failure modes

- **flat patch dump**: rebuilds print raw patch lines and lose syntax-aware rendering, selection-friendly gutters, and conservative word-diff behavior
- **over-eager word diff**: non-adjacent or heavily rewritten line blocks still receive word-level emphasis and become noisy or misleading
- **snapshot fiction**: the renderer is rebuilt as if it always needs historical file snapshots, even though the real consumer contract can enrich from current file metadata and optional current contents
- **narrow-terminal breakage**: gutter splitting stays enabled when the terminal is too narrow and the content column collapses or becomes uncopyable
- **dim-mode mismatch**: dimmed historical or de-emphasized diffs still emit bright inline word highlights and break the intended visual hierarchy
- **native-parity overclaim**: the portable renderer is treated as byte-for-byte identical to the native highlighter, causing rebuilds to encode the wrong guarantee around token coloring or `BAT_THEME`

## Test Design

In the observed source, dialog and approval behavior is verified through focused rendering or view-model regressions, store-backed integration tests, and interactive acceptance flows.

Equivalent coverage should prove:

- focus, overlay arbitration, diff navigation, structured rendering, and approval routing preserve the invariants documented in this leaf
- dialog state remains correctly coupled to permission, plan, session, and transcript stores without timing-dependent leaks
- users can actually reach, dismiss, accept, deny, export, or navigate these surfaces through the packaged interactive UI
