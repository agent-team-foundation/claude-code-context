---
title: "Special Entrypoint Argv Rewrite and Fullscreen Handoff"
owners: []
soft_links: [/integrations/clients/direct-connect-session-bootstrap-and-environment-selection.md, /integrations/clients/assistant-viewer-attach-and-history-paging.md, /integrations/clients/ssh-remote-session-and-auth-proxy.md, /collaboration-and-agents/remote-and-bridge-flows.md]
---

# Special Entrypoint Argv Rewrite and Fullscreen Handoff

Some Claude Code entry surfaces are not ordinary subcommands. They are recognized before normal command dispatch, rewritten back into the main startup path, and then handed off to the full-screen REPL or a special headless runner. Rebuilding them as independent command handlers would miss important behavior.

## Rewrite-first boundary

Equivalent behavior should preserve:

- special entrypoints being recognized before normal command parsing commits to a commander action
- the rewrite stage being able to stash parsed state, remove the triggering token from `argv`, and then let the normal startup pipeline continue
- fallback commander registrations still existing for help and usage, but not acting as the primary implementation

## Direct-connect URL entrypoints

Equivalent behavior should preserve:

- raw `cc://` and `cc+unix://` tokens being recognized as direct-connect entrypoints
- interactive launches stripping the URL token and dangerous-permissions shortcut from `argv`, parsing the URL into connection state, and then continuing into the main REPL startup instead of a reduced-purpose subcommand
- headless launches detecting `-p` or `--print` and rewriting into a hidden `open <url>` path so print-style direct connect still uses a dedicated non-REPL runner
- successful interactive connect being allowed to replace the effective working directory with the server-normalized work directory before the REPL comes up
- the interactive handoff showing only a lightweight connection banner before the regular terminal UI takes over

## Position-0 command rewrites

Equivalent behavior should preserve:

- `assistant` and `ssh` only triggering their rewrite path when they appear in argv position 0 after the executable name
- words that merely appear later in argv, prompt text, or flag values not activating those special modes
- root flags placed before those tokens falling through to ordinary parser behavior instead of silently changing meaning

## Assistant handoff

Equivalent behavior should preserve:

- `assistant [sessionId]` stashing either a concrete target session or a discover-and-pick intent
- the rewritten path launching the normal REPL chrome as a viewer-style remote client, not a one-off assistant screen
- the registered `assistant` command mainly existing to print usage when the rewrite predicate did not match

## SSH handoff

Equivalent behavior should preserve:

- `ssh <host> [dir]` extracting its own flags before deciding which argument is the host, so flags-before-positionals and flags-after-positionals behave the same
- SSH-specific permission flags, dangerous bypass, local test mode, and forwarded resume or model flags being separated from local argv before the main parser runs
- headless `-p/--print` being rejected early for SSH because the local REPL is required for interrupt and approval UX
- successful SSH bootstrap returning control to the ordinary full-screen REPL with a remote-backed session object instead of local execution

## Stub-only registrations

Equivalent behavior should preserve:

- help-visible or hidden commander registrations continuing to exist for `ssh`, `assistant`, `remote-control`, and headless `open`
- `ssh` and `assistant` actions acting as usage stubs when rewrite did not happen, not as alternate implementations
- the hidden `remote-control` registration remaining only a safety shell because the real remote-control entry is intercepted earlier in startup
- the `open` command remaining the headless-only direct-connect surface rather than the primary interactive surface

## Failure modes

- **flattened entrypoint model**: special surfaces are rebuilt as ordinary subcommands and lose the main REPL handoff
- **flag-order skew**: forms like root-flags-before-subcommand accidentally enter special mode instead of showing usage
- **mode confusion**: interactive direct connect or SSH falls into a headless runner
- **double implementation drift**: fallback command actions start behaving differently from the rewrite-first path
