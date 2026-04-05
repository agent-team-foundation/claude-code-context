# Context Tree Upgrade — v0.1.0 -> v0.2.0

## Installed Skill
- [x] Review local customizations under `.agents/skills/first-tree/` and `.claude/skills/first-tree/` and reapply them if needed
- [x] Re-copy any workflow updates you want from `.agents/skills/first-tree/assets/framework/workflows/` into `.github/workflows/`
- [x] Re-check any local agent setup that references `.claude/skills/first-tree/assets/framework/examples/` or `.claude/skills/first-tree/assets/framework/helpers/`
- [x] Re-check any repo scripts or workflow files that reference `.agents/skills/first-tree/assets/framework/`

## Agent Instructions
- [x] Compare the framework section in `AGENTS.md` with `.agents/skills/first-tree/assets/framework/templates/agents.md.template` and update the content between the markers if needed

## Verification
- [x] `.agents/skills/first-tree/assets/framework/VERSION` reads `0.2.0`
- [x] `context-tree verify` passes

---

**Important:** As you complete each task, check it off in `.agents/skills/first-tree/progress.md` by changing `- [ ]` to `- [x]`. Run `context-tree verify` when done — it will fail if any items remain unchecked.
