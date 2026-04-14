---
title: "Root CLI Flag Contracts and Bootstrap Overrides"
owners: []
soft_links:
  - /product-surface/interaction-modes.md
  - /product-surface/startup-entrypoint-routing-and-session-handoff.md
  - /runtime-orchestration/sessions/resume-path.md
  - /integrations/clients/structured-io-and-headless-session-loop.md
  - /tools-and-permissions/permissions/permission-mode-transitions-and-gates.md
  - /integrations/mcp/config-layering-policy-and-dedup.md
  - /integrations/plugins/plugin-source-precedence-and-cache-loading.md
  - /integrations/plugins/skill-loading-contract.md
  - /platform-services/interactive-startup-and-project-activation.md
  - /runtime-orchestration/turn-flow/turn-attachments-and-sidechannels.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/released-cli-e2e-test-set.md
---

# Root CLI Flag Contracts and Bootstrap Overrides

The top-level `claude` entrypoint is not just a prompt-or-subcommand switch. Public root flags can change whether the runtime starts a REPL or a headless session, which settings and integrations are even loaded, what tools or prompts the first turn sees, how continuation is validated, and whether startup-local files must exist before the UI renders.

A faithful rebuild needs those launch-time overrides as one explicit contract. If they are modeled only as scattered option handlers, the rewrite will accept familiar flags while quietly booting the wrong session shape.

## Scope boundary

This leaf covers:

- public root flags on `claude` that materially reshape session startup before the first ordinary turn
- headless-only output and streaming gates
- launch-time injection of prompts, settings, extra directories, MCP config, plugins, agents, tools, and permission posture
- continuation, naming, and deterministic session-ID validation at process start
- startup file-resource downloads triggered by the public `--file` flag
- the version-sensitive minimal or hermetic `--bare` posture exposed by the analyzed source snapshot

It intentionally does not re-document:

- the deeper structured transport protocol already captured in [../integrations/clients/structured-io-and-headless-session-loop.md](../integrations/clients/structured-io-and-headless-session-loop.md)
- the full resume restoration internals already captured in [../runtime-orchestration/sessions/resume-path.md](../runtime-orchestration/sessions/resume-path.md)
- the full MCP, plugin, skill, or permission engines beyond how root flags shape them at launch
- hidden debug, analytics, or internal-only flags unless they affect a visible compatibility rule

## Root flags mutate canonical startup state, not side channels

Equivalent behavior should preserve:

- root flags being interpreted before the normal session loop or local slash-command handling begins
- early validation failures staying fail-closed and user-visible instead of accepting an incompatible flag set and silently degrading later
- flag effects writing into the same canonical startup state used by the rest of the product, not into one-off alternate code paths that drift from ordinary runtime behavior
- launch-time flag shaping being visible to the real live session that follows, including the command catalog, tool pool, settings view, and session metadata seen by later surfaces

The clean-room point is that "accepted by commander" is not enough. A rebuild must preserve which startup flags truly change the launched session and which combinations are refused.

## Headless and structured-output flags are one launch family

Equivalent behavior should preserve:

- `-p/--print` switching the root entrypoint into a headless or non-interactive session loop instead of the normal REPL
- `--output-format` only mattering on that headless path, with distinct text, JSON-envelope, and stream-JSON outcomes
- `--input-format stream-json` requiring the structured headless path instead of being accepted in the interactive REPL
- stream-JSON output remaining gated by the observed packaging rules, including the visible compatibility checks around verbose or streaming posture
- `--include-partial-messages` and `--replay-user-messages` being stream-oriented launch modifiers, not generic flags that do anything useful on ordinary text output
- `--json-schema` enabling a dedicated structured machine-output channel instead of pretending the human-readable `result` field itself becomes schema-stable
- `--no-session-persistence` being headless-only and severing ordinary later continuation semantics for that invocation
- budget- or fallback-style flags such as `--max-budget-usd` and `--fallback-model` behaving like headless launch posture controls rather than ordinary long-lived settings mutations

The important reconstruction rule is that print-mode flags are not just formatting sugar. They switch the product onto a different session surface with narrower compatibility rules.

## Continuation, identity, and naming are validated before the session boots

Equivalent behavior should preserve:

- `--continue` and `--resume` remaining continuation requests, not aliases for a fresh session with copied transcript text
- explicit `--session-id` validation happening before local startup continues, including early rejection of malformed local UUIDs
- local fresh-session IDs being rejected when they would collide with an already existing session identity
- `--session-id` staying restricted when it is paired with `--continue` or `--resume`, so fresh IDs do not silently overwrite an existing continuation path unless a fork-style branch of behavior was explicitly requested
- remote or tagged session-ID modes being allowed to bypass local UUID-only assumptions when the session authority is no longer purely local
- `-n/--name` acting as a startup display-name override that affects the live session identity surface, including resume-facing labels and terminal-title style affordances, without creating orphaned session artifacts before the real session exists

The product requirement is that these flags shape session identity before the first turn, not after the runtime already committed to another session lineage.

## Launch-time bootstrap injection is explicit and source-aware

Equivalent behavior should preserve:

- `--settings` being able to inject either a path-backed settings layer or an inline JSON layer at launch
- `--setting-sources` being parsed early enough that later settings loading, plugin state, and other source-aware bootstrap steps actually honor the narrowed source set
- `--system-prompt` and `--append-system-prompt` feeding the canonical system-prompt builder used by real turns rather than a separate prompt wrapper
- mutually exclusive prompt-source variants failing closed when incompatible prompt flags are supplied together
- `--add-dir` expanding more than simple filesystem reach: it also contributes explicit extra discovery roots for instruction or skill surfaces that are allowed to honor explicit external directories
- `--mcp-config` accepting both file-backed and inline JSON MCP definitions as explicit launch-time injection
- `--strict-mcp-config` narrowing the live MCP surface to only the explicitly supplied MCP config instead of merely adding extra servers on top of all other discovery sources
- `--plugin-dir` acting as session-only plugin injection that changes the live command, hook, MCP, agent, or LSP surface for that process only
- session-only plugin injection still remaining subordinate to higher-precedence administrative or managed restrictions instead of becoming a bypass path
- `--agents` injecting session-scoped custom agent definitions while `--agent` selects the active agent for the launched session
- `--tools`, `--allowedTools`, and `--disallowedTools` shaping the real initial tool surface, not merely decorating the prompt or only affecting one later sub-flow
- `--permission-mode` entering through the same centralized permission-mode transition model used by interactive changes later in the session
- `--allow-dangerously-skip-permissions` acting as an explicit launch-time opt-in that makes a full bypass posture legally available without necessarily forcing the session to start there immediately
- `--dangerously-skip-permissions` acting as a stronger launch request that still must survive the product's startup safety gates instead of bypassing them blindly
- later attempts to enter `bypassPermissions` remaining invalid when the session was not launched with the required dangerous-bypass opt-in posture
- startup toggles such as `--ide`, `--chrome`, and `--no-chrome` remaining launch-time integration posture controls rather than synthetic transcript commands

The reconstruction-critical point is that these flags do not all have the same precedence or persistence, but they do all belong to one startup override family.

## Explicit launch inputs stay explicit even when discovery is narrowed

Equivalent behavior should preserve:

- explicit launch-time injections continuing to matter even when automatic discovery is otherwise narrowed
- source filters, plugin locks, and policy gates still being allowed to refuse some explicit inputs when the product's security or governance contract requires it
- explicit additions such as `--add-dir`, `--plugin-dir`, `--agents`, or `--mcp-config` not being quietly dropped just because ordinary auto-discovery was reduced
- discovery narrowing and policy narrowing staying distinct concepts: one changes what the product auto-loads, while the other can still block explicit user intent

This distinction is load-bearing because the observed product treats "skip what I did not ask for" differently from "pretend what I asked for never existed."

## `--bare` is a version-sensitive minimal posture, not an imaginary flag

The analyzed source snapshot exposes a public or minimally public `--bare` launch mode that is not advertised in the local `claude 2.1.19` help surface on this machine. A faithful rebuild should therefore treat bare mode as **version-sensitive and evidence-backed**, not as a universal guarantee and not as an invented internal-only rumor.

Equivalent behavior should preserve:

- bare mode acting as one-switch minimal or hermetic startup posture rather than as a random pile of small feature disables
- bare mode suppressing broad classes of automatic bootstrap work such as hook execution, automatic discovery, background prefetch, plugin sync, LSP startup, auto-memory, keychain or OAuth convenience reads, and similar non-essential startup layers
- bare mode still honoring explicit launch-time inputs such as injected prompts, explicit settings, extra directories, explicit MCP config, injected agents, or session-only plugins when those inputs are otherwise allowed
- bare mode narrowing first-party auth posture toward explicit API-key-style or similarly hermetic credentials instead of silently falling back to keychain or browser-backed OAuth discovery
- bare mode not bypassing policy or managed locks; it is a narrower startup mode, not an admin override

The clean-room insight is that bare mode means "skip ambient discovery and convenience," not "ignore explicit intent" and not "disable security."

## `--file` seeds startup-local files before the session becomes usable

Equivalent behavior should preserve:

- `--file <file_id>:<relative_path>` acting as a real root-entrypoint bootstrap flag rather than a later slash-command surface
- repeated file specs and space-expanded file-spec groups being parsed into one launch-time download list
- malformed file specs not producing half-valid path state; invalid entries should fail or be skipped explicitly rather than silently mutating arbitrary files
- startup file downloads requiring a session-ingress-style auth token and failing early with a clear error when that token is unavailable
- the session identity used for file download pathing preferring the authoritative remote session identity when one exists, and otherwise using the local session identity
- download targets being normalized into a session-scoped uploads namespace under the current workspace instead of writing arbitrary absolute destinations
- path traversal above that workspace-scoped upload area being rejected explicitly
- redundant incoming `uploads/` prefixes being cleaned up so callers do not accidentally create doubly nested upload directories
- downloads being allowed to start early in startup, but the REPL or first interactive use still waiting until those files are locally available
- bounded parallel download behavior instead of one fully serial fetch path for multi-file startup bundles
- partial per-file failure surfacing as a visible warning summary while catastrophic download-path failures still fail the launch
- successfully downloaded files becoming normal local artifacts for later prompt, attachment, or tool flows rather than remaining remote-only opaque handles

This flag matters because it turns a remote file handle into local pre-turn state. If a rebuild omits that bridge, the same public command line will launch into a materially different working context.

## Failure modes

- **accepted-but-ignored flags**: the CLI parser accepts a public launch flag, but startup never mutates the real session state that later surfaces read
- **headless compatibility leak**: stream-oriented or no-persistence flags appear to work outside the headless path and then silently degrade
- **source-filter bypass**: `--setting-sources` or `--strict-mcp-config` is parsed, but later loaders still read suppressed sources
- **tool-surface drift**: `--tools`, `--allowedTools`, or `--disallowedTools` changes one code path but not the actual live tool pool presented to the session
- **bare-mode amnesia**: minimal mode suppresses automatic discovery but also wrongly discards explicit launch-time inputs the user asked for
- **policy bypass through explicit injection**: `--plugin-dir`, `--mcp-config`, or `--add-dir` is treated as stronger than managed or policy restrictions when the observed product would still block it
- **continuation identity clobber**: `--session-id` or `--name` is applied too late and overwrites existing continuation state incorrectly
- **upload-path escape**: `--file` writes outside the session-scoped upload namespace or double-nests upload roots unpredictably
- **startup file race**: the REPL renders before required downloaded files exist locally, so the first visible turn sees a different workspace than the user requested

## Test Design

In the observed source and local CLI evidence, this area is protected by packaged CLI acceptance behavior, headless protocol tests, and runtime comparison checks across real entrypoints.

Equivalent coverage should prove:

- root-entry flag parsing, incompatibility checks, and fail-closed error messages match the packaged CLI behavior
- headless text, JSON, stream-JSON, schema-output, replay, and no-persistence paths preserve their public compatibility matrix
- session identity, continuation, and naming flags shape startup state before the first turn and survive later resume-facing inspection correctly
- explicit source-injection flags for settings, extra dirs, MCP, plugins, agents, tools, and permission posture actually change the launched session in the expected precedence order
- version-sensitive `--bare` behavior is either reproduced for the targeted version or explicitly marked as unsupported for that version instead of being silently ignored
- `--file` path normalization, auth-token requirements, partial-failure warnings, and pre-render availability are covered with deterministic fixtures rather than only live remote downloads
