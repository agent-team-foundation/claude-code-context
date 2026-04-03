---
title: "Compact Path"
owners: []
soft_links: [/product-surface/end-to-end-scenario-graphs.md, /runtime-orchestration/state-machines-and-failures.md, /memory-and-context/compaction-and-dream.md]
---

# Compact Path

Compaction is one of the defining hard problems in a long-lived coding agent. A correct rebuild needs more than "summarize old messages."

## Trigger classes

- proactive auto-compact when token pressure crosses a configured threshold
- reactive compact after the model or API rejects an oversized turn
- manual compact initiated by the user

## Core path

1. Runtime estimates effective context headroom for the active model.
2. Runtime decides whether compaction is allowed in the current query source.
3. Compaction worker prepares a reduced transcript, stripping or transforming content that should not dominate the summary.
4. Summary is generated.
5. Post-compact cleanup restores critical state such as memory hints, plans, file references, or task-adjacent context.
6. A compact boundary is recorded so later turns understand that history was intentionally collapsed.

## Guardrails

- compaction must not recurse forever when the compact request itself is too large
- some query sources should never auto-compact because they are already internal maintenance flows
- circuit breakers are required to stop repeated doomed compaction attempts
- post-compact rehydration is mandatory or the reduced transcript becomes misleading

## Failure branches

- **prompt-too-long while compacting**
- **not enough messages to compact meaningfully**
- **user-aborted compact**
- **compaction succeeded but dropped critical working context**
- **repeated failures leading to circuit-breaker shutdown**

The clean-room lesson is that compaction is a first-class recovery system, not just a convenience feature.
