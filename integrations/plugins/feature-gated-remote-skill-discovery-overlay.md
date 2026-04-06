---
title: "Feature-Gated Remote Skill Discovery Overlay"
owners: []
soft_links: [/integrations/plugins/skill-discovery-and-listing-surfaces.md, /product-surface/prompt-command-and-skill-execution.md, /runtime-orchestration/turn-flow/turn-attachments-and-sidechannels.md, /runtime-orchestration/turn-flow/query-loop.md]
---

# Feature-Gated Remote Skill Discovery Overlay

The observed snapshot contains a second, feature-gated skill-discovery layer beyond the ordinary local skill registry. It does not replace bundled, local, plugin, or MCP skills. Instead, it supplements them with per-turn discovery signals and a model-only path for previously discovered remote skills. A faithful rebuild therefore needs a separate contract for discovery timing, surfaced reminders, session state, and remote-skill execution, even though the retrieval backend itself is absent from this snapshot.

## Scope boundary

This leaf covers:

- the feature-gated discovery guidance injected into main-session and subagent prompts
- turn-zero and inter-turn skill-discovery signal timing
- how discovered skills are surfaced back into the conversation
- the model-only execution path for previously discovered remote skills
- session and turn state that tracks discovered names

It intentionally does not re-document:

- ordinary skill loading, filesystem discovery, and registry ordering already covered in [skill-loading-contract.md](skill-loading-contract.md)
- static model-facing skill listings and the human `/skills` dialog already covered in [skill-discovery-and-listing-surfaces.md](skill-discovery-and-listing-surfaces.md)
- ordinary local SkillTool and prompt-command execution already covered in [../../product-surface/prompt-command-and-skill-execution.md](../../product-surface/prompt-command-and-skill-execution.md)
- hidden ranking, retrieval, transport, or storage details that are not visible in this snapshot

## The overlay fills gaps instead of replacing visible skills

Equivalent behavior should preserve:

- this mode being feature-gated rather than part of the baseline public skill contract
- ordinary bundled, local, plugin, and MCP skills still remaining available through the normal skill surface
- discovery guidance telling the model to rely on already surfaced skills first and to call a dedicated discovery tool only when the visible skills do not cover the next action
- the discovery path filtering out already visible or already loaded skills instead of re-surfacing duplicates
- static eager skill listings narrowing when this mode is active, so long-tail project, user, and plugin skills can arrive through discovery instead of bloating the base prompt

## Main sessions and subagents both need discovery framing

Equivalent behavior should preserve:

- the main session system prompt adding explicit discovery guidance only when both SkillTool and the discovery tool are enabled
- that guidance teaching the model that relevant skills may arrive automatically as `"Skills relevant to your task"` reminders
- the same guidance being added again on the subagent prompt-enhancement path, because subagents do not reuse the main-session system-prompt assembly path
- workers therefore understanding discovery reminders even when they encounter them only after spawn-time prompt enhancement

## Discovery has two timing modes

Equivalent behavior should preserve:

- user input on turn zero being able to trigger a blocking discovery pass before the first model request
- later turns starting discovery asynchronously while the model streams and tools run
- that inter-turn discovery prefetch being tied to the current turn trajectory rather than acting as a blind every-turn catalog refresh
- the prefetched discovery results being collected only after tool execution, so the next recursive request benefits without delaying the current response
- plan-exit notifications not re-triggering discovery when the relevant planning request already provided the signal earlier in the turn

## Prompt-expanded skill bodies must not recursively trigger discovery

Equivalent behavior should preserve:

- skill discovery being skipped when the current input is the expanded body of a selected skill rather than fresh user intent
- `@`-mention extraction still being allowed over that expanded skill body
- rebuilds treating this as a correctness requirement rather than a mere optimization, because otherwise large skill bodies trigger redundant discovery work and surface irrelevant reminders

## Discovery results surface as reminder attachments, not registry mutations

Equivalent behavior should preserve:

- discovered skills entering the conversation as attachment-style system reminders rather than silently mutating the root system prompt
- the rendered reminder format being a short `"Skills relevant to your task"` block with skill names and descriptions
- those reminders instructing the model to invoke the surfaced skill through SkillTool for full instructions rather than treating the reminder text as the full skill body
- discovery attachments joining the same post-tool sidechannel lane as other structured enrichments, so they affect the next recursive request rather than a separate conversation

## Discovered-skill state is session-scoped

Equivalent behavior should preserve:

- interactive REPL sessions keeping a discovered-skill set across multiple turns so later invocations can still count as previously discovered
- clearing a conversation also clearing that discovered-skill set, alongside other session-scoped context caches
- headless or SDK submits clearing their discovered-skill set at the start of each submitted message, so discovery state does not grow forever across unrelated turns
- subagent or fork contexts getting their own discovered-skill tracking sets instead of sharing one process-global set blindly

## Previously discovered remote skills are model-only and session-gated

Equivalent behavior should preserve:

- remotely discovered skills not living in the local command registry
- the model being unable to invoke one merely by guessing its name; it must have been discovered earlier in the current session first
- validation checking that prior discovery before execution proceeds
- permission handling auto-allowing this path by default only after explicit deny rules have had a chance to block it
- remotely discovered skills remaining model-facing rather than becoming normal user slash commands

## Remote discovered-skill execution bypasses local slash compilation

Equivalent behavior should preserve:

- the remote discovered-skill path short-circuiting before ordinary local command lookup
- remote skill content loading as declarative markdown rather than reusing local prompt-command compilation
- this path not performing local-style shell expansion or argument substitution over the remote markdown body
- frontmatter being stripped from the loaded markdown before injection
- the final injected content still receiving the same base-directory hint plus `${CLAUDE_SKILL_DIR}` and `${CLAUDE_SESSION_ID}` substitutions that help the model resolve local references
- the resulting skill content being registered with invoked-skill state so compaction and later restoration preserve it like locally loaded skills
- execution returning a meta user-message injection instead of a visible slash-command scaffold

## Clean-room gap

This snapshot exposes the prompt guidance, attachment timing, discovered-name state, and remote-execution behavior around feature-gated skill discovery, but it does not include the underlying discovery backend modules themselves. Rebuilds should therefore preserve:

- when discovery runs
- what kind of reminder it emits
- how discovered names gate remote execution
- how remote skill content is injected once discovered

They should not invent hidden ranking, retrieval, transport, or storage details beyond those observable contracts.

## Failure modes

- **turn-zero blind spot**: discovery only runs asynchronously later, so the first turn misses relevant skills the model was supposed to see up front
- **recursive discovery spam**: expanded `SKILL.md` bodies are treated as fresh user intent and repeatedly trigger discovery
- **subagent framing gap**: workers receive discovery attachments but never got the guidance explaining what those reminders mean
- **guessed remote execution**: a remotely discovered skill can be invoked without prior discovery, so the model can call hidden names by guesswork
- **local-remote conflation**: remotely discovered skills are run through ordinary local prompt compilation and accidentally gain shell expansion or argument interpolation
- **state drift**: discovered-skill state is never cleared, or is cleared too aggressively, so later turns either lose legitimate discovery context or accumulate stale names forever
