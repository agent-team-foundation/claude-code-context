---
title: "Interactive Startup and Project Activation"
owners: []
soft_links: [/platform-services/startup-service-sequencing-and-capability-gates.md, /platform-services/bootstrap-and-service-failures.md, /platform-services/workspace-trust-dialog-and-persistence.md, /platform-services/trust-and-capability-hydration.md, /platform-services/settings-change-detection-and-runtime-reload.md, /platform-services/usage-analytics-and-migrations.md, /runtime-orchestration/worktree-session-lifecycle.md, /product-surface/command-runtime-matrix.md]
---

# Interactive Startup and Project Activation

Claude Code startup is not one monolithic init call. The local interactive product has a staged activation pipeline: import-time prewarm, cwd-sensitive setup, trust gating, post-trust capability activation, and a later deferred-prefetch phase after the UI is already alive. Rebuilding the individual services without this ordering contract will still produce the wrong product.

Shared service-waiter creation, managed-settings/policy/sync join points, and the headless-versus-bare startup split live in [startup-service-sequencing-and-capability-gates.md](startup-service-sequencing-and-capability-gates.md). This leaf focuses on the interactive local activation pipeline layered on top.

## Import-time prewarm and eager normalization

Equivalent behavior should preserve:

- a tiny set of import-time side effects that start profiling and prewarm slow host reads before the rest of the module graph finishes loading
- early normalization of entrypoint, cwd, session identity, and flag-scoped settings sources before deeper startup logic starts caching state from the filesystem
- safety-sensitive environment hardening and warning-handling being installed before later startup code can spawn child processes or emit noisy terminal warnings
- startup migrations and cache-warming reads being allowed to begin early, while still remaining subordinate to later trust and project-activation boundaries

The clean-room point is that startup does not wait until "the app is initialized" to begin all work. Some background reads intentionally overlap with module evaluation so later interactive startup is faster.

## Cwd-sensitive setup before command activation

Equivalent behavior should preserve:

- one dedicated setup phase running before any logic that depends on the active working directory, worktree posture, or hook snapshot
- the active cwd being established before hooks are snapshotted, so hook configuration is captured from the correct project
- cwd-derived hook watching being initialized from that same early snapshot rather than from a later, potentially drifted directory state
- startup worktree creation running before the command catalog is finalized, so command availability and later project identity reflect the final checkout rather than the pre-worktree directory
- bundled skills and bundled plugins registering before command-catalog preloading, so the first command snapshot does not accidentally memoize an empty bundled-extension surface
- command and agent catalog preloading overlapping with setup only when startup is guaranteed not to change cwd mid-flight; worktree-changing startup must serialize those steps

This phase is where Claude Code decides which directory the rest of startup is really about.

## Trust gate before project-scoped execution

Equivalent behavior should preserve:

- the interactive trust and onboarding surface appearing before the REPL becomes fully active, even though some earlier parsing and safe cache reads have already happened
- trust rejection or early shutdown aborting the rest of project activation instead of letting post-trust services keep initializing in the background
- capability or entitlement checks that need authenticated trusted context being deferred until after the trust gate completes
- assistant, remote-control, LSP, project-scoped helpers, and other execution-capable integrations being kept behind that same trust boundary
- the startup timer used for product-health measurement being recorded before human-paced dialogs such as trust, onboarding, login, or resume pickers would otherwise distort the metric

The important distinction is that startup may inspect enough state to decide whether it can continue, while still refusing to activate repo-controlled execution surfaces until trust is settled.

## Post-trust activation before the loop is warm

Equivalent behavior should preserve:

- post-trust refresh of auth-dependent or entitlement-dependent clients before those services decide what the session is allowed to do
- worktree-entered startup re-reading settings and hook state from the new checkout before the rest of activation treats that worktree as the project root
- shared managed-settings/policy startup loads already having been launched under the startup service sequencing contract, so post-trust activation joins or reacts to them instead of redefining their fetch lifecycle
- settings validation, remote-control eligibility, and other trust-dependent warnings surfacing only after the trust gate rather than during the pre-trust phase
- session-start hooks and MCP connection warmup being allowed to overlap with one another after trust, while still avoiding duplicate startup-trigger execution on resume-like paths
- MCP resource preconnect and similar optional integration warmups staying non-blocking for the interactive loop, so a slow server does not postpone first useful interaction

This is the phase where the product moves from "trusted enough to continue" to "fully activated session with optional capabilities arriving in parallel."

## First-render boundary and deferred work

Equivalent behavior should preserve:

- a real first-render boundary after which latency-hiding work can begin without delaying the initial interactive surface
- heavy but deferrable prefetches such as user context, system context, tips, model-capability refresh, analytics gates, file counters, and change detectors starting only after that boundary
- startup code distinguishing "needed before first render" from "useful before first query" rather than treating all cache warmups as equally urgent
- headless or non-interactive callers being allowed to start some of these prefetches earlier because there is no human-first render to protect
- the deferred phase remaining optional in stripped-down modes, so bare or scripted sessions can skip first-turn UX optimizations that are pure overhead for them

The clean-room insight is that "as soon as possible" is not the same as "before render." Claude Code deliberately saves some startup work for the moment after the UI is already responsive.

## Mode-specific startup branches

Equivalent behavior should preserve:

- startup `--worktree` being allowed to change the project's effective root before command loading, while mid-session worktree entry remains a separate later runtime concern
- non-interactive or print-style sessions treating trust as implicit and therefore applying the fuller project environment earlier than the interactive REPL path would allow, while still preserving richer headless joins such as hooks, MCP connect, plugin/state refresh, and immediate deferred prefetch
- bare mode, by contrast, cutting away hooks, plugin-sync helpers, LSP startup, attribution helpers, and most background prefetches without skipping minimal safety checks or core session bookkeeping
- resume-like flows, remote-control attach, and other specialized entry paths reusing as much of the shared startup pipeline as possible while still short-circuiting the parts that would double-run ownership or startup hooks

Headless and bare are therefore different branches: headless is trust-implicit but still feature-rich, while bare is intentionally stripped down.

This is how one codebase supports multiple entry surfaces without silently drifting into different products.

## Failure modes

- **cwd race**: command discovery, hook snapshotting, or project identity are computed before startup has finished choosing the final directory
- **pre-trust execution leak**: LSP, remote-control, helpers, or full project environment activate before the trust gate is resolved
- **false parallelism**: setup and command loading are overlapped even though startup worktree creation can still move cwd underneath them
- **first-render stall**: optional prefetches, detectors, or plugin startup checks run too early and make the terminal feel hung before the user can act
- **post-shutdown drift**: trust rejection or another early-exit path starts graceful shutdown, but later activation phases keep running anyway
- **mode-branch skew**: bare, print, resume, or worktree startup paths silently skip or duplicate steps that the rest of the runtime assumes already happened
