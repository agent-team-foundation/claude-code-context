---
title: "Background Housekeeping and Deferred Maintenance"
owners: []
soft_links: [/platform-services/interactive-startup-and-project-activation.md, /platform-services/bootstrap-and-service-failures.md, /memory-and-context/auto-dream-consolidation-and-locking.md, /integrations/plugins/skill-improvement-detection-and-apply-flow.md, /integrations/plugins/plugin-management-and-marketplace-flows.md]
---

# Background Housekeeping and Deferred Maintenance

Claude Code has a background-housekeeping orchestrator that starts opportunistic services and postpones disruptive cleanup until the session is warm enough to tolerate it. This is not the same as core startup, trust gating, or the first-render prefetch tier. A faithful rebuild needs the exact start timing, idle deferral, and long-running-session cleanup rules, or optional maintenance will either slow first interaction or quietly never happen.

## Scope boundary

This leaf covers:

- when background housekeeping starts in interactive versus headless flows
- the immediate fire-and-forget services that housekeeping boots
- the delayed "very slow operations" tier and its user-activity gate
- the recurring long-running-session cleanup cadence
- the process-lifetime and failure-handling rules for those timers

It intentionally does not re-document:

- the broader startup pipeline already covered in [interactive-startup-and-project-activation.md](interactive-startup-and-project-activation.md)
- deeper auto-dream internals already covered in [../memory-and-context/auto-dream-consolidation-and-locking.md](../memory-and-context/auto-dream-consolidation-and-locking.md)
- the detailed skill-improvement detector already covered in [../integrations/plugins/skill-improvement-detection-and-apply-flow.md](../integrations/plugins/skill-improvement-detection-and-apply-flow.md)
- marketplace refresh and plugin update internals already covered in [../integrations/plugins/plugin-management-and-marketplace-flows.md](../integrations/plugins/plugin-management-and-marketplace-flows.md)

## Startup entry contract

Equivalent behavior should preserve:

- interactive REPL sessions not starting background housekeeping at mount time
- the interactive path only starting housekeeping after the first real submit, so a user who opens the REPL but never works does not immediately pay for maintenance traffic
- headless non-bare sessions starting housekeeping immediately during startup because there is no human-first-render typing budget to protect
- bare mode skipping this whole housekeeping layer
- headless startup treating housekeeping as optional bookkeeping that scripted calls can safely omit in stripped-down modes because a later interactive session can reconcile the missed maintenance
- deferred prefetch and background housekeeping staying conceptually separate even when the headless path starts them back-to-back

## Immediate fire-and-forget bootstraps

Equivalent behavior should preserve:

- housekeeping immediately kicking off several independent background capabilities without awaiting them
- MagicDocs initialization being booted from this orchestrator rather than from the first explicit docs command
- skill-improvement detection being booted from the same orchestrator rather than from the first skill UI render
- auto-dream registration happening here as a once-at-startup hook bootstrap rather than being lazily initialized only after memory pressure is already visible
- extract-memories bootstrapping remaining feature-gated and only running when its compile-time feature is present
- plugin marketplace auto-update starting silently in the background without blocking ordinary user interaction
- deep-link protocol registration only being attempted when the relevant feature is enabled and the session is interactive
- each bootstrapped service remaining responsible for its own inner rollout gates, current-state checks, and early no-op exits instead of forcing the orchestrator to understand every service's semantics

## Deferred slow-maintenance tier

Equivalent behavior should preserve:

- one delayed maintenance timer whose job is to wait roughly ten minutes after housekeeping starts before running the truly slow tasks
- an activity gate before those slow tasks begin: if the user interacted within the last minute, the slow-maintenance tier should back off and retry later instead of competing with active work
- the retry delay after an activity collision staying at the same long delay window rather than busy-polling every few seconds
- a one-time `needsCleanup` flag ensuring transcript and artifact cleanup runs at most once for that housekeeping lifetime
- old message, session, plan, and file-history cleanup running before the old-version cleanup step
- a second activity check after the first cleanup pass and before version cleanup, so a newly active user still postpones the heavier version-pruning step
- the first delayed cleanup pass using the regular old-version cleanup entrypoint rather than the daily-throttled wrapper used for long-running recurring maintenance

## Long-running recurring cleanup

Equivalent behavior should preserve:

- long-lived sessions scheduling a recurring maintenance interval at roughly twenty-four-hour cadence
- that recurring interval being ant-only
- the recurring interval cleaning npm cache entries for Anthropic packages and running the throttled old-version cleanup wrapper
- the recurring old-version cleanup using per-machine marker files and lockfiles so it runs at most once per day even if many processes are alive
- npm cache cleanup following the same "skip if recent, skip if another process holds the lock" pattern
- recurring maintenance being allowed to silently no-op on most days because the helpers themselves decide whether enough time has passed
- the recurring tier being about ongoing disk hygiene for long-running sessions, not about replacing installer-time or startup-time cleanup paths

## Process-lifetime contract

Equivalent behavior should preserve:

- housekeeping timers being detached from process lifetime so they do not keep Claude Code alive on their own
- both the delayed slow-maintenance timeout and the recurring cleanup interval being `unref`-style background timers
- housekeeping using fire-and-forget async jobs rather than adding a new mandatory await barrier to startup or submit handling
- optional background services failing independently without cancelling sibling background tasks
- cleanup helpers and other bootstrapped services being expected to self-throttle or self-noop when already current, already cleaned, disabled, or unsupported

## Relationship to adjacent subsystems

Equivalent behavior should preserve:

- background housekeeping being the shared orchestration layer for several otherwise unrelated maintenance features
- that orchestration layer booting auto-dream and skill-improvement detection early, while leaving their actual runtime decisions to their own modules
- plugin marketplace auto-update piggybacking on the same background slot so restart-worthy extension maintenance does not delay first interaction
- deep-link registration being treated as maintenance of an OS integration artifact, not as a prerequisite for the core REPL
- the broader startup pipeline still owning trust, cwd activation, and first-render protection; housekeeping only begins after those boundaries say the session is ready for opportunistic work

## Failure modes

- **first-turn slowdown**: interactive sessions start housekeeping too early and make the prompt feel busy before the user has even submitted once
- **scripted overwork**: bare or minimal headless sessions pay for interactive-only maintenance they do not benefit from
- **idle misfire**: slow cleanup runs during recent user activity because the last-interaction gate or retry timing is wrong
- **cleanup storm**: recurring version or npm-cache cleanup lacks marker-and-lock throttling and multiple processes all do the same expensive work
- **immortal timers**: housekeeping timers keep the process alive after useful work is done
- **service entanglement**: a failure in MagicDocs, skill improvement, auto-update, or cleanup blocks unrelated background services or bubbles up as a startup failure
