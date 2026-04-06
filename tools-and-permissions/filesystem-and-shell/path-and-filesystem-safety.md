---
title: "Path and Filesystem Safety"
owners: []
soft_links: [/tools-and-permissions/permissions/permission-model.md, /tools-and-permissions/permissions/permission-decision-pipeline.md, /memory-and-context/context-cache-and-invalidation.md]
---

# Path and Filesystem Safety

Claude Code treats path safety as a layered boundary shared by file tools and shell tools. A rebuild cannot rely on naive string-prefix checks or generic "inside cwd" logic and still preserve the same behavior.

## Global filesystem boundary

The shared path engine should evaluate both lexical and resolved forms of a path.

Important invariants:

- the allowed working set is the original session cwd plus any approved additional working directories
- both candidate paths and working directories must be checked in resolved form so symlinks do not create false denials or false allows
- comparisons must normalize case to prevent mixed-case bypasses on case-insensitive filesystems
- common platform alias roots such as macOS temp/var symlinks should normalize before containment checks

## Rule matching and path roots

Path rules are not matched as raw absolute strings only.

Equivalent behavior should preserve:

- source-relative roots for different rule origins
- gitignore-style subtree matching rather than ad hoc substring checks
- deny, ask, and allow lookups over both the original path and the resolved path

That dual lookup is load-bearing for symlink safety and for consistent rule suggestions.

## Read permission order

Read permission should follow this precedence:

1. suspicious network-style or platform-specific path shapes ask before ordinary matching
2. read-specific deny rules
3. read-specific ask rules
4. edit permission may imply read permission, but only after read-specific deny/ask checks
5. working-directory reads are allowed by default
6. internal harness-readable paths are allowed
7. explicit read allow rules
8. everything else asks, usually with a directory-scoped read suggestion

This ordering matters because explicit read restrictions must outrank the broader "if you can edit it you can read it" shortcut.

## Write permission order

Write permission should follow a different order:

1. edit deny rules
2. internal harness-editable paths
3. narrowly scoped session permissions for protected Claude-owned folders when the product explicitly offers them
4. safety checks for dangerous files and dangerous directories
5. edit ask rules
6. edit-mode allows inside working directories
7. explicit edit allow rules
8. everything else asks

Protected-path safety checks must be able to survive broad edit modes unless the runtime intentionally issued a narrower session-scoped bypass.

## Protected surfaces

A faithful rebuild should explicitly protect at least these classes:

- repository control paths such as `.git`
- editor and IDE control paths such as `.vscode` and `.idea`
- Claude-owned settings and automation folders
- shell startup files and similar execution hooks
- MCP and Claude configuration files that can redirect execution or exfiltration

These checks must resist bypasses through case changes, redundant `./` segments, `..` traversal, and symlink rewrites.

## Internal harness carve-outs

Some paths are always safe for the harness itself and should not prompt like arbitrary user files.

Equivalent behavior should preserve read and/or write carve-outs for classes such as:

- current-session plan files
- session scratchpad files
- session memory and project memory artifacts
- persisted tool-result storage
- project-scoped temporary directories
- agent/self-improvement memory stores
- task/team coordination state
- bundled skill reference extraction
- current job directories and preview-launch configuration

These carve-outs exist because the product itself depends on them. They are not generic user-file permissions.

## Suggestion strategy

Path-related asks should suggest the narrowest useful capability:

- out-of-bounds reads should suggest a directory-scoped read rule
- out-of-bounds writes should suggest adding the containing directory
- write prompts may also suggest an edit-friendly session mode, but only when that would actually upgrade capability rather than silently downgrade a stronger mode
- when the blocked target is inside one Claude skill, suggestions should prefer that single skill subtree over the whole Claude config tree

## Bash path validation

Bash path validation needs command-aware extraction instead of generic token guessing.

Required behavior:

- maintain command-specific extractors for common read/write/create commands and for output redirections
- honor the POSIX `--` end-of-options delimiter so paths beginning with `-` are still validated
- strip harmless wrapper commands before deciding which underlying command is being validated
- treat read-only `sed` forms as reads rather than writes
- if a compound Bash command changes directories and then performs a write or a redirection, require manual approval because relative paths can no longer be trusted against the original cwd
- dangerous `rm` or `rmdir` targets should force an ask with no persistent allow suggestion

When an AST is available, validation should prefer parsed argv spans over string re-parsing so quoting edge cases do not silently skip path checks.

## PowerShell path validation

PowerShell needs a richer contract because cmdlets express path semantics through parameters rather than bare argv position.

Equivalent behavior should preserve:

- a per-cmdlet configuration describing operation type, path-taking parameters, known switches, known non-path value parameters, positional arguments to skip, and write cmdlets whose write target is optional
- parameter parsing that respects PowerShell abbreviations and real parameter syntax instead of ASCII-only heuristics
- extraction only from statically literal element types; arrays, subexpressions, variables, expandable strings, or other dynamic forms must force an ask
- unknown parameters should fail closed, but still surface any obvious colon-syntax path value so deny rules can fire
- leaf-only filename parameters should only auto-validate simple leaf names; path-like values must ask
- pipeline expression sources that feed path cmdlets should ask even for reads, while still attempting deny-rule matching when a literal piped path is obvious
- cwd-changing cmdlets in a compound statement should force approval for later relative path operations because the original cwd snapshot is no longer trustworthy
- dangerous removal of protected system paths should be a hard deny, not an ask
- write cmdlets with no validated target path should ask unless the cmdlet is explicitly "optional write"

## Sandbox-aware path allowance

When sandboxing is enabled, sandbox write-allowlisted directories act as an extra write boundary outside the working directory. They should not be used to bypass ordinary in-project edit gating.

## Failure modes

- **symlink drift**: only the lexical path is checked and a resolved target escapes the allowed boundary
- **protected-file bypass**: mixed case, traversal segments, or cwd changes let writes hit Claude or repository control files
- **deny downgrade**: an unparseable or unknown parameter path falls back to ask instead of honoring an explicit deny rule
- **overbroad suggestion**: the runtime suggests granting all of `.claude` when only one skill subtree was needed
- **optional-write confusion**: network-fetch cmdlets are treated as mandatory disk writers even when no output path was supplied
