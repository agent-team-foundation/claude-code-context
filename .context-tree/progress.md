# Context Tree Init

**Agent instructions:** Before starting work, analyze the full task list below and identify all information you need from the user. Ask the user for their code repositories or project directories so you can analyze the source yourself — derive project descriptions, domains, and members from the code instead of asking the user to describe them. Collect everything upfront using the **AskUserQuestion** tool with structured options — present selectable choices (with label and description) so the user can pick instead of typing free-form answers. You may batch up to 4 questions per AskUserQuestion call.

## Root Node
- [x] NODE.md has a placeholder title — replaced with the repository name `Claude Code Context`
- [x] NODE.md has placeholder owners — set owners to `bingran-you`
- [x] NODE.md has placeholder content — analyzed the provided Claude Code source snapshot and replaced placeholders with a full domain structure

## Agent Instructions
- [x] Added project-specific clean-room reconstruction instructions below the framework markers in AGENT.md

## Members
- [x] Added member nodes under `members/` for the tree owner and the context-building assistant

## Agent Integration
- [x] Configured Claude Code session-start integration via `.claude/settings.json`

## CI / Validation
- [x] Copied `.context-tree/workflows/validate.yml` to `.github/workflows/validate.yml`
- [x] PR review workflow intentionally skipped for now so the repo can stay secret-free and immediately usable; it can be enabled later with either supported provider.
  1. **OpenRouter** — use an OpenRouter API key
  2. **Claude API** — use a Claude API key directly
  3. **Skip** — do not set up PR reviews
If (1): copy `.context-tree/workflows/pr-review.yml` to `.github/workflows/pr-review.yml` as-is; the repo secret name is `OPENROUTER_API_KEY`. If (2): copy the workflow and replace the `env` block with `ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}`, remove the `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, and `ANTHROPIC_DEFAULT_SONNET_MODEL` lines; the repo secret name is `ANTHROPIC_API_KEY`. If (3): skip this and the next task.
- [x] API secret configuration skipped because PR review setup was intentionally deferred.
  1. **Set it now** — provide the key and the agent will run `gh secret set <SECRET_NAME> --body <KEY>`
  2. **I'll do it myself** — the agent will show manual instructions
If (1): ask the user to provide the key, then run `gh secret set` with the secret name from the previous step. If (2): tell the user to go to their repo → Settings → Secrets and variables → Actions → New repository secret, and create the secret with the name from the previous step. Skip this task if the user chose Skip in the previous step.
- [x] Copied `.context-tree/workflows/codeowners.yml` to `.github/workflows/codeowners.yml` to auto-generate CODEOWNERS from tree ownership on every PR.

## Populate Tree
- [x] Proceeded with full population based on the provided local Claude Code source directory.
- [x] Analyzed the codebase and created logical top-level domains and subdomains focused on capabilities, runtime contracts, integrations, and guardrails.
- [x] Populated the tree directly in this pass and established cross-domain soft links where they improve navigation.
- [x] Updated the root NODE.md to list every top-level domain and verified that placeholders were removed.

## Verification
After completing the tasks above, run `context-tree verify` to confirm:
- [x] `.context-tree/VERSION` exists
- [x] Root NODE.md has valid frontmatter (title, owners)
- [x] AGENT.md exists with framework markers
- [x] `context-tree verify` passes with no blocking errors once tree population and frontmatter fixes were completed
- [x] At least one member node exists

---

**Important:** As you complete each task, check it off in `.context-tree/progress.md` by changing `- [ ]` to `- [x]`. Run `context-tree verify` when done — it will fail if any items remain unchecked.
