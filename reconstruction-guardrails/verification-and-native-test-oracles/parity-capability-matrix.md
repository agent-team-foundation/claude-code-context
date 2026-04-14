---
title: "Parity Capability Matrix"
owners: [bingran-you]
soft_links:
  - /reconstruction-guardrails/rebuild-phasing.md
  - /reconstruction-guardrails/verification-and-acceptance-strategy.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/reconstruction-target-and-evidence-boundary.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-lane-coverage-map.md
  - /product-surface/NODE.md
  - /platform-services/NODE.md
  - /integrations/NODE.md
  - /collaboration-and-agents/NODE.md
  - /ui-and-experience/NODE.md
---

# Parity Capability Matrix

The tree already explains many Claude Code behaviors in prose. What it still needed was a reusable answer to a narrower execution question: **which capability families are blocking for parity, which are extension-level, and what evidence bar must each family clear before a rebuild can claim success?**

This matrix is that answer. It is not a file inventory and not a rewrite backlog by repository. It is a capability-first go/no-go frame for reconstruction and evaluation work.

## Scope boundary

This leaf covers:

- the capability bands a serious Claude Code rebuild must track
- the minimum evidence bar for each band
- the difference between "usable", "high-confidence parity", and "100% parity claim"

It intentionally does not re-document:

- detailed subsystem contracts already captured in domain leaves
- runner-specific implementation tasks for any one rewrite repository
- exact command scripts or fixture contents

## Status vocabulary

The matrix uses these tree-readiness labels:

- **contract-covered**: the tree already captures the behavior family well enough to guide implementation
- **partially executable**: the tree has useful acceptance guidance, but still lacks enough runnable or directly reusable verification assets to make the family cheap to prove
- **not yet executable**: the tree has broad prose or partial coverage, but still needs a tighter acceptance asset or parity bundle before it can act like a TCK for that family

## Capability bands

| Band | Capability family | Minimum accepted surface | Evidence minimum | Current tree state |
| --- | --- | --- | --- | --- |
| `P0` | Root startup and interactive shell | trusted workspace entry, persistent REPL shell, prompt loop, basic progress/error feedback | tree contract + automated shell coverage + real CLI comparison | `contract-covered`, `partially executable` |
| `P0` | Headless and structured I/O | `-p`, JSON output, stream-json init/events, schema output, mode gating | tree contract + deterministic protocol tests + real CLI comparison | `contract-covered`, `partially executable` |
| `P0` | Core tools and permission model | core read/edit/search/shell flows, allow/deny/ask semantics, end-to-end approval routing | tree contract + regression/integration lanes + at least one approval-focused e2e harness | `contract-covered`, `partially executable` |
| `P0` | Session persistence, resume, and compaction | session creation, directory-scoped continuation, resume, fork, compaction, rehydration | tree contract + persistence-aware tests + real CLI comparison | `contract-covered`, `partially executable` |
| `P0` | Auth, provider routing, trust, and settings posture | workspace trust, provider-specific auth, config layering, policy-sensitive capability hydration | tree contract + integration coverage + named-provider runtime comparison | `contract-covered`, `partially executable` |
| `P1` | Skills, MCP, and plugins | skill loading, command projection, MCP server lifecycle, plugin management, trust-sensitive runtime effects | tree contract + integration coverage + command-level runtime comparison | `contract-covered`, `partially executable` |
| `P1` | Agents, tasks, and background work | built-in agent surfaces, local worker lifecycle, task visibility, steering, verification-agent semantics | tree contract + lifecycle tests + interactive runtime comparison | `contract-covered`, `not yet executable` |
| `P1` | Maintenance and operational surfaces | `doctor`, install, update, token/setup, diagnostics, state round-trip | tree contract + command-level comparison + state-path verification | `contract-covered`, `partially executable` |
| `P2` | Remote and multi-surface execution | `ssh`, direct connect, bridge/remote-control, reconnect, transport-sensitive permission routing | tree contract + transport e2e harnesses + environment-matched runtime comparison | `contract-covered`, `not yet executable` |
| `P2` | Specialized user surfaces | voice, companion, IDE/browser-adjacent surfaces, feature-gated differentiation | tree contract + targeted acceptance flows + version-aware runtime comparison | `contract-covered`, `not yet executable` |

## Go/no-go rules

Equivalent behavior should preserve these claim thresholds:

- **not ready for parity claims** if any `P0` family is missing or only partially described at the contract layer
- **usable daily local rewrite** only after all `P0` families have both implementation coverage and at least one real-client comparison bundle for the chosen target line
- **high-confidence parity milestone** only after all relevant `P0` and selected `P1` families for the milestone are backed by automated evidence and state-path checks
- **100% parity claim** only after all `P0`, `P1`, and target-relevant `P2` families are satisfied for one explicitly named reconstruction target

The last line matters. A rebuild cannot honestly claim "100%" while leaving remote, bridge, maintenance, or specialized surfaces out of scope unless the target itself excluded them.

## Reconstruction planning rule

Use the matrix together with [rebuild-phasing.md](../rebuild-phasing.md):

- `P0` maps to the minimum phases that turn the system into a real Claude Code-like product
- `P1` covers extension and daily-operations families that strongly affect practical parity
- `P2` covers the high-risk, transport-heavy, or feature-gated families where shallow demo parity is especially misleading

This keeps the tree from treating every missing leaf as equally urgent.

## Verification planning rule

Use the matrix together with [verification-and-acceptance-strategy.md](../verification-and-acceptance-strategy.md):

- the acceptance strategy says **how** to prove parity
- this matrix says **which capability families must clear that proof bar before a milestone can use a stronger label**

If a milestone note says "Claude Code parity" but does not identify which matrix rows are actually green, the claim is too vague.

## Why this is still not a full executable TCK

The matrix is a control surface, not the final runnable suite.

It deliberately does not pretend the tree already contains:

- every fixture corpus
- every golden transcript
- every provider-specific replay asset
- every transport harness needed for `P2`

What it does provide is the missing review frame for deciding whether a proposed rewrite milestone is:

- below parity bar
- locally convincing for a named capability band
- or strong enough to claim end-to-end equivalence

## Failure modes

- **coverage prose illusion**: many leaves exist, but nobody can say which parity-critical capability families are actually proven
- **milestone inflation**: a rewrite calls itself "Claude Code-compatible" after clearing only a subset of `P0` families
- **band collapse**: maintenance, remote, and specialized surfaces are treated as optional forever even when the target parity claim includes them
- **versionless completion**: all matrix rows are discussed abstractly, but no row is tied to one explicit reconstruction target and runtime posture
