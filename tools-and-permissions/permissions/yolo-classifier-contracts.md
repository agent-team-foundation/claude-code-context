---
title: "YOLO Classifier Contracts"
owners: [bingran-you]
soft_links: [/tools-and-permissions/permissions/permission-decision-pipeline.md, /tools-and-permissions/permissions/permission-model.md]
native_source: utils/permissions/yoloClassifier.ts
verification_status: native_test_derived
---

# YOLO Classifier Contracts

This leaf documents the testable contracts for the YOLO (auto mode) classifier, extracted from Claude Code source `utils/permissions/yoloClassifier.ts` (1496 lines). The YOLO classifier is an ML-based system that decides whether agent actions should be auto-approved or require user confirmation.

## Scope boundary

This leaf covers:

- Transcript building and serialization contracts
- Classifier response parsing contracts
- Auto mode rules configuration contracts
- Two-stage XML classifier behavior contracts

It intentionally does not cover:

- General permission decision pipeline (see permission-decision-pipeline.md)
- Permission model architecture (see permission-model.md)
- Bash-specific classifier rules (separate module)

## Core types

### `AutoModeRules`

Configuration schema for customizable classifier rules.

```typescript
type AutoModeRules = {
  allow: string[]      // Actions to auto-approve
  soft_deny: string[]  // Actions to block (soft, can be overridden)
  environment: string[] // Environment context for classifier
}
```

### `TranscriptEntry`

Format for conversation history entries fed to classifier.

```typescript
type TranscriptEntry = {
  role: 'user' | 'assistant'
  content: TranscriptBlock[]
}

type TranscriptBlock =
  | { type: 'text'; text: string }
  | { type: 'tool_use'; name: string; input: unknown }
```

### `YoloClassifierResult`

Response schema from classifier.

```typescript
// Tool-use classifier response (via classify_result tool)
{
  thinking: string      // Brief step-by-step reasoning
  shouldBlock: boolean  // true = block, false = allow
  reason: string        // Brief explanation
}
```

## Testable function contracts

### `buildTranscriptEntries(messages: Message[]): TranscriptEntry[]`

Builds transcript from message history for classifier input.

**Contract**:
- Includes user text messages as `{ role: 'user', content: [{ type: 'text', text }] }`
- Includes assistant tool_use blocks (excluding assistant text to prevent classifier manipulation)
- Extracts queued_command prompts from attachment messages
- Returns empty content array entries are filtered out

**Test cases**:
```
INPUT: [{ type: 'user', message: { content: 'Hello' } }]
OUTPUT: [{ role: 'user', content: [{ type: 'text', text: 'Hello' }] }]

INPUT: [{ type: 'assistant', message: { content: [
  { type: 'text', text: 'I will run a command' },  // EXCLUDED
  { type: 'tool_use', name: 'Bash', input: { command: 'ls' } }
] } }]
OUTPUT: [{ role: 'assistant', content: [{ type: 'tool_use', name: 'Bash', input: { command: 'ls' } }] }]
```

### `buildTranscriptForClassifier(messages: Message[], tools: Tools): string`

Serializes transcript to compact string format for classifier.

**Contract**:
- Uses tool's `toAutoClassifierInput()` method for encoding
- JSONL format when enabled: `{"Bash":"ls"}\n`
- Legacy format: `Bash ls\n`
- User messages: `{"user":"text"}\n` or `User: text\n`
- Empty tool encodings (`''`) are skipped

**Test cases**:
```
# JSONL format
TOOL_USE(Bash, {command: 'ls'}) -> '{"Bash":"ls"}\n'
USER_TEXT('hello') -> '{"user":"hello"}\n'

# Legacy format
TOOL_USE(Bash, {command: 'ls'}) -> 'Bash ls\n'
USER_TEXT('hello') -> 'User: hello\n'
```

### `getDefaultExternalAutoModeRules(): AutoModeRules`

Parses default rules from external permissions template.

**Contract**:
- Extracts bullet items from `<user_allow_rules_to_replace>` tag
- Extracts bullet items from `<user_deny_rules_to_replace>` tag
- Extracts bullet items from `<user_environment_to_replace>` tag
- Each line starting with `- ` becomes one array entry (minus the prefix)

**Test cases**:
```
TEMPLATE: "<user_allow_rules_to_replace>\n- Rule 1\n- Rule 2\n</user_allow_rules_to_replace>"
OUTPUT: { allow: ['Rule 1', 'Rule 2'], soft_deny: [], environment: [] }
```

### `formatActionForClassifier(toolName: string, toolInput: unknown): TranscriptEntry`

Creates a transcript entry for a single action being classified.

**Contract**:
- Returns `{ role: 'assistant', content: [{ type: 'tool_use', name: toolName, input: toolInput }] }`
- Used to format the current action being evaluated

**Test cases**:
```
INPUT: ('Bash', { command: 'rm -rf /' })
OUTPUT: { role: 'assistant', content: [{ type: 'tool_use', name: 'Bash', input: { command: 'rm -rf /' } }] }
```

## XML classifier contracts

The two-stage XML classifier is an alternative to the tool-use classifier.

### XML response parsing

**`parseXmlBlock(text: string): boolean | null`**

Parses `<block>yes/no</block>` from classifier response.

**Contract**:
- Strips `<thinking>...</thinking>` content first (prevent manipulation)
- Returns `true` for "yes" (should block)
- Returns `false` for "no" (should allow)
- Returns `null` if unparseable
- Case-insensitive matching

**Test cases**:
```
PASS: "<block>yes</block>" -> true
PASS: "<block>no</block>" -> false
PASS: "<block>YES</block>" -> true
PASS: "<thinking>ignore</thinking><block>no</block>" -> false
FAIL: "<thinking><block>yes</block></thinking><block>no</block>" -> false (inner ignored)
FAIL: "no block tag" -> null
```

**`parseXmlReason(text: string): string | null`**

Extracts `<reason>...</reason>` from classifier response.

**Contract**:
- Strips `<thinking>...</thinking>` content first
- Returns trimmed reason text
- Returns `null` if no reason tag

**Test cases**:
```
PASS: "<reason>Security risk</reason>" -> "Security risk"
PASS: "<reason>  Trimmed  </reason>" -> "Trimmed"
FAIL: "no reason" -> null
```

### Two-stage classifier modes

**Modes**:
- `'both'` (default): Stage 1 fast decision, escalate to Stage 2 on block
- `'fast'`: Stage 1 only, verdict is final
- `'thinking'`: Stage 2 only, includes chain-of-thought

**Stage 1 (fast)**:
- max_tokens: 64 (256 in fast-only mode)
- Suffix: "Err on the side of blocking. <block> immediately."
- If `<block>no</block>` → allow immediately (fast path)
- If `<block>yes</block>` or null → escalate to Stage 2 (or block in fast-only)

**Stage 2 (thinking)**:
- max_tokens: 4096
- Suffix: "Review the classification process and follow it carefully..."
- Includes `<thinking>` before `<block>`

## Classifier response schema

### Tool-use classifier

Uses `classify_result` tool with schema:

```json
{
  "type": "object",
  "properties": {
    "thinking": { "type": "string", "description": "Brief step-by-step reasoning" },
    "shouldBlock": { "type": "boolean", "description": "Whether to block (true) or allow (false)" },
    "reason": { "type": "string", "description": "Brief explanation" }
  },
  "required": ["thinking", "shouldBlock", "reason"]
}
```

### Error handling

**Contract**:
- On parse failure → `shouldBlock: true` with reason "blocking for safety"
- On API error → `shouldBlock: true` with `unavailable: true`
- On abort signal → `shouldBlock: true` with `unavailable: true`
- On prompt too long → `shouldBlock: true` with `transcriptTooLong: true`

## PowerShell deny guidance

When PowerShell auto mode is active, additional deny rules are appended:

| Pattern | Maps to Category |
|---------|------------------|
| `iex (iwr ...)`, `Invoke-Expression (Invoke-WebRequest ...)` | Code from External |
| `Remove-Item -Recurse -Force`, `rm -r -fo` | Irreversible Local Destruction |
| Modifying `$PROFILE`, `Register-ScheduledTask` | Unauthorized Persistence |
| `Start-Process -Verb RunAs`, `-ExecutionPolicy Bypass` | Security Weaken |

## Reconstruction guidance

A Python reconstruction should:

1. Implement `TranscriptEntry` and `TranscriptBlock` types
2. Implement `build_transcript_entries(messages)` extracting:
   - User text messages (excluding images)
   - Assistant tool_use blocks (excluding assistant text)
   - Queued command prompts from attachments
3. Implement `build_transcript_for_classifier(messages, tools)` with:
   - Tool `to_auto_classifier_input()` method support
   - JSONL and legacy format output
4. Implement XML response parsers:
   - `parse_xml_block(text)` with thinking-stripping
   - `parse_xml_reason(text)` with thinking-stripping
5. Implement classifier result schema validation
6. Implement fail-safe error handling (block on any failure)

## Acceptance criteria

- [ ] TranscriptEntry correctly excludes assistant text content
- [ ] buildTranscriptEntries handles queued_command attachments
- [ ] buildTranscriptForClassifier uses tool's toAutoClassifierInput
- [ ] parseXmlBlock strips thinking content before parsing
- [ ] parseXmlReason strips thinking content before parsing
- [ ] Classifier returns shouldBlock: true on any error
- [ ] Two-stage classifier escalates correctly from Stage 1 to Stage 2
- [ ] PowerShell deny guidance maps to correct categories
