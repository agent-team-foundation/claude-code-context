---
title: "Permission Rule Loading and Persistence"
owners: []
soft_links: [/platform-services/policy-and-managed-settings-lifecycle.md, /tools-and-permissions/permission-model.md, /tools-and-permissions/permission-mode-transitions-and-gates.md, /tools-and-permissions/config-discovery-and-trigger-tool-contracts.md, /tools-and-permissions/shell-rule-grammar-and-matching.md, /tools-and-permissions/path-and-filesystem-safety.md, /memory-and-context/instruction-sources-and-precedence.md]
---

# Permission Rule Loading and Persistence

Permission state is assembled from multiple sources, can be edited at runtime, and must survive mode changes without losing source attribution. Reimplementation requires more than "store a few allowlists."

## Rule-source model

Permission rules come from layered sources, including:

- managed and other on-disk settings
- command-line overlays
- command-scoped temporary grants
- session-scoped temporary grants

The runtime must preserve each rule's source so that later UI actions know whether a rule is editable, temporary, or enterprise-controlled.

## Managed-only posture

Enterprise policy can force a managed-only rule posture.

When that posture is active:

- only managed permission rules participate in execution
- user-facing "always allow" affordances should disappear
- syncing from disk must clear non-managed rule sources out of the in-memory context

This is not just a UI toggle. It changes which rules actually exist for decision-making.

## Editable versus non-editable sources

Not every source is writable.

Equivalent behavior should treat only local, user, and project settings as persistable destinations. Managed policy, build flags, command-scoped rules, and session-scoped rules may affect runtime behavior but should not be edited through the normal persistence path.

## Update operations

The permission subsystem needs structured update primitives, not ad hoc file edits.

Supported update classes should include:

- set default mode
- add rules
- replace all rules for one source and behavior
- remove rules
- add additional working directories
- remove additional working directories

These updates must work both in-memory and, when allowed, on disk.

These same primitives should back any permission browser or retry surface. User actions there should mutate structured, source-attributed rule state rather than editing raw settings text blindly.

## Canonical normalization

Rule editing must normalize legacy spellings and equivalent forms.

Equivalent behavior should normalize through a parse-and-serialize roundtrip when adding or removing rules so that:

- deprecated tool names collapse to canonical names
- broad equivalents such as bare tool rules and wildcard spellings compare correctly
- duplicate rules are detected even if the stored text differs

Without normalization, deletion and deduplication become unreliable.

## Lenient editing path

Settings files may contain unrelated invalid fields, but permission editing should still preserve the rest of the file.

That means the editing path needs a lenient loader that can:

- parse raw settings data without full schema validation
- append or remove permission entries without discarding unrelated unknown fields
- continue to use the strict loader for actual runtime execution

The editing path and the execution path should therefore be intentionally different.

## Additional working directories

Permission state includes more than tool rules.

Equivalent behavior should also track additional working directories with source attribution, including:

- directories granted through settings
- directories granted through command-line options
- session-scoped directory aliases such as a symlinked process working directory that differs from the canonical cwd

Directory additions should be validated and normalized before entering the permission context.

## Startup bootstrap

Initial permission context assembly is a bootstrap step.

A correct rebuild should:

- load rules from disk
- merge command-line allow and deny overlays
- apply any base-tool narrowing or preset-derived tool exclusions
- validate extra working directories
- produce both the active permission context and any warnings needed for the foreground session

This bootstrap must happen before the tool pool and permission UI are treated as authoritative.

## Dangerous-rule stripping for auto mode

Auto mode cannot blindly inherit every allow rule.

On entry to auto mode, the runtime should strip allow rules that would bypass action classification, including:

- shell-wide wildcard allows
- interpreter-prefix shell allows
- dangerous PowerShell execute-or-spawn patterns
- subagent-spawn allows
- equivalent arbitrary-execution shortcuts in supported foreground builds

The stripped rules should be stashed, not discarded permanently.

## Restore-on-exit behavior

Leaving auto mode should restore the user's previously stripped dangerous rules.

This preserves the user's broader default-mode permissions while keeping auto mode safer. A rebuild that permanently deletes those rules will silently corrupt the user's configuration model.

## Overly broad foreground warnings

The runtime also distinguishes between rules that are merely broad and rules that are classifier-bypassing.

Equivalent behavior should be able to warn foreground users when shell-wide allow rules effectively grant full shell freedom, even outside auto mode. That warning surface is separate from the stricter auto-mode stripping path.

## Failure modes

- **source erasure**: persisted and temporary rules become indistinguishable
- **managed-policy leak**: non-managed rules still influence execution in managed-only mode
- **edit corruption**: removing one rule rewrites or discards unrelated settings
- **auto-mode bypass**: dangerous allow rules survive into auto mode and nullify classifier safety
- **restoration loss**: stripped rules are not restored when leaving auto mode
