---
title: "Permission Model"
owners: []
soft_links: [/ui-and-experience/interaction-feedback.md, /platform-services/auth-config-and-policy.md]
---

# Permission Model

Tool execution is controlled by an explicit permission context rather than ad hoc prompts.

The model should include:

- multiple permission postures, from conservative interactive approval to more automated modes
- per-tool allow, deny, and ask rules
- support for additional working directories beyond the main cwd
- different behavior for foreground sessions versus background agents that cannot interrupt the user
- sandbox-aware routing for shell and file operations
- safety filters for destructive commands, path escapes, and other high-risk actions

Permission state is session-critical. Temporary modes such as planning or automation can relax or tighten behavior, but the runtime must be able to restore the prior posture cleanly.
