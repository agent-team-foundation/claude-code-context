---
title: "Verification Agent Contract"
owners: [bingran-you]
soft_links: [/tools-and-permissions/tool-catalog/agent-definition-loading-and-precedence.md, /tools-and-permissions/execution-and-hooks/agent-runtime-context-and-tool-shaping.md, /runtime-orchestration/automation/review-path.md]
native_source: tools/AgentTool/built-in/verificationAgent.ts
verification_status: native_test_derived
---

# Verification Agent Contract

This leaf documents the testable contract for Claude Code's built-in verification agent, extracted from `tools/AgentTool/built-in/verificationAgent.ts` and cross-checked against the built-in-agent catalog wiring in `tools/AgentTool/builtInAgents.ts`, `tools/AgentTool/constants.ts`, and `tools/AgentTool/AgentTool.tsx`.

## Scope boundary

This leaf covers:

- how the verification agent becomes available in the built-in agent catalog
- the built-in definition fields that materially affect runtime behavior
- the behavioral contract encoded in the verification system prompt
- the required verdict format and check structure
- reconstruction guidance for reproducing the same verification posture

It intentionally does not re-document:

- generic built-in agent loading precedence already covered in [agent-definition-loading-and-precedence.md](agent-definition-loading-and-precedence.md)
- the broader worker runtime shaping path already covered in [../execution-and-hooks/agent-runtime-context-and-tool-shaping.md](../execution-and-hooks/agent-runtime-context-and-tool-shaping.md)
- the user-facing review command family already covered in [../../product-surface/review-and-pr-automation-commands.md](../../product-surface/review-and-pr-automation-commands.md)

## Catalog availability and activation

The verification agent is not always present.

**Contract**:

- It is a built-in agent definition (`source: built-in`, `baseDir: built-in`).
- Higher-precedence built-in-catalog exits can prevent it from appearing at all:
  - noninteractive SDK sessions can disable all built-in agents through `CLAUDE_AGENT_SDK_DISABLE_BUILTIN_AGENTS`
  - coordinator-mode routing can return the coordinator agent set before ordinary built-ins are assembled
- Within the ordinary built-in-catalog path, it is appended only when both conditions hold:
  - feature flag `VERIFICATION_AGENT` is enabled
  - GrowthBook gate `tengu_hive_evidence` resolves truthy
- It is added by `getBuiltInAgents()` beside other built-ins, not loaded from markdown or plugin sources.
- It is defined with `background: true`, so the runtime should treat it as an async/background-style agent by default rather than an ordinary foreground helper.

**Important runtime nuance**:

- The agent type is `verification`.
- `ONE_SHOT_BUILTIN_AGENT_TYPES` only names `Explore` and `Plan`, not `verification`.
- Therefore a faithful rebuild should not silently treat verification runs as the same special one-shot completion path used by Explore/Plan.

## Built-in definition fields

The built-in definition carries these load-bearing fields:

| Field | Value / behavior |
|------|------|
| `agentType` | `verification` |
| `whenToUse` | Verify implementation correctness before reporting completion; especially after non-trivial work |
| `color` | `red` |
| `background` | `true` |
| `model` | `inherit` |
| `source` | `built-in` |
| `baseDir` | `built-in` |
| `criticalSystemReminder_EXPERIMENTAL` | Reasserts that this is verification-only and must end with `VERDICT: PASS/FAIL/PARTIAL` |

## Disallowed tool contract

The verification agent is intentionally prevented from using project-mutating authoring tools.

**Disallowed tools**:

- `Agent`
- `ExitPlanMode`
- `FileEdit`
- `FileWrite`
- `NotebookEdit`

**Contract**:

- Verification work must not create a second layer of nested agent orchestration.
- Verification work must not directly edit project files through ordinary write/edit tools.
- The no-write posture is enforced both by prompt contract and by explicit disallowed-tool configuration.

## Input contract

The prompt contract says the caller should provide:

- the original user task description
- the list of files changed
- the approach taken
- optionally a plan file path

**Contract**:

- A reconstruction should preserve that verification is invoked with implementation context, not as a detached generic code-review pass.
- The agent is meant to verify a claimed implementation outcome, not rediscover the task from scratch.

## Core behavioral contract

The verification system prompt encodes an adversarial testing posture rather than a code-reading posture.

### Required stance

Equivalent behavior should preserve:

- the agent's job is to try to break the implementation, not to confirm it looks plausible
- code reading alone is not acceptable evidence
- a passing test suite is context, not sufficient proof
- the agent should adapt verification strategy to the change type and still run at least one adversarial probe before PASS

### Forbidden project mutations

Equivalent behavior should preserve:

- no creating, modifying, or deleting files in the project directory
- no dependency installation
- no Git write operations such as add, commit, or push
- ephemeral scripts are allowed only under temp directories such as `/tmp` or `$TMPDIR`

### Tool availability contract

Equivalent behavior should preserve:

- the agent must inspect which tools are actually available in the session
- browser automation should be attempted when present instead of being pre-dismissed
- environment/tool limitations justify `PARTIAL`, but uncertainty about correctness does not

## Verification strategy taxonomy

The built-in prompt gives type-specific strategies rather than one generic "run tests" instruction.

### Change-type examples explicitly named

- frontend changes
- backend/API changes
- CLI/script changes
- infrastructure/config changes
- library/package changes
- bug fixes
- mobile changes
- data/ML pipelines
- database migrations
- refactors with claimed no behavior change

### Universal baseline

A faithful reconstruction should preserve the universal baseline sequence:

1. Read project instructions and build/test conventions (`CLAUDE.md`, `README`, script metadata).
2. Run the build if applicable.
3. Run the test suite if it exists.
4. Run linters/type-checkers if configured.
5. Check related-code regressions.

### Adversarial probe requirement

The built-in prompt makes this a hard requirement:

- before issuing PASS, the report must include at least one adversarial probe
- examples include concurrency, boundary values, idempotency, or orphan-operation tests
- "returns 200" or "tests pass" alone is not enough

## Output contract

Every reported check must use a structured evidence block.

### Required check shape

Each check must include:

- a `### Check:` heading
- `Command run:`
- `Output observed:`
- `Result: PASS` or `FAIL`

### Final verdict contract

The report must end with exactly one of:

- `VERDICT: PASS`
- `VERDICT: FAIL`
- `VERDICT: PARTIAL`

**Contract**:

- `PARTIAL` is only for environmental/tooling limitations
- `FAIL` should include the concrete failure and reproduction
- output formatting is parser-sensitive; the literal `VERDICT: ` prefix matters

## Reconstruction guidance

A Python reconstruction of this verification lane should preserve:

1. a separately identifiable built-in `verification` agent type
2. availability that respects both higher-precedence built-in-catalog bypasses and the explicit verification feature gates, rather than assuming unconditional presence
3. background-style launch intent
4. explicit disallowed authoring tools that reinforce a verification-only posture
5. change-type-sensitive verification strategy instead of one monolithic script
6. hard requirements around build/test/lint/regression baselines
7. adversarial probes as mandatory PASS evidence
8. an exact terminal verdict grammar with `PASS`, `FAIL`, or `PARTIAL`

## Acceptance criteria

- [ ] Verification agent availability is gated by built-in feature/config and surrounding catalog-routing conditions, not assumed unconditional
- [ ] Agent definition preserves `agentType`, `background`, `model`, and disallowed-tool posture
- [ ] Verification runs cannot directly edit project files through ordinary write/edit tools
- [ ] Reconstruction preserves the baseline build/test/lint/regression sequence
- [ ] Reconstruction preserves change-type-specific strategies for frontend, backend, CLI, infra, refactor, and other named classes
- [ ] PASS requires at least one adversarial probe with actual evidence
- [ ] Final output ends with exact verdict grammar: `VERDICT: PASS`, `VERDICT: FAIL`, or `VERDICT: PARTIAL`
- [ ] Verification completion is not collapsed into the Explore/Plan one-shot built-in shortcut
