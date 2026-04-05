---
title: "Skill Discovery and Listing Surfaces"
owners: []
soft_links: [/integrations/plugins/skill-loading-contract.md, /product-surface/prompt-command-and-skill-execution.md, /product-surface/command-dispatch-and-composition.md, /ui-and-experience/terminal-ui.md]
---

# Skill Discovery and Listing Surfaces

Loading a skill into Claude Code does not automatically determine who sees it or how it is described. The product maintains distinct discovery surfaces for the model, for interactive users, and for headless or bridge-adjacent summaries. Rebuilding skills faithfully therefore requires more than reproducing the load path: it requires reproducing the filters, budgets, grouping rules, and delta-announcement behavior that decide which skills are surfaced to which audience.

## Scope boundary

This leaf covers:

- how the model learns which skills are currently available
- how the interactive `/skills` surface presents skills to users
- how model-facing and human-facing skill inventories intentionally diverge
- how listing budgets and delta updates prevent skill discoverability from overwhelming the prompt

It intentionally does not re-document:

- skill discovery from disk, plugins, MCP, or dynamic nested paths already covered in [skill-loading-contract.md](skill-loading-contract.md)
- feature-gated discovery-tool timing, discovery reminders, and remote discovered-skill follow-through already covered in [feature-gated-remote-skill-discovery-overlay.md](feature-gated-remote-skill-discovery-overlay.md)
- prompt-command and SkillTool execution after a skill has been chosen, already covered in [../../product-surface/prompt-command-and-skill-execution.md](../../product-surface/prompt-command-and-skill-execution.md)
- generic command-registry precedence and collision rules already covered in [../../product-surface/command-dispatch-and-composition.md](../../product-surface/command-dispatch-and-composition.md)

## The model and the human do not receive the same skill catalog

Equivalent behavior should preserve:

- the model-facing skill surface being delivered through SkillTool instructions plus later skill-listing attachments rather than through the `/skills` dialog
- the human-facing `/skills` dialog being an interactive local JSX surface over the current command registry rather than a model-visible prompt payload
- headless or bridge-adjacent skill summaries using yet another filtered view for system-init and analytics-style inventories
- these surfaces intentionally disagreeing about which skills are worth showing, because discoverability, prompt budget, and direct invocability are different concerns

## The SkillTool prompt teaches invocation, not the full inventory

Equivalent behavior should preserve:

- the SkillTool prompt teaching that slash-command-style requests correspond to skills
- the prompt treating matching skill use as mandatory before the model writes an ordinary response about that task
- the prompt forbidding the model from mentioning a skill without actually calling the tool
- the prompt telling the model not to use SkillTool for built-in CLI commands
- the prompt teaching the model to recognize command-loading metadata tags so it does not reload a skill that is already active in the current turn
- the actual list of available skills arriving separately through the attachment path instead of being hardcoded into the static tool prompt

## Model-facing skill listings are filtered and budgeted

Equivalent behavior should preserve:

- model-facing listings being generated only when the current tool surface actually includes SkillTool
- the base local model-facing set coming from prompt commands that are model-invocable, non-built-in, and sufficiently descriptive to be discoverable
- bundled skills and legacy command-backed skills staying eligible even when they rely on auto-derived descriptions, while ordinary plugin or MCP prompt commands need explicit description-style metadata to qualify
- plain MCP prompts staying out of the model-facing skill list while MCP skills are unioned in as skills
- name-based deduplication between local and MCP skill surfaces before the listing is announced
- feature-gated skill-search mode narrowing the eager model-facing list to bundled and MCP skills, so user or project or plugin skills can flow through discovery signals instead of bloating the turn-zero prompt

## Listing attachments are incremental, per-agent, and resume-aware

Equivalent behavior should preserve:

- the skill list entering the conversation as attachment-style announcements rather than as a permanent static block inside the root system prompt
- each agent or main session tracking which skill names it has already been told about
- initial startup delivery sending the first batch as one attachment and later plugin reloads or MCP changes sending only deltas
- resume paths suppressing reinjection of the current skill set because the transcript already contains the earlier announcements
- skill listings being skipped entirely when there are no new eligible skills to announce

## Model-facing descriptions obey a strict prompt budget

Equivalent behavior should preserve:

- a default listing budget of roughly 1% of the model context window, measured in characters rather than tokens, with an explicit environment override for testing or tuning
- description text using description plus when-to-use guidance when available
- each individual description being hard-capped before any global budget fitting runs
- bundled skills keeping their full descriptions whenever possible, because they are treated as core capability anchors
- non-bundled skills being truncated progressively when the total listing would exceed budget
- an extreme fallback where non-bundled entries degrade to names-only while bundled skills keep descriptions
- truncation telemetry distinguishing between trimmed-description mode and names-only mode

The important invariant is that skill discovery stays prompt-cheap without letting bundled core skills disappear first.

## The `/skills` dialog is a separate human-facing inventory

Equivalent behavior should preserve:

- `/skills` opening a local JSX dialog instead of starting a model turn
- the dialog filtering to prompt commands loaded from skill directories, deprecated commands directories, plugins, and MCP
- bundled skills not being shown in this dialog even though they remain important in the model-facing discovery surface
- dialog sections being rendered in explicit user-facing groups for project skills, user skills, policy-managed skills, plugin skills, and MCP skills
- each group being sorted by display name instead of raw filesystem order
- file-backed groups showing their source directories in the subtitle, with deprecated commands paths appended when that compatibility path is in use
- MCP groups showing contributing server names instead of filesystem paths
- each listed skill row showing the display name plus an approximate description-token cost
- plugin skill rows also surfacing the plugin name
- the empty state explicitly telling the user where to create local skills
- dismissing the dialog producing only system-style feedback, not a model-visible prompt payload

## Inventory summaries used outside the dialog follow their own filter

Equivalent behavior should preserve:

- some skill-count and system-init surfaces using a broader slash-command skill filter than the model-facing SkillTool list
- that broader filter still excluding built-in commands while allowing skills that matter for slash-oriented inventories even if they are not part of the model's eager listing
- skill discoverability metrics and summaries therefore not being assumed to match the exact model-invocable list one-for-one

## Failure modes

- **surface conflation**: the model-facing skill list and the human `/skills` dialog are treated as the same inventory and lose their intentionally different filters
- **bundled invisibility**: bundled skills get truncated away or hidden from the model even though they are meant to stay prominent in the discovery prompt
- **MCP flattening**: plain MCP prompts leak into skill listings, or MCP skills lose their server-scoped identity
- **delta spam**: resume, reload, or MCP-refresh paths keep re-announcing the same skills instead of sending only new names
- **budget drift**: description fitting ignores the shared budget rules and either wastes prompt space or silently drops too much guidance for non-bundled skills
