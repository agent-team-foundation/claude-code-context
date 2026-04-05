---
title: "Remote Handoff Path"
owners: []
soft_links: [/product-surface/command-execution-archetypes.md, /collaboration-and-agents/remote-session-contract.md, /collaboration-and-agents/bridge-contract.md]
---

# Remote Handoff Path

Remote handoff covers the transition from a local coding session into a remote or cross-machine execution context and back again.

## Main variants

- hand off a new task to a remote environment
- resume an existing remote or web-backed session from a local machine
- launch remote review or planning work and keep a local task handle
- attach a bridge or companion client to an active session

## Handoff sequence

1. User expresses intent to move work off-machine or continue elsewhere.
2. Runtime validates preconditions:
   auth, policy, repository state, working-tree cleanliness, and remote feature availability.
3. Runtime decides what is being handed off:
   repository clone, branch reference, bundle, or existing remote session.
4. Remote session is created or located.
5. Local session records enough metadata to reconnect, resume, or surface results.
6. Branch, transcript, and session identity are reconciled on return.

## State transitions

- local ready -> handoff requested
- handoff requested -> preflight passed or blocked
- preflight passed -> remote session established
- remote session established -> local observer or coupled-controller state
- coupled-controller state -> resumed locally or archived remotely

## Failure branches

- **dirty local repo blocks handoff**
- **auth insufficient for remote session APIs**
- **repository mismatch between local checkout and remote session**
- **branch checkout fails on return, but transcript can still resume**
- **transport dies mid-handoff and leaves local state uncertain**

The key reconstruction principle is that remote handoff is a coordinated state transition across identity, repository, transcript, and permission systems.
