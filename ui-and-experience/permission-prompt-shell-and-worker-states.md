---
title: "Permission Prompt Shell and Worker States"
owners: []
soft_links: [/ui-and-experience/interaction-feedback.md, /tools-and-permissions/permission-model.md, /tools-and-permissions/permission-decision-pipeline.md, /collaboration-and-agents/teammate-mailbox-and-permission-bridge.md]
---

# Permission Prompt Shell and Worker States

Permission approval is not one ad hoc modal. Claude Code routes the queue head into a tool-specific renderer, wraps most requests in a shared dialog shell, keeps long plan exits navigable with a fullscreen sticky footer, and shows a separate worker-side waiting card when approval is delegated to the leader. A faithful rebuild needs the same queue ownership, dialog chrome, feedback-input behavior, and worker identity cues or approvals will feel inconsistent across foreground and swarm flows.

## Queue ownership and activation

Equivalent behavior should preserve:

- only the first pending tool-permission item becoming the active approval surface, with later requests waiting in queue order
- the active permission surface being keyed by tool-use identity so per-request focus, feedback text, and sticky-footer state reset cleanly when the queue head changes
- resolving a request removing only the queue head and then revealing the next request, rather than flushing the whole queue
- fullscreen REPL mode routing the active permission request into a dedicated overlay slot, while non-fullscreen mode keeps the request inline and therefore cannot host a sticky footer
- ordinary transcript animation yielding while a permission request is active, so approval UI owns attention instead of competing with streaming motion

## Tool-specific request routing

Equivalent behavior should preserve:

- one central router selecting the permission renderer by tool identity before any generic fallback shell is built
- file edit and file write requests using diff-oriented file dialogs, while glob, grep, and file-read requests share a filesystem prompt
- bash and PowerShell each using shell-specific approval surfaces rather than a generic tool card
- enter-plan and exit-plan requests using plan-specific renderers, and notebook edit, web fetch, skill, and ask-user requests each getting their own specialized surface
- review-artifact, workflow, and monitor permission UIs being feature-gated and falling back to the generic renderer when their specialized implementation is unavailable
- unknown tools still rendering through a safe fallback prompt instead of failing to surface approval state

## Attention and interruption behavior

Equivalent behavior should preserve:

- every permission request scheduling a delayed user-facing notification on a permission-prompt channel
- notification wording specializing for exit-plan, enter-plan, and review-artifact requests before falling back to the tool's user-facing name or a generic attention message
- the confirmation context binding the global interrupt action to reject the active request, close the surface, and invoke the request's own reject callback
- sticky-footer registration being passed only in fullscreen mode, because scrollback mode has no fixed bottom slot for pinned controls
- exit-plan requests being the canonical consumer of that sticky-footer capability so action choices remain visible while the user scrolls through a long plan

## Shared dialog chrome

Equivalent behavior should preserve:

- most permission surfaces using one shared dialog shell with a rounded top border, no left or right frame, no bottom frame, a configurable accent color, and a padded body section
- the shell exposing a title row, optional subtitle, optional worker identity, and optional right-aligned title content without forcing each tool-specific prompt to rebuild that structure
- title rows showing the main title in the request color and appending worker identity as a dimmed `@worker` handle instead of repeating a full colored badge
- string subtitles rendering dimmed and truncating from the start so the differentiating tail remains visible
- plan-related prompts recoloring the shared shell into a dedicated plan-mode palette rather than reusing the ordinary permission tone
- specialized request bodies being able to drop inner horizontal padding to zero when they need full-width diffs or other custom layouts

## Shared choice prompt behavior

Equivalent behavior should preserve:

- the common choice prompt rendering a question, a select list with inline descriptions, and a trailing hint line instead of bespoke accept or reject controls for every tool
- options being able to opt into amendable feedback mode tagged as either accept-side or reject-side guidance
- the tab hint appearing only when the focused option supports feedback and is not already in input mode
- entering feedback mode converting that option into an inline input field with intent-specific default placeholders for approval guidance versus rejection guidance
- moving focus away from an untouched feedback field collapsing input mode automatically, while typed content keeps the field logically active until submission or explicit cancel
- feedback being trimmed before submission, with blank feedback treated as absent rather than forwarded as an empty string
- individual options being able to bind direct key actions that submit the same decision without manual list navigation

## Cancellation and hint semantics

Equivalent behavior should preserve:

- the shared hint line always preserving an escape-to-cancel instruction
- that same hint line appending a tab-to-amend nudge only for amendable options
- pressing escape canceling through the prompt's provided callback instead of silently dismissing the UI
- empty submit being allowed to cancel out of an input-mode option instead of forcing a meaningless blank instruction through the pipeline

## Worker-side waiting state

Equivalent behavior should preserve:

- worker sessions waiting on leader approval not showing the leader's full approval dialog; they show a separate waiting card with a spinner and warning tone
- that waiting card including the pending tool name, a human-readable action summary, and the target team context when a team name is known
- local worker identity and teammate color, when available, producing a full colored badge on the worker-side waiting card
- leader-side approval dialogs using a lighter-weight worker identity cue than the worker-side waiting card, so the leader sees who requested approval without duplicating the worker's full status treatment
- the waiting card remaining a blocked-state surface only: it explains that approval has been handed off and that the worker is paused for a decision

## Failure modes

- **queue collapse**: resolving one prompt flushes or skips later permission requests instead of advancing one slot at a time
- **worker ambiguity**: leader-side approval dialogs omit requesting-worker identity and make swarm approvals unsafe
- **feedback loss**: moving focus or leaving input mode drops guidance that should have been submitted with the decision
- **sticky-footer leak**: a long plan leaves fullscreen footer controls mounted after the prompt is gone
- **attention split**: streaming transcript motion or another overlay keeps competing with the permission prompt instead of yielding focus
