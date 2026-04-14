---
title: "Claude Code MCP Serve Surface"
owners: []
soft_links:
  - /integrations/mcp/server-contract.md
  - /integrations/clients/structured-io-and-headless-session-loop.md
  - /tools-and-permissions/tool-catalog/tool-families.md
  - /tools-and-permissions/execution-and-hooks/tool-execution-state-machine.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/released-cli-e2e-test-set.md
---

# Claude Code MCP Serve Surface

Claude Code is not only an MCP client. It also ships a `claude mcp serve` entrypoint that turns the local runtime into an MCP server over stdio. That is an inverse extension surface: external MCP hosts can call Claude Code's own tools. A faithful rebuild needs this contract explicitly, because it is not the same thing as configuring outbound MCP servers inside Claude Code.

## Scope boundary

This leaf covers:

- the local `claude mcp serve` bootstrap path
- the capabilities Claude Code exposes when acting as an MCP server
- how the live local tool catalog is projected into MCP tool metadata
- the execution, permission, caching, and error-shaping rules for inbound MCP tool calls

It intentionally does not re-document:

- outbound MCP server discovery, policy, auth, and live-refresh behavior already covered in [server-contract.md](server-contract.md) and sibling MCP leaves
- the broader structured I/O session loop already covered in [../clients/structured-io-and-headless-session-loop.md](../clients/structured-io-and-headless-session-loop.md)
- generic tool-family definitions beyond the parts that become visible through this MCP server surface

## `claude mcp serve` is a local headless bootstrap, not a management UI

Equivalent behavior should preserve:

- one explicit `claude mcp serve` subcommand as the entrypoint for exposing Claude Code itself as an MCP server
- validation that the current working directory still exists before the server boot proceeds
- reuse of the shared local setup/bootstrap path before transport startup, so the serve surface inherits ordinary config and runtime initialization instead of inventing a second stripped-down process model
- stdio transport as the observable public surface for this serve path
- debug and verbose flags flowing into the runtime context for served tool calls without changing the server's externally advertised capability set

## The current serve surface is tools-only

Equivalent behavior should preserve:

- the advertised MCP capability surface containing tools and not pretending to expose prompts, resources, or a generic mirror of every outward-facing Claude Code subsystem
- `tools/list` projecting the currently admitted local tool catalog rather than a hardcoded static manifest
- tool descriptions being generated from the live tool prompt/description builders, not copied from a second stale registry
- input schemas being converted from the local schema source into MCP-compatible JSON Schema
- output schemas being exposed only when they can be represented as a valid object-root MCP schema, with incompatible roots omitted instead of exported incorrectly
- no recursive re-exposure of already connected outbound MCP tools or resources through this server surface

The clean-room point is that `claude mcp serve` currently exports Claude Code as a tool server, not as a full reflection of every MCP concept Claude Code can consume.

## Inbound tool execution reuses the local tool runtime with a narrow context

Equivalent behavior should preserve:

- tool lookup by the same live local tool names used inside Claude Code itself
- a non-interactive execution context with no transcript history, no ordinary app-state mutation, and no nested outbound MCP clients/resources injected into the call path
- disabled thinking posture for served tool calls rather than a full assistant conversation loop
- a bounded file-state cache so repeated serve-mode file operations do not grow memory without limit
- the current main-loop model and a small built-in command context remaining available where the local tool runtime expects them
- default permission posture still applying through the normal tool permission checker instead of all inbound MCP tool calls becoming silently auto-allowed

## Call and result shaping must stay conservative

Equivalent behavior should preserve:

- unknown tool names failing as real errors instead of being ignored
- local input validation still running when a served tool defines validation
- tools returning either plain text or structured data without the serve surface inventing a second result model
- plain string tool results flowing back as text content
- structured tool results being serialized into one text payload rather than leaking local in-memory result objects directly over the wire
- local tool errors being normalized into an MCP `isError` response with readable text instead of raw stack dumps or process crashes
- aborted tool calls degrading cleanly without leaving the server in a wedged state

## This surface is the inverse of outbound MCP integration, not a duplicate of it

Equivalent behavior should preserve:

- clear separation between "Claude Code connects to external MCP servers" and "external MCP hosts connect to Claude Code"
- the serve surface reflecting Claude Code's own local tool catalog and runtime gates, not the session-state slices that connected external MCP servers may have added elsewhere
- future rebuilds avoiding accidental capability inflation where the serve path exposes prompt, resource, or remote-server concepts that today's product does not actually advertise here

## Failure modes

- **capability overclaim**: the server advertises prompts, resources, or recursive outbound-MCP surfaces that the observed product does not actually expose through `claude mcp serve`
- **permission escape**: inbound MCP tool calls bypass the normal local permission checker and gain broader authority than the same tool would have inside Claude Code
- **schema lie**: output schemas with incompatible roots are still exported, causing downstream MCP hosts to trust invalid structure
- **recursive reflection**: connected external MCP tools are re-exported through Claude Code's own server surface and create confusing or unsafe double indirection
- **cache leak**: long-lived serve mode keeps unbounded file-read state in memory
- **raw error spill**: tool exceptions leak internal stack detail instead of returning a normalized MCP error payload

## Test Design

In the observed source, this surface is backed by a real CLI entrypoint and by local tool-runtime reuse rather than by a fake adapter.

Equivalent coverage should prove:

- `claude mcp serve` boots through the packaged CLI path, speaks MCP over stdio, and returns a real tool catalog over `tools/list`
- representative tool calls preserve the same enablement, validation, permission, and error-shaping behavior documented above
- the serve surface stays tools-only and does not silently drift into re-exporting outbound MCP session state or other non-tool capabilities
