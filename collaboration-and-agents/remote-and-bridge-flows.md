---
title: "Remote and Bridge Flows"
owners: []
soft_links: [/integrations/clients/client-surfaces.md, /platform-services/auth-config-and-policy.md, /collaboration-and-agents/remote-control-spawn-modes-and-session-resume.md, /collaboration-and-agents/repl-remote-control-lifecycle.md]
---

# Remote and Bridge Flows

Claude Code supports work that does not stay entirely inside one local terminal process.

Capabilities in this area include:

- remote agent sessions for long-running or heavyweight work
- bridge layers that connect local terminal state with remote execution or companion surfaces
- interactive sessions whose REPL can keep an always-on Remote Control bridge alive through explicit command, startup auto-connect, or outbound-only mirror mode
- standalone remote-control hosting that can stay as one resumable session or become a persistent multi-session host with shared-directory versus worktree-isolated placement
- direct-connect or session-handoff flows that require auth, transport setup, and repo identity checks
- resume and cross-machine handoff behavior that brings remote results back into the local working context

A correct reimplementation should treat transport, auth, and repository validation as first-class concerns. Remote handoff is part of the product experience, not a hidden implementation trick.
