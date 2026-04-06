# Context Tree Upgrade — v0.2.2 -> v0.1.1

## Installed Skill
- [x] Review local customizations under `.agents/skills/first-tree/` and `.claude/skills/first-tree/` and reapply them if needed
- [x] Re-copy any workflow updates you want from `.agents/skills/first-tree/assets/framework/workflows/` into `.github/workflows/`
- [x] Re-check any local agent setup that references `.claude/skills/first-tree/assets/framework/examples/` or `.claude/skills/first-tree/assets/framework/helpers/`
- [x] Re-check any repo scripts or workflow files that reference `.agents/skills/first-tree/assets/framework/`
- [x] Replace any stale `context-tree` CLI command references in repo-specific docs, scripts, workflows, or agent config with `first-tree`

## Agent Instructions
- [x] Compare the framework section in `AGENTS.md` with `.agents/skills/first-tree/assets/framework/templates/agents.md.template` and update the content between the markers if needed
- [x] Compare the framework section in `CLAUDE.md` with `.agents/skills/first-tree/assets/framework/templates/claude.md.template` and update the content between the markers if needed

## Verification
- [x] `.agents/skills/first-tree/assets/framework/VERSION` reads `0.1.1`
- [x] `first-tree verify` passes

---

**Important:** As you complete each task, check it off in `.agents/skills/first-tree/progress.md` by changing `- [ ]` to `- [x]`. Run `first-tree verify` when done — it will fail if any items remain unchecked.
