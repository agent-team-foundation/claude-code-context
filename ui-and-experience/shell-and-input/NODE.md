---
title: "Shell and Input"
owners: []
---

# Shell and Input

This subdomain captures the terminal shell itself: composition, input modes, history, and the overlays that feed structured material back into the prompt.

Relevant leaves:

- **[terminal-ui.md](terminal-ui.md)** — Composition of the terminal application and major UI regions.
- **[terminal-runtime-and-fullscreen-interaction.md](terminal-runtime-and-fullscreen-interaction.md)** — Terminal capability negotiation, buffered redraws, fullscreen behavior, and input-protocol gating.
- **[terminal-setup-and-multiline-entry-affordances.md](terminal-setup-and-multiline-entry-affordances.md)** — `/terminal-setup` install flows, multiline-enter fallbacks, and terminal-specific input compatibility.
- **[prompt-composer-and-queued-command-shell.md](prompt-composer-and-queued-command-shell.md)** — How the interactive prompt shell coordinates composition, autocomplete, history, pasted artifacts, queue recovery, footer focus, and busy-state submission routing.
- **[shared-file-suggestion-sources-and-refresh.md](shared-file-suggestion-sources-and-refresh.md)** — How quick-open and inline `@` suggestions reuse one repo-aware file inventory, command override, fuzzy index, and progressive refresh path.
- **[prompt-history-persistence-and-paste-store.md](prompt-history-persistence-and-paste-store.md)** — How durable prompt history, paste-cache indirection, Up-arrow recall, search, and interrupted-submit undo stay consistent across sessions.
- **[prompt-history-picker-dialog.md](prompt-history-picker-dialog.md)** — How the modal prompt-history picker loads timestamped candidates, ranks exact/subsequence matches, previews multiline prompts, and restores full composer state.
- **[keybinding-customization-and-context-resolution.md](keybinding-customization-and-context-resolution.md)** — How `/keybindings`, config loading, context priority, chord interception, and warning surfaces stay aligned.
- **[vim-mode-and-modal-editing.md](vim-mode-and-modal-editing.md)** — How `/vim`, editor-mode persistence, modal prompt parsing, repeat/register memory, and Vim-specific UI cues stay coordinated.
- **[voice-mode-and-hold-to-talk-dictation.md](voice-mode-and-hold-to-talk-dictation.md)** — How voice eligibility, hold-to-talk capture, streaming transcription, prompt injection, and voice-specific feedback stay coordinated.
- **[workspace-search-and-open-overlays.md](workspace-search-and-open-overlays.md)** — How quick-open and workspace-search overlays preview files or matches and either open them externally or insert structured references into the draft.
