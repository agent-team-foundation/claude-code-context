---
title: "GitHub App and Actions Setup Flow"
owners: []
soft_links: [/product-surface/command-surface.md, /platform-services/auth-config-and-policy.md, /platform-services/auth-login-logout-and-token-lifecycle.md, /integrations/clients/remote-setup-and-companion-bootstrap.md]
---

# GitHub App and Actions Setup Flow

Claude Code treats GitHub automation setup as an interactive install wizard, not a blind one-shot mutation. A faithful rebuild needs the whole chain: verify GitHub CLI prerequisites, choose or normalize the target repository, guide browser-based GitHub App installation, decide whether workflow files should be created or skipped, source credentials from either a local API key or a generated OAuth token, and finish by handing the user to a browser-based compare or PR page.

## Scope boundary

This leaf covers:

- how `/install-github-app` sequences CLI checks, repository selection, app installation, workflow creation or skipping, secret provisioning, and final PR handoff
- how GitHub CLI auth, token scopes, current-repo discovery, existing workflow files, and existing secrets change the wizard path
- how GitHub workflow files and repository secrets are created or updated through `gh`
- how GitHub Actions OAuth token creation differs from ordinary Claude login replacement
- how success, warning, error, dismissal, and tip-suppression behavior close the loop

It intentionally does not re-document:

- generic command registration and slash-command composition already captured in [command-surface.md](../product-surface/command-surface.md)
- broader auth layering and policy precedence already captured in [auth-config-and-policy.md](../platform-services/auth-config-and-policy.md)
- the general login and OAuth transport contract beyond this setup-specific token path already captured in [auth-login-logout-and-token-lifecycle.md](../platform-services/auth-login-logout-and-token-lifecycle.md)
- the separate web bootstrap flow that imports an existing local GitHub credential into another client surface already captured in [remote-setup-and-companion-bootstrap.md](clients/remote-setup-and-companion-bootstrap.md)

## Preflight checks separate recoverable warnings from hard blockers

Equivalent behavior should preserve:

- the wizard starting with a GitHub CLI presence check and a GitHub auth check before any repository mutation or browser handoff
- a missing `gh` install or missing GitHub login becoming a warning that users may continue past, rather than an immediate hard stop
- an authenticated `gh` session being inspected for required repository-management and workflow-management scopes, with missing scopes becoming a terminal error instead of a warning because later writes would be guaranteed to fail
- the scope failure path telling users to refresh GitHub CLI permissions rather than pretending setup can still succeed
- current repository detection running after preflight so the wizard can default to the active repo when possible instead of forcing manual entry every time
- the setup wizard using a richer GitHub auth probe than the lighter startup telemetry helper, because this flow needs scope detail while the generic helper only needs install-or-auth state

## Repository selection and existing repo state decide the mutation path

Equivalent behavior should preserve:

- repository input accepting either `owner/repo` shorthand or a full GitHub URL, then normalizing successful URL input down to the canonical repo slug
- malformed GitHub URLs or slug-less input becoming recoverable warnings with corrective guidance instead of crashing the flow
- repository permission checks looking for admin-capable access on the target repo and warning when the repo is missing, inaccessible, or probably lacks the permissions needed to install apps and manage secrets
- the active repo toggle only changing which repo slug is submitted to setup, not rewriting any local git state
- existing workflow detection probing for the canonical Claude workflow path before workflow creation starts
- the "existing workflow" branch keying off the primary Claude workflow path only, rather than treating every related workflow file as proof that setup already ran
- an existing workflow forcing an explicit branch in the wizard: update the workflow file, skip workflow changes and configure secrets only, or exit without further mutation
- the workflow-selection step requiring at least one built-in workflow and defaulting to the assistant and review variants together

## Secret sourcing supports local keys, custom names, and setup-only OAuth tokens

Equivalent behavior should preserve:

- the wizard preferring a locally available Claude API key when one already exists, so some users can skip manual credential entry entirely
- secret existence checks specifically looking for the default GitHub Actions secret name and, when found, letting the user either reuse that secret or choose a new secret name
- custom secret names being constrained to alphanumeric characters and underscores so later workflow templating remains valid
- the credential source menu supporting three conceptual paths: reuse an existing local key, paste a new key, or generate a long-lived OAuth token when Anthropic auth supports that mode
- the OAuth path opening a browser-based login flow, waiting for an automatic callback first, then exposing a manual paste path after a short delay if the browser handoff does not complete automatically
- manual OAuth recovery requiring both an authorization code and its paired state value, so pasted partial values are rejected rather than being misinterpreted
- OAuth retry staying inside the wizard instead of forcing a full command restart
- GitHub Actions OAuth tokens being treated as inference-only setup credentials, saved without performing the destructive logout or account-replacement behavior used by full login flows
- the OAuth path switching both the secret name and downstream workflow parameterization so generated tokens are not mistaken for ordinary API keys

## GitHub mutations are branch-based and browser-finished

Equivalent behavior should preserve:

- setup validating repository existence, default branch name, and default-branch head SHA before it attempts branch creation, file writes, or secret updates
- workflow-creating flows making a fresh branch from the default branch instead of writing workflow files directly onto the default branch
- workflow creation supporting both the assistant workflow and the review workflow, with one or both files written according to the multiselect result
- workflow file creation using repository-content APIs through `gh`, updating an existing file only when its current blob identity is known, and surfacing a dedicated conflict error when a stale or competing workflow file blocks the write
- workflow content being templated with the chosen secret contract so default API-key secrets, custom secret names, and OAuth-token secrets all wire into the correct workflow input
- secret creation or update running through GitHub Actions secrets management and being skipped entirely when the user explicitly chose to keep using an already-present secret
- the skip-workflow path avoiding branch creation and PR handoff while still allowing secret configuration to complete
- the non-skip path finishing by opening a browser compare or PR page with prefilled metadata instead of creating or merging the PR directly from the terminal

## Outcomes, counters, and lighter browser installs stay explicit

Equivalent behavior should preserve:

- warning screens aggregating all currently known issues, showing concrete remediation steps, and still allowing an explicit continue-anyway path
- success output differing between "workflow created" and "secret only" outcomes so users know whether a PR still needs to be merged
- error output carrying both a high-level reason and setup guidance, with manual documentation offered as the fallback path for every hard failure
- dismissing success or failure returning a summarized completion message back to the command caller rather than silently exiting
- successful GitHub Actions setup incrementing a persisted install counter so first-run tips for `/install-github-app` stop resurfacing once the user has already completed setup
- simpler browser-backed install commands reusing the same broad pattern: record that the user attempted setup, open the external marketplace or install page, and fall back to printing the destination when browser launch fails
- the lightweight Slack installer following that degenerate pattern, with its own persisted counter used to suppress future `/install-slack-app` tips once the user has already tried the flow

## Failure modes

- **scope false-positive**: the wizard treats a GitHub CLI session as sufficient even though repository or workflow scopes are missing, so setup advances into guaranteed write failures
- **repo normalization drift**: URL parsing or current-repo inference produces the wrong repo slug and the app, secrets, or workflows are installed against the wrong repository
- **warning hard-stop confusion**: recoverable issues such as missing `gh` or missing admin access are treated as fatal when the real product allows users to continue manually
- **workflow clobbering**: existing Claude workflow files are overwritten without the explicit update-or-skip decision point or without checking the current blob identity
- **review-only blind spot**: rebuilds treat any related workflow as "already installed" instead of matching the product's narrower primary-workflow check, changing when users see the update-or-skip branch
- **secret contract mismatch**: custom secret names or OAuth-token secrets are written, but workflow templating still points at the default API-key secret contract
- **logout regression**: the GitHub Actions OAuth path reuses full-login persistence logic and accidentally replaces or destroys the user's current Claude auth session
- **secret-only branch leak**: the skip-workflow path still creates a branch or compare page even though no workflow file changed
- **browser handoff dead-end**: compare-page or install-page launch failure leaves no printable fallback or next-step guidance
- **tip spam**: setup-attempt counters are not persisted, so install tips for GitHub or Slack keep resurfacing across later sessions
