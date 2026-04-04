---
title: "Remote and Managed Client Envelopes"
owners: []
soft_links: [/collaboration-and-agents/remote-session-contract.md, /platform-services/auth-config-and-policy.md, /platform-services/sync-and-managed-state.md]
---

# Remote and Managed Client Envelopes

Claude Code clients can run inside envelopes that add remote environment selection, browser handoff, enterprise policy, or managed configuration on top of the shared runtime.

These envelopes should be reconstructed as wrappers around the same core runtime, not as separate products.

Important envelope behaviors:

- **remote environment selection** picks the execution target from an available environment set, while still honoring layered setting sources and surfacing where the effective choice came from
- **web or companion bootstrap** can use a local authenticated toolchain to help a browser or hosted client gain the credentials and environment metadata it needs
- **managed-client overlays** can inject organization-controlled settings, feature eligibility, and security checks before the user reaches ordinary session interaction
- **remote-session viewers** can present browser URLs, QR-style handoff, or other companion-surface affordances without changing session identity semantics

Reconstruction requirements:

- The user should be able to tell which remote environment will actually be used and why, including whether it came from defaults, local settings, or higher-priority managed configuration.
- Remote-capable clients must fail clearly when the missing piece is auth, GitHub connectivity, environment setup, or policy disallowance.
- Remote control and remote execution are related but distinct envelopes. One can proxy or observe a local session; the other can select or create a remote environment that executes work elsewhere.
- Managed settings must be able to constrain these envelopes without forcing a fork of the underlying runtime semantics.
- Browser handoff should be best-effort and user-visible. Opening a companion surface is part of the product flow, not an implementation detail hidden from the user.
- Session creation inside these envelopes should carry explicit repo, model, and permission context rather than assuming the remote side can infer them later.

This envelope model matters because many high-value Claude Code experiences are neither purely local nor purely server-side. They are negotiated clients around one shared session model.
