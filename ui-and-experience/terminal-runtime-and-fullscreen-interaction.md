---
title: "Terminal Runtime and Fullscreen Interaction"
owners: []
soft_links: [/ui-and-experience/terminal-ui.md, /ui-and-experience/focused-dialog-and-overlay-arbitration.md, /ui-and-experience/keybinding-customization-and-context-resolution.md, /integrations/clients/surface-adapter-contract.md]
---

# Terminal Runtime and Fullscreen Interaction

Claude Code's terminal UX depends on negotiated terminal capabilities, not just on React-style rendering. A clean-room rebuild needs to model the terminal runtime itself: what the host terminal can do, which protocols are safe to enable, and when full-screen or high-frequency redraw surfaces need different behavior.

## Capability detection

Equivalent behavior should preserve runtime checks for at least these capabilities:

- progress reporting support
- synchronized output support for flicker-free redraws
- xterm.js-style integrated-terminal detection, including an asynchronous probe path that survives SSH
- extended keyboard protocol support for disambiguating modifier-rich shortcuts
- known terminal-specific cursor or viewport quirks

These capabilities cannot be inferred from one environment variable alone.

## Buffered redraw contract

The terminal renderer should treat one frame as one buffered write unit.

Equivalent behavior should preserve:

- accumulation of one redraw into a single output buffer
- optional synchronized-output wrappers when the terminal truly supports them
- omission of those wrappers when an intermediate multiplexer breaks their atomicity
- support for cursor movement, cursor visibility toggles, clear operations, hyperlink emission, and raw styled text inside the same buffered frame

Without buffered redraws, complex task and dialog surfaces will flicker or tear.

## Fullscreen and high-frequency surfaces

Fullscreen or alternate-screen surfaces place different stress on terminal capability assumptions.

A faithful rebuild should preserve:

- the ability for high-frequency redraw surfaces to opt out of synchronization markers when the host or multiplexer cannot preserve atomic output
- terminal-quirk awareness for layouts that rely heavily on cursor-up movement or alternate-screen behavior
- delayed or lazy use of asynchronous terminal probes when SSH or nested-terminal setups may hide capability from environment variables

This is how the same UI can stay usable across local terminals, SSH, tmux, and editor-integrated terminals.

## Input protocol negotiation

Equivalent behavior should not enable every advanced input protocol everywhere.

The runtime should:

- allowlist terminals known to support richer key reporting correctly
- avoid globally enabling modifier protocols in terminals that would emit unsupported key sequences
- preserve ordinary fallback input behavior when richer protocols are unavailable

This is a usability contract as much as a rendering contract.

## Failure modes

- **false capability detection**: the runtime enables advanced output or input protocols in terminals that mis-handle them
- **multiplexer breakage**: synchronized-output markers are emitted through a proxy that destroys their atomicity
- **SSH blind spot**: integrated-terminal behavior is missed because detection relies only on local environment variables
- **viewport yank**: cursor-heavy rendering paths trigger terminal-specific scrolling bugs
