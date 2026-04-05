---
title: "Review Path"
owners: []
soft_links: [/product-surface/command-execution-archetypes.md, /collaboration-and-agents/remote-handoff-path.md, /tools-and-permissions/tool-execution-state-machine.md]
---

# Review Path

Review is not one feature path. It has at least two important variants: a local review flow and a remote deep-review flow.

## Local review path

1. User enters a review command.
2. Command expands into a structured review prompt rather than launching a bespoke review runtime.
3. The standard query loop executes.
4. Tool use gathers PR metadata, diff context, and repository evidence.
5. The assistant synthesizes review findings back into the local session.

## Remote review path

1. User enters a remote-review style command.
2. Runtime checks eligibility, quota or billing posture, and remote preconditions.
3. Runtime chooses a remote execution substrate and packages the review target.
4. A remote-agent task is registered locally so results can stream back.
5. Local session transitions into "review running elsewhere" while keeping visibility into task state.
6. Results return as task output or remote session events and are folded into the local experience.

## State transitions that matter

- ready -> review requested
- review requested -> local analysis or remote preflight
- remote preflight -> remote task registered
- analysis running -> evidence gathered
- evidence gathered -> findings synthesized
- findings synthesized -> review complete

## Failure branches

- **no review target**: the user needs a PR number, a current PR, or a detectable diff target
- **remote preconditions failed**: repo, auth, quota, or environment requirements are not satisfied
- **empty review surface**: there is no diff worth reviewing
- **verification timeout**: remote or local evidence gathering exceeds acceptable time or budget

Rebuilders should treat review as an orchestration pattern layered on top of the normal query loop and optional remote delegation.
