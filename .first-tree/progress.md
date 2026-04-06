# Context Tree Migration — legacy installed-skill tree -> dedicated tree metadata

## Tree Metadata
- [x] Review any repo docs, hooks, or automation that still assume the dedicated tree repo keeps local `.agents/skills/first-tree/` or `.claude/skills/first-tree/` copies
- [x] Replace any stale `context-tree` CLI command references in repo-specific docs, scripts, workflows, or agent config with `first-tree`

## Agent Instructions
- [x] Compare the framework section in `AGENTS.md` with the current `first-tree` template and update the text between the markers if needed
- [x] Compare the framework section in `CLAUDE.md` with the current `first-tree` template and update the text between the markers if needed

## Verification
- [x] `.first-tree/VERSION` reads `0.1.1`
- [x] `first-tree verify` passes

---

**Important:** As you complete each task, check it off in `.first-tree/progress.md` by changing `- [ ]` to `- [x]`. Run `first-tree verify` when done — it will fail if any items remain unchecked.
