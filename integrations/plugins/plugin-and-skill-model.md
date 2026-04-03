---
title: "Plugin and Skill Model"
owners: []
soft_links: [/collaboration-and-agents/multi-agent-topology.md, /platform-services/auth-config-and-policy.md]
---

# Plugin and Skill Model

Plugins and skills solve different problems and should stay distinct in a clean-room design.

Plugins:

- executable extensions that add commands, behavior, or integrations
- require validation, trust decisions, lifecycle management, versioning, and marketplace or cache support

Skills:

- reusable task guidance and domain instructions loaded into the agent
- can be bundled, discovered locally, or synthesized from other integration sources
- shape how work is done without being equivalent to executable plugins

The extension model should support bundled defaults, user-managed additions, reload flows, validation errors, and explicit trust warnings.
