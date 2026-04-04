<!-- BEGIN CONTEXT-TREE FRAMEWORK — do not edit this section -->
# Agent Instructions for Context Tree

You are working in a **Context Tree** — the living source of truth for decisions across the organization. Read and follow this before doing anything.

## Principles

1. **Source of truth for decisions, not execution.** The tree captures the *what* and *why* — strategic choices, cross-domain relationships, constraints. Execution details stay in source systems. If an agent needs this information to *decide* on an approach, it belongs in the tree. If the agent only needs it to *execute*, it stays in the source system.

2. **Agents are first-class participants.** The tree is designed to be navigated and updated by agents, not just humans. Domains are organized by concern — what an agent needs to know to act — not by repo, team, or org chart.

3. **Transparency by default.** All information is readable by everyone. Writing requires owner approval; reading is open.

4. **Git-native tree structure.** Each node is a file; each domain is a directory. Soft links allow cross-references without the complexity of a full graph. History, ownership, and review follow Git conventions.

See `skills/first-tree/references/principles.md` for detailed explanations and examples.

## Before Every Task

1. **Read the root NODE.md** to understand the domain map.
2. **Read the NODE.md of every domain relevant to your task.** If unsure which domains are relevant, start from root and follow the structure — it's organized by concern, not by repo.
3. **Follow soft_links.** If a node declares `soft_links` in its frontmatter, read those linked nodes too. They exist because the domains are related.
4. **Read leaf nodes that match your task.** NODE.md tells you what exists in each domain — scan it and read the leaves that are relevant.

Do not skip this. The tree is already a compression of expensive knowledge — cross-domain relationships, strategic decisions, constraints. An agent that skips the tree will produce decisions that conflict with existing ones.

## During the Task

- **Decide in the tree, execute in source systems.** If the task involves a decision (not just a bug fix), draft or update the relevant tree node before executing.
- **The tree is not for execution details.** Function signatures, DB schemas, API endpoints, ad copy — those live in source systems. The tree captures the *why* and *how things connect*.
- **Respect ownership.** Each node declares owners in its frontmatter. If your changes touch a domain you don't own, flag it — the owner needs to review.

## After Every Task

Ask yourself: **Does the tree need updating?**

- Did you discover something the tree didn't capture? (A cross-domain dependency, a new constraint, a decision that future agents would need.)
- Did you find the tree was wrong or outdated? That's a tree bug — fix it.
- Not every task changes the tree, but the question must always be asked.

## Reference

For ownership rules, tree structure, and key files, see [NODE.md](NODE.md) and `skills/first-tree/references/ownership-and-naming.md`.
<!-- END CONTEXT-TREE FRAMEWORK -->

# Project-Specific Instructions

This repository is a clean-room reconstruction spec for Claude Code.

Additional rules for this tree:

1. Do not copy source code, prompt bodies, large string literals, internal codenames, secrets, or implementation-specific prose from the analyzed source snapshot into this tree.
2. Normalize source findings into product behavior, subsystem contracts, state transitions, constraints, and rationale. Prefer "what must exist" over "how one file implemented it."
3. Organize by concern, not by the original repository layout. Directory names from the source are evidence, not structure.
4. If a detail is only needed to execute inside the original codebase, leave it out. If it is needed to rebuild equivalent behavior from scratch, restate it in implementation-neutral language.
5. Flag gaps openly. A missing or uncertain behavior is better than silently guessing from leaked code.
6. Treat any non-public or obviously internal-only capability as feature-gated unless it is clearly core to the product shape. Document the gate, not the hidden implementation.
7. After each meaningful milestone, open a PR and merge via squash into `main` once reviewed. Keep the tree continuously releasable.
8. Before concluding any task, run `context-tree verify` and make sure `skills/first-tree/progress.md` still reflects reality.
