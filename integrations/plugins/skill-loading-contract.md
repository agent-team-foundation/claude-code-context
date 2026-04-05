---
title: "Skill Loading Contract"
owners: []
soft_links: [/integrations/plugins/plugin-and-skill-model.md, /tools-and-permissions/tool-families.md, /product-surface/command-execution-archetypes.md]
---

# Skill Loading Contract

Skills are a prompt-layer extension mechanism, but the runtime does not load them through one uniform path. Bundled skills, file-backed local skills, plugin skills, MCP-delivered skills, and dynamically discovered nested skills each arrive through different channels, then meet again inside the shared command registry. A faithful rebuild needs those channels and their ordering to stay intact, or user-visible slash resolution, SkillTool availability, and dynamic path-triggered skills will drift.

## Scope boundary

This leaf covers:

- startup discovery of bundled, file-backed, plugin, MCP, and dynamic nested skills
- policy and `--bare` rules that suppress or narrow discovery
- frontmatter fields that materially change invocation behavior
- late activation of conditional and dynamically discovered skills
- command-registry ordering and name-collision behavior for skills

It intentionally does not re-document:

- the broader conceptual difference between skills and plugins already covered in [plugin-and-skill-model.md](plugin-and-skill-model.md)
- model-facing and human-facing skill listing surfaces already covered in [skill-discovery-and-listing-surfaces.md](skill-discovery-and-listing-surfaces.md)
- feature-gated discovery-tool overlays and remote discovered-skill behavior already covered in [feature-gated-remote-skill-discovery-overlay.md](feature-gated-remote-skill-discovery-overlay.md)
- prompt-command and SkillTool execution paths already covered in [../../product-surface/prompt-command-and-skill-execution.md](../../product-surface/prompt-command-and-skill-execution.md)
- the feature-gated skill-improvement rewrite loop already covered in [feature-gated-project-skill-improvement-loop.md](feature-gated-project-skill-improvement-loop.md)

## The runtime tracks provenance and loading channel separately

Equivalent behavior should preserve:

- bundled skills registering outside the filesystem scan
- file-backed managed, user, project, and `--add-dir` skills all loading through the same `/skills` loader even though their provenance differs
- provenance staying attached as the source class:
  - managed policy settings
  - user settings
  - project settings
- loading channel staying distinct from provenance:
  - modern `/skills`
  - legacy `/commands`
  - plugin-delivered skills
  - bundled skills
  - MCP-delivered skills
- public reconstruction not inventing a separate managed-only skill format just because managed policy is one source class

## Startup discovery order is fixed and visible

Equivalent behavior should preserve:

- bundled skills being registered before command loading begins
- disk-backed startup discovery scanning, in order:
  - managed `.claude/skills`
  - user `~/.claude/skills`
  - project `.claude/skills` directories from cwd upward toward the repo boundary
  - explicit `--add-dir` roots by looking for `dir/.claude/skills`
  - legacy `/commands` discovery
- plugin skills being loaded through the plugin system rather than through the ordinary disk-backed skill scan
- MCP skills arriving through the MCP integration path instead of being treated like file-backed markdown
- project discovery stopping at the repo boundary rather than walking all the way to the filesystem root
- worktrees without a checked-out `.claude/<subdir>` being able to fall back to the canonical repo copy for those project-scoped markdown sources

## `--bare` and plugin-only policy narrow discovery but do not bypass policy

Equivalent behavior should preserve:

- `--bare` suppressing managed, user, and automatic project discovery
- `--bare` also suppressing legacy `/commands` discovery
- `--bare` still allowing only explicit `--add-dir` skill roots to load, and only if project settings are otherwise allowed
- plugin-only policy being able to lock the skill surface so user and project file-backed skills do not load
- that same plugin-only policy also blocking `--bare` from sneaking project skill roots back in
- bundled skills remaining separately registered even when file-backed discovery is narrowed

## Filesystem formats and naming rules are channel-specific

Equivalent behavior should preserve:

- modern `/skills` directories only accepting `skill-name/SKILL.md`
- standalone `.md` files being ignored inside `/skills`
- legacy `/commands` discovery remaining backward-compatible with both:
  - `dir/SKILL.md`
  - ordinary `.md` files
- nested legacy command directories becoming `:`-namespaced command names
- plugin skill names being namespaced from their plugin identity instead of sharing the raw local filename namespace
- MCP skills using `server:skill` style names, which are distinct from plain MCP prompts

## Frontmatter is shared, but invocation transforms are not trivial

Equivalent behavior should preserve:

- these shared frontmatter fields materially affecting runtime behavior:
  - description fallback from body text
  - `allowed-tools`
  - `argument-hint`
  - argument names
  - `when_to_use`
  - `version`
  - `model`, including explicit `inherit`
  - `disable-model-invocation`
  - `user-invocable`, defaulting to true
  - hooks
  - `context: fork`
  - `agent`
  - `effort`
  - `shell`
  - `paths`
- `paths` using CLAUDE.md-style matching, stripping trailing `/**`, and collapsing all-`**` patterns into "unconditional"
- invocation-time prompt assembly doing more than just read markdown:
  - prepend a base-directory hint for file-backed and plugin skills
  - substitute positional arguments
  - substitute `${CLAUDE_SKILL_DIR}` when the skill has a real local directory
  - substitute `${CLAUDE_SESSION_ID}`
- plugin skills additionally being able to substitute plugin-root-relative paths and non-sensitive plugin user-config values
- inline shell execution from skill markdown being allowed for local and plugin skills
- inline shell execution from MCP skills being explicitly disabled because those skills are remote and untrusted

## Deduplication is by file identity, not by skill name

Equivalent behavior should preserve:

- canonical-file deduplication using resolved file identity rather than plain path string
- symlinked or overlapping paths to the same physical skill collapsing to one entry
- distinct files with the same skill name not being globally merged away
- name collisions therefore remaining order-dependent at command-resolution time instead of being normalized into one canonical winner during loading

## Conditional and nested skills are late-bound

Equivalent behavior should preserve:

- startup-visible unconditional skills being separated from conditional `paths` skills
- conditional `paths` skills being stored but withheld from the active command list until matching file paths are touched
- path activation using cwd-relative matching and ignoring files outside the cwd boundary
- activation being one-way for the current session once a conditional skill has matched
- nested `.claude/skills` directories being discoverable dynamically by walking upward from touched file paths toward cwd
- nested skill discovery caching both hits and misses so repeated file operations do not restat the same directories forever
- directories whose containing path is gitignored being skipped from dynamic skill discovery
- deeper nested skill directories overriding shallower dynamic ones when they collide by name

## Loading must preserve per-skill identity until command composition

Equivalent behavior should preserve:

- same-named skills from different channels staying as distinct loaded candidates until [../../product-surface/command-dispatch-and-composition.md](../../product-surface/command-dispatch-and-composition.md) applies final registry ordering and first-match resolution
- dynamic skill discovery handing late candidates into that same command-composition phase rather than retroactively rewriting or renormalizing already loaded command records
- user-invocable and model-invocable metadata staying attached to the loaded skill record so later slash-command UI, SkillTool filtering, and attachment surfaces can diverge without reparsing markdown sources

## MCP skills are a separate surface from plain MCP prompts

Equivalent behavior should preserve:

- ordinary MCP prompts and MCP skills staying distinct even though both are delivered through MCP
- MCP prompts being treated as prompt resources rather than as skills
- MCP skills being discovered from MCP skill-like resources and registered into the skill surface with `loadedFrom: mcp`
- SkillTool and skill listings being able to filter MCP skills specifically instead of conflating them with every MCP prompt
- the exact `skill://` resource builder path remaining a known clean-room gap in this snapshot, while the surrounding call sites still make the distinction reconstruction-critical

## Cache invalidation is multi-layered

Equivalent behavior should preserve:

- dynamic skill discovery firing a lightweight signal that clears command memoization without wiping the dynamic skill state it just added
- on-disk skill edits going through a stronger watcher path that clears the ordinary skill and command caches after debounce
- feature-flag or enablement refreshes being able to invalidate memoized command visibility without pretending the underlying skill files changed
- late skill activation therefore becoming visible promptly without forcing a full session restart

## Failure modes

- **policy bypass**: `--bare` or `--add-dir` can load project skills even when plugin-only policy should have locked the surface
- **filesystem flattening**: `/skills` and legacy `/commands` are treated as the same format and lose their distinct naming and compatibility rules
- **name-merge fiction**: same-named skills from different channels are silently merged even though the observed runtime keeps order-dependent shadowing
- **dynamic override bug**: nested dynamic skills replace already-visible base commands even though the observed runtime only inserts missing names
- **unsafe shell expansion**: remote MCP skills are allowed to execute inline shell bodies like local skills
- **stale visibility**: dynamic or conditional skill activation never invalidates command caches, so touched-path skills remain undiscoverable until restart
