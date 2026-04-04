---
title: "Terminal Setup and Multiline Entry Affordances"
owners: []
soft_links: [/ui-and-experience/prompt-composer-and-queued-command-shell.md, /ui-and-experience/keybinding-customization-and-context-resolution.md, /product-surface/init-command-and-claude-md-setup.md, /tools-and-permissions/tool-hook-control-plane.md]
---

# Terminal Setup and Multiline Entry Affordances

Claude Code treats multiline input as a cross-terminal compatibility feature, not just one keybinding. The behavior combines install-time terminal setup, runtime input decoding, and fallback entry semantics.

## Scope boundary

This leaf covers:

- `/terminal-setup` availability and per-terminal install flows
- persisted setup flags used by onboarding/tips logic
- multiline-enter behavior in the input hook (modifier-based and fallback paths)
- compatibility handling for SSH/coalesced carriage-return input

It does not re-document:

- full prompt composer queue/history behavior
- generic keybinding customization UI

## Command availability model

Equivalent behavior should preserve:

- a native-terminal allowlist where `/terminal-setup` is hidden because multiline modifiers already work without installation
- a supported-install target set for terminals that need configuration writes
- explicit unsupported-terminal messaging instead of silent no-op
- platform-aware guidance when setup cannot run in the current host terminal

## Setup dispatch contract

Equivalent behavior should preserve per-terminal setup branches:

- Apple Terminal branch that configures Option-as-Meta and visual-bell-compatible behavior
- VS Code-family branch that writes terminal send-sequence keybindings in user config
- Alacritty branch that appends/merges Shift+Enter binding in terminal config
- Zed branch that adds Shift+Enter terminal send-text binding in keymap config

## Safety and idempotency

Equivalent behavior should preserve:

- read/parse/merge writes instead of blind overwrite
- duplicate-binding detection before writing
- backup creation before mutating existing config files when applicable
- actionable failure output for remote-editor sessions that cannot be edited locally from the current runtime
- Apple Terminal backup-and-restore behavior when profile mutation fails

## Persisted completion signals

Equivalent behavior should preserve:

- global flags recording whether Shift+Enter setup (or Apple Terminal Option-as-Meta setup) has been installed
- idempotent writes for these flags
- project-onboarding completion check triggered after successful terminal setup

## Runtime multiline semantics

Equivalent behavior should preserve Enter handling priority:

1. if multiline mode is active and the character before cursor is backslash:
   remove that backslash and insert newline
2. else if the key event includes meta or shift:
   insert newline
3. else if on Apple Terminal and native modifier polling reports shift held:
   insert newline
4. otherwise:
   submit input

This ordering is part of the contract; Apple Terminal fallback depends on it.

## Key-mapping and raw-input compatibility

Equivalent behavior should preserve:

- key-return handling before generic meta-path handling, so Option/Meta+Return can still produce newline
- carriage-return normalization in raw input streams to handle SSH coalescing and paste paths
- special-case handling to avoid misclassifying legacy backslash+carriage-return sequences as ordinary submit signals
- tracking usage of backslash+return fallback for discovery/analytics surfaces

## Tip and onboarding coupling

Equivalent behavior should preserve:

- spinner-tip relevance gates that depend on setup-installed flags and terminal type
- post-setup tips that switch from "how to install" guidance to "how to use multiline enter" guidance

## Failure modes

- **false native detection**: setup is hidden on a terminal that actually needs config, leaving users without multiline modifier entry
- **non-idempotent writes**: repeated `/terminal-setup` calls duplicate keybindings or corrupt config
- **remote-edit confusion**: setup attempts mutate server-side editor config when local-machine edits are required
- **enter-priority regression**: submission fires before multiline newline insertion on modifier or backslash paths
- **carriage-return drift**: SSH/coalesced input sequences are interpreted as literal text or accidental submit events
