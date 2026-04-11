---
title: "Federated Auth Conformance and IdP Test Seeding"
owners: [bingran-you]
soft_links:
  - /integrations/mcp/oauth-step-up-and-client-registration.md
  - /integrations/mcp/server-contract.md
  - /platform-services/auth-config-and-policy.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/test-seams-reset-hooks-and-injected-dependencies.md
  - /reconstruction-guardrails/verification-and-native-test-oracles/e2e-harness-reality-boundaries.md
---

# Federated Auth Conformance and IdP Test Seeding

The federated MCP auth path has a conformance-sensitive verification contract that is more specific than ordinary OAuth flow coverage. The current snapshot shows a dedicated XAA-style path whose testing posture must preserve both wire-level expectations and deterministic mock-IdP entrypoints.

## Federated auth is not generic OAuth

Equivalent behavior should preserve:

- a distinct federated path instead of silently collapsing back to ordinary per-server consent
- stable auth-method expectations where conformance relies on a specific token-exchange style
- persistence of the federated auth server identity and related secure-storage slots across reconnects and refreshes

The main clean-room point is that this path has stricter interoperability expectations than a generic "browser login happened" check.

## Mock-IdP seeding is a supported verification seam

The snapshot shows a direct token-seeding path for cases where the mock identity provider does not serve the full browser authorization surface.

Equivalent behavior should preserve:

- a way to inject a pre-obtained federated identity token for controlled verification contexts
- storage of that injected token in the same cache slot the ordinary login path later reads
- expiry handling derived from the token itself when possible, so seeded tokens behave like real cached credentials

This is an important seam because conformance and e2e runs need a deterministic entrypoint that still exercises the real downstream cache and exchange path.

## Wire-level conformance expectations

Equivalent behavior should preserve:

- token-exchange defaults that match the expected conformance posture unless a server explicitly requires another method
- clear failure when those expectations are violated, instead of silently falling through to a different auth style
- the distinction between configuration-time secure secrets and login-time seeded tokens

## Failure modes

- **federated fallback surprise**: the runtime silently uses a different auth path than the server contract intended
- **seed-slot mismatch**: injected test tokens do not land in the same cache identity ordinary auth later reads
- **wire drift**: token exchange changes method or request shape and quietly stops matching conformance expectations
- **fake auth success**: tests seed a token into a bypass-only slot and stop exercising the real federated credential path

## Test Design

In the observed source, MCP behavior is verified through contract regressions, seeded or fixture-backed integration flows, and connection-realistic end-to-end scenarios.

Equivalent coverage should prove:

- config layering, server lifecycle, permission relay, and resource projection preserve the contracts described in this leaf
- auth, OAuth step-up, federated identity, and recovery branches can be exercised deterministically without depending on unstable live infrastructure
- users still see the expected MCP connection, gating, refresh, and failure behavior through the real runtime surfaces
