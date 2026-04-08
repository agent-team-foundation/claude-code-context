---
title: "E2E Permission Testing Contracts"
owners: [bingran-you]
soft_links: [/tools-and-permissions/permissions/permission-decision-pipeline.md, /tools-and-permissions/permissions/yolo-classifier-contracts.md]
native_source: tools/testing/TestingPermissionTool.tsx
verification_status: native_test_derived
---

# E2E Permission Testing Contracts

This leaf documents the testable contracts for end-to-end permission testing, extracted from Claude Code source `tools/testing/TestingPermissionTool.tsx` (73 lines). This tool provides a harness for testing the permission dialog flow.

## Scope boundary

This leaf covers:

- TestingPermissionTool behavior contracts
- E2E permission flow testing patterns
- Test environment gating

It intentionally does not cover:

- YOLO classifier internals (see yolo-classifier-contracts.md)
- Permission decision pipeline (see permission-decision-pipeline.md)

## TestingPermissionTool contract

A testing-only tool that **always triggers a permission dialog** when called by the model.

### Core properties

| Property | Value | Purpose |
|----------|-------|---------|
| `name` | `'TestingPermission'` | Tool identifier |
| `maxResultSizeChars` | `100_000` | Max result size |
| `isEnabled()` | `process.env.NODE_ENV === 'test'` | Only enabled in test environment |
| `isConcurrencySafe()` | `true` | Safe for concurrent execution |
| `isReadOnly()` | `true` | Does not modify state |

### Input schema

```typescript
z.strictObject({})  // Empty object, no parameters
```

### Permission behavior

```typescript
checkPermissions(): PermissionResult {
  return {
    behavior: 'ask',
    message: 'Run test?'
  }
}
```

**Contract**: Always returns `{ behavior: 'ask' }` regardless of:
- Permission mode (auto, plan, normal)
- User settings
- Any other context

This makes it ideal for testing the permission dialog flow.

### Execution behavior

```typescript
call(): { data: string } {
  return { data: 'TestingPermission executed successfully' }
}
```

**Contract**: On successful execution (after permission granted), returns success message.

## Test cases

### isEnabled contract

```
TEST: Tool only available in test environment
CONDITION: NODE_ENV === 'test'
EXPECTED: isEnabled() returns true

CONDITION: NODE_ENV === 'production'
EXPECTED: isEnabled() returns false

CONDITION: NODE_ENV === 'development'
EXPECTED: isEnabled() returns false
```

### checkPermissions contract

```
TEST: Always asks for permission regardless of mode
CONTEXT: Any permission mode (auto, plan, normal)
EXPECTED: { behavior: 'ask', message: 'Run test?' }

TEST: Permission message is consistent
CALL: checkPermissions()
EXPECTED: message === 'Run test?'
```

### call contract

```
TEST: Successful execution returns expected message
PRECONDITION: Permission was granted
CALL: call()
EXPECTED: { data: 'TestingPermission executed successfully' }
```

## Testing patterns derived from this tool

### Pattern 1: Environment-gated test tools

Tools that should only be available during testing should implement:

```typescript
isEnabled() {
  return process.env.NODE_ENV === 'test'
}
```

This ensures the tool is:
- Available during automated tests
- Hidden from production users
- Excluded from tool catalogs in production builds

### Pattern 2: Unconditional permission triggers

For testing permission flows, tools should bypass all permission caching and rules:

```typescript
checkPermissions() {
  return { behavior: 'ask', message: '...' }  // Always 'ask', never 'allow' or 'deny'
}
```

### Pattern 3: Minimal side effects

Test tools should be:
- `isConcurrencySafe: true` - Safe to run in parallel
- `isReadOnly: true` - No filesystem/state mutations
- Deterministic output - Same input always produces same output

## E2E permission flow test scenarios

Using TestingPermissionTool, the following E2E scenarios can be verified:

### Scenario 1: Permission dialog appearance

```
1. Model calls TestingPermission tool
2. VERIFY: Permission dialog appears with "Run test?" message
3. VERIFY: Dialog shows correct tool name
```

### Scenario 2: Permission grant flow

```
1. Model calls TestingPermission tool
2. User grants permission
3. VERIFY: Tool executes successfully
4. VERIFY: Result contains "executed successfully"
```

### Scenario 3: Permission deny flow

```
1. Model calls TestingPermission tool
2. User denies permission
3. VERIFY: Tool does not execute
4. VERIFY: Appropriate denial message returned to model
```

### Scenario 4: Permission dialog state management

```
1. Model calls TestingPermission tool
2. VERIFY: Dialog enters pending state
3. User responds
4. VERIFY: Dialog transitions to resolved state
5. VERIFY: State cleanup occurs
```

## Reconstruction guidance

A Python reconstruction should:

1. Implement `TestingPermissionTool` with:
   - Environment check in `is_enabled()`
   - Always-ask behavior in `check_permissions()`
   - Deterministic success response in `call()`

2. Use it to test:
   - Permission dialog rendering
   - User interaction handling
   - Grant/deny flow completion
   - State machine transitions

3. Ensure tool is excluded from production builds or gated by environment

## Acceptance criteria

- [ ] `isEnabled()` returns `True` only when `NODE_ENV === 'test'`
- [ ] `checkPermissions()` always returns `{ behavior: 'ask' }`
- [ ] `call()` returns `{ data: 'TestingPermission executed successfully' }`
- [ ] Tool is not visible in production tool catalog
- [ ] Permission dialog appears when tool is called
- [ ] Grant flow completes successfully
- [ ] Deny flow blocks execution
