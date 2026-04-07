---
title: "Shell Rule Grammar and Matching"
owners: []
soft_links: [/tools-and-permissions/filesystem-and-shell/shell-command-parsing-and-classifier-flow.md, /tools-and-permissions/permissions/permission-rule-loading-and-persistence.md, /tools-and-permissions/permissions/permission-decision-pipeline.md, /tools-and-permissions/agent-and-task-control/control-plane-tools.md]
---

# Shell Rule Grammar and Matching

Claude Code's shell permission system is built on a shared rule grammar, but Bash and PowerShell apply different normalization and canonicalization rules before a command is considered a match.

## Shared rule grammar

Equivalent shell-rule handling should support three rule kinds:

- exact rules that match one fully normalized command string
- prefix rules that match a stable command prefix plus optional arguments
- wildcard rules where `*` matches any sequence of characters

Legacy prefix syntax should still round-trip as a stored `:*` rule, even if the runtime internally parses it as a dedicated prefix type.

## Wildcard semantics

The wildcard engine should preserve these details:

- `\*` means a literal asterisk, not a wildcard
- `\\` means a literal backslash
- matching is against the entire normalized command, not an arbitrary substring
- wildcard matching must span embedded newlines so multiline shell commands do not silently evade stored patterns
- a single trailing `" *"` wildcard should behave like a prefix rule and therefore match both the bare command and the command with extra arguments

That last rule avoids needless mismatch between wildcard and prefix storage for common shell patterns.

## Bash normalization

Bash matching is not performed against the raw typed string alone.

The matching layer should be able to compare rules against normalized candidates that:

- strip comment-only lines
- strip a narrow allowlist of harmless leading environment assignments
- strip a narrow allowlist of wrapper commands that only exec their arguments
- repeat those stripping passes until the normalized command stops changing

This normalization is a convenience feature for permission matching and sandbox exclusions. It is not a license to treat arbitrary wrappers or arbitrary environment variables as safe.

## Bash suggestion strategy

Bash permission suggestions should prefer durable prefixes instead of fragile exact matches.

Required behavior:

- heredoc commands should suggest a stable prefix before the heredoc body, not the full multiline payload
- other multiline commands should usually fall back to a first-line prefix
- single-line commands should prefer a two-word prefix when the second token looks like a real subcommand
- commands whose first token is itself an unsafe shell launcher or wrapper must not auto-suggest a broad prefix rule
- if no stable prefix exists, the fallback may remain an exact rule

The UI may still seed a broader editable starting point than the backend would auto-save. That is a product choice, not a contradiction.

## PowerShell canonical matching

PowerShell matching must be case-insensitive and alias-aware.

Equivalent behavior should preserve these rules:

- command names should be canonicalized so alias rules and full-cmdlet rules can meet in the middle
- deny and ask rules may strip module prefixes to fail closed across equivalent command spellings
- allow rules must not over-canonicalize module qualification, because broadening an allow is fail-open
- whitespace normalization around the command name and the remaining arguments matters; tabs or alternate spacing should not create bypasses

## PowerShell suggestion strategy

PowerShell should be stricter about when it proposes an exact reusable rule.

Equivalent behavior should avoid exact auto-suggestions for:

- multiline commands
- commands containing literal glob stars that cannot round-trip back through the parser as the same exact command

## Compound-command matching

Shell rules must not only inspect the first visible command in a compound string.

A correct rebuild should preserve these protections:

- hook-style matchers should inspect subcommands, not only the whole raw string
- allow/ask/deny decisions must still be able to fire when a risky subcommand appears later in a compound shell command
- PowerShell pipelines and multi-statement commands should evaluate per subcommand so a harmless first stage does not silently bless a harmful later stage
- when richer parsed shell structure is available, compound-command matching should treat that parsed structure as authoritative and leave string-prefix heuristics to the UI fallback path

## Auto-allow exclusions

Some matches must still refuse automatic allow behavior even when a rule technically matches.

Important exclusions include:

- PowerShell commands whose parsed command name is actually a script or executable path rather than a cmdlet/application alias
- PowerShell commands whose arguments obviously leak runtime values and therefore should not be silently blessed by an exact allow rule
- Bash prefixes that would effectively authorize arbitrary shell evaluation

## Failure modes

- **wildcard overreach**: a stored wildcard matches far more than the user intended because escaping or trailing-argument handling changed
- **dead exact rule**: a heredoc or multiline exact rule is stored even though it will never match future commands
- **allow widening**: PowerShell canonicalization broadens an allow rule across module boundaries
- **subcommand blind spot**: only the first command in a pipeline or compound string is checked
- **unsafe normalization**: wrapper or environment stripping turns a convenience feature into an unintended security boundary
