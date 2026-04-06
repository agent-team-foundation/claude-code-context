---
title: "Transcript Search and Less-Style Navigation"
owners: []
soft_links: [/ui-and-experience/shell-and-input/terminal-runtime-and-fullscreen-interaction.md, /ui-and-experience/dialogs-and-approvals/diff-dialog-and-turn-history-navigation.md, /ui-and-experience/feedback-and-notifications/interaction-feedback.md]
---

# Transcript Search and Less-Style Navigation

Claude Code's fullscreen transcript behaves like a terminal pager, not like a generic scroll view. Search, repeated match navigation, dump-to-scrollback escape hatches, and editor handoff all assume a less-style browsing posture, while still adapting to a React-driven virtual transcript.

## Scope boundary

This leaf covers:

- fullscreen transcript search availability and lifecycle
- the `/` search bar, incremental matching, and `n` or `N` repetition
- how scrolling, resizing, dump mode, and external-editor handoff affect search state
- how footer badges and pager hints communicate current search state

It intentionally does not re-document prompt-history search in the composer or the non-fullscreen thirty-row transcript fallback.

## Search belongs to the fullscreen transcript pager

Equivalent behavior should preserve:

- transcript search only being active inside fullscreen transcript mode when virtual scrolling is available
- dump-to-scrollback mode disabling jump-based search because there is no longer a live virtual list to seek inside
- each transcript entry acting like a fresh pager instance, so leaving transcript mode clears committed search query, match counts, current-position badge, dump mode, and editor status
- the footer showing a current/count badge and `n/N` navigation hint whenever a committed query is still active after the bar closes

## `/` opens an incremental search bar with an anchor

Equivalent behavior should preserve:

- pressing `/` capturing the current scroll position before the bar opens
- that captured scroll position acting as the incremental-search anchor, so a zero-match query snaps back to where the search started instead of leaving the viewport marooned at a stale preview jump
- the search bar occupying the same bottom-slot height as the ordinary transcript footer so opening it does not jolt the scroll viewport
- the bar supporting inline cursor editing, cancellation, and backspace-past-empty exit rather than append-only typing
- the first search in a transcript session being allowed to show a brief indexing status while cached search text warms
- search highlighting updating immediately while the more expensive transcript scan waits for index warm-up to finish
- the search bar chrome being excluded from highlight scans so the query does not match itself inside the bar
- unlike canonical `less`, reopening `/` starting from an empty editable buffer instead of pre-filling the prior committed query, while cancel still restores the previously committed search state

## Matching is message-aware, then occurrence-aware

Equivalent behavior should preserve:

- transcript search indexing renderable transcript text, including tool-result text extracted through tool-owned search extractors when available
- initial incremental search choosing the matched message nearest to the anchor rather than always jumping to the topmost match
- the first preview inside that nearest message landing on that message's trailing occurrence, which reduces movement in the common "anchored near the transcript bottom" case while still keeping navigation deterministic
- `n` and `N` stepping through occurrences inside the current matched message before jumping to the next or previous matched message
- repeated key batches such as held `nnn` or `NN` being interpreted as repeated match steps instead of one debounced action
- manual scroll clearing the current-occurrence marker and seek state because screen-relative highlight positions are no longer trustworthy after the viewport moves
- a committed query remaining active after manual scroll, so the next `n` or `N` can re-establish exact positioning without forcing the user to reopen `/`
- wraparound protection preventing endless loops when every engine-level match turns out to be non-renderable or phantom after layout

## Commit, cancel, resize, and transcript exit all diverge deliberately

Equivalent behavior should preserve:

- `Enter` committing the current search text for future `n/N` navigation only when at least one match exists
- a zero-match commit clearing the persistent query and badge state instead of preserving a dead search that cannot navigate
- `Esc`, `Ctrl+C`, and `Ctrl+G` cancelling the live bar edit and restoring whatever committed query was active before `/` opened
- terminal-width changes aborting search entirely because wrapped line positions and cached highlight offsets are width-dependent
- transcript exit clearing both text-match highlights and screen-relative current-match boxes so stale overlays do not bleed into normal mode

## Pager escape hatches stay available but obey search ownership

Equivalent behavior should preserve:

- `q` exiting the transcript pager even when a committed search is active
- `[` forcing a full dump to native terminal scrollback with transcript expansion and render caps removed, so terminal or tmux native search can take over
- `v` rendering the full transcript to a temporary file and handing it to the configured external editor
- `[` and `v` being treated as literal query input while the search bar owns the keyboard, rather than as transcript commands
- `v` remaining available after dump mode, because exporting the flattened transcript to an editor is still useful after leaving jump-search mode

## Failure modes

- **anchor loss**: zero-match edits leave the viewport at a stale preview location instead of snapping back to the pre-search position
- **stale highlight**: resize or manual scroll leaves the current-match marker painted on the wrong row
- **dead query persistence**: a no-match commit keeps a badge and `n/N` state that can no longer navigate
- **chrome self-match**: the search bar highlights its own query text and misreports the only visible match
