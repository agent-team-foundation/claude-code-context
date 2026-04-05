---
title: "Session Utility Commands"
owners: []
soft_links: [/runtime-orchestration/resume-path.md, /runtime-orchestration/session-artifacts-and-sharing.md, /runtime-orchestration/session-discovery-and-lite-indexing.md, /ui-and-experience/conversation-export-dialog.md, /ui-and-experience/resume-picker-search-preview-and-filters.md]
---

# Session Utility Commands

Claude Code keeps several slash commands focused on the current conversation as an artifact: naming it, optionally tagging it, extracting it, reopening it, or handing it off to another surface. These commands are small on the surface, but they encode which session metadata is first-class and which continuation paths are allowed to happen silently versus only through explicit user handoff.

## Scope boundary

This leaf covers:

- user-facing contracts for `/rename`, profile-gated `/tag`, `/copy`, `/export`, remote-only `/session`, and the slash-command surface of `/resume`
- which of those commands mutate session metadata immediately versus opening local UI flows
- how same-session, same-repo, same-worktree-family, and cross-project continuation are distinguished at the command surface

It intentionally does not re-document:

- transcript rehydration, snapshot restoration, reset lineage, and remote resume internals already covered in [../runtime-orchestration/resume-path.md](../runtime-orchestration/resume-path.md)
- picker-only search, preview, rename, and filter UX already covered in [../ui-and-experience/resume-picker-search-preview-and-filters.md](../ui-and-experience/resume-picker-search-preview-and-filters.md)
- `/export` dialog mode transitions, filename-entry UI, and clipboard-versus-file chooser behavior already covered in [../ui-and-experience/conversation-export-dialog.md](../ui-and-experience/conversation-export-dialog.md)

## Session metadata commands mutate live identity, not just disk

Equivalent behavior should preserve:

- `/rename` rejecting subordinate swarm or teammate sessions whose displayed identity is leader-owned
- `/rename <name>` trimming and persisting the new session title immediately
- bare `/rename` attempting to synthesize a name from the current conversation after the most recent compact boundary, and failing with guidance if not enough conversation context exists yet
- rename persistence updating both durable custom-title metadata and the standalone prompt-bar or agent display name used by the live session
- rename also best-effort syncing any paired remote session title without blocking the local command on network success
- `/tag` only existing when session tagging is enabled for the active build or profile, rather than being part of the universal baseline command set
- when present, `/tag` treating tag names as sanitized session metadata rather than raw freeform text
- same-tag invocation becoming an explicit remove-confirmation path, while a different tag replaces the old one directly
- missing session or empty tag input returning session-visible errors instead of silently no-oping
- help- or info-style tag invocations returning usage guidance instead of mutating state
- tags remaining first-class resume metadata, including visibility and searchability in resume surfaces

## Copy and export produce user-facing transcript artifacts, not raw logs

Equivalent behavior should preserve:

- `/copy` walking backward through only a bounded recent set of eligible assistant responses, rather than copying arbitrary transcript blocks
- tool-only assistant turns and API-error turns being skipped when building the copy candidate set
- `/copy N` selecting the Nth-latest eligible assistant response, with clear errors for invalid or too-large indices
- responses with no code-block ambiguity copying immediately, while mixed prose-plus-code responses can open a local picker unless the user's persistent preference says to always copy the full response
- that picker allowing whole-response copy, single-code-block copy, or a persistent "always copy full response" choice rather than forcing one policy forever
- clipboard copy staying best-effort and being paired with a temp-file fallback so the user still gets a recoverable result when terminal clipboard transport is partial
- individual code-block file exports deriving a sanitized extension from the declared code-block language instead of trusting arbitrary label text
- `/export` first rendering one plain-text conversation artifact and then either writing it directly when a filename argument is supplied or handing it to the dedicated export dialog when no filename is given
- direct filename export normalizing output to a plain-text suffix and rooting the write under the current working directory
- default export filenames deriving from the first line of the first user prompt when possible and otherwise falling back to a timestamped conversation name

## Resume and remote session inspection are guarded continuation surfaces

Equivalent behavior should preserve:

- `/session` only appearing when remote mode is active, rather than being a universal always-visible command
- `/session` being a local inspection command for remote-mode sessions rather than a model turn
- `/session` showing a remote session URL whenever one exists and attempting a QR rendering as a convenience rather than as a prerequisite
- if the local UI path is reached without remote state, it degrading to a clear "start in remote mode" message instead of crashing or turning into a model query
- bare `/resume` opening the interactive picker over an already-filtered resumable session set, with picker-only search, preview, filters, and cross-project handoff behavior staying in the dedicated resume-browser leaves
- slash-argument resume staying intentionally narrow: it first attempts exact session-ID resolution, including a fallback direct-log lookup when enriched session summaries omitted an otherwise valid session
- exact custom-title matches being able to bypass the picker when the title feature is enabled, while ambiguous title matches return an explicit disambiguation message instead of guessing
- failed direct slash-argument lookup returning an explicit not-found result instead of falling through into fuzzy or all-project search

## Failure modes

- **identity split-brain**: rename updates stored title but not the live standalone session name or remote mirror
- **unsafe tag input**: hidden Unicode or empty tags are persisted as searchable session metadata
- **artifact leakage**: copy or export expose raw transcript envelopes, tool-only turns, or API-error noise instead of user-facing response text
- **resume misfire**: slash-argument `/resume` silently expands into fuzzy or cross-project search and resumes the wrong conversation
- **remote affordance lie**: `/session` leaks into non-remote surfaces or fails hard when the URL exists but QR rendering does not
