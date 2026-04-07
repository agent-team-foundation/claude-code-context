# Context Tree Upgrade — v0.1.1 -> v0.2

## Tree Metadata
- [x] Replace any stale `context-tree` CLI command references in repo-specific docs, scripts, workflows, or agent config with `first-tree`

## Agent Instructions
- [x] Compare the framework section in `AGENTS.md` with the bundled template (run `first-tree init --help` to see what templates ship) and update the text between the markers if needed
- [x] Compare the framework section in `CLAUDE.md` with the bundled template and update the text between the markers if needed

## Verification
- [x] `.first-tree/VERSION` reads `0.2`
- [x] `first-tree verify` passes

---

**Important:** As you complete each task, check it off in `.first-tree/progress.md` by changing `- [ ]` to `- [x]`. Run `first-tree verify` when done — it will fail if any items remain unchecked.
