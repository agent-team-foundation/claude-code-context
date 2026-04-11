---
title: "Deep Link Protocol Trampoline and Origin Banner"
owners: []
soft_links: [/platform-services/interactive-startup-and-project-activation.md, /product-surface/init-command-and-claude-md-setup.md, /ui-and-experience/feedback-and-notifications/interaction-feedback.md]
---

# Deep Link Protocol Trampoline and Origin Banner

External `claude-cli://open` links do not drop directly into an already-running REPL. They enter through a headless trampoline that sanitizes the link, resolves the working directory, relaunches Claude Code inside a terminal, and marks the interactive session as externally originated so startup can show a strong provenance warning.

## Headless trampoline entrypoint

Equivalent behavior should preserve:

- OS protocol registration invoking the current CLI binary through a dedicated `--handle-uri` entrypoint instead of relying on PATH lookup or a wrapper shell
- the trampoline bailing out before full interactive startup because it only needs to parse the URI, choose a cwd, and launch a terminal
- macOS URL-handler launches being treated as a separate but equivalent entry path when the URL arrives through an app-bundle event instead of argv
- the relaunched interactive session using the exact same binary that the OS invoked for the trampoline

## URI parsing and guardrails

Equivalent behavior should preserve:

- only the `claude-cli://open` action being accepted
- optional `q`, `cwd`, and `repo` parameters being URL-decoded, Unicode-sanitized, and rejected if they contain control characters
- `cwd` being required to be an absolute path and rejected when it is implausibly long
- `repo` being treated as a simple owner or repo slug, not as a filesystem path fragment
- overlong prompt prefills being rejected rather than truncated so the link cannot silently change meaning

## Working-directory resolution

Equivalent behavior should preserve:

- working-directory precedence being explicit path first, then most-recent known local clone for a repo slug, then the user home directory
- a repo that is not cloned locally falling through to home instead of hard-failing the open flow
- the repo slug only being carried forward as provenance when local clone resolution actually succeeded
- repository freshness being computed in the trampoline by checking `FETCH_HEAD` timestamps before the interactive session starts

## Terminal selection and relaunch

Equivalent behavior should preserve:

- macOS preferring a stored terminal choice captured from earlier interactive sessions, then falling back to current terminal hints or installed apps
- Linux preferring `$TERMINAL`, then `x-terminal-emulator`, then a curated priority list
- Windows preferring Windows Terminal, then PowerShell, then Command Prompt
- the launched interactive process receiving `--deep-link-origin` plus optional repo, fetch-age, and prefill flags
- pure argv handoff being used whenever a terminal offers it, with shell-string fallback only where the platform gives no argv-style interface
- the trampoline spawning the terminal detached so it can exit immediately after launch

## Interactive provenance warning

Equivalent behavior should preserve:

- the interactive session prepending a warning system message when `--deep-link-origin` is present
- that warning always naming the resolved cwd because it determines which local project files and `CLAUDE.md`-style guidance will load
- repo-resolved launches also showing which clone was selected and how recently it was fetched, with a stronger warning when the clone may be stale
- prefilled prompts triggering a prompt-review warning, escalating to a stronger "review the full prompt" style warning once the prefill is long enough to extend off-screen
- plain `--prefill` without deep-link origin still showing a weaker caution banner rather than the full provenance treatment

## Failure modes

- **unsafe acceptance**: dangerous control characters or oversized prefills are accepted after truncation instead of rejected
- **cwd ambiguity**: repo links silently choose an arbitrary clone or fail hard when no clone exists
- **launcher drift**: the trampoline resolves one binary but the terminal opens another from PATH
- **missing provenance**: externally supplied cwd or prompt reaches the REPL without a conspicuous origin warning

## Test Design

In the observed source, platform-service behavior is verified through sequencing-sensitive integration tests, deterministic state regressions, and CLI-visible service flows.

Equivalent coverage should prove:

- config resolution, policy gates, persistence, and service startup ordering preserve the contracts and failure handling described above
- provider-backed or OS-bound branches use fixtures, seeded stores, or narrow seams so auth, update, telemetry, and trust behavior stays reproducible
- users still encounter the expected startup, settings, trust, diagnostics, and account-state behavior through the real CLI surface
