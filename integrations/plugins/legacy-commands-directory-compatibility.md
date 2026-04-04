---
title: "Legacy Commands Directory Compatibility"
owners: []
soft_links: [/integrations/plugins/skill-loading-contract.md, /product-surface/command-runtime-matrix.md, /tools-and-permissions/tool-families.md]
---

# Legacy Commands Directory Compatibility

Claude Code's prompt-extension system is centered on `/skills`, but `.claude/commands` still survives as a compatibility source. It is not a second-class parser bolted on afterward. It rides the same markdown discovery machinery, then gets translated into deprecated prompt commands with a few explicit behavioral differences.

## Scope boundary

This leaf covers:

- how legacy `.claude/commands` content is discovered
- the accepted legacy file shapes and namespace rules
- how legacy entries are normalized into prompt commands
- the places where legacy commands intentionally differ from modern `/skills`
- bare-mode, additional-directory, and deduplication behavior for compatibility loading

It intentionally does not re-document:

- the main skill loading model already captured in [skill-loading-contract.md](skill-loading-contract.md)
- general command visibility and remote-safe filtering already captured elsewhere in the command-surface leaves

## Discovery uses the same upward markdown loader

Equivalent behavior should preserve:

- `.claude/commands` discovery using the same markdown-directory loader family that walks current-project directories upward toward the stop boundary
- the same git-root stop behavior that prevents parent repositories from leaking commands into a child repo
- the same user, project, managed, and worktree-aware directory search posture that the markdown loader already applies to markdown config sources
- existing-directory filtering and worktree fallback behavior staying aligned with the normal markdown discovery path rather than inventing a commands-only search routine

The compatibility source should feel like an older shape on the same loading rail, not a totally separate plugin system.

## Two accepted legacy shapes

Equivalent behavior should preserve two accepted shapes inside `.claude/commands`:

- a single markdown file such as `foo.md`
- a directory shape such as `foo/SKILL.md`

When a directory contains `SKILL.md`, that file wins for the directory and the loader ignores sibling markdown files in the same directory for command creation purposes.

## Nested directories become `:` namespaces

Equivalent behavior should preserve:

- command names derived from relative path segments inside `.claude/commands`
- nested directories becoming `:` namespaces rather than slash-delimited names
- directory-form commands taking the name of the directory that contains `SKILL.md`
- single-file commands taking the basename of the markdown file

That keeps old command hierarchies addressable without adopting the newer skill-directory contract verbatim.

## Legacy entries load as deprecated prompt commands

Equivalent behavior should preserve:

- legacy `.claude/commands` entries loading as prompt commands rather than a new command type
- those commands being tagged as `commands_DEPRECATED`
- legacy entries using the same frontmatter parser and prompt-shell preparation logic as skills
- legacy command descriptions and model-visible listing behavior staying compatible with other prompt commands after normalization

The important contract is that legacy commands still enter the prompt-command ecosystem, but with a distinct provenance tag.

## Conditional path activation is intentionally disabled

Equivalent behavior should preserve:

- legacy `.claude/commands` entries inheriting skill-like frontmatter parsing
- their normalized `paths` field being forced to undefined even when frontmatter mentions conditional paths
- modern conditional path activation therefore remaining a `/skills` capability, not something revived through the deprecated commands directory

This protects compatibility without silently broadening what old command directories can do.

## `--bare` and `--add-dir` do not resurrect legacy commands

Equivalent behavior should preserve:

- `--bare` skipping all auto-discovered legacy `/commands` loading
- `--bare` still allowing explicitly added directories to contribute `.claude/skills`, subject to the normal policy locks
- `--add-dir` contributing only modern `/skills` directories, not legacy `/commands`
- skill-lock or plugin-only policy still blocking legacy `/commands` loading because those entries are still treated as skills for policy purposes

So explicit extra directories are a bridge into `/skills`, not a backdoor to keep the deprecated commands layout alive.

## Deduplication is file-identity-based, not name-based

Equivalent behavior should preserve:

- deduplication by canonical file identity such as realpath or equivalent resolved-file identity
- symlinked or duplicate parent-directory discoveries collapsing only when they resolve to the same underlying file
- no semantic deduplication by command name alone
- same-name commands from distinct files being allowed to coexist until later command ordering decides which one resolves first for a given lookup

This matters because the compatibility loader preserves discovery order and provenance, not just final display names.

## Failure modes

- **loader fork**: legacy commands start using a special discovery walk and drift away from the normal markdown search boundaries
- **shape regression**: either `foo.md` or `foo/SKILL.md` stops loading, breaking older repos that still use that layout
- **path creep**: legacy commands begin honoring conditional `paths` frontmatter and accidentally gain modern activation semantics
- **bare bypass**: `--bare` or `--add-dir` quietly re-enable deprecated `/commands` sources that were supposed to stay off
- **name-only dedupe**: one same-name legacy command incorrectly suppresses another distinct file and changes shadowing behavior
