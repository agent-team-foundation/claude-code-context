---
title: "Structured Output Enforcement and Artifact Projection"
owners: []
soft_links: [/integrations/clients/structured-io-and-headless-session-loop.md, /integrations/clients/sdk-control-protocol.md, /tools-and-permissions/execution-and-hooks/tool-hook-control-plane.md, /runtime-orchestration/turn-flow/api-request-assembly-retry-and-prompt-cache-stability.md, /platform-services/provider-model-mapping-and-capability-gates.md]
---

# Structured Output Enforcement and Artifact Projection

Claude Code does not treat structured output as one generic formatting flag. It supports two different mechanisms, and the agentic headless path relies on a hidden tool-plus-hook contract rather than on provider-native response formatting alone.

## Scope boundary

This leaf covers:

- structured-output behavior for headless and SDK-driven agentic turns
- the distinction between provider-native output formatting and the hidden schema-enforced tool path
- how structured output is enforced, persisted, retried, and surfaced back to clients

It intentionally does not re-document:

- general headless transport framing already covered in [../../integrations/clients/structured-io-and-headless-session-loop.md](../../integrations/clients/structured-io-and-headless-session-loop.md)
- generic hook-source merge and lifecycle points already covered in [../../tools-and-permissions/execution-and-hooks/tool-hook-control-plane.md](../../tools-and-permissions/execution-and-hooks/tool-hook-control-plane.md)
- provider capability gates already covered in [../../platform-services/provider-model-mapping-and-capability-gates.md](../../platform-services/provider-model-mapping-and-capability-gates.md)

## Two structured-output mechanisms must stay distinct

Equivalent behavior should preserve two separate structured-output paths:

- a provider-native output-format path for bounded helper queries that can rely on model and provider support
- a hidden tool-based path for full agentic headless turns, where the model is forced to deliver final structured output through an internal tool contract

The rebuild target is not "pick one." Both paths exist because they solve different problems.

## Agentic headless turns use a hidden schema tool, not an exposed user tool

Equivalent behavior should preserve:

- structured-output activation on the main agentic path only for non-interactive or headless sessions that explicitly provided a JSON schema
- upfront schema validation before the turn starts, so malformed schemas fail at setup time rather than midway through a live conversation
- injection of one internal structured-output tool after the ordinary visible tool set has already been assembled and filtered
- that internal tool staying out of ordinary user-facing tool catalogs and permission semantics, because it is an enforcement mechanism rather than a user-controlled capability
- the tool remaining read-only and side-effect-free from the runtime's perspective, since its job is to deliver validated data back into the host contract

## Hook enforcement requires exactly-one successful completion path

Equivalent behavior should preserve a stop-time enforcement layer around that hidden tool:

- a session-scoped hook or equivalent stop-phase contract checking whether the structured-output tool has already succeeded
- if not, the runtime appending a direct reminder that completion requires calling that tool now
- enforcement running as part of the same recursive turn lifecycle rather than as a detached post-processor
- successful structured-output completion short-circuiting further enforcement retries for that request

This is what turns schema output from a polite suggestion into an actual runtime contract.

## Structured output is persisted as an attachment artifact

Equivalent behavior should preserve:

- successful structured-output tool calls yielding a structured-output attachment artifact rather than hiding the payload only inside an in-memory callback
- that attachment being recorded inline with the turn's other persisted artifacts so resume, replay, and later result projection all see the same structured payload
- structured output remaining distinct from ordinary assistant prose, because a turn may complete with little or no visible text while still having a valid machine-readable final result

The key invariant is that structured output becomes part of the durable session record, not just a transient transport response.

## Success and failure projection differ from ordinary text turns

Equivalent behavior should preserve these result-shaping rules:

- final success payloads may include both ordinary text output and a separate structured-output field
- the text field may legitimately be empty when the real completion artifact is the structured output and the model otherwise ends cleanly
- empty assistant text must therefore not automatically become an execution failure when the turn ended lawfully and the structured-output contract was satisfied
- structured-output retry exhaustion must surface through its own typed terminal error rather than collapsing into generic execution failure, max-turns, or max-budget paths

Clients need this distinction to tell "schema contract was never satisfied" apart from ordinary model or tool failure.

## Retry accounting is based on structured-output completion attempts

Equivalent behavior should preserve:

- retry exhaustion being counted from structured-output completion attempts within the request flow, not just from total turn count
- one configurable ceiling on how many times the runtime will let the model attempt structured completion before returning a hard typed error
- keeping that terminal separate from other recovery ladders so structured-output enforcement cannot silently loop forever

This keeps schema enforcement bounded and observable.

## Headless and SDK transports project the artifact explicitly

Equivalent behavior should preserve:

- initialize-style control surfaces being able to supply the schema that activates structured-output enforcement
- final headless or SDK result payloads exposing the structured output in a dedicated field rather than forcing hosts to scrape it back out of transcript attachments
- protocol schemas including a distinct error subtype for structured-output exhaustion so generated clients can branch on it explicitly

Hosts should not need to reverse-engineer transcript structure to recover the final machine-readable answer.

## Native output-format support remains valuable for bounded helper calls

Equivalent behavior should preserve:

- helper or side-query flows being able to use provider-native output formatting when the selected model and provider support it
- capability gating for that native path staying provider-aware
- the main agentic headless schema path not depending on native structured-output support, because the hidden tool-based contract is the portability fallback

Without this distinction, a rebuild will either underuse native support or wrongly disable headless schemas on unsupported providers.

## Failure modes

- **catalog leakage**: the internal structured-output tool appears in ordinary visible tool or permission surfaces
- **missing enforcement**: the model stops without ever satisfying the schema contract, yet the host still receives an apparent success
- **artifact loss**: structured output is validated transiently but not persisted into the durable turn artifact stream
- **empty-response false error**: a valid structured-output completion with no user-facing prose is misclassified as execution failure
- **capability coupling**: the agentic headless schema path is wrongly tied to provider-native structured-output support and breaks on unsupported backends
- **retry blur**: structured-output exhaustion collapses into a generic failure type and downstream clients cannot tell what actually failed

## Test Design

In the observed source, turn-flow behavior is verified through a mix of deterministic module tests, resume-sensitive integration coverage, and CLI-visible end-to-end scenarios.

Equivalent coverage should prove:

- pre-query mutation, continuation branches, and typed terminal outcomes stay stable under test posture
- tool results, compaction, queued-command replay, and transcript persistence still compose correctly inside one logical turn
- interactive and structured-I/O paths surface the same visible outcome when interruption, permission denial, or recovery branches occur
