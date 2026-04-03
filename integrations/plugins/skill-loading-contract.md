---
title: "Skill Loading Contract"
owners: []
soft_links: [/integrations/plugins/plugin-and-skill-model.md, /tools-and-permissions/tool-families.md, /product-surface/command-runtime-matrix.md]
---

# Skill Loading Contract

Skills are a prompt-layer extension mechanism. They behave like reusable domain guidance, not like executable plugins.

## Source classes

- project-local skills
- user-level skills
- managed or policy-provided skills
- bundled defaults
- plugin-provided skills
- skills synthesized from other integration systems such as MCP

## Loading boundary

- A skill may specify metadata such as description, recommended tools, invocation controls, or model preferences.
- A skill should compile down to promptable guidance or controlled execution context, not arbitrary runtime mutation.
- Skill loading failures should degrade softly; a bad skill index must not crash the entire product.

## Lifecycle

1. Discover markdown or generated skill source.
2. Parse frontmatter and normalize metadata.
3. Deduplicate by canonical identity rather than only by filename.
4. Index for search, listing, and invocation.
5. Expand into prompt content when invoked or selected.

## Failure classes

- **frontmatter invalid**: the skill exists but cannot be safely interpreted
- **duplicate identity**: multiple paths resolve to the same underlying skill
- **stale index**: a new skill exists but command or search caches have not refreshed
- **capability mismatch**: a skill recommends tools or modes unavailable in the current runtime
