---
title: "Review and PR Automation Commands"
owners: []
soft_links: [/product-surface/command-dispatch-and-composition.md, /runtime-orchestration/automation/review-path.md, /runtime-orchestration/sessions/remote-agent-restoration-and-polling.md, /integrations/plugins/plugin-runtime-contract.md, /tools-and-permissions/permissions/permission-model.md, /platform-services/auth-config-and-policy.md]
---

# Review and PR Automation Commands

Claude Code's review and pull-request commands are not one monolithic subsystem. They are a family of command contracts layered on top of the shared slash-command registry: some expand into plain prompts, some gate into a remote review task, some pre-execute shell snapshots before the model sees the prompt, some temporarily masquerade as built-ins while their real implementation lives in a plugin, and one command name is intentionally left as a hidden no-op stub. Rebuilding the surface faithfully means preserving those differences instead of collapsing everything into a generic "review PR" feature.

## Scope boundary

This leaf covers:

- the built-in local `/review` prompt contract for pull-request review
- the gated `/ultrareview` surface, including billing checks, launch dialog behavior, PR-versus-branch targeting, and remote review task handoff
- the `/commit-push-pr` contract that snapshots repo state, narrows tool scope, and instructs the model to branch, commit, push, and create or edit a PR in one turn
- the temporary built-in wrappers for `/pr-comments` and `/security-review` while those commands are in plugin migration
- the intentionally disabled `autofix-pr` stub behavior

It intentionally does not re-document:

- generic command discovery, aliasing, and registry composition already captured in [command-dispatch-and-composition.md](command-dispatch-and-composition.md)
- the shared local-versus-remote review lifecycle already captured in [review-path.md](../runtime-orchestration/automation/review-path.md)
- generic remote-task registration, restore, and polling behavior already captured in [remote-agent-restoration-and-polling.md](../runtime-orchestration/sessions/remote-agent-restoration-and-polling.md)
- the broader plugin runtime and marketplace loading model already captured in [plugin-runtime-contract.md](../integrations/plugins/plugin-runtime-contract.md)
- generic permission evaluation rules already captured in [permission-model.md](../tools-and-permissions/permissions/permission-model.md)

## `/review` stays local and is defined by a prompt contract, not a bespoke runtime

Equivalent behavior should preserve:

- `/review` being a plain prompt command rather than a JSX dialog or dedicated review engine
- the command passing any raw argument string through as the pull-request identifier hint instead of first validating or normalizing it in command code
- a missing pull-request number causing the generated prompt to tell the model to discover candidate PRs first rather than hard-failing in command code
- a provided pull-request number causing the generated prompt to steer the model toward PR metadata lookup and diff retrieval through `gh`
- the review contract remaining focused on concise but thorough analysis of correctness, project conventions, performance, test coverage, and security, instead of trying to mutate git state
- `/review` remaining the local-only review entry point even when `/ultrareview` exists, so rebuilds do not silently route ordinary review requests into the remote cloud path

## `/ultrareview` is a separately gated remote-review command with session-scoped billing consent

Equivalent behavior should preserve:

- `/ultrareview` appearing only when a feature-flag payload explicitly enables it, so ineligible users do not even see the command in the slash-command surface
- the visible command description making it clear that the run takes roughly minutes rather than seconds and executes in Claude Code on the web rather than purely in the local terminal
- team and enterprise subscribers bypassing free-review quota and extra-usage prompts entirely
- consumer-style plans checking review quota and billing utilization in parallel before launch instead of serializing those network calls
- missing quota data or transient utilization lookup failure defaulting to "allow launch" rather than blocking review on telemetry or billing-read outages
- remaining free reviews attaching a human-readable note to the launch result so the user knows which free review they are consuming
- exhausted free reviews branching into three distinct outcomes: hard stop when extra usage is disabled, hard stop when available balance is below the minimum threshold, or an explicit consent dialog when extra usage is available
- the extra-usage consent being remembered only for the current session and only after a non-aborted launch, so cancelling during launch does not silently pre-authorize later reviews
- the overage dialog supporting both explicit cancel and escape-to-abort behavior, with cancellation also aborting any in-flight remote launch attempt

## Remote ultrareview launch preserves GitHub-specific and branch-bundle variants

Equivalent behavior should preserve:

- `/ultrareview` remaining the only remote deep-review entry point; rebuilds should not make `/review` and `/ultrareview` interchangeable
- remote-review preflight checking general remote-agent eligibility but ignoring a missing named remote environment when the synthetic code-review environment can still be used
- other remote precondition failures being converted into user-visible recovery text rather than buried in logs or silently downgraded into local review
- a numeric argument selecting pull-request mode, which requires a detectable GitHub-hosted repository and targets the review at that PR's head ref instead of the local working tree
- pull-request mode packaging repository identity and PR number as remote environment inputs so the cloud-side review target is the hosted PR state
- non-numeric or empty arguments selecting branch mode, which computes the fork point against the default branch, refuses to launch when no merge base can be found, and refuses to launch when there are no changes against that fork point
- branch mode using a bundle-style transfer of the current branch state so local unpublished changes can be reviewed, while still failing early with a repo-too-large message if bundling cannot be created
- remote review configuration values being sourced from feature-config data but sanitized through bounded positive-integer fallbacks, so stale or malformed config cannot stretch the job past the local poller's safety envelope
- a successful launch registering a remote task as an ultrareview job and returning only a concise acknowledgement payload with the tracking URL and billing note, leaving the assistant to briefly acknowledge the launch without repeating already-visible details
- unrecoverable remote launch failure producing a system-level failure message instead of pretending a remote session exists or falling back into the local-review prompt path

## `/commit-push-pr` snapshots repo state and constrains the model to one bounded automation turn

Equivalent behavior should preserve:

- `/commit-push-pr` acting as a prompt command that precomputes repository context rather than directly performing git and GitHub mutations in command code
- the prompt inlining fresh shell snapshots of git status, diff against HEAD, current branch name, diff against the detected default branch, and any already-open PR for the current branch before the model starts planning
- default-branch selection being dynamic rather than hardcoded, so the prompt compares and branches against the repo's actual base branch
- the command installing a narrow allowlist of git, `gh`, search, and optional Slack messaging tools only for this command invocation instead of broadly widening shell permissions for the session
- the generated instructions forbidding destructive git operations, force pushes to protected default branches, git-config mutation, hook-skipping flags, interactive git flags, and accidental secret commits
- the model being told to inspect the entire diff against the default branch, not just the last commit, before naming the commit or PR
- being on the default branch forcing creation of a new working branch with a user-derived prefix, while already being on a feature branch preserves that branch as the PR branch
- commit creation using a single heredoc-style commit message block so multi-line messages and attribution text survive quoting intact
- the flow always pushing to origin before PR creation or PR update
- an existing PR for the branch being updated in place while a missing PR causes a new one to be created
- PR titles being kept short while summary, test plan, and optional changelog or attribution detail live in the body
- the model being instructed to complete branch creation, commit, push, and PR create-or-edit in one assistant turn instead of pausing after each step for extra confirmation
- user-supplied arguments being appended as additional instructions to the prompt rather than replacing the built-in automation contract

## Attribution, public-repo redaction mode, and Slack handoff change the `/commit-push-pr` prompt shape

Equivalent behavior should preserve:

- commit and PR attribution text being derived dynamically rather than hardcoded, with remote sessions using a resumable session URL and local sessions using configured or default attribution text
- enhanced PR attribution being able to include contribution statistics, prompt-count hints, model naming that is sanitized for external repos, and optional internal-only trailer lines when the build and repo class allow it
- user settings being able to override or suppress attribution without changing the rest of the command contract
- an internal public-repo redaction mode injecting strict instructions to avoid company-identifying language in commits or PRs while also removing reviewer defaults, changelog boilerplate, Slack follow-up, and attribution text
- the default public-facing path still requesting the configured automated reviewer on PR creation or update unless that redaction mode explicitly strips that behavior
- the optional Slack follow-up step staying conditional on two things: project guidance mentioning Slack routing, and discovery of an actual Slack send tool
- the Slack step asking the user for confirmation before posting the PR URL rather than sending automatically

## Plugin-migrated helpers keep temporary built-in fallbacks while the marketplace path is gated

Equivalent behavior should preserve:

- `/pr-comments` and `/security-review` presenting as built-in prompt commands even though their long-term home is a plugin
- internal marketplace-enabled users being told only how to install and invoke the plugin variant, without the built-in command attempting to execute the legacy behavior
- external or marketplace-blocked users still receiving a built-in fallback prompt so the command remains usable before the plugin marketplace is public
- `/pr-comments` using GitHub CLI and GitHub API calls to gather both PR-level issue comments and line-level review comments, with optional source fetches for referenced files, and returning only a threaded formatted comment transcript or an explicit "no comments" result
- `/security-review` using a markdown-frontmatter prompt contract that narrows the available tools, expands inline shell snapshots of branch status and diff context before model execution, and asks for a high-confidence security-only review instead of a general code-quality review
- the security-review fallback explicitly biasing toward high-signal findings, excluding a long list of low-value or non-exploitable issue classes, and requiring an additional false-positive filtering pass before final output

## `autofix-pr` is intentionally inert

Equivalent behavior should preserve:

- the command name remaining hidden and disabled by default
- rebuilds not inventing dormant autofix behavior merely because the command directory exists
- any future real implementation being treated as a separate feature addition rather than inferred from the current stub

## Failure modes

- **review-path collapse**: `/review` and `/ultrareview` are treated as interchangeable, erasing the product's local-versus-remote distinction
- **surface leak**: `/ultrareview` shows up for users whose feature flag should hide it entirely
- **billing-consent stickiness**: cancelling or aborting the overage dialog still marks the session as pre-approved for paid ultrareviews
- **remote-target drift**: PR mode reviews the local branch state or branch mode reviews the wrong merge base, changing what code is actually inspected
- **empty-review launch**: branch-mode ultrareview launches even though there is no diff against the fork point
- **automation overreach**: `/commit-push-pr` gets broad shell freedom or performs partial multi-turn actions instead of one tightly bounded automation turn
- **PR duplication**: the flow creates a second PR for a branch that already has one instead of editing the existing PR
- **attribution leak**: public-repo redaction mode or user attribution settings are ignored, exposing internal wording or unwanted attribution in public PRs
- **plugin-double path**: migrated commands both advertise plugin installation and still run the fallback path in the same build context
- **stub resurrection**: `autofix-pr` becomes visible or active even though the current product intentionally ships only a hidden disabled stub
