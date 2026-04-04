---
title: "Workspace Trust Dialog and Persistence"
owners: []
soft_links: [/platform-services/trust-and-capability-hydration.md, /platform-services/auth-config-and-policy.md, /platform-services/bootstrap-and-service-failures.md, /collaboration-and-agents/remote-and-bridge-flows.md, /integrations/plugins/plugin-management-and-marketplace-flows.md, /tools-and-permissions/permission-model.md]
---

# Workspace Trust Dialog and Persistence

Claude Code treats workspace trust as a startup contract with its own dialog, storage model, and inheritance rules. Reconstructing only the post-trust hydration path is not enough: the product also decides when trust must be re-asked, what counts as repo-controlled risk before trust, and when a session is allowed to treat the current directory as already trusted.

## Scope boundary

This leaf covers:

- when interactive startup decides to show or skip the trust dialog
- which project-scoped risk signals are inspected before trust is granted
- how acceptance, decline, cancellation, and session-only trust behave
- how trust is persisted, inherited, and re-checked for the current directory or an arbitrary path

It intentionally does not re-document:

- the post-trust startup hydration order already captured in [trust-and-capability-hydration.md](trust-and-capability-hydration.md)
- detailed tool-permission prompts or managed-settings security prompts, which remain separate approval layers

## Interactive startup gate

Equivalent behavior should preserve:

- interactive startup always treating workspace trust as a separate gate from permission mode
- bypass-style permission modes not suppressing workspace trust for the interactive REPL path
- non-interactive startup paths such as `--print` never entering the interactive trust-dialog flow and instead treating trust as implicit
- the trust dialog running before the REPL mounts, before background plugin installation begins, and before assistant-mode or project-scoped helper execution is allowed to activate
- the startup path short-circuiting the TrustDialog render entirely when the current directory already resolves trusted
- declining the trust decision ending startup rather than continuing in a reduced interactive mode

## What counts as pre-trust risk

Before the user accepts trust, the product gathers repo-controlled signals that indicate the workspace could execute code or redirect sensitive behavior.

Equivalent behavior should preserve:

- project-scoped MCP server definitions being treated as a trust-relevant signal
- hooks configured in `.claude/settings.json` or `.claude/settings.local.json` being treated as trust-relevant because they can execute commands
- allow rules for the Bash tool in project or local permission rules being treated as trust-relevant
- deprecated slash-command prompts loaded from project or local settings being treated as trust-relevant when they are allowed to invoke Bash
- skill- or plugin-backed prompt commands being treated as trust-relevant when they come from project-controlled sources and are allowed to invoke Bash
- project or local `apiKeyHelper`, AWS refresh or export helpers, GCP refresh helpers, and `otelHeadersHelper` being treated as trust-relevant because they can spawn commands
- project or local environment variables outside the safe allowlist being treated as trust-relevant
- user-owned, flag-owned, or policy-owned settings not being the primary trust-risk inputs for this dialog because they are not repository-controlled in the same way

## Dialog contract and interaction model

Equivalent behavior should preserve:

- the dialog showing the current working directory and warning that Claude Code will be able to read, edit, and execute files there
- the dialog presenting a simple binary decision: trust the folder or exit
- a security-guide link being available from the dialog
- Enter confirming, escape-like cancellation exiting, and keyboard exit shortcuts shutting the process down immediately rather than falling through into the REPL
- the dialog auto-resolving if trust becomes true before it finishes rendering
- analytics events recording whether the cwd is the home directory and which risk signals were present when the dialog was shown or accepted
- the current dialog copy staying generic; the inspected risk signals feed behavior and analytics, not a long inline list of suspicious files or commands

## Acceptance persistence model

Equivalent behavior should preserve:

- normal acceptance persisting `hasTrustDialogAccepted` in the global Claude config rather than writing into the repository itself
- persistence being keyed by the startup workspace root: canonical git root when inside a repository, otherwise the original startup cwd
- trust for the home directory not being persisted to disk
- accepting trust from the home directory setting only a session flag so trust-gated features work for that process without permanently trusting `~`
- the session-level trust flag being consulted before disk-backed trust so home-directory acceptance can unlock the rest of startup immediately
- a positive trust result being safely latched in memory for the rest of the session, while false results are re-computed so a mid-session acceptance is picked up without restart

## Inheritance and lookup rules

Equivalent behavior should preserve:

- persisted trust applying to child directories, not only the exact directory that triggered the prompt
- trust checks walking parent directories until filesystem root, so trusting an ancestor covers nested workspaces
- git-repository persistence effectively trusting the whole repository, because acceptance in any subdirectory writes to the repo root key
- the current-cwd trust check consulting both the memoized workspace root entry and a parent walk from the live cwd
- arbitrary-path checks using a separate ancestor walk over persisted trust only, without consulting the session-only home-directory flag

## Special modes and downstream enforcement

Equivalent behavior should preserve:

- bridge and headless remote-control paths refusing to start in an untrusted directory because they bypass the interactive dialog path
- assistant-mode activation refusing to fully enable from an untrusted directory and instructing the user to accept trust first
- some standalone maintenance or inspection commands intentionally skipping the interactive dialog and instead warning in their command help that they should only be run in trusted directories
- system-context prefetch, project-scoped auth helpers, hook execution, and plugin startup checks each defending themselves against pre-trust execution even if earlier startup code already parsed the relevant settings
- full project-scoped environment variables being applied only after trust is accepted in interactive mode, while non-interactive mode may apply them immediately because trust is implicit there

## Failure modes

- **permission-mode confusion**: permissive execution settings suppress the trust dialog even though trust is supposed to be a separate boundary
- **repo-root drift**: trust is stored against the current subdirectory instead of the repository root, causing sibling directories to re-prompt unexpectedly
- **home-dir overtrust**: accepting trust from `~` is persisted to disk and permanently trusts the entire home directory
- **false-result caching**: a pre-trust false result is memoized too aggressively, so accepting trust mid-session does not unlock trust-gated features
- **risk-signal blind spots**: project-provided Bash-capable prompts or helper commands are omitted from the pre-trust risk model
- **bridge bypass**: a headless or bridge path starts executing project-controlled behavior without first requiring previously persisted trust
