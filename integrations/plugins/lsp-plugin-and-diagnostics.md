---
title: "LSP Plugin and Diagnostics"
owners: []
soft_links: [/integrations/plugins/plugin-runtime-contract.md, /tools-and-permissions/tool-pool-assembly.md, /ui-and-experience/interaction-feedback.md]
---

# LSP Plugin and Diagnostics

Claude Code's LSP layer is not a generic editor integration bolted onto the side. It is a plugin-fed subsystem with its own trust boundary, lazy startup path, request-routing contract, passive diagnostic attachment flow, and recommendation loop for installing missing LSP plugins. A faithful rebuild needs all of those pieces or the product will either expose dead LSP tools, execute untrusted plugin code too early, or surface diagnostics in noisy and inconsistent ways.

## Scope boundary

This leaf covers the end-to-end path from plugin-declared LSP server definitions through runtime activation, request routing, passive diagnostics, edit-triggered refresh behavior, and LSP plugin recommendation UX.

It intentionally does not cover:

- the generic plugin discovery and admission lifecycle already summarized in [plugin-runtime-contract.md](plugin-runtime-contract.md)
- the full dynamic tool-pool model already summarized in [tool-pool-assembly.md](../../tools-and-permissions/tool-pool-assembly.md)
- the full terminal dialog hierarchy or global interaction model beyond the LSP-specific recommendation and diagnostic surfaces
- generic MCP IDE diagnostics as a standalone subsystem, except where edit tools coordinate with LSP diagnostic refresh

## Plugin-only source of truth

Equivalent behavior should preserve:

- LSP servers being sourced only from enabled plugins, not from user settings, project settings, or a separate top-level LSP config file
- plugin loading happening through the same enabled-plugin set that powers other dynamic extension surfaces
- one plugin being able to declare LSP servers through either a `.lsp.json` file in the plugin directory or `manifest.lspServers`
- `manifest.lspServers` supporting inline objects, relative file paths, or arrays that mix those forms
- relative manifest file references being validated to stay inside the plugin directory so path traversal cannot escape the plugin root
- invalid or unreadable plugin LSP declarations becoming plugin errors rather than crashing the whole subsystem
- multiple plugin LSP configs being merged into one runtime server map, with later merged entries preserving precedence just like other plugin materialization passes

## Server config shaping and scoping

Equivalent behavior should preserve:

- per-server validation requiring at least a command and an `extensionToLanguage` map before a server can participate
- plugin-specific variable substitution happening before final server activation
- plugin LSP configs being able to reference plugin-root, plugin-data, user-config, and ordinary environment variables
- user-config substitution only running when the plugin actually declares `userConfig`, so ordinary plugins do not pay unnecessary option-loading cost or fail on missing `user_config.*` placeholders
- missing environment variables being logged as warnings without blocking the whole plugin
- every plugin-provided server name being rewritten into a scoped runtime name such as `plugin:<pluginName>:<serverName>` so plugins cannot collide on bare server identifiers
- plugin LSP servers carrying dynamic scope and source metadata so downstream error reporting can attribute failures to the owning plugin

## Trust, startup, and refresh gates

Equivalent behavior should preserve:

- LSP initialization being deferred until workspace trust is established in interactive mode
- non-interactive execution treating trust as implicit and therefore allowing post-setup LSP initialization without the interactive trust dialog
- bare or simple mode skipping the LSP subsystem entirely
- the startup path creating an LSP manager singleton synchronously, then performing server-config initialization asynchronously in the background
- explicit initialization states for `not-started`, `pending`, `success`, and `failed`, so callers can distinguish "not ready yet" from "broken"
- a generation counter invalidating stale initialization promises when a refresh or retry happens mid-flight
- plugin refresh forcing an LSP reinitialization even after prior success, so new plugin LSP servers appear and removed ones stop lingering in config
- that refresh path reloading plugin LSP metadata unconditionally, not only when a plugin count changed
- `/reload-plugins` reporting plugin LSP server counts separately from plugin MCP servers and from built-in or user-configured integrations

## Manager lifecycle and file-type routing

Equivalent behavior should preserve:

- one manager instance owning all configured LSP server instances for the session
- manager initialization eagerly building an extension-to-server routing table from every server's `extensionToLanguage` map
- multiple servers being allowed to claim the same extension, with current runtime routing taking the first registered server rather than doing dynamic arbitration
- server instances being created during manager initialization but not necessarily started yet
- actual child-process startup being lazy: a server only starts when a matching file is used
- servers in `stopped` or `error` state being restarted on the next relevant request
- a crash callback moving a server into `error` state immediately so the manager does not keep treating a dead server as healthy
- crash recovery attempts being capped per server to avoid unbounded respawn loops
- reverse-direction `workspace/configuration` requests being answered with null placeholders, because Claude declares that it does not really implement configuration sourcing for LSP clients

## LSP server instance contract

Equivalent behavior should preserve:

- each server instance owning a lifecycle state machine with `stopped`, `starting`, `running`, `stopping`, and `error` semantics
- startup validating that not-yet-implemented config fields such as crash auto-restart policy or custom shutdown timeout are rejected instead of silently ignored
- server initialization using the plugin-configured command, args, env, and optional workspace folder
- initialization sending both modern workspace folders and legacy root fields so older servers still resolve project paths correctly
- client capabilities advertising only the subset Claude actually supports, especially around text synchronization, diagnostics, hover, definitions, references, document symbols, and call hierarchy
- startup timeout support when a server config specifies one
- transient `content modified` request failures being retried with bounded exponential backoff rather than failing instantly

## Tool exposure and request path

Equivalent behavior should preserve:

- the LSP tool only surfacing when the manager initialized successfully and at least one configured server is not in hard error state
- the tool waiting for pending manager initialization rather than prematurely claiming that no servers exist
- input validation confirming that the requested path is a real file and rejecting missing or non-file paths cleanly
- filesystem validation special-casing UNC-style paths to avoid unsafe network-path probing during validation
- the tool opening a file in the appropriate LSP server before making requests when that file was not already synchronized
- file content being read lazily and refused for very large files above the 10MB analysis cap
- request routing being driven by file extension, not by explicit user server choice
- unsupported file types returning a graceful "no LSP server available for this file type" result instead of failing the whole turn
- incoming and outgoing call queries using the required two-step protocol: prepare call hierarchy first, then request incoming or outgoing calls from the first prepared item
- location-heavy operations filtering out gitignored targets before formatting results back to the model
- malformed LSP results still being logged for diagnostics while returning a readable error or empty result to the caller

## File synchronization after edits

Equivalent behavior should preserve:

- edit and write tools capturing a pre-edit diagnostic baseline before mutating the file
- those same tools clearing any previously delivered passive LSP diagnostics for the edited file so identical future diagnostics can be shown again after the next change
- successful writes notifying the LSP manager with `didChange`
- successful writes also notifying the LSP manager with `didSave`, because some servers only recalculate diagnostics after save
- these LSP notifications being fire-and-forget so file tools do not block user-visible write success on language-server responsiveness
- change or save notification failures being logged without rolling back the already-completed file write
- an available but not-yet-fully-integrated `didClose` path existing for future compaction or context-eviction cleanup

## Passive diagnostic delivery

Equivalent behavior should preserve:

- LSP `textDocument/publishDiagnostics` notifications being registered only after successful manager initialization
- handler registration occurring per server, with one bad server not preventing other servers from delivering diagnostics
- incoming diagnostic payloads being validated structurally before use
- file URIs being converted into Claude's attachment-friendly diagnostic-file format, while malformed URIs degrade gracefully instead of crashing the notification loop
- empty diagnostic batches being dropped quietly
- diagnostics being buffered into a pending registry for later async attachment delivery rather than injected immediately into the visible transcript
- consecutive diagnostic-handler failures being tracked per server and escalated in debug logs after repeated failures
- partial registration failures being summarized so operators can tell which servers will never deliver passive diagnostics

## Deduplication, limiting, and re-delivery rules

Equivalent behavior should preserve:

- deduplication across the current pending batch by file URI plus diagnostic identity
- cross-turn deduplication so the same unresolved diagnostic is not reattached every turn forever
- delivered-diagnostic tracking using an LRU bound rather than an unbounded in-memory set
- per-file and total-volume caps, with higher-severity diagnostics surviving first
- severity ordering prioritizing errors over warnings, info, and hints
- diagnostics only being marked delivered after successful deduplication and limiting
- files with no remaining diagnostics after deduplication or truncation being omitted entirely
- file edits clearing the remembered delivered-diagnostic set for that file so a repeated post-edit diagnostic can legitimately reappear

## Recommendation and installation loop

Equivalent behavior should preserve:

- a separate recommendation path for users editing file types that could benefit from an LSP plugin they have not installed yet
- recommendations only considering marketplace plugins that advertise LSP servers in inline manifest data; plugins whose LSP config lives only in external `.lsp.json` files cannot be pre-recommended from marketplace metadata alone
- a candidate plugin only being recommended when its file-extension coverage matches the edited file, the plugin is not already installed, it is not on the user's never-suggest list, and the underlying LSP binary is already present on the system
- official marketplace plugins being sorted ahead of third-party candidates
- only one LSP recommendation being shown per session
- the recommendation dialog living in the same focus-priority band as other low-priority plugin hints and yielding to more important prompts
- the dialog auto-dismissing after thirty seconds and treating that path like an ignored recommendation
- repeated ignored recommendations eventually disabling the feature entirely
- users being able to install now, decline for now, never suggest this plugin again, or disable all LSP recommendations globally
- accepting the recommendation both caching or registering the plugin and enabling it in user settings so it survives restart

## User-facing surfaces

Equivalent behavior should preserve:

- `/reload-plugins` being the explicit interactive refresh path that rehydrates active plugin commands, hooks, MCP servers, and LSP servers together
- LSP diagnostic issues surfacing as async feedback rather than only as hidden debug logs
- the recommendation dialog presenting LSP as code intelligence for tasks such as go-to-definition and error checking, not as a vague plugin upsell
- plugin-install success from the recommendation flow feeding into the ordinary plugin activation pipeline instead of inventing a separate LSP-only install state

## Failure modes

- **early untrusted execution**: plugin LSP servers are initialized before trust is accepted and can execute plugin-declared commands in an untrusted checkout
- **stale plugin config**: plugin refresh updates commands or MCP servers but leaves the old LSP server map in memory
- **server collision**: two plugins declare the same bare server name and one silently overwrites the other because runtime scoping was skipped
- **dead tool exposure**: the LSP tool is shown even though initialization failed or no matching file-type server exists
- **diagnostic spam**: passive diagnostics are reattached every turn because cross-turn deduplication or per-file clearing rules are wrong
- **diagnostic starvation**: edits never clear delivered-diagnostic memory, so legitimately new post-edit diagnostics are suppressed as duplicates
- **recommendation thrash**: the same plugin suggestion reappears endlessly because ignore counters, never-suggest entries, or per-session suppression are not honored
- **false recommendation**: Claude recommends an LSP plugin whose binary is not installed, creating an install path that still leaves the user without a working server
