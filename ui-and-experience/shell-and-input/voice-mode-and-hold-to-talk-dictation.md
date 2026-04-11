---
title: "Voice Mode and Hold-to-Talk Dictation"
owners: []
soft_links: [/product-surface/command-surface.md, /ui-and-experience/shell-and-input/keybinding-customization-and-context-resolution.md, /ui-and-experience/feedback-and-notifications/interaction-feedback.md, /platform-services/auth-config-and-policy.md]
---

# Voice Mode and Hold-to-Talk Dictation

Claude Code's voice support is not just a `/voice` toggle. It is a gated input subsystem that combines runtime eligibility, persistent enablement, key-hold detection, microphone capture, streaming speech-to-text, prompt-buffer anchoring, and dedicated feedback surfaces. A faithful rebuild needs the whole chain. Recreating only the command or only the recorder will miss the text-leak guards, retry behavior, and UI state transitions that make the feature usable.

## Scope boundary

This leaf covers the end-to-end user-facing voice path:

- availability and visibility gates
- `/voice` and `voiceEnabled` enablement behavior
- hold-to-talk activation and release detection
- audio capture and voice-stream speech-to-text session management
- prompt-input transcript insertion and interim rendering
- footer, notification, and onboarding-style voice notices

It intentionally does not re-document:

- the generic command-family organization already summarized in [command-surface.md](../product-surface/command-surface.md)
- the general keybinding configuration model already summarized in [keybinding-customization-and-context-resolution.md](keybinding-customization-and-context-resolution.md)
- generic prompt layout, footer layout, or notification framework behavior outside the voice-specific branches
- broader auth-policy architecture beyond the voice-specific requirement that this feature only works with Claude.ai OAuth

## Availability, gating, and visibility

Equivalent behavior should preserve:

- build-time dead-code elimination around voice so non-voice builds omit the command, context provider, hook implementation, and UI strings entirely
- a separate runtime kill-switch that can hide or disable voice even when the build includes it
- the kill-switch defaulting to "voice allowed" when cached GrowthBook data is missing or stale, so fresh installs do not wait for feature initialization before voice can appear
- voice requiring Claude.ai OAuth, not API keys or alternate providers such as Bedrock, Vertex, or Foundry
- the distinction between a cheap "GrowthBook says voice may exist" check and a stricter "voice is fully usable right now" check that also requires a real OAuth token
- React render paths using a memoized auth-aware hook rather than synchronously re-reading secure token storage on every render
- `/voice`, config-setting prompts, and startup notices all using the same runtime gate so they do not disagree about whether voice exists
- the config-setting surface treating `voiceEnabled` as an unknown setting when the runtime kill-switch is off, so voice-specific strings do not leak through a disabled feature

## Persistent enablement surfaces

Equivalent behavior should preserve:

- `/voice` acting as a pure toggle command: if voice is enabled it disables immediately, and if it is disabled it runs pre-flight checks before enabling
- `voiceEnabled` living in persistent settings and feeding the live app state used by render-time voice eligibility checks
- both `/voice` and the config-setting tool performing the same enable-time pre-flight checks instead of letting one path bypass the other
- successful writes notifying the settings change detector so the live app state and cached settings snapshot both refresh immediately
- the command being hidden when voice is unavailable at runtime even if the command registry still includes a build-time placeholder
- `/voice` and config-based enabling both returning user-facing error text instead of silently failing when prerequisites are missing

## Enable-time pre-flight checks

Equivalent behavior should preserve:

- enablement checking runtime kill-switch and OAuth eligibility before touching audio or voice-stream services
- a recording-availability probe that rejects remote or homespace-style environments where no local microphone can exist
- a separate voice-stream availability check that confirms Claude.ai OAuth is present before starting audio capture
- dependency checks that prefer the native audio module when available, but still validate Linux fallbacks such as `arecord` or `rec`
- Linux and WSL availability checks probing whether fallback binaries can actually open a capture device instead of trusting mere PATH presence
- proactive microphone-permission probing during enablement so the operating system permission dialog appears at setup time rather than on the user's first hold-to-talk attempt
- platform-specific remediation guidance when microphone permission is denied
- enable success text naming the currently resolved push-to-talk shortcut instead of hardcoding `Space`
- enable success text also surfacing the resolved dictation language, including a warning when the configured language is unsupported and must fall back to English
- global counters limiting how often the dictation-language hint is repeated across sessions, with the counter resetting when the resolved language changes

## Command and notice surfaces

Equivalent behavior should preserve:

- `/voice` being the explicit command affordance for toggling the feature
- `voiceEnabled` being discoverable through the configuration tool only when voice is runtime-enabled
- a startup notice that says voice is now available but not yet enabled
- that notice only appearing when voice is eligible, the setting is still off, a global show-count cap has not been reached, and a higher-priority notice is not occupying the same area
- the startup notice incrementing its own capped global counter so it appears only a small number of sessions
- the footer idle hint `hold <shortcut> to speak` using a separate capped counter from the startup notice

## Activation key resolution

Equivalent behavior should preserve:

- the hold-to-talk action being driven by the `voice:pushToTalk` keybinding in `Chat` context
- the shipped default keybinding being `space`
- the default binding existing partly so shortcut-display helpers can resolve the hint without falling back to hardcoded analytics-backed defaults
- the runtime key lookup scanning bindings with last-wins semantics, matching the general resolver contract
- explicit user overrides being respected: if a later binding null-unbinds or reassigns the same key, the voice handler must treat voice activation as disabled for that key
- a hardcoded `space` fallback being used only when no keybinding provider exists at all, not when the provider exists and the user explicitly overrode voice
- voice activation rejecting multi-step chords as unsupported
- modifier-plus-space being treated as a broken binding shape rather than a first-class supported path because terminal input does not deliver it reliably
- validation warning when `voice:pushToTalk` is bound to a bare letter, since warmup leaks that character into the prompt before activation fully takes over

## Hold detection and release semantics

Equivalent behavior should preserve:

- hold detection being built around terminal auto-repeat rather than a direct key-down/key-up API
- a rapid-key gap threshold of about 120ms for deciding whether repeated key events belong to one held-key activation sequence
- bare printable keys requiring a warmup period and a higher activation threshold so normal typing still works
- the first two rapid bare-key events being allowed through to the prompt so a normal single tap still types normally
- voice warmup feedback beginning once the system has enough rapid presses to infer "user is probably holding the key" rather than just typing
- activation for bare keys occurring after roughly five rapid events
- modifier combos activating on the first press because they are already unambiguous user intent
- modifier combos using a much longer first-press fallback timer, around two seconds, to bridge the operating system's initial repeat delay
- bare-key activations stripping the warmup characters that leaked into the prompt before recording started
- that strip logic preserving real trailing user text as much as possible by tracking how many leaked characters are intentional warmup versus pre-existing prompt content
- when the configured hold key is space, full-width spaces inserted by CJK IMEs being treated as the same physical key for both leak cleanup and activation matching
- continued auto-repeat during recording being swallowed and forwarded only to the release detector
- release detection using an inactivity timeout of about 200ms after repeat has started
- a separate fallback timer of about 600ms so a quick tap-and-release still transitions out of recording even if auto-repeat never starts
- processing state ignoring further activation input until the current transcript finalization finishes

## REPL integration and prompt-target guards

Equivalent behavior should preserve:

- the REPL creating one voice integration object that owns stripping, anchoring, transcript insertion, and interim-range calculation
- a separate keybinding handler component mounting alongside the rest of the REPL keybinding stack
- the handler refusing to swallow keys when the normal prompt input is not a valid target, such as when a local JSX command hides the prompt or a modal overlay has focus
- the handler reading the voice store synchronously inside the same tick so it can tell whether activation actually transitioned out of idle before deciding to keep swallowing repeated keypresses
- failed activations resetting any temporary prompt anchor they created, so stale prefix or suffix references do not survive into the next attempt

## Voice store and state model

Equivalent behavior should preserve:

- a dedicated voice store separate from the main app store
- stable read, subscribe, and set-state helpers so callers can read fresh voice state inside event handlers without forcing extra renders
- explicit voice state values of `idle`, `recording`, and `processing`
- separate store fields for `voiceError`, `voiceInterimTranscript`, `voiceAudioLevels`, and `voiceWarmingUp`
- slice subscriptions only re-rendering when the selected value changes, so high-frequency audio-level updates do not fan out across unrelated UI
- synchronous voice-state writes being visible immediately to later logic in the same tick

## Prompt anchoring and transcript insertion

Equivalent behavior should preserve:

- capturing the prompt prefix and suffix around the cursor position at activation time
- inserting interim and final transcripts between that prefix and suffix instead of overwriting the whole prompt
- adding a separating space only when needed, so transcripts do not jam into adjacent words but also do not create double spaces
- inserting a temporary gap before a non-space suffix so the cursor and interim waveform sit in the gap instead of covering the first suffix character
- tracking the exact input value last written by the voice subsystem so late interim or final transcript updates can detect whether the user already edited or submitted the prompt
- refusing to re-fill the prompt after the user has changed it, even if the voice WebSocket is still draining late transcript events
- computing and exposing the character range of the interim portion so the UI can dim or style the not-yet-finalized text differently
- updating the stored prefix after each flushed final transcript so a continuous session can append more dictated text after earlier dictated text

## Recording backend selection

Equivalent behavior should preserve:

- lazy-importing the audio service only after voice is enabled or activated, because loading the native audio module can block the event loop and may provoke microphone permission flows
- preferring the native audio module on macOS, Linux, and Windows when it is available
- Linux refusing to use the native path when the machine has no ALSA cards, because the in-process backend can otherwise spam stderr or fail opaquely
- Linux falling back to `arecord` only when a real probe has confirmed it can open an input device
- Linux and macOS falling back to SoX `rec` when native recording is unavailable and `arecord` is absent or unusable
- Windows having no shell-command fallback and therefore failing if the native module is unavailable
- push-to-talk capture disabling silence detection, because the user explicitly controls when recording starts and stops
- the service still retaining silence-detection support internally for other callers, even though the current REPL hold-to-talk path disables it
- stop calls preferring the native backend shutdown path when a native recording is active

## Voice-stream connection contract

Equivalent behavior should preserve:

- refreshing OAuth tokens before opening the speech-to-text WebSocket
- connecting to the API listener that accepts the same OAuth credentials but avoids the browser-focused TLS challenge behavior of the regular Claude web host
- passing encoding, sample rate, channel count, endpointing, utterance-end, language, and optional keyterm hints through the WebSocket query string
- a runtime gate being able to switch the backend provider or model variant without changing the local voice UI contract
- immediate and periodic keepalive control messages so the server does not time out before audio capture begins or while the user pauses briefly
- returning a connection object with `send`, `finalize`, `close`, and `isConnected` semantics rather than exposing the raw WebSocket
- dropping any late audio frames after `CloseStream` has been sent, because the server rejects post-finalize audio
- deferring the actual `CloseStream` send by one event-loop tick so recorder callbacks already queued in the runtime can flush before the server stops accepting audio

## Recording session lifecycle

Equivalent behavior should preserve:

- recording sessions entering `recording` synchronously before any async pre-checks or network awaits, so hold-state logic does not observe stale `idle`
- audio capture starting immediately and buffering audio locally while the WebSocket handshake is still in flight
- buffered audio being flushed once the WebSocket is truly ready, then later audio going directly to the connection
- buffered audio being coalesced into larger slices before send so the system does not emit one WebSocket frame per tiny capture chunk
- per-session generation counters preventing stale callbacks from an abandoned connection from mutating the active session
- separate attempt-generation tracking so a retried connection can suppress stale errors from the first failed attempt
- recording metrics tracking whether any meaningful audio signal was captured, whether the WebSocket ever connected, and whether retry or silent-drop replay paths were used
- audio-level snapshots being fed into the voice store continuously during recording for waveform rendering

## Transcript handling and finalization

Equivalent behavior should preserve:

- interim transcripts always updating the live preview
- hold-to-talk mode accumulating finalized transcript segments until the user releases the key
- final transcript segments being separated by spaces when multiple finalized chunks arrive in one hold-to-talk session
- `TranscriptEndpoint` promoting the latest interim segment to a final segment
- close-time promotion of any leftover interim text so the last phrase is not lost if the server closes before sending a formal endpoint marker
- a finalize path that can resolve early when the server has clearly flushed everything, instead of always waiting for full WebSocket teardown
- a no-data timeout and a safety timeout around finalization so empty sessions do not hang indefinitely
- the no-data timeout being cancelled only after post-`CloseStream` transcript data really arrives
- non-Nova interim handling auto-finalizing a previous segment when a completely different segment begins, preventing later speech from overwriting earlier speech
- Nova-style cumulative interims skipping that auto-finalize heuristic because revisions to earlier text would otherwise duplicate content
- empty-transcript warnings surfacing only for sessions long enough to look intentional, while short accidental taps quietly fall back to idle

## Retry and degraded-network behavior

Equivalent behavior should preserve:

- one retry for early, non-fatal voice-stream failures that occur before any transcript has been delivered and while the user is still recording
- that retry inserting a short backoff before reconnecting
- audio captured during the retry window being buffered instead of lost
- fatal upgrade failures, such as rejected HTTP upgrades in the 4xx range, surfacing immediately instead of retrying forever
- the WebSocket client surfacing real HTTP upgrade rejections when available, including Bun-specific quirks where a spurious `unexpected-response` event can fire with status 101
- a separate silent-drop replay path when the server accepted audio and the microphone had real signal but the session finalized with no transcript
- that silent-drop replay being attempted only once, after a short backoff, and only for non-focus sessions with retained audio buffers
- finalize-time error suppression so a late close or finalize-related error does not wipe the transcript the system is still trying to read

## Language normalization and recognition hints

Equivalent behavior should preserve:

- normalizing configured dictation language into a supported BCP-47 code before opening the voice stream
- accepting both language codes and common English or native language names
- falling back to English when the configured language is unsupported instead of hard-failing the entire voice feature
- surfacing that fallback to the user when enabling voice
- enriching the STT request with keyterms for coding vocabulary, current project name, and git branch words, while preserving helper support for recent-file enrichment even though the current live REPL path does not pass recent files
- capping the total number of keyterms so context enrichment stays bounded

## User-facing feedback surfaces

Equivalent behavior should preserve:

- a dedicated footer warmup hint while the user is in the rapid-hold detection window
- the footer showing `hold <shortcut> to speak` only when voice is enabled, idle, and there is room for the hint
- the footer hint being capped across sessions so it does not appear forever
- prompt notifications being temporarily replaced by a dedicated voice indicator while recording or processing is active
- recording state showing a listening indicator
- processing state showing a distinct processing indicator, with reduced-motion fallback
- the prompt input hiding placeholder text while recording
- the text cursor becoming a miniature waveform based on live audio levels while recording, with reduced-motion and accessibility fallbacks
- voice errors surfacing through the same notification area instead of being hidden in logs only

## Latent backend path that current REPL does not use

The underlying voice hook also contains a focus-driven recording mode:

- recording can start when the terminal gains focus and end when it loses focus
- finalized transcript chunks flush immediately instead of waiting for release
- a silence timeout tears the session down if the focused terminal stays quiet for several seconds
- keypresses can re-arm a session after a silence timeout

The current REPL integration passes `focusMode: false`, so a reconstruction of today's product should preserve the backend capability but should not accidentally expose it as the default user experience.

## Failure modes

- **gate drift**: `/voice`, config settings, and startup notices disagree about whether voice exists because they consult different eligibility checks
- **provider leak**: voice is shown for API-key or non-Claude.ai users even though the speech-to-text endpoint requires Claude.ai OAuth
- **startup freeze**: the native audio module is preloaded at app startup and blocks the terminal or provokes microphone prompts too early
- **false release**: the 200ms release timer starts before auto-repeat begins, so recording ends before the user has actually finished holding the key
- **stuck recording**: repeat and fallback timers are not cleared correctly, so release is never detected
- **text leakage**: bare-key activation does not strip warmup characters or strip-floor logic is wrong, leaving repeated letters or spaces in the prompt
- **text clobbering**: late interim or final transcripts overwrite prompt edits because the system does not track whether the user changed the prompt after voice started writing
- **stale anchor reuse**: a failed activation leaves prefix or suffix refs behind, so the next activation inserts text at the wrong place
- **missing opening speech**: audio capture waits for the WebSocket handshake instead of buffering immediately, so the beginning of the utterance is lost
- **empty-transcript flakiness**: early retry and silent-drop replay paths are omitted, causing intermittent "no speech detected" failures even when audio reached the backend
- **finalize wipeout**: finalize-related close or error events trigger generic cleanup before the accumulated transcript has been read
- **unsupported-language breakage**: the client forwards arbitrary configured language strings to the backend, causing avoidable connection failures instead of a controlled English fallback
- **dead shortcut hinting**: the footer or `/voice` success text hardcodes `Space` and drifts from the user's resolved push-to-talk binding

## Test Design

In the observed source, shell-and-input behavior is verified through deterministic key-sequence regressions, store-backed integration coverage, and interactive terminal end-to-end checks.

Equivalent coverage should prove:

- input reducers, keybinding resolution, history state, and prompt composition preserve the invariants documented above
- queue, history, suggestion, and terminal-runtime coupling behave correctly with real stores, temp files, and reset hooks between cases
- multiline entry, fullscreen behavior, pickers, and suggestion surfaces work through the packaged interactive shell instead of only through isolated render helpers
