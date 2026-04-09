---
title: "Verification and Acceptance Strategy"
owners: []
soft_links: [/reconstruction-guardrails/rebuild-standard.md, /reconstruction-guardrails/rebuild-phasing.md, /product-surface/command-surface.md, /platform-services/auth-login-logout-and-token-lifecycle.md, /integrations/mcp/config-layering-policy-and-dedup.md, /integrations/plugins/plugin-management-and-marketplace-flows.md]
---

# Verification and Acceptance Strategy

This tree already explains what a faithful Claude Code rebuild must contain, but a clean-room rewrite still needs an explicit answer to a different question: **how do we prove the rebuild now behaves like Claude Code instead of merely resembling it on paper?**

A reconstruction effort is not complete when every domain has prose coverage. It is complete only when the implementation clears a repeatable acceptance contract that combines documentation completeness, automated evidence, and direct behavior comparison against a runnable Claude Code client.

## Scope boundary

This leaf covers:

- the acceptance bar for a rebuild that claims end-to-end Claude Code parity
- what evidence must exist before a milestone can be called complete
- the minimum automated and manual comparison matrix for CLI, print-mode, auth, MCP, plugin, session, and agent surfaces
- how to treat known divergence during an incremental reconstruction

It intentionally does not re-document:

- the domain-specific product contracts already captured in the rest of the tree
- implementation-specific test runner wiring for any one rewrite repository
- private fixture contents, recorded transcripts, or provider credentials

## Completion rule

Equivalent behavior should preserve this definition of done:

- **not complete** means a feature exists in the source product shape but the rebuild is missing the surface entirely, cannot execute the flow end to end, or still requires unexplained manual intervention
- **conditionally complete** means the rebuild implements the flow and has evidence, but known divergence remains and is recorded explicitly with impact and follow-up scope
- **complete enough to claim parity** means the rebuild passes automated coverage for the surface, survives manual comparison against a real Claude Code client, and has no untracked user-visible differences for the accepted environment

No milestone should be reported as "fully working like Claude Code" while a known divergence list still exists.

## Evidence stack

Every serious reconstruction milestone should carry evidence from all three layers:

1. **tree evidence** — the relevant behavior contract exists in this Context Tree and is detailed enough that another engineer could rebuild the surface without privileged source access
2. **automated evidence** — unit, integration, scenario, and end-to-end tests cover the surface with deterministic pass/fail outcomes
3. **runtime comparison evidence** — the rebuild is exercised side by side with a runnable Claude Code CLI using the same machine, workspace shape, and provider posture when possible

If any one of those layers is missing, the milestone is still provisional.

## Acceptance matrix for a CLI rebuild

Equivalent behavior should preserve an explicit acceptance matrix rather than relying on ad hoc spot checks.

At minimum, the matrix should cover:

- root entry behavior: default interactive startup, prompt-as-argument startup, `--help`, `--version`, `--resume`, `--continue`, and top-level command dispatch
- print mode: `-p/--print`, plain text output, JSON output, session-persistence toggles, schema validation, and prompt-plus-tail-option parsing
- provider and auth routing: API-key auth, Foundry or third-party provider auth, login status surfaces, logout teardown, and limited-scope token setup behavior
- session storage and restoration: session creation, latest-session reuse, naming, branching, transcript durability, and project identity matching
- MCP management and runtime effects: add, add-json, list, get, remove, project-choice reset, scope layering, and resulting live server visibility
- plugin management and runtime effects: marketplace listing, install, enable, disable, uninstall, update, validation, settings round-trip, and cache/index behavior
- agent surfaces: top-level `agents`, built-in agent visibility, agent selection defaults, and delegated worker flows
- update and install flows: launcher installation, version reporting, updater diagnostics, and safe behavior when a real Claude installation already exists
- doctor and diagnostics: health summaries, provider mode reporting, install-path reporting, and recovery guidance

The exact command list can evolve, but the acceptance matrix must be concrete enough that two different people would run materially the same comparison.

## Real-client comparison contract

Equivalent behavior should preserve direct comparison against a runnable Claude Code binary whenever the question is about user-visible behavior.

That comparison should favor:

- the exact locally runnable `claude` binary or launcher the user actually uses
- absolute commands with explicit flags rather than paraphrased expectations
- the same workspace root and config posture for both clients when possible
- the same provider mode and model defaults when the flow depends on remote inference

Useful comparison commands usually include:

- `claude --help`
- `claude --version`
- `claude -p 'Reply with exactly OK' --output-format json --no-session-persistence`
- `claude auth status --text`
- `claude agents`
- `claude mcp --help`
- `claude mcp list`
- `claude plugin --help`
- `claude plugin list`
- `claude plugin marketplace list --json`
- `claude update`
- `claude install stable --force`

The point is not that this exact list is sacred. The point is that each milestone should leave behind a concrete comparison bundle instead of a vague statement that the rewrite was "tested manually."

## State-path round-trip contract

A CLI rebuild is not faithful if it only matches stdout while silently drifting on-disk state.

Equivalent behavior should preserve verification of the user-visible state layer, especially for:

- user home state under `~/.claude/`
- global private state in `~/.claude.json`
- project-local private settings such as `.claude/settings.local.json`
- checked-in project settings such as `.claude/settings.json` or `.mcp.json`
- plugin marketplace metadata, plugin install indexes, and plugin cache paths
- MCP configuration persistence and later reload behavior

For each mutable surface, verification should prove both:

- the command prints the expected result
- the expected state file changes, and the same client can later read that change back correctly

## Fixture and transcript policy

Equivalent behavior should preserve a deterministic replay strategy for surfaces that would otherwise depend on provider variability.

That means:

- stable unit and integration tests should prefer fixtures or replay when remote inference is not the thing being verified
- real-provider parity tests should be reserved for cases where output shape or provider wiring is the subject of the test
- golden transcripts should capture command-level envelopes and state transitions, not private source code or secret-bearing payloads
- fixture refresh must be explicit and reviewable rather than happening silently in ordinary test runs

## Divergence logging rule

Equivalent behavior should preserve a written divergence log whenever the rebuild is still behind the source client.

Each divergence entry should include:

- the exact command or workflow that differs
- whether the difference is cosmetic, operational, or blocking
- whether the issue lives in docs coverage, command routing, runtime logic, provider wiring, persistence, or UI
- what evidence proved the mismatch
- what milestone is expected to remove it

Unlogged divergence is reconstruction debt that will be rediscovered repeatedly.

## Milestone acceptance bundle

Before squashing a parity milestone into `main`, the bundle should include at least:

- a green automated test run for the affected rewrite repository
- manual comparison notes for the changed command surfaces
- any updated Context Tree leaves required to explain the new behavior
- an explicit list of remaining parity gaps, or an explicit statement that no known user-visible gaps remain for the accepted environment

If a milestone changes only internal structure and not user-visible behavior, the comparison bundle may be smaller, but the author should still say why no broader parity rerun was needed.

## Failure modes

- **paper parity**: the tree says a surface exists, but there is no automated or runtime evidence that the rebuild actually behaves that way
- **stdout-only verification**: command text matches, but config files, session state, plugin indexes, or MCP scopes drift from source behavior
- **partial rerun blindness**: a new milestone re-tests only the changed command and misses regressions in adjacent root-entry or persistence behavior
- **provider ambiguity**: parity claims are made without saying which auth/provider posture was used, so others cannot reproduce the result
- **hidden divergence**: known mismatches are left out of milestone notes, making later agents assume the rebuild is farther along than it is
- **non-deterministic acceptance**: tests depend on live inference or mutable remote state without replay or controlled comparison, so parity status changes between runs
