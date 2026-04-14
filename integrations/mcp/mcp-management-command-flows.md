---
title: "MCP Management Command Flows"
owners: []
soft_links:
  - /integrations/mcp/config-layering-policy-and-dedup.md
  - /integrations/mcp/connection-and-recovery-contract.md
  - /platform-services/workspace-trust-dialog-and-persistence.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/released-cli-e2e-test-set.md
---

# MCP Management Command Flows

Claude Code does not leave MCP server setup to hand-edited JSON alone. It ships a local `claude mcp` command family that lets users add, inspect, import, remove, and reset MCP server configuration without entering a model turn. A faithful rebuild needs these management surfaces explicitly, not only the runtime behavior after a server already exists.

## Scope boundary

This leaf covers:

- the local `claude mcp` management subcommands for add, add-json, add-from-claude-desktop, list, get, remove, and reset-project-choices
- scope resolution, config mutation, health checking, and secret cleanup behavior for those commands
- the interactive Claude Desktop import surface and the project-scoped approval reset surface

It intentionally does not re-document:

- the separate `claude mcp serve` surface, which is captured in [claude-code-mcp-serve-surface.md](claude-code-mcp-serve-surface.md)
- outbound MCP runtime connection, auth, and live-surface behavior after a server is already configured
- generic MCP policy and precedence rules beyond the parts these commands must respect while reading or mutating config

## The `claude mcp` family is a local administration surface

Equivalent behavior should preserve:

- one top-level `claude mcp` namespace for MCP server management
- management subcommands executing locally instead of entering a model turn or requiring the interactive REPL
- clear separation between config-management actions and runtime-use actions, so adding or removing a server does not pretend to be the same thing as making it live in the current session
- public management coverage for at least add, add-json, add-from-claude-desktop, list, get, remove, and reset-project-choices

## Scope selection and config authority stay explicit

Equivalent behavior should preserve:

- user-facing scope selection across local, user, and project config targets
- explicit scope flags writing directly to the chosen config target
- commands with no explicit scope still respecting the effective config graph instead of assuming one universal file
- removal with an omitted scope refusing to guess when the same server exists in multiple scopes, and instead printing the valid scope-specific removal commands
- project-scoped MCP config remaining distinct from local private project config, because later approval behavior depends on that distinction

## Add flows support both structured flags and raw JSON

Equivalent behavior should preserve:

- `mcp add` supporting stdio-style process launches as well as remote HTTP or SSE-style connectors
- transport type, environment variables, and request headers being part of the add contract rather than post-hoc hidden edits
- `mcp add-json` accepting an inline JSON config object for cases where the flag surface is not expressive enough
- add flows recording the transport type accurately so later health, auth, and removal behavior can branch correctly
- OAuth client-secret capture, when needed, happening before config write so cancellation cannot leave partial config state behind

## `list` and `get` are health-aware inspection surfaces

Equivalent behavior should preserve:

- `mcp list` showing an explicit empty-state message when no MCP servers are configured
- non-empty list output performing real server-health checks instead of printing stale config blindly
- those health checks running concurrently within a bounded batch size rather than serially blocking on large MCP inventories
- list output formatting transport-specific summaries for stdio, HTTP, SSE, and proxy-like variants
- internal-only connector variants staying out of ordinary visible list output even if they exist elsewhere in code
- `mcp get` showing one server's scope, health, transport details, and configured OAuth shape
- `mcp get` ending with a concrete scope-aware removal hint so the command doubles as an operator recovery surface
- inspection commands shutting down helper processes cleanly after health checks instead of leaking child MCP processes

## Removal is config mutation plus secret cleanup

Equivalent behavior should preserve:

- removing a server from one scope not silently mutating the others
- remote-style server removal cleaning up locally stored auth or client-secret state tied to that server, not only deleting the visible config entry
- missing-server errors staying explicit when the named server does not exist anywhere
- scope-aware success output telling the user which config file actually changed

## Claude Desktop import is interactive and source-aware

Equivalent behavior should preserve:

- `mcp add-from-claude-desktop` reading candidate servers from Claude Desktop configuration rather than asking the user to retype them manually
- a clear empty-state message when Claude Desktop config does not exist or contains no MCP servers
- an interactive checklist-style import surface for choosing what to bring in, not a blind bulk copy
- this import path staying TTY-oriented rather than pretending to be a plain non-interactive pipe command
- imported servers still landing in one explicit chosen scope instead of always writing to one fixed target

## Project approval reset is stored separately from server definitions

Equivalent behavior should preserve:

- project-scoped `.mcp.json` approval memory being stored separately from the checked-in server definitions themselves
- `mcp reset-project-choices` clearing both approved and rejected project-server memories, plus any "enable all project servers" latch
- the next Claude Code startup re-prompting for project-scoped server approval instead of silently reusing the old decision

## Failure modes

- **scope guess mutation**: a removal without explicit scope deletes the wrong config entry when the same server exists in multiple scopes
- **stale health lie**: list/get surfaces print config only and stop checking whether the server can still connect
- **secret orphan**: removing a remote MCP server leaves OAuth or client-secret material behind in local secure storage
- **partial add**: client-secret capture or JSON parsing fails after the config file was already mutated
- **blind desktop bulk import**: Claude Desktop import writes every discovered server with no user choice or TTY-driven checklist
- **approval memory confusion**: resetting project choices mutates the checked-in server definitions instead of only clearing local approval state

## Test Design

In the observed source, this family is backed by real packaged CLI subcommands, transport-aware health checks, and an interactive import surface.

Equivalent coverage should prove:

- add, add-json, remove, list, and get preserve the same scope-aware mutation and inspection behavior through the packaged CLI
- remote-style server cleanup, concurrent health checks, and project-choice reset behave deterministically across repeated runs
- the Claude Desktop import path remains an interactive TTY surface with explicit selection semantics rather than degrading into a blind config copier
