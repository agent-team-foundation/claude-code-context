---
title: "Query Loop"
owners: []
soft_links: [/memory-and-context/memory-layers.md, /tools-and-permissions/tool-families.md]
---

# Query Loop

The runtime centers on a streaming query loop rather than a one-shot request model.

Core responsibilities:

- Assemble message history plus system and user context before each turn.
- Select the active model and output budget for the turn.
- Stream assistant output incrementally instead of waiting for a full response.
- Execute tool calls mid-turn, append tool results, and continue the same trajectory.
- Recover from context pressure, output limits, and tool-related interruptions without discarding the session.
- Preserve provenance so later summarization, retry, resume, and analytics flows can explain what happened.

The architectural requirement is continuity. Tool use, retries, compaction, and continuation are part of one turn lifecycle and must be modeled that way.
