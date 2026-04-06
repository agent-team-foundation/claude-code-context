---
title: "Vim Mode and Modal Editing"
owners: []
soft_links: [/product-surface/command-surface.md, /ui-and-experience/shell-and-input/terminal-ui.md, /ui-and-experience/shell-and-input/keybinding-customization-and-context-resolution.md, /ui-and-experience/feedback-and-notifications/interaction-feedback.md]
---

# Vim Mode and Modal Editing

Claude Code's Vim support is not a cosmetic keybinding preset. When `editorMode` is `vim`, the prompt swaps from the default text-input path onto a dedicated modal editor with its own state machine, command parser, replay memory, register handling, and UI cues. A faithful rebuild needs that whole subsystem, not just a list of shortcut remaps.

## Scope boundary

This leaf covers:

- how Vim mode is enabled, persisted, and mounted into the prompt
- the INSERT versus NORMAL mode model
- the NORMAL-mode command-state machine and supported motions/operators
- register, repeat, find-repeat, and undo integration
- footer and status-line Vim indicators
- the places where Claude Code intentionally diverges from full Vim

It intentionally does not re-document:

- the general slash-command catalog beyond the `/vim` entry point already summarized in [command-surface.md](../product-surface/command-surface.md)
- the generic keybinding customization pipeline already summarized in [keybinding-customization-and-context-resolution.md](keybinding-customization-and-context-resolution.md)
- the full base text-input implementation outside the Vim-specific wrapper and routing rules

## Activation, persistence, and entry surfaces

Equivalent behavior should preserve:

- a persistent global `editorMode` setting whose user-facing values are `normal` and `vim`
- backward compatibility that treats legacy `emacs` config as `normal`
- a `/vim` local command that toggles the persisted setting between `normal` and `vim`
- `/vim` returning explicit user-facing confirmation text describing the new mode rather than silently flipping config
- the settings/config panel exposing the same `editorMode` switch, so command and settings surfaces stay aligned
- analytics treating command-driven and config-panel-driven mode changes as distinct sources while mutating the same underlying setting

## Prompt mounting and ownership model

Equivalent behavior should preserve:

- the main prompt choosing between the standard text input and a dedicated Vim text input at render time based on the current global config
- the REPL owning a live `vimMode` state value and passing it into the prompt, footer, and status-line layers
- the Vim text input wrapping the same base text-input renderer rather than reimplementing terminal text painting from scratch
- the wrapper delegating rendering, cursor layout, paste handling, history hooks, and image-paste hooks to the base input while replacing only the key-routing and mode-state logic
- the Vim wrapper honoring an externally supplied initial mode and syncing when that external mode changes

## Top-level mode model

Equivalent behavior should preserve:

- exactly two top-level modes: `INSERT` and `NORMAL`
- `INSERT` carrying transient `insertedText` memory so dot-repeat can replay the text typed during the current insert session
- `NORMAL` carrying a nested command-parsing state machine rather than a flat "last key pressed" flag
- new Vim inputs starting in `INSERT`
- leaving `INSERT` recording the inserted text as the latest change only if something was actually typed during that insert session
- leaving `INSERT` moving the cursor one grapheme left unless the cursor is already at offset `0` or is immediately after a newline

## Visible mode cues

Equivalent behavior should preserve:

- the footer showing `-- INSERT --` only when Vim mode is enabled, the live mode is `INSERT`, and history search is not currently using the footer area
- the normal footer hint row being suppressed while the insert banner is visible
- the status-line command input receiving structured Vim state when Vim mode is globally enabled
- that status payload containing the live mode, defaulting to `INSERT` if a caller does not pass an explicit mode yet

## Input-routing contract

Equivalent behavior should preserve:

- a single Vim-specific input handler sitting in front of the base text-input handler
- `inputFilter` still being invoked in all modes so stateful filters can disarm themselves on every keypress
- only `INSERT` mode consuming the transformed `inputFilter` output, because NORMAL-mode command parsing expects literal single-character command tokens
- all `Ctrl` combinations flowing straight to the base text-input path instead of being interpreted as Vim commands
- `Enter` always flowing to the base text-input path, so prompt submission still works from `NORMAL`
- `Escape` in `INSERT` being hardwired to "switch to NORMAL" and intentionally excluded from configurable keybindings
- `Escape` in `NORMAL` resetting any partially parsed command back to idle instead of leaving the parser mid-operator or mid-find
- backspace and delete remapping only happening in motion-expecting NORMAL states, so literal-character states such as replace or find are canceled instead of accidentally turning deletion keys into destructive motions
- delete specifically not being remapped while the parser is collecting a count, so a user does not accidentally turn a canceled numeric prefix into an `x` command
- global request-cancel handling refusing to claim `Escape` while Vim is enabled and the prompt is in `INSERT`, so mode switching wins over chat cancel

## NORMAL-mode command-state machine

Equivalent behavior should preserve:

- an explicit parser state machine with these states:
- `idle`
- `count`
- `operator`
- `operatorCount`
- `operatorFind`
- `operatorTextObj`
- `find`
- `g`
- `operatorG`
- `replace`
- `indent`
- `0` in `idle` being line-start motion, not a count prefix
- counts beginning only with `1` through `9`
- count accumulation being clamped to a hard upper bound of `10000`
- operator-leading counts and motion-leading counts multiplying together, so sequences equivalent to `2d3w` operate with an effective count of `6`
- any unrecognized input in an in-progress parser state canceling back to `idle` rather than executing a best-effort fallback

## Supported movement semantics

Equivalent behavior should preserve:

- basic motions `h`, `j`, `k`, `l`
- logical-line motions `j` and `k`, not wrapped-screen-line movement
- wrapped-line motions only on `gj` and `gk`
- word motions `w`, `b`, `e`
- WORD motions `W`, `B`, `E`
- line-position motions `0`, `^`, `$`
- file-position motions `gg` and `G`
- counted `G` going to the requested logical line while bare `G` goes to the last line
- counted `gg` going to the requested logical line while bare `gg` goes to the first line
- character-find motions `f`, `F`, `t`, `T`
- `;` and `,` repeating the last character-find, with `,` reversing direction
- cursor calculations being grapheme-aware rather than raw UTF-16 code-unit arithmetic
- arrow keys in idle NORMAL mode falling back to the base handler for ordinary prompt navigation and history behavior
- arrow keys in motion-expecting command states being remapped to Vim motions instead

## Supported edit commands and operators

Equivalent behavior should preserve:

- insert-entry commands `i`, `I`, `a`, `A`, `o`, and `O`
- `I` entering insert at the first non-blank character of the logical line
- `A` entering insert at the logical end of the current line
- `a` entering insert one grapheme to the right unless already at end of buffer
- `o` and `O` inserting a blank logical line below or above and immediately entering `INSERT`
- operators `d`, `c`, and `y`
- doubled operator keys (`dd`, `cc`, `yy`) acting as logical-line operations
- operator-plus-motion combinations using a shared operator range calculator rather than bespoke per-command logic
- single-key edits `x`, `r`, `~`, `J`, `p`, `P`, `>>`, and `<<`
- shorthand line-tail commands `D`, `C`, and `Y`
- `u` delegating to the prompt's supplied undo callback instead of maintaining a standalone Vim undo tree

## Operator range and edit semantics

Equivalent behavior should preserve:

- operator motions distinguishing exclusive motions from inclusive motions such as `e`, `E`, and `$`
- linewise motions treating `j`, `k`, `G`, and `gg` as full-line ranges when combined with operators
- `cw` and `cW` using Vim-style "change to end of current/target word" behavior rather than deleting through the start of the next word
- find-based operators using the find resolver's adjusted offsets, so `t` and `T` honor their "before target" semantics
- yanks and deletes writing affected content into one unnamed register shared across later pastes
- linewise register content ending with a trailing newline so paste logic can distinguish linewise from characterwise content
- deleting the final logical line also removing the preceding newline when appropriate, so the buffer does not keep a dangling blank line
- linewise paste inserting full lines before or after the current logical line
- characterwise `p` inserting after the current grapheme and characterwise `P` inserting before the cursor
- join behavior trimming leading whitespace from subsequent lines and reintroducing at most one joining space
- indent behavior using a two-space indent unit
- left-indent removing two leading spaces when present, otherwise one leading tab, otherwise up to two leading whitespace characters

## Text objects, Unicode safety, and structured-placeholder safety

Equivalent behavior should preserve:

- operator text-object parsing through `i` or `a` scope selectors followed by a supported object type
- text objects for `w`, `W`, `"`, `'`, backtick quotes, `(`, `)`, `b`, `[`, `]`, `{`, `}`, `B`, `<`, and `>`
- word-object resolution that distinguishes Vim word characters, whitespace, and punctuation runs
- `aw` and related "around" objects expanding to surrounding whitespace when appropriate
- quoted text objects pairing quotes within the current logical line rather than searching arbitrarily across the whole buffer
- bracket-like text objects handling nesting depth correctly across the full text
- text-object scanning and character replacement working on grapheme boundaries, so multi-codepoint characters are not split incorrectly
- word-motion operator ranges snapping outward around structured image placeholders so commands like `dw`, `cw`, or `yw` do not leave half of an `[Image #N]` chip behind

## Repeat, find memory, register memory, and replay rules

Equivalent behavior should preserve:

- persistent Vim memory surviving across individual NORMAL-mode commands
- that memory including:
- the last editable change
- the last character-find command and target character
- unnamed register contents
- whether the stored register payload is linewise
- `.` replaying the last recorded change
- replay supporting insert sessions, `x`, `r`, `~`, indent, join, open-line, operator-motion edits, operator-find edits, and operator-text-object edits
- replay reusing the same operator implementations while suppressing a second round of change-recording during the replay itself
- find-repeat using the separately stored last-find data rather than trying to infer it from the latest change
- insert-mode repeat replaying the literal inserted text at the current cursor position

## Deliberate divergences from full Vim

Equivalent behavior should preserve these intentional limits:

- only `INSERT` and `NORMAL` modes exist; there is no visual, select, command-line, ex, or search mode
- NORMAL-mode `?` does not open a backward-search prompt; it injects a literal `?` into the input buffer
- there is one unnamed register, not a family of named registers
- there is no macro recording or playback subsystem
- there are no marks, jumps, windows, tabs, buffers, or colon commands inside this prompt editor
- quote objects are simpler than full Vim's quote parsing because they pair quotes sequentially within one logical line
- undo is delegated outward, so Vim mode depends on the host prompt's undo model instead of shipping its own branching undo history
- only a focused subset of motions, operators, and text objects is implemented, but the supported subset is modeled as real modal editing instead of one-off shortcuts

## Failure modes

- **mode drift**: `/vim`, settings, prompt mounting, and footer/status indicators disagree about whether the session is currently using Vim mode
- **escape collision**: global cancel or keybinding plumbing claims `Escape` before the Vim handler can use it to leave `INSERT`
- **parser collapse**: the NORMAL-mode state machine is replaced with ad hoc if-statements and starts mishandling counts, operator-pending commands, or cancel behavior
- **repeat corruption**: insert sessions or replayed edits overwrite the last-change record incorrectly, so `.` replays the wrong thing
- **range bugs**: operator ranges ignore inclusive motions, linewise expansion, grapheme boundaries, or image placeholders and end up deleting malformed text
- **UI invisibility**: the live mode stops flowing into the footer or status line, making modal state hard to read during normal use
- **false parity claims**: a rebuild advertises "Vim mode" but omits the actual modal parser, replay memory, or register behavior and delivers only a shallow shortcut theme
