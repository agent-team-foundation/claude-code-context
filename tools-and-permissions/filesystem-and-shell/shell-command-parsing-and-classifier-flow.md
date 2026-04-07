---
title: "Shell Command Parsing and Classifier Flow"
owners: []
soft_links: [/tools-and-permissions/filesystem-and-shell/shell-rule-grammar-and-matching.md, /tools-and-permissions/filesystem-and-shell/path-and-filesystem-safety.md, /tools-and-permissions/permissions/permission-decision-pipeline.md, /ui-and-experience/dialogs-and-approvals/permission-prompt-shell-and-worker-states.md, /collaboration-and-agents/teammate-mailbox-and-permission-bridge.md]
---

# Shell Command Parsing and Classifier Flow

Shell approval in Claude Code is not driven by raw command strings alone. The runtime first tries to derive a trustworthy shell structure, then uses that structure to decide whether rules, path checks, classifier shortcuts, or human approval are even legal to apply.

## Scope boundary

This leaf covers:

- shell-command parsing before permission decisions
- the fail-closed boundary between trustworthy decomposition and "ask the user"
- how parsed shell structure feeds rule matching, path extraction, and suggestion generation
- the speculative Bash classifier path that can auto-approve some interactive asks before a full dialog is needed

It intentionally does not re-document:

- stored shell-rule grammar already covered in [shell-rule-grammar-and-matching.md](shell-rule-grammar-and-matching.md)
- shell execution and task backgrounding already covered in [shell-execution-and-backgrounding.md](shell-execution-and-backgrounding.md)
- detailed path policy order already covered in [path-and-filesystem-safety.md](path-and-filesystem-safety.md)

## Parsing is a safety gate, not a UI convenience

Equivalent behavior should preserve a staged shell-analysis boundary before ordinary allow or ask logic proceeds:

- the runtime first attempts to derive trustworthy simple-command structure, not just a best-effort token split
- the parse outcome must distinguish:
  - clean simple-command decomposition
  - parse unavailable fallback
  - parser-aborted or resource-limited failure that still counts as unsafe for structural trust
  - too-complex or unsupported structure that must stay interactive
- unsupported syntax, parser differentials, hidden substitutions, or dynamic control-flow constructs must fail closed into `ask`, not be approximated into a potentially unsafe argv

The important invariant is that rule matching and auto-approval only operate on shell structure the runtime is willing to trust.

## Bash uses a fail-closed AST-backed primary path

Equivalent behavior should preserve Bash analysis that can return, per simple command:

- resolved argv-like command tokens
- leading environment assignments
- redirect metadata
- original source spans for display and downstream validation

That primary path should also preserve these safety properties:

- only an explicit allowlist of understood node and argument shapes is trusted
- unknown or unsupported node types become "too complex" rather than partially interpreted
- dangerous dynamic constructs such as substitutions, control flow, opaque expansions, or parser-differential edge cases do not produce trusted command structure
- semantic checks still run after a clean parse, so obviously dangerous shell-evaluation primitives or wrapper patterns can force `ask` even when tokenization succeeded

This path is not a sandbox. Its job is to decide whether downstream permission logic can safely reason about the command structure.

## Heredoc handling stays narrow and explicit

Equivalent behavior should preserve heredoc-specific trust boundaries:

- literal heredoc forms may keep narrow safe handling when the body is treated as inert text
- heredoc forms that still perform substitutions or hide runtime expansion must not be treated as statically trustworthy
- multiline shell content should therefore not be auto-approved merely because its leading command token looked familiar

This distinction matters because heredocs otherwise create an easy path to hide dynamic shell behavior behind a superficially ordinary command prefix.

## Legacy parsing remains a compatibility fallback

Equivalent behavior should preserve a fallback path for builds or environments where the richer Bash parser is unavailable or intentionally disabled:

- the fallback may still reject malformed syntax early
- the fallback may still honor stored exact, prefix, wildcard, deny, and ask rules
- the fallback must not claim the same structural authority as the AST-backed path
- optional shadow or telemetry comparison modes may observe divergence between legacy and AST parsing without changing the real decision path

A rebuild should not collapse "fallback exists" into "fallback is equally trustworthy."

## Parsed structure feeds more than one consumer

Equivalent behavior should preserve parsed shell structure being reused by several downstream consumers:

- shell-rule evaluation over compound commands and later subcommands
- command-aware path and redirection extraction
- hook-style matching and other permission-side inspection that need stable subcommand boundaries
- semantic deny checks for risky wrappers or shell-evaluation primitives
- compound-command permission suggestions that may need one rule per actionable subcommand
- shell UI affordances that need a stable editable prefix or concise command summary

This reuse is why shell parsing belongs in the reconstruction tree: it is a shared contract, not one tool-local helper.

## Compound-command suggestions come from backend analysis, not string heuristics

Equivalent behavior should preserve a deliberate split between backend truth and UI fallback:

- compound Bash commands should derive approval suggestions from backend subcommand analysis rather than by inventing one broad prefix from the whole raw string
- when exactly one reusable shell rule is appropriate, the dialog may seed that rule into an editable field
- when several subcommands each need their own rule, the dialog should preserve that multi-rule suggestion set instead of flattening it into a dead or over-broad prefix
- non-compound prompts may still seed an initial prefix from cheap synchronous heuristics and later refine it if richer parsing finishes before the user edits
- overly broad shell-launcher prefixes or brittle multiline exact rules must not be auto-suggested just because they are easy to derive

The backend is the authority for durable shell suggestions. UI heuristics are just a starting point when no stronger analysis has landed yet.

## Speculative Bash classifier is a pre-dialog shortcut, not the whole permission model

Equivalent behavior should preserve a classifier-backed path for some Bash asks:

- only eligible interactive Bash asks should carry pending classifier work
- classifier execution should race in the background against hooks, bridge callbacks, and direct user action rather than blocking the whole permission pipeline up front
- a short grace window should ignore accidental immediate keypresses before treating the user as having taken over the dialog
- once the user meaningfully interacts, the auto-approval attempt must stop trying to win the race
- successful classifier approval may briefly transition the dialog into an auto-approved state before removing it, so the user can understand why the request disappeared
- if the classifier does not win, the request should simply continue as an ordinary shell approval

This classifier path is an optimization on top of the ask flow. It is not a replacement for ordinary shell approval logic.

## Build and shell asymmetries are deliberate

Equivalent behavior should preserve several important asymmetries:

- some builds compile out the Bash classifier path entirely and fall back directly to ordinary ask behavior
- PowerShell uses its own parser and cmdlet-aware permission logic rather than inheriting Bash-specific AST and classifier behavior
- worker, headless, and no-prompt contexts cannot depend on local shell UI even when the same underlying parse or suggestion logic exists

A faithful rebuild should therefore avoid flattening all shell tools into one parser or one auto-approval policy.

## Read-only classification is downstream of trusted decomposition

Equivalent behavior should preserve shell read-only classification as a prepared semantic view, not a raw string tag:

- overlap-safe read-only classification should depend on trusted command decomposition, not only on the first visible executable name
- cwd-changing, redirected-output, argument-forwarding, or repository-shaping constructs must be able to keep a command out of the read-only bucket even when the surface verb looks harmless
- the same classification can then be reused by concurrency gating, collapsed read/search rendering, and other execution-preparation behavior

This is another reason shell parsing is a cross-cutting contract rather than an isolated parser detail.

## Worker and leader approval paths reuse the same prechecks

Equivalent behavior should preserve:

- in-process worker Bash requests being able to auto-resolve through the same classifier shortcut before escalating to the leader
- unresolved requests carrying parser-informed descriptions and suggestions into leader-side approval rather than raw opaque command text alone
- resolve-once behavior across classifier, hooks, local interaction, and bridge responses so one shell request cannot be accepted or rejected twice

The bridge transports unresolved approval state. It does not create a second shell-permission engine.

## Failure modes

- **parse optimism**: unsupported shell constructs still get decomposed and matched against allow rules
- **compound flattening**: only the first visible subcommand is checked or suggested, so later risky stages slip through
- **fallback equivalence myth**: a degraded parser is treated as equally authoritative as the AST-backed path
- **classifier race leak**: auto-approval wins after the user or another channel already took ownership of the same request
- **build skew**: external or disabled-classifier builds still assume speculative approval will run and therefore leave shell asks in a broken waiting state
