---
title: "Hooks and Event Surface"
owners: []
soft_links: [/integrations/clients/sdk-control-protocol.md, /ui-and-experience/feedback-state-machine.md, /integrations/plugins/plugin-runtime-contract.md]
---

# Hooks and Event Surface

Claude Code exposes more than command results. It also has a hookable event surface that lets clients, plugins, skills, and session-scoped logic react to runtime lifecycle changes.

The important layers are:

- **persistent hooks** loaded from configured settings, plugins, skills, or frontmatter-style project context
- **session-scoped hooks** attached only for the lifetime of one running session
- **client-visible hook events** emitted on a side channel that is separate from the ordinary transcript stream

Reconstruction requirements:

- Hooks must bind to named lifecycle events rather than fragile text matching against transcript output.
- The system should support matcher-based routing so only relevant hooks run for a given event or target.
- Session-local hooks need to exist as a first-class concept. They should be addable and removable at runtime without becoming durable user settings.
- Hook execution should expose at least three phases to observing clients: started, progress, and terminal response.
- Event delivery should tolerate late subscribers. If the client event handler attaches after hooks begin, recent pending events should still be replayable within a bounded buffer.

Noise control matters here. A correct rebuild should distinguish:

- a **small always-visible lifecycle set** that low-noise clients can safely consume
- an **expanded event stream** that richer SDK, remote, or debug surfaces can opt into

Hook outputs are not the transcript. They are auxiliary signals that a host can render as status rows, stream panels, SDK messages, or audit entries. The product shape depends on keeping that distinction intact.
