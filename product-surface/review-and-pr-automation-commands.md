---
title: "Review and PR Automation Commands"
owners: []
soft_links: [/product-surface/command-dispatch-and-composition.md, /runtime-orchestration/automation/review-path.md, /runtime-orchestration/sessions/remote-agent-restoration-and-polling.md, /integrations/plugins/plugin-runtime-contract.md, /tools-and-permissions/permissions/permission-model.md, /platform-services/auth-config-and-policy.md]
---

# Review and PR Automation Commands

Claude Code's review and pull-request commands are a family of distinct contracts layered on top of the shared slash-command surface. Some stay entirely local, some launch a remote deep-review job, some wrap a tightly bounded Git/PR automation turn, some are temporary built-in bridges to plugin-owned behavior, and one visible name is intentionally kept inert. Rebuilding this surface faithfully means preserving those differences instead of collapsing everything into one generic "review PR" feature.

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

## `/review` stays local and is defined by a prompt contract, not a bespoke review runtime

Equivalent behavior should preserve:

- `/review` being a prompt expansion that re-enters the ordinary local turn loop rather than a separate review engine
- any raw argument string being treated as a review-target hint instead of being rigidly normalized up front by command code
- a missing explicit target causing the generated instructions to ask the assistant to discover likely review candidates first rather than hard-failing immediately
- a provided target causing the generated instructions to steer the assistant toward pull-request metadata lookup and diff retrieval through the repository's hosting tooling
- the resulting review staying focused on concise but thorough findings about correctness, conventions, performance, test coverage, and security instead of mutating Git state
- `/review` remaining the ordinary local review entry point even when `/ultrareview` exists, so rebuilds do not silently route routine review requests into the remote cloud path

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

## Remote ultrareview launch preserves hosted-PR and local-branch variants

Equivalent behavior should preserve:

- `/ultrareview` remaining the only remote deep-review entry point; rebuilds should not make `/review` and `/ultrareview` interchangeable
- remote-review preflight checking general remote-agent eligibility but not failing merely because a named user-configured remote environment is missing when a dedicated review environment can still be synthesized
- other remote precondition failures being converted into user-visible recovery text rather than buried in logs or silently downgraded into local review
- a hosted-pull-request variant that reviews the hosted PR state rather than the caller's current local working tree
- the hosted-pull-request variant requiring a detectable supported repository host and carrying repository identity plus PR identity into the remote job
- a branch-or-working-tree variant that computes its comparison point from the repo's default-branch fork point, refuses to launch when that comparison base cannot be established, and refuses to launch when there is no diff worth reviewing
- the branch-or-working-tree variant being able to package local unpublished branch state so the remote review can inspect work that does not yet exist as a hosted PR
- the packaging path failing early with an explicit repo-too-large or packaging-unavailable message instead of launching a doomed remote job
- remote review configuration values being sourced from feature configuration but constrained through safe local bounds, so malformed or stale config cannot stretch the remote job past the local supervision envelope
- a successful launch registering a remote review task locally and returning a concise acknowledgement with tracking details and any applicable billing note, leaving the assistant to briefly acknowledge the launch without restating information already shown in the UI
- unrecoverable remote launch failure staying explicit instead of pretending a remote session exists or silently reinterpreting the request as a local review

## `/commit-push-pr` snapshots repo state and constrains the model to one bounded automation turn

Equivalent behavior should preserve:

- `/commit-push-pr` acting as a prompt command that precomputes repository context rather than directly performing Git or PR mutations in command code
- the prompt inlining fresh repository snapshots before the model starts planning, including working-tree state, current branch identity, the full diff against the default branch, and whether a PR already exists for the active branch
- default-branch selection being dynamic rather than hardcoded, so the prompt compares and branches against the repo's actual base branch
- the command installing a narrow temporary tool allowance only for this invocation, covering the Git, hosting, search, and optional notification capabilities needed for this flow rather than broadly widening session permissions
- the generated instructions forbidding destructive Git operations, protected-branch force pushes, Git-config mutation, hook-skipping flags, and accidental secret commits
- the model being told to inspect the entire diff against the default branch, not just the last commit, before naming the commit or PR
- being on the default branch forcing creation of a new working branch with a user-derived prefix, while already being on a feature branch preserves that branch as the PR branch
- commit and PR-body construction using a single multi-line-safe emission strategy so long summaries and attribution text survive quoting intact
- the flow always pushing to origin before PR creation or PR update
- an existing PR for the branch being updated in place while a missing PR causes a new one to be created
- PR titles being kept short while summary, test plan, and optional changelog or attribution detail live in the body
- the model being instructed to complete branch creation, commit, push, and PR create-or-edit in one assistant turn instead of pausing after each step for extra confirmation
- user-supplied arguments being appended as additional instructions to the prompt rather than replacing the built-in automation contract

## Attribution, public-repo redaction mode, and optional follow-up notifications reshape the `/commit-push-pr` prompt

Equivalent behavior should preserve:

- commit and PR attribution text being derived dynamically rather than hardcoded, with remote sessions using a resumable session URL and local sessions using configured or default attribution text
- enhanced PR attribution being able to include session-derived contribution metadata while sanitizing or suppressing fields that should not appear on public repositories
- user settings being able to override or suppress attribution without changing the rest of the command contract
- an internal public-repo redaction mode injecting stricter wording and removing internal-only embellishments such as default reviewer additions, attribution trailers, or internal follow-up guidance
- the default public-facing path still being able to request a configured automated reviewer on PR creation or update unless policy or redaction mode strips that behavior
- the optional follow-up notification step staying conditional on project guidance plus discovery of a suitable outbound messaging tool
- the follow-up step asking the user for confirmation before posting the PR URL rather than sending automatically

## Plugin-migrated helpers keep temporary built-in fallbacks while the marketplace path is gated

Equivalent behavior should preserve:

- `/pr-comments` and `/security-review` presenting as built-in prompt commands even though their long-term home is a plugin
- internal marketplace-enabled users being told only how to install and invoke the plugin variant, without the built-in command attempting to execute the legacy behavior
- external or marketplace-blocked users still receiving a built-in fallback prompt so the command remains usable before the plugin marketplace is public
- `/pr-comments` gathering both PR-level discussion and line-level review comments, with optional source-context fetches for referenced files, and returning only a threaded formatted comment transcript or an explicit "no comments" result
- `/security-review` narrowing the available evidence-gathering tools, preloading branch and diff context before model execution, and asking for a high-confidence security-only review instead of a general code-quality review
- the security-review fallback explicitly biasing toward high-signal findings, excluding broad classes of low-value or non-exploitable issues, and requiring an extra false-positive filtering pass before final output

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
- **attribution leak**: public-repo redaction mode or user attribution settings are ignored, exposing internal wording or unwanted attribution in public PRs or notifications
- **plugin-double path**: migrated commands both advertise plugin installation and still run the fallback path in the same build context
- **stub resurrection**: `autofix-pr` becomes visible or active even though the current product intentionally ships only a hidden disabled stub
