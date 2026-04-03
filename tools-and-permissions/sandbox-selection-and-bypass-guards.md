---
title: "Sandbox Selection and Bypass Guards"
owners: []
soft_links: [/tools-and-permissions/permission-model.md, /platform-services/policy-and-managed-settings-lifecycle.md, /tools-and-permissions/path-and-filesystem-safety.md]
---

# Sandbox Selection and Bypass Guards

Sandboxing is chosen by policy and command shape, not by a single boolean on the tool call. Claude Code also distinguishes between convenience exclusions and true security boundaries.

## Sandbox decision order

Equivalent shell sandbox selection should preserve this order:

1. if sandboxing is globally unavailable or disabled, do not sandbox
2. if the caller asked to disable sandboxing and policy allows unsandboxed commands, honor that override
3. if there is no command, do not sandbox
4. if the command matches the user or dynamic excluded-command set, run unsandboxed
5. otherwise, run sandboxed

The override is therefore policy-gated, not absolute.

## Excluded-command semantics

Excluded commands are a usability feature, not a security boundary.

A correct rebuild should preserve these traits:

- excluded commands use the same exact/prefix/wildcard rule grammar as shell permission rules
- compound commands are split so a later excluded subcommand can still opt the shell run out of sandboxing
- matching should also consider normalized candidates with harmless env vars and harmless wrappers stripped, so convenience exclusions still work through common wrappers
- malformed commands should fail back to ordinary validation rather than crashing sandbox selection

Because exclusions are convenience-only, bypassing them should never be treated as equivalent to bypassing the permission system itself.

## Policy-gated unsandboxed execution

`dangerouslyDisableSandbox` should only work when the active policy explicitly allows unsandboxed commands.

If policy forbids unsandboxed execution, the runtime must keep the command sandboxed or reject it outright depending on platform capability. It must not silently degrade into an unsandboxed run just because the caller requested one.

## Native Windows refusal path

PowerShell has an additional enterprise-policy contract on native Windows:

- native Windows does not provide the same shell sandbox implementation as the POSIX platforms
- if policy requires sandboxing and also forbids unsandboxed shell commands, PowerShell must be refused instead of running outside the sandbox
- that refusal needs to exist both in normal validation and again at the actual execution entry point so direct internal callers cannot bypass it

On supported POSIX-style platforms, PowerShell should share the same sandbox wrapping model as Bash.

## Relationship to permission checks

Sandboxing does not replace the permission engine.

A faithful rebuild should keep these layers distinct:

- sandbox exclusions are convenience hints
- permission rules still decide allow, deny, or ask
- protected-path safety checks still apply even when the command is unsandboxed
- sandbox write allowlists can widen writable directories for shell-created files, but only as an explicit sandbox boundary, not as a replacement for ordinary working-directory policy

## Result surfacing

Sandbox behavior should remain visible after execution. Equivalent implementations should preserve result annotation when the sandbox blocked part of the command rather than failing silently or rewriting the command result as if the sandbox never existed.

## Failure modes

- **policy bypass**: a sandbox override works even though managed policy disallowed unsandboxed commands
- **Windows silent fallback**: native Windows runs unsandboxed even when policy required sandboxing
- **exclusion confusion**: excluded commands are mistaken for a true security allow and weaken the permission model
- **normalization gap**: wrapper or env-prefixed commands miss excluded-command matching and behave inconsistently
- **invisible sandbox failure**: users cannot tell whether a command failed because of the shell itself or because the sandbox blocked it
