---
title: "Trust and Capability Hydration"
owners: []
soft_links: [/platform-services/auth-config-and-policy.md, /integrations/mcp/server-contract.md, /memory-and-context/instruction-sources-and-precedence.md]
---

# Trust and Capability Hydration

Workspace trust is a first-class startup boundary in Claude Code. It is not the same thing as tool permissions, and several other services stay partially dormant until that boundary is crossed.

## Trust is its own gate

Interactive sessions should establish workspace trust even when the user has chosen permissive tool execution.

Equivalent behavior should preserve these rules:

- trust review happens for interactive sessions unless the workspace is already trusted
- bypass or dangerous permission modes do not automatically waive workspace trust
- non-interactive sessions may skip the dialog, but that is a separate execution mode, not evidence that trust no longer matters

This boundary exists because untrusted repositories can affect more than command execution.

## Post-trust hydration order

After trust is accepted, the runtime should hydrate dependent capabilities in a deliberate sequence.

The important sequence is:

1. mark trust as accepted for the session
2. reinitialize experiment and entitlement clients so they can use trusted auth-bearing requests
3. prefetch stable system context
4. if settings are valid, run approval flows for config-driven integrations such as MCP servers
5. surface warnings for external instruction includes that would extend the trusted context boundary
6. update repo-to-platform mappings and other cwd-derived metadata only after the workspace is trusted
7. apply the full environment-variable overlay
8. initialize telemetry only after trusted env vars and trust-gated helpers are available

The order matters as much as the individual steps.

## Why trust happens before env and telemetry

Several startup actions become dangerous if they run too early:

- cwd-derived repo mappings can be poisoned by an untrusted directory
- env-var application can activate risky settings or endpoints from untrusted sources
- telemetry initialization may depend on env-backed configuration and helpers that should not run before trust
- experiment clients may need to be re-created after trust so auth headers and trusted identity are attached correctly

A rebuild that does all startup hydration before trust will expose the wrong attack surface.

## Trust-adjacent approvals

Workspace trust does not automatically approve every secondary extension point.

A faithful implementation should keep separate approval steps for things like:

- newly discovered MCP server definitions
- external instruction includes
- custom API keys or other credential introductions
- explicitly dangerous operating modes or development-channel toggles

Those checks belong after the workspace trust boundary, but they remain independent decisions.

## Capability hydration is incremental

The product does not switch from "off" to "fully ready" in one atomic step.

Instead, capabilities become active as more prerequisites line up:

- trust status
- valid settings state
- authenticated experiments and entitlements
- approved integrations
- environment-variable application
- telemetry and analytics boot

This incremental hydration model explains why some features appear unavailable during early startup and then become ready moments later.

## Failure modes

- **permission-trust confusion**: a permissive tool mode accidentally bypasses workspace trust
- **pre-trust poisoning**: repo mappings or env-backed behavior initialize from an untrusted cwd
- **stale entitlement client**: experiment or entitlement fetches keep using pre-trust auth posture
- **approval collapse**: trust acceptance implicitly activates MCP servers or external includes without their own review step
- **telemetry misboot**: observability starts before trusted env configuration and helper state are available
