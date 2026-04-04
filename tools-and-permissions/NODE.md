---
title: "Tools and Permissions"
owners: []
soft_links: [/runtime-orchestration, /collaboration-and-agents]
---

# Tools and Permissions

This domain captures the tool contract that powers agentic work and the permission system that keeps it safe.

Relevant leaves:

- **[tool-families.md](tool-families.md)** — The major classes of tools that must exist.
- **[tool-pool-assembly.md](tool-pool-assembly.md)** — How the runtime assembles the exact tool list that the model and UI can see in one session.
- **[deferred-tool-discovery-and-tool-search.md](deferred-tool-discovery-and-tool-search.md)** — Deferred tool admission, ToolSearch-based discovery, discovered-tool persistence across compaction, and schema-mismatch recovery hints.
- **[control-plane-tools.md](control-plane-tools.md)** — Tools that mutate runtime state, teams, tasks, or execution modes.
- **[task-and-team-control-tool-contracts.md](task-and-team-control-tool-contracts.md)** — Transactional contracts for task creation, task updates, ownership routing, and team initialization.
- **[config-discovery-and-trigger-tool-contracts.md](config-discovery-and-trigger-tool-contracts.md)** — Read and write configuration surfaces, permission browser behavior, retry paths, and policy-gated triggers.
- **[ask-user-question-tool-contract.md](ask-user-question-tool-contract.md)** — How the AskUserQuestion tool defines question schemas, preview payloads, interactive availability, and answer serialization.
- **[agent-tool-launch-routing.md](agent-tool-launch-routing.md)** — How the Agent tool chooses between teammate, fork, background, worktree, and remote execution paths.
- **[permission-model.md](permission-model.md)** — Safety, sandboxing, and approval behavior.
- **[permission-mode-transitions-and-gates.md](permission-mode-transitions-and-gates.md)** — Startup precedence, centralized mode transitions, async auto-mode gates, and dangerous-rule stripping or restoration.
- **[permission-decision-pipeline.md](permission-decision-pipeline.md)** — The layered rule, mode, classifier, worker, and dialog flow behind each tool approval.
- **[permission-rule-loading-and-persistence.md](permission-rule-loading-and-persistence.md)** — How permission rules are loaded, normalized, stripped for auto mode, restored, and persisted.
- **[permission-resolution-races-and-forwarding.md](permission-resolution-races-and-forwarding.md)** — Single-winner ask-resolution races across dialog, bridge, mailbox, channel relay, hooks, classifier, and abort paths.
- **[shell-execution-and-backgrounding.md](shell-execution-and-backgrounding.md)** — How shell tools stream, background, reuse tasks, and stay responsive in assistant mode.
- **[shell-rule-grammar-and-matching.md](shell-rule-grammar-and-matching.md)** — The shared exact/prefix/wildcard rule grammar and the Bash/PowerShell normalization rules around it.
- **[path-and-filesystem-safety.md](path-and-filesystem-safety.md)** — Working-directory boundaries, protected files, internal harness paths, and shell path validators.
- **[file-read-write-edit-and-notebook-consistency.md](file-read-write-edit-and-notebook-consistency.md)** — Shared read-state invariants, native media and notebook branches, atomic text edits, full-file writes, and notebook-cell mutation rules.
- **[sandbox-selection-and-bypass-guards.md](sandbox-selection-and-bypass-guards.md)** — How sandbox selection, excluded commands, policy-gated overrides, and Windows refusal paths interact.
- **[delegation-modes.md](delegation-modes.md)** — Plan mode, worktree mode, and delegated execution patterns.
- **[tool-execution-state-machine.md](tool-execution-state-machine.md)** — How tools move from selection to execution, denial, retry, and result integration.
- **[tool-batching-and-streaming-execution.md](tool-batching-and-streaming-execution.md)** — How concurrent-safe tools, streaming execution, progress, and synthetic repairs work.
- **[tool-hook-control-plane.md](tool-hook-control-plane.md)** — Hook source merge, matcher and dedup semantics, structured outputs, lifecycle integration points, and out-of-band execution boundaries.
