---
title: "Mock Rate Limit Scenarios and Test Contracts"
owners: [bingran-you]
soft_links: [/platform-services/claude-ai-limits-and-extra-usage-state.md, /reconstruction-guardrails/verification-and-native-test-oracles/native-test-derived-asset-provenance-and-acceptance-rules.md]
native_source: services/mockRateLimits.ts
verification_status: native_test_derived
---

# Mock Rate Limit Scenarios and Test Contracts

This leaf documents the testable contracts for rate limit scenario simulation, extracted from the Claude Code source `services/mockRateLimits.ts` (883 lines). These contracts define the mock scenarios used for testing rate limit handling without hitting actual API limits.

## Scope boundary

This leaf covers:

- Mock scenario definitions and their expected header configurations
- Rate limit header types and valid values
- Test contracts for scenario state transitions
- Acceptance criteria for Python reconstruction

It intentionally does not cover:

- Actual API rate limit handling (see claude-ai-limits-and-extra-usage-state.md)
- Error dialog UI (see ui-and-experience)

## Access gate

All mock functions are gated by `process.env.USER_TYPE !== 'ant'`. In production contexts where `USER_TYPE` is not `ant`, mock functions return early without effect.

## MockScenario type contract

The system defines 20 distinct mock scenarios:

```typescript
type MockScenario =
  | 'normal'                    // Normal usage, no limits
  | 'session-limit-reached'     // 5-hour session limit exceeded
  | 'approaching-weekly-limit'  // Warning: approaching 7-day limit
  | 'weekly-limit-reached'      // 7-day aggregate limit exceeded
  | 'overage-active'            // Using extra usage (overage available)
  | 'overage-warning'           // Approaching extra usage limit
  | 'overage-exhausted'         // Both subscription and overage exhausted
  | 'out-of-credits'            // Wallet empty (out_of_credits)
  | 'org-zero-credit-limit'     // Org spend cap is $0
  | 'org-spend-cap-hit'         // Org monthly spend cap reached
  | 'member-zero-credit-limit'  // Member individual limit is $0
  | 'seat-tier-zero-credit-limit' // Seat tier limit is $0
  | 'opus-limit'                // Opus model limit reached
  | 'opus-warning'              // Approaching Opus limit
  | 'sonnet-limit'              // Sonnet model limit reached
  | 'sonnet-warning'            // Approaching Sonnet limit
  | 'fast-mode-limit'           // Fast mode rate limit (>20s cooldown)
  | 'fast-mode-short-limit'     // Fast mode rate limit (<20s cooldown)
  | 'extra-usage-required'      // Headerless 429: 1M context requires extra usage
  | 'clear'                     // Clear all mock headers
```

## MockHeaders type contract

Rate limit headers follow a unified naming convention:

```typescript
type MockHeaders = {
  'anthropic-ratelimit-unified-status'?: 'allowed' | 'allowed_warning' | 'rejected'
  'anthropic-ratelimit-unified-reset'?: string  // Unix timestamp
  'anthropic-ratelimit-unified-representative-claim'?:
    'five_hour' | 'seven_day' | 'seven_day_opus' | 'seven_day_sonnet'
  'anthropic-ratelimit-unified-overage-status'?: 'allowed' | 'allowed_warning' | 'rejected'
  'anthropic-ratelimit-unified-overage-reset'?: string
  'anthropic-ratelimit-unified-overage-disabled-reason'?: OverageDisabledReason
  'anthropic-ratelimit-unified-fallback'?: 'available'
  'anthropic-ratelimit-unified-fallback-percentage'?: string
  'retry-after'?: string  // Seconds until reset
  // Early warning utilization headers
  'anthropic-ratelimit-unified-5h-utilization'?: string
  'anthropic-ratelimit-unified-5h-reset'?: string
  'anthropic-ratelimit-unified-5h-surpassed-threshold'?: string
  'anthropic-ratelimit-unified-7d-utilization'?: string
  'anthropic-ratelimit-unified-7d-reset'?: string
  'anthropic-ratelimit-unified-7d-surpassed-threshold'?: string
  'anthropic-ratelimit-unified-overage-utilization'?: string
  'anthropic-ratelimit-unified-overage-surpassed-threshold'?: string
}
```

## OverageDisabledReason values

```typescript
type OverageDisabledReason =
  | 'out_of_credits'              // Wallet is empty
  | 'org_service_zero_credit_limit' // Org-level spend cap is $0
  | 'org_level_disabled_until'    // Org monthly cap hit
  | 'member_zero_credit_limit'    // Member limit is $0
  | 'seat_tier_zero_credit_limit' // Seat tier limit is $0
```

## Testable function contracts

### `setMockRateLimitScenario(scenario: MockScenario): void`

Sets up a predefined rate limit scenario with appropriate headers.

**Scenario test cases**:

| Scenario | status | overage-status | claim | disabled-reason |
|----------|--------|----------------|-------|-----------------|
| `normal` | `allowed` | - | - | - |
| `session-limit-reached` | `rejected` | - | `five_hour` | - |
| `approaching-weekly-limit` | `allowed_warning` | - | `seven_day` | - |
| `weekly-limit-reached` | `rejected` | - | `seven_day` | - |
| `overage-active` | `rejected` | `allowed` | `five_hour`* | - |
| `overage-warning` | `rejected` | `allowed_warning` | `five_hour`* | - |
| `overage-exhausted` | `rejected` | `rejected` | `five_hour`* | - |
| `out-of-credits` | `rejected` | `rejected` | `five_hour`* | `out_of_credits` |
| `org-zero-credit-limit` | `rejected` | `rejected` | `five_hour`* | `org_service_zero_credit_limit` |
| `org-spend-cap-hit` | `rejected` | `rejected` | `five_hour`* | `org_level_disabled_until` |
| `member-zero-credit-limit` | `rejected` | `rejected` | `five_hour`* | `member_zero_credit_limit` |
| `seat-tier-zero-credit-limit` | `rejected` | `rejected` | `five_hour`* | `seat_tier_zero_credit_limit` |
| `opus-limit` | `rejected` | - | `seven_day_opus` | - |
| `opus-warning` | `allowed_warning` | - | `seven_day_opus` | - |
| `sonnet-limit` | `rejected` | - | `seven_day_sonnet` | - |
| `sonnet-warning` | `allowed_warning` | - | `seven_day_sonnet` | - |

\* Default claim when no exceeded limits are set; preserves existing exceeded limits for overage scenarios.

### `setMockHeader(key: MockHeaderKey, value: string | undefined): void`

Sets individual mock headers with automatic handling.

**Contract**:
- Keys are mapped to full header names (`status` → `anthropic-ratelimit-unified-status`)
- `retry-after` is not prefixed
- Setting `undefined` or `'clear'` removes the header
- Setting `reset` or `overage-reset` with a number treats it as hours from now
- Setting `claim` adds to exceeded limits and updates representative claim
- `retry-after` is auto-calculated when status changes to `rejected`

**Test cases**:
```
SET: setMockHeader('status', 'rejected')
  -> mockHeaders['anthropic-ratelimit-unified-status'] = 'rejected'

SET: setMockHeader('reset', '5')
  -> mockHeaders['anthropic-ratelimit-unified-reset'] = String(now + 5*3600)

SET: setMockHeader('claim', 'five_hour')
  -> exceededLimits = [{ type: 'five_hour', resetsAt: now + 5*3600 }]
  -> mockHeaders['anthropic-ratelimit-unified-representative-claim'] = 'five_hour'

CLEAR: setMockHeader('status', undefined)
  -> delete mockHeaders['anthropic-ratelimit-unified-status']
```

### `addExceededLimit(type, hoursFromNow): void`

Adds an exceeded limit with custom reset time.

**Contract**:
- `type`: `'five_hour' | 'seven_day' | 'seven_day_opus' | 'seven_day_sonnet'`
- Sets status to `rejected` if limits exist
- Updates representative claim to furthest reset time

**Test cases**:
```
addExceededLimit('five_hour', 4)
  -> exceededLimits includes { type: 'five_hour', resetsAt: now + 4*3600 }
  -> status = 'rejected'
  -> representative-claim = 'five_hour'

addExceededLimit('seven_day', 120)
  -> exceededLimits includes { type: 'seven_day', resetsAt: now + 120*3600 }
  -> representative-claim = 'seven_day' (if furthest)
```

### `setMockEarlyWarning(claimAbbrev, utilization, hoursFromNow?): void`

Sets mock early warning utilization headers.

**Contract**:
- `claimAbbrev`: `'5h' | '7d' | 'overage'`
- Clears ALL early warning headers first (5h is checked before 7d)
- Sets `utilization`, `reset`, and `surpassed-threshold` headers
- Sets status to `allowed` if not already set

**Test cases**:
```
setMockEarlyWarning('5h', 0.92)
  -> '5h-utilization' = '0.92'
  -> '5h-reset' = String(now + 4*3600)  // default 4 hours
  -> '5h-surpassed-threshold' = '0.92'
  -> status = 'allowed' (if not set)

setMockEarlyWarning('7d', 0.85, 48)
  -> '7d-utilization' = '0.85'
  -> '7d-reset' = String(now + 48*3600)
  -> '7d-surpassed-threshold' = '0.85'
```

### `getCurrentMockScenario(): MockScenario | null`

Reverse-lookups the current scenario from active headers.

**Contract** (lookup priority):
1. If `claim` is `seven_day_opus`: return `opus-limit` or `opus-warning`
2. If `claim` is `seven_day_sonnet`: return `sonnet-limit` or `sonnet-warning`
3. If `overage-status` is `rejected`: return `overage-exhausted`
4. If `overage-status` is `allowed_warning`: return `overage-warning`
5. If `overage-status` is `allowed`: return `overage-active`
6. If `status` is `rejected`:
   - `claim` is `five_hour`: return `session-limit-reached`
   - `claim` is `seven_day`: return `weekly-limit-reached`
7. If `status` is `allowed_warning` and `claim` is `seven_day`: return `approaching-weekly-limit`
8. If `status` is `allowed`: return `normal`
9. Otherwise: return `null`

### `getScenarioDescription(scenario: MockScenario): string`

Returns human-readable description for each scenario.

**Test cases**:
```
getScenarioDescription('normal') -> 'Normal usage, no limits'
getScenarioDescription('session-limit-reached') -> 'Session rate limit exceeded'
getScenarioDescription('overage-exhausted') -> 'Both subscription and extra usage limits exhausted'
getScenarioDescription('out-of-credits') -> 'Out of extra usage credits (wallet empty)'
getScenarioDescription('opus-limit') -> 'Opus limit reached'
getScenarioDescription('extra-usage-required') -> 'Headerless 429: Extra usage required for 1M context'
```

### `checkMockFastModeRateLimit(isFastModeActive?: boolean): MockHeaders | null`

Checks and returns mock headers for fast mode rate limits.

**Contract**:
- Returns `null` if no fast mode limit is configured
- Returns `null` if `isFastModeActive` is false
- Returns `null` if rate limit has expired
- On first error, sets expiry timestamp
- Calculates dynamic `retry-after` based on remaining time

### `applyMockHeaders(headers: Headers): Headers`

Applies mock headers to an existing Headers object.

**Contract**:
- Returns original headers if mocking is disabled
- Creates new Headers object with originals
- Overwrites with mock headers
- Returns modified Headers

## Reset time conventions

| Limit Type | Default Reset |
|------------|---------------|
| `five_hour` | 5 hours from now |
| `seven_day` | 7 days from now |
| `seven_day_opus` | 7 days from now |
| `seven_day_sonnet` | 7 days from now |
| overage | End of current month |

## Reconstruction guidance

A Python reconstruction should:

1. Define `MockScenario` enum with all 20 scenarios
2. Define `MockHeaders` dataclass with all header fields
3. Define `OverageDisabledReason` enum with 5 reasons
4. Implement `set_mock_rate_limit_scenario(scenario)`:
   - Map each scenario to correct header configuration
   - Handle exceeded limits list for overage scenarios
   - Calculate reset timestamps
5. Implement `set_mock_header(key, value)`:
   - Map abbreviated keys to full header names
   - Handle `reset`/`overage-reset` time calculation
   - Handle `claim` with exceeded limits tracking
   - Auto-calculate `retry-after` on status changes
6. Implement `add_exceeded_limit(type, hours_from_now)`:
   - Add to exceeded limits list
   - Update representative claim
   - Set status to rejected
7. Implement `set_mock_early_warning(claim_abbrev, utilization, hours?)`:
   - Clear all early warning headers first
   - Set utilization, reset, and surpassed-threshold
8. Implement `get_current_mock_scenario()`:
   - Reverse lookup scenario from headers
   - Follow priority order exactly
9. Implement `apply_mock_headers(headers)`:
   - Return new headers with mocks applied

## Acceptance criteria

- [ ] All 20 scenarios produce correct header configurations
- [ ] `setMockHeader` correctly maps keys and handles special cases
- [ ] `addExceededLimit` updates representative claim to furthest reset
- [ ] `setMockEarlyWarning` clears existing early warning headers first
- [ ] `getCurrentMockScenario` correctly reverses all scenarios
- [ ] `getScenarioDescription` returns correct descriptions for all scenarios
- [ ] Fast mode rate limit expiry and dynamic retry-after work correctly
- [ ] All functions are gated by USER_TYPE check
- [ ] Reset time calculations use correct offsets (5h, 7d, end of month)
