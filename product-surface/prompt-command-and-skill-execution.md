---
title: "Prompt Command and Skill Execution"
owners: []
soft_links: [/product-surface/command-dispatch-and-composition.md, /integrations/plugins/skill-loading-contract.md, /integrations/plugins/markdown-prompt-shell-expansion.md, /tools-and-permissions/execution-and-hooks/agent-runtime-context-and-tool-shaping.md, /runtime-orchestration/turn-flow/unified-command-queue-and-drain.md]
---

# Prompt Command and Skill Execution

Prompt-backed commands are loaded through the command and skill registries, but they do not all execute the same way once invoked. Claude Code distinguishes between direct user slash invocation, model-driven SkillTool invocation, coordinator-mode delegation summaries, and worker-backed fork execution. Reconstructing that split matters because the same markdown prompt can change who is allowed to run it, which tools become temporarily legal, whether it re-enters the main turn loop, and whether its result arrives as transcript text, a tool result, or a queued hidden follow-up.

## Scope boundary

This leaf covers:

- how prompt-backed slash commands execute after command lookup succeeds
- how SkillTool reuses, narrows, or bypasses that same prompt-command pipeline
- how `user-invocable`, `disable-model-invocation`, and `context: fork` divide the execution surface
- how prompt-command `allowedTools`, model, effort, and hooks become runtime state

It intentionally does not re-document:

- registry composition, precedence, and name resolution already covered in [command-dispatch-and-composition.md](command-dispatch-and-composition.md)
- skill discovery channels and frontmatter loading rules already covered in [../integrations/plugins/skill-loading-contract.md](../integrations/plugins/skill-loading-contract.md)
- model-facing and human-facing skill listing surfaces already covered in [../integrations/plugins/skill-discovery-and-listing-surfaces.md](../integrations/plugins/skill-discovery-and-listing-surfaces.md)
- feature-gated discovery-tool overlays and remote discovered-skill follow-through already covered in [../integrations/plugins/feature-gated-remote-skill-discovery-overlay.md](../integrations/plugins/feature-gated-remote-skill-discovery-overlay.md)
- markdown prompt compilation, placeholder substitution, and inline shell execution already covered in [../integrations/plugins/markdown-prompt-shell-expansion.md](../integrations/plugins/markdown-prompt-shell-expansion.md)
- the post-selection worker runtime shaping once a forked prompt has already become a worker run, already covered in [../tools-and-permissions/execution-and-hooks/agent-runtime-context-and-tool-shaping.md](../tools-and-permissions/execution-and-hooks/agent-runtime-context-and-tool-shaping.md)

## One prompt-backed asset can run through several invocation surfaces

Equivalent behavior should preserve:

- direct user slash invocation as the manual surface for prompt commands that remain user-invocable
- SkillTool invocation as the model-facing surface for prompt-based skills and commands that are allowed to be model-invoked
- coordinator-mode main-thread invocation as a third surface that may summarize a skill for delegation instead of loading its full prompt body
- `context: fork` acting as an execution-mode switch that can apply from both user slash invocation and SkillTool, rather than as a separate registry or file format

The key invariant is that prompt content is reusable, but the execution envelope depends on who invoked it and in what runtime mode.

## User slash gating and model gating are intentionally different

Equivalent behavior should preserve:

- `user-invocable: false` blocking direct user slash execution with an explanatory response instead of silently hiding the reason
- `disable-model-invocation` blocking SkillTool use even when the same prompt command can still be invoked manually by the user
- SkillTool validating that the target is prompt-based before execution rather than letting local or local-JSX commands masquerade as skills
- SkillTool's model-facing skill surface including MCP-delivered skills but excluding plain MCP prompts
- the model-facing skill listing staying narrower than the full command catalog, so built-in slash commands are not presented as normal skills even when the broader command registry still knows they exist

## Inline prompt commands compile into a hidden turn scaffold

Equivalent behavior should preserve:

- normal prompt-command invocation calling the command's prompt builder and then feeding the result back into the ordinary query loop instead of inventing a second model-execution engine
- pasted images and preceding input blocks being prepended into the same model-visible prompt message when the user invoked the command with extra payload already in hand
- hook registration for prompt commands happening at invocation time, with the same source-trust policy that prevents user-controlled hook escalation under plugin-only lock-down
- invoked-skill tracking recording the expanded prompt content and associating it with the current agent identity so compaction only restores the skills that belong to that agent
- attachment extraction running over the expanded prompt text so command arguments can surface resource mentions or agent mentions, while skill discovery stays disabled for the prompt body itself to avoid treating large `SKILL.md` content as fresh user intent
- the emitted transcript scaffold containing:
  - a visible loading-metadata message
  - a hidden meta user message with the expanded prompt body
  - any derived attachment messages
  - a hidden permission or model metadata attachment for the query loop
- prompt-command invocation returning `shouldQuery = true` together with any model or effort override, so the next ordinary main-turn query consumes the scaffold

## Coordinator mode replaces prompt bodies with delegation summaries on the main thread

Equivalent behavior should preserve:

- coordinator mode on the main thread refusing to dump full skill bodies into the coordinator's own limited tool posture
- the coordinator instead receiving a short summary containing the skill name, description, when-to-use guidance, and any extra tool permissions the skill would grant to a worker
- that summary explicitly instructing the coordinator to delegate the skill to a worker rather than execute it itself
- subagents under coordinator mode still being allowed to load the real skill content, because the restriction applies to the coordinator's main-thread posture, not to workers that actually run the skill

## Forked prompt commands and forked skills become worker runs

Equivalent behavior should preserve:

- `context: fork` on a prompt command routing user slash invocation into the worker-launch path instead of the inline main-turn prompt scaffold
- the same `context: fork` on SkillTool causing skill execution to become a worker run instead of an inline context modification
- fork preparation choosing a base agent from the command's explicit agent field when present and otherwise falling back to the general-purpose worker
- command or skill `effort` merging into that worker definition before execution
- command or skill `allowedTools` being injected into the worker's derived permission view instead of broadening the parent session globally
- synchronous forked slash execution showing worker progress UI and then returning transcript-style stdout output without launching another main-thread model turn
- forked SkillTool execution instead returning a tool result that contains the worker's final text, because from the model's perspective the skill call itself is the active tool round

## Assistant-mode forked slash commands detach and re-enter through the queue

Equivalent behavior should preserve:

- assistant or daemon-style user slash execution being able to background forked prompt commands instead of blocking the main session until the worker completes
- those detached slash-command workers using their own abort controller so main-turn cancellation does not kill scheduled or proactive work mid-run
- startup-time detached forked commands waiting briefly for pending MCP connections to settle, then refreshing the tool set before launch so early scheduled work does not capture a stale pre-MCP tool surface
- completed detached forked commands re-entering the shared command queue as hidden prompt notifications instead of writing directly into the visible transcript
- the hidden follow-up prompt preserving the originating workload and skipping slash re-parsing, so the next main-agent turn can interpret the result as system-delivered context rather than as a fresh user slash command

## SkillTool has its own permission gate and inline reuse contract

Equivalent behavior should preserve:

- SkillTool validating the requested skill name against the available command surface, including MCP skills, before the tool call proceeds
- SkillTool permission checks honoring explicit allow and deny rules for exact names and prefix patterns
- Skills with only a reviewed safe-property subset auto-approving through SkillTool, while any extra meaningful properties force an ask path by default
- ask-mode SkillTool permissions suggesting both an exact allow rule and a prefix allow rule for future reuse
- a feature-gated remote discovered-skill variant remaining a separate model-only path: once previously discovered, it bypasses local command lookup and injects remote markdown directly instead of running local slash-command compilation

## Inline SkillTool execution reuses prompt expansion but changes state propagation

Equivalent behavior should preserve:

- non-forked SkillTool execution reusing the same prompt-command expansion pipeline as direct slash invocation instead of maintaining a second markdown-expansion implementation
- SkillTool stripping the slash-style loading metadata message from the forwarded transcript payload because the tool renderer already provides its own progress and success UI
- the forwarded prompt messages being tagged with the parent tool-use identity so they remain transient until the SkillTool call resolves
- inline SkillTool calls returning a context modifier rather than immediate worker output
- that context modifier unioning the skill's extra allowed tools onto the current command-rule set, preserving any already-active command allowances instead of replacing them
- the same context modifier carrying model overrides forward in a way that preserves session-specific model-window suffixes instead of accidentally shrinking the context window
- effort overrides being applied through the same chained context modifier so the following query sees the skill's effort request without mutating unrelated global state

## Turn-scoped command permissions must be applied and cleared at the right boundary

Equivalent behavior should preserve three distinct permission-propagation paths:

- direct prompt-command invocation setting the turn's slash-command `allowedTools` into shared session state before the main query begins, and clearing that state again on the next non-skill turn
- inline SkillTool invocation adding its `allowedTools` through the tool call's context modifier, because it is already inside a running main turn
- forked command or skill execution injecting `allowedTools` only into the worker's derived app-state view, so parent-session ad hoc permissions do not leak into the worker and worker-only allowances do not leak back out

The ordering matters. If the session-level write for slash-command `allowedTools` happens too late, forked prompt commands can inherit stale permissions from an earlier skill turn.

## Failure modes

- **surface collapse**: user-invocable and model-invocable gates are treated as one flag, so users lose valid slash commands or the model gains skills it should not call
- **wrong execution mode**: a `context: fork` prompt runs inline in the main turn, or an inline prompt unnecessarily spawns a worker and changes result semantics
- **permission drift**: skill-scoped `allowedTools` linger into later unrelated turns, or inline SkillTool execution accidentally clears unrelated command allowances
- **coordinator overload**: coordinator mode loads full skill bodies and permission metadata into the main thread instead of delegating to workers
- **queue bypass**: detached assistant-mode forked slash commands write directly into the transcript instead of re-entering through the hidden queue path, breaking attribution and follow-up semantics
- **MCP prompt confusion**: plain MCP prompts are treated as SkillTool-usable skills, collapsing the boundary between prompt resources and true skills
