---
title: "Markdown Prompt Shell Expansion"
owners: []
soft_links: [/integrations/plugins/skill-loading-contract.md, /integrations/plugins/plugin-runtime-contract.md, /tools-and-permissions/filesystem-and-shell/shell-execution-and-backgrounding.md, /tools-and-permissions/permissions/permission-model.md, /product-surface/review-and-pr-automation-commands.md]
---

# Markdown Prompt Shell Expansion

Claude Code does not treat markdown-backed commands and skills as static prompt text. Before the model ever sees that content, the runtime can substitute arguments and runtime variables, decide which shell backend is allowed, execute embedded shell snippets through the same permission-aware shell tools used elsewhere, and splice the resulting output back into the prompt. Rebuilding this correctly matters because many command contracts rely on those pre-expanded snapshots rather than asking the model to collect the same context after the turn starts.

## Scope boundary

This leaf covers:

- how built-in prompt commands, local skills, and plugin-provided markdown commands are turned into final prompt text at invocation time
- runtime variable substitution such as skill-directory and session-ID placeholders
- inline shell snippet syntax, shell backend selection, permission checks, and result insertion
- the trust boundary that forbids remote MCP skills from executing embedded shell snippets
- the caller-scoped allowlist model used while expanding markdown-backed prompts

It intentionally does not re-document:

- the broader skill discovery and indexing lifecycle already captured in [skill-loading-contract.md](skill-loading-contract.md)
- generic plugin admission, caching, and marketplace behavior already captured in [plugin-runtime-contract.md](plugin-runtime-contract.md)
- ordinary model-initiated shell tool execution already captured in [shell-execution-and-backgrounding.md](../../tools-and-permissions/filesystem-and-shell/shell-execution-and-backgrounding.md)
- the general permission engine outside this prompt-expansion path already captured in [permission-model.md](../../tools-and-permissions/permissions/permission-model.md)
- the higher-level user-facing review and PR command contracts that merely reuse this expansion pipeline, already captured in [review-and-pr-automation-commands.md](../../product-surface/review-and-pr-automation-commands.md)

## Markdown-backed commands are compiled at invocation time, not stored as static text

Equivalent behavior should preserve:

- built-in prompt commands, local skills, and plugin markdown commands each producing mutable prompt text that is finalized only when the command is invoked
- argument substitution happening before shell expansion so embedded shell snippets can depend on user-supplied arguments or derived placeholders
- runtime placeholders such as the current session ID being substituted into the prompt body before shell execution starts
- skill-backed prompts receiving a stable "this skill lives here" directory hint so bundled helper scripts can be referenced without hardcoding installation paths
- Windows skill-directory placeholders being normalized to forward slashes before insertion so embedded shell commands do not misread backslashes as escape characters
- plugin-backed prompts being able to substitute plugin-root variables, command- or skill-specific directories, and saved user-config option placeholders before shell execution
- sensitive saved plugin options being replaced with descriptive placeholders instead of raw secret values, because the expanded prompt text is destined for the model

## Inline shell execution supports two markdown syntaxes and a strict trigger grammar

Equivalent behavior should preserve:

- embedded shell execution supporting both inline ``!`command` `` syntax and fenced code blocks whose fence starts with ```!```
- inline execution only triggering when the `!` marker appears at start-of-line or after whitespace, so ordinary markdown code spans, adjacent backticks, and shell-variable text are not accidentally treated as executable snippets
- fenced execution treating the block body as the command payload after trimming surrounding whitespace
- prompt bodies with no inline shell markers avoiding the expensive inline-regex scan entirely instead of always paying that cost on large markdown inputs
- multiple embedded shell snippets being expanded in one prompt assembly pass rather than requiring a second round trip through the model

## Shell backend selection is author-driven but still constrained by runtime gates

Equivalent behavior should preserve:

- prompt-shell expansion defaulting to Bash unless the markdown author explicitly selected PowerShell in frontmatter
- prompt-shell expansion never reading the user's interactive default-shell setting, because author-authored markdown shell snippets and user-entered `!` commands are intentionally separate routing paths
- PowerShell prompt expansion only being allowed on Windows, where the PowerShell permission and path-normalization logic is supported
- internal builds defaulting PowerShell on, subject to explicit opt-out, while external builds default it off unless the user explicitly opts in
- a frontmatter request for PowerShell falling back to Bash when the runtime gate says PowerShell is unavailable, instead of failing open or pretending a PowerShell backend exists
- the PowerShell tool being loaded lazily on first use so ordinary startup does not pay the cost of initializing the full PowerShell stack

## Prompt-shell snippets reuse the real shell tools, permission checks, and output persistence pipeline

Equivalent behavior should preserve:

- each embedded shell snippet being checked through the same permission engine used for ordinary tool calls before the shell command is executed
- prompt expansion supplying caller-scoped always-allow command rules so built-in commands, skills, and plugin commands can permit only their declared shell patterns during this preprocessing step
- the shell tool being called directly with the command payload after permission approval, while still relying on the concrete shell tool's own safety checks to catch invalid inputs
- large shell outputs flowing through the same tool-result persistence pipeline used for regular shell tools, so oversized snapshots can collapse to preview-plus-artifact form instead of being truncated away
- prompt substitution preserving raw shell output faithfully, including dollar signs and other replacement-sensitive characters, rather than letting string-replacement semantics corrupt the inserted content
- stdout and stderr both being represented in the final inserted prompt text when shell execution succeeds with warnings or partial output

## Trust boundaries differ across local skills, plugin content, and MCP skills

Equivalent behavior should preserve:

- local skills and plugin-provided markdown being allowed to execute embedded shell snippets only after passing the normal prompt-shell permission checks
- MCP-provided skills being treated as remote and untrusted, which means their markdown body must never execute embedded shell snippets during prompt assembly
- MCP skills still participating in the broader skill surface even though their inline shell blocks are ignored
- skill-directory placeholders being meaningless for MCP skills and therefore not used as a backdoor to local file execution
- plugin-provided command names and skill namespaces still being able to reuse this shell-expansion path when their source is local and trusted

## Failure handling is fail-closed and should not silently leave stale shell syntax behind

Equivalent behavior should preserve:

- permission denial during prompt-shell expansion being surfaced as a malformed command-expansion failure instead of silently skipping the shell snippet
- interrupted or failed shell execution becoming explicit formatted expansion errors instead of half-expanded prompt text with raw markdown shell markers still present
- malformed prompt-shell snippets preventing the caller from receiving a misleadingly complete prompt body
- callers reusing this expansion pipeline remaining responsible for declaring the narrow allowlist that makes their shell snippets legal in the first place
- shared shell-selection and formatting logic staying aligned with the user-facing `!` command path where appropriate, so prompt expansion and interactive shell commands do not drift on backend choice or output formatting conventions

## Failure modes

- **secret prompt leakage**: saved plugin option secrets are inserted verbatim into prompt text instead of redacting to descriptive placeholders
- **untrusted-shell execution**: MCP-delivered skills are allowed to run embedded shell snippets against the local machine
- **backend drift**: prompt-shell expansion starts honoring the interactive default shell or ignores the PowerShell runtime gate, so the same markdown executes against the wrong shell backend
- **permission bypass**: embedded shell snippets run without caller-scoped allow rules or without the ordinary permission check path
- **output corruption**: replacement-sensitive shell output such as dollar signs or persisted-output wrappers is mangled during prompt insertion
- **false trigger parsing**: ordinary markdown code spans or shell-variable text are mistakenly executed as prompt-shell snippets
- **silent partial expansion**: a failed shell snippet is dropped and the model receives incomplete context without any indication that prompt compilation failed
