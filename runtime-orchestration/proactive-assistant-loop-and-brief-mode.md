---
title: "Proactive Assistant Loop and Brief Mode"
owners: []
soft_links: [/product-surface/interaction-modes.md, /runtime-orchestration/unified-command-queue-and-drain.md, /tools-and-permissions/shell-execution-and-backgrounding.md, /memory-and-context/durable-memory-recall-and-auto-memory.md, /integrations/clients/remote-and-managed-client-envelopes.md]
---

# Proactive Assistant Loop and Brief Mode

Claude Code has a persistent-assistant posture that is more than a flag. Assistant mode, proactive ticking, BriefTool, and team bootstrap are coupled startup and runtime contracts. A faithful rebuild needs these boundaries, not just a generic "autonomous chat" switch.

## Assistant mode and proactive mode are related but distinct

Equivalent behavior should preserve:

- assistant mode being a trusted-directory, feature-gated posture that can be enabled from project settings or forced by a daemon-style caller
- proactive mode being the autonomous wake/sleep loop that can be enabled separately through flags, env, or control messages
- spawned teammates sharing the same repository settings without re-running assistant-leader startup side effects
- assistant mode and proactive mode being able to share prompt sections and tool choices without collapsing into one boolean

This distinction matters because assistant mode changes startup identity and communication defaults, while proactive mode changes the turn scheduler.

## Startup gating and pre-seeded team context

Equivalent behavior should preserve:

- refusing to activate assistant mode from an untrusted directory even if project settings request it
- daemon-forced assistant sessions being able to bypass the local entitlement re-check because the parent process already performed that check
- assistant activation forcing brief-style user communication on before the rest of startup snapshots tool and teammate state
- assistant activation pre-seeding an in-process team context before general setup captures teammate mode, so later agent launches behave like a persistent leader instead of an ordinary chat session
- assistant activation implicitly opting into the remote-control envelope at startup so a long-lived assistant can be observed from other clients

The clean-room point is that assistant activation mutates more than the prompt. It changes team bootstrap and client envelope selection.

## Brief entitlement versus brief activation

Equivalent behavior should preserve:

- build flags, runtime gates, and a dev-only env override deciding whether BriefTool is allowed at all
- explicit opt-ins such as flags, settings-driven default view, slash-command toggle, or SDK tool selection deciding whether non-assistant sessions actually activate brief behavior
- assistant mode bypassing ordinary brief opt-in because its system prompt already assumes SendUserMessage is the visible communication channel
- periodic gate revalidation acting as a kill switch that can disable BriefTool later for already opted-in sessions
- mid-session brief toggles updating both the visible display mode and the model-facing tool availability, then injecting an explicit reminder so the next turn switches channels cleanly

Without that last step, the UI and the model drift apart about which output channel is valid.

## Proactive tick scheduling and pacing

Equivalent behavior should preserve:

- proactive activation happening before tool discovery so the Sleep tool is present from the first autonomous turn
- hidden periodic wake-up prompts being enqueued only after the queue goes idle, with an event-loop yield so pending user input or interrupts win the race
- ticks using ordinary queued-prompt machinery rather than a separate transcript backdoor
- control requests being able to toggle proactive mode on or off mid-session
- paused or context-blocked states suppressing further ticks until compaction or recovery clears the block

This is how the assistant stays autonomous without starving real user input or spinning uselessly.

## Model-facing autonomy contract

Equivalent behavior should preserve:

- the first wake-up in a new proactive session greeting the user briefly and asking what to work on instead of exploring unprompted
- later wake-ups either doing useful work or calling the Sleep tool immediately when no load-bearing action exists
- multiple batched ticks collapsing to the latest wake-up signal rather than being narrated one by one
- terminal focus influencing how autonomous or collaborative the assistant should be
- brief instructions being appended inside the proactive section when both modes are active, so the model sees one coherent communication contract instead of duplicated rules

The important clean-room rule is that autonomy is prompt-shaped and queue-shaped at the same time.

## User-visible communication channel

Equivalent behavior should preserve:

- BriefTool being the sanctioned user-facing channel whenever brief is active
- brief messages being classifiable as ordinary replies versus unsolicited proactive updates
- optional attachments being validated and resolved before delivery so logs, screenshots, or diffs can accompany the message safely
- the visible brief-only filter and the actual tool availability staying in sync, or the user will either see hidden plain text or lose the only allowed output channel

## Failure modes

- **untrusted assistant activation**: project-controlled assistant settings take effect before trust is accepted
- **tick starvation**: proactive activates after tools are built and the Sleep tool is missing from the first autonomous turn
- **tick spam**: autonomous ticks fire while the queue still has real input or while the runtime is paused on a context error
- **brief split-brain**: brief-only UI hides plain text while the model was never given BriefTool, or the inverse
- **leader re-bootstrap**: spawned teammates re-run assistant-only startup and corrupt the session's team or proactive state
