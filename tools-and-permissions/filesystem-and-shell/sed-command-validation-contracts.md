---
title: "Sed Command Validation Contracts"
owners: [bingran-you]
soft_links: [/tools-and-permissions/filesystem-and-shell/shell-command-parsing-and-classifier-flow.md, /tools-and-permissions/permissions/permission-decision-pipeline.md, /reconstruction-guardrails/verification-and-native-test-oracles/native-test-derived-asset-provenance-and-acceptance-rules.md]
native_source: tools/BashTool/sedValidation.ts
verification_status: native_test_derived
---

# Sed Command Validation Contracts

This leaf documents the testable contracts for sed command validation, extracted from the Claude Code source `tools/BashTool/sedValidation.ts` (685 lines). These contracts define which sed commands are automatically allowed vs. which require explicit user approval.

## Scope boundary

This leaf covers:

- sed command allowlist patterns for automatic approval
- sed command denylist patterns that trigger approval prompts
- testable function contracts with input/output specifications
- extractable test cases for Python reconstruction validation

It intentionally does not cover:

- general shell command parsing (see shell-command-parsing-and-classifier-flow.md)
- permission decision pipeline (see permission-decision-pipeline.md)

## Test entry point pattern

The source marks testable functions with `@internal Exported for testing` JSDoc comments. This is the primary pattern for identifying test contracts.

## Testable function contracts

### `isPrintCommand(cmd: string): boolean`

Validates that a sed expression is a safe print command.

**Contract**: Returns `true` only for these exact forms:
- `p` (print all)
- `Np` (print line N, where N is digits)
- `N,Mp` (print lines N through M)

**Implementation regex**: `/^(?:\d+|\d+,\d+)?p$/`

**Test cases**:
```
PASS: "p"       -> true
PASS: "1p"      -> true
PASS: "123p"    -> true
PASS: "1,5p"    -> true
PASS: "10,200p" -> true

FAIL: ""        -> false
FAIL: "w file"  -> false
FAIL: "e cmd"   -> false
FAIL: "1,5w"    -> false
FAIL: "p;w"     -> false
FAIL: "1p;2p"   -> false (semicolons not allowed in isPrintCommand itself)
```

### `isLinePrintingCommand(command: string, expressions: string[]): boolean`

Validates Pattern 1: sed commands with `-n` flag and print expressions.

**Contract**:
- Must have `-n` (or `--quiet`/`--silent`) flag
- Only allows flags: `-n`, `--quiet`, `--silent`, `-E`, `--regexp-extended`, `-r`, `-z`, `--zero-terminated`, `--posix`
- All expressions must be valid print commands (allows semicolon-separated)
- File arguments ARE allowed for this pattern

**Test cases**:
```
PASS: "sed -n '1p'"
PASS: "sed -n '1,5p'"
PASS: "sed -n '1p;2p;3p'"
PASS: "sed -nE '1p' file.txt"

FAIL: "sed '1p'"           (missing -n flag)
FAIL: "sed -n 's/a/b/'"    (substitution, not print)
FAIL: "sed -n '1w file'"   (write command)
FAIL: "sed -ni '1p'"       (disallowed -i flag for pattern 1)
```

### `hasFileArgs(command: string): boolean`

Detects if a sed command has file arguments (not just stdin).

**Contract**:
- Returns `true` if any non-flag, non-expression arguments exist
- Handles `-e`/`--expression` flags correctly
- Treats glob patterns as file arguments
- Returns `true` on parse failure (fail-closed)

**Test cases**:
```
PASS (has files): "sed 's/a/b/' file.txt"       -> true
PASS (has files): "sed -e 's/a/b/' file.txt"    -> true
PASS (has files): "sed 's/a/b/' *.log"          -> true

FAIL (no files):  "sed 's/a/b/'"                -> false
FAIL (no files):  "sed -e 's/a/b/'"             -> false
```

### `extractSedExpressions(command: string): string[]`

Extracts sed expressions from command for validation.

**Contract**:
- Returns array of sed expressions (content inside quotes)
- Handles `-e`/`--expression` flags
- Throws on dangerous flag combinations (`-ew`, `-eW`, `-ee`, `-we`)
- Throws on malformed shell syntax

**Test cases**:
```
PASS: "sed 's/a/b/'"                  -> ["s/a/b/"]
PASS: "sed -e 's/a/b/' -e 's/c/d/'"   -> ["s/a/b/", "s/c/d/"]
PASS: "sed --expression='1p'"          -> ["1p"]

THROW: "sed -ew 's/a/b/'"             (dangerous flag combo)
THROW: "sed 's/a/b"                   (malformed syntax)
```

### `sedCommandIsAllowedByAllowlist(command: string, options?: { allowFileWrites?: boolean }): boolean`

Main entry point for sed validation.

**Contract**:
- Pattern 1 (line printing): `-n` flag + print commands, file args allowed
- Pattern 2 (substitution): `s/pattern/replacement/flags`, stdout only by default
- With `allowFileWrites: true`: Pattern 2 allows `-i` flag and file arguments
- Defense-in-depth: Even if allowlist matches, denylist is still checked
- Pattern 2 does not allow semicolons in expressions

**Allowed substitution flags**: `g`, `p`, `i`, `I`, `m`, `M`, `1-9`

**Test cases**:
```
# Pattern 1 - line printing
PASS: "sed -n '1p'"
PASS: "sed -n '1,5p' file.txt"

# Pattern 2 - substitution (stdout only)
PASS: "sed 's/foo/bar/'"
PASS: "sed 's/foo/bar/g'"
PASS: "sed -E 's/foo/bar/gi'"

FAIL: "sed 's/foo/bar/' file.txt"       (file args without allowFileWrites)
FAIL: "sed -i 's/foo/bar/' file.txt"    (in-place without allowFileWrites)

# Pattern 2 with allowFileWrites: true
PASS: "sed -i 's/foo/bar/' file.txt"    (in-place editing allowed)
```

## Denylist patterns (`containsDangerousOperations`)

The denylist provides defense-in-depth by blocking dangerous patterns even if the allowlist matched.

### Blocked patterns

| Pattern | Examples | Reason |
|---------|----------|--------|
| Non-ASCII | `ｗ` (fullwidth), `ᴡ` (small capital) | Unicode homoglyphs |
| Curly braces | `{cmd}`, `{1,5}` | Block constructs too complex |
| Newlines | `\n` in expression | Multi-line commands |
| Write commands | `w file`, `W file`, `/pattern/w file` | File writes |
| Execute commands | `e`, `1e`, `/pattern/e` | Shell execution |
| Substitution write flag | `s/old/new/w file` | Write via s flag |
| Substitution execute flag | `s/old/new/e` | Execute via s flag |
| Negation | `!/pattern/`, `/pattern/!` | Negation operator |
| Step address | `1~2`, `$~3` | GNU step syntax |
| Backslash delimiter | `s\pattern\repl\` | Alternate delimiter tricks |
| y command with w/W/e/E | `y/a/b/w` | Paranoid block |

**Test cases**:
```
BLOCK: "{}"                    (curly braces)
BLOCK: "\n"                    (newline)
BLOCK: "w output.txt"          (write command)
BLOCK: "e /bin/sh"             (execute command)
BLOCK: "1w file"               (addressed write)
BLOCK: "s/old/new/w file"      (substitution write flag)
BLOCK: "s/old/new/e"           (substitution execute flag)
BLOCK: "/pattern/w file"       (pattern-addressed write)
BLOCK: "!/pattern/p"           (negation)
BLOCK: "1~2p"                  (step address)
```

## Reconstruction guidance

A Python reconstruction should:

1. Implement `is_print_command(cmd)` with regex `/^(?:\d+|\d+,\d+)?p$/`
2. Implement `is_line_printing_command(command, expressions)` checking:
   - `-n` flag presence
   - Flag allowlist validation
   - All expressions are valid print commands
3. Implement `has_file_args(command)` with shell parsing
4. Implement `extract_sed_expressions(command)` with:
   - `-e`/`--expression` handling
   - Dangerous flag combo detection
   - Error on malformed syntax
5. Implement `sed_command_is_allowed_by_allowlist(command, allow_file_writes)` combining:
   - Pattern 1 and Pattern 2 checks
   - Denylist defense-in-depth
6. Implement `contains_dangerous_operations(expression)` with all denylist patterns

## Acceptance criteria

- [ ] All `isPrintCommand` test cases pass
- [ ] All `isLinePrintingCommand` test cases pass
- [ ] All `hasFileArgs` test cases pass
- [ ] All `extractSedExpressions` test cases pass (including throws)
- [ ] All `sedCommandIsAllowedByAllowlist` test cases pass
- [ ] All denylist patterns correctly blocked
- [ ] Defense-in-depth: denylist runs even when allowlist matches
