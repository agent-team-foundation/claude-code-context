---
title: "End-to-End Scenario Graphs"
owners: []
soft_links: [/runtime-orchestration/review-path.md, /runtime-orchestration/resume-path.md, /memory-and-context/compact-path.md, /collaboration-and-agents/remote-handoff-path.md]
---

# End-to-End Scenario Graphs

This node captures the user-facing chain that rebuilders must preserve:

`user journey -> command -> runtime subsystem -> tool or task -> state transition`

These scenarios intentionally omit code-level detail and focus on product behavior.

## Review

```mermaid
flowchart LR
  A["User wants confidence in a change"] --> B["/review or remote review entry"]
  B --> C["Command resolves to local prompt path or remote review path"]
  C --> D["Runtime selects local query loop or remote-agent handoff"]
  D --> E["Tools or tasks gather PR context, diffs, and verification signal"]
  E --> F["State shifts to analysis, verification, and review completion"]
```

## Resume

```mermaid
flowchart LR
  A["User wants to continue prior work"] --> B["/resume, --continue, --resume, or teleport resume"]
  B --> C["Session locator resolves picker, session ID, title match, or remote session"]
  C --> D["Runtime restores transcript, session state, cwd, and mode context"]
  D --> E["Optional tools or transport steps recover missing branch or repo state"]
  E --> F["State shifts from dormant session to active continuation"]
```

## Compact

```mermaid
flowchart LR
  A["Long session approaches context pressure"] --> B["Auto, reactive, or manual compact trigger"]
  B --> C["Runtime evaluates budget and selects compaction path"]
  C --> D["Compaction worker summarizes and preserves required state"]
  D --> E["Post-compact cleanup rehydrates critical context"]
  E --> F["State shifts back to active turn with reduced history weight"]
```

## Remote handoff

```mermaid
flowchart LR
  A["User wants work to continue or move off-machine"] --> B["Teleport, remote review, or remote session launch"]
  B --> C["Runtime validates auth, repo identity, and handoff mode"]
  C --> D["Remote session or bridge transport is established"]
  D --> E["Tasks, messages, and permission loops are routed across surfaces"]
  E --> F["State shifts to coupled local and remote continuation or returns with results"]
```

## Design takeaway

The key reconstruction insight is that commands are not the real architecture. The real architecture is a set of reusable execution chains that commands enter at different points.
