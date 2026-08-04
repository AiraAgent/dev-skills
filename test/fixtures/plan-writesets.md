# A fixture plan for preflight --parallel

Four phases whose *Changes* fields carry real backticked paths, arranged so the
write-sets answer both ways:

- phases 2 and 3 are disjoint — the canonical contract-parallel shape;
- phase 4 collides with phase 2 on `src/api/client.ts`.

The fenced block inside phase 1's *How* names a path that must never be read as
a write: a path inside a fence is an example, not a declaration.

### Phase 1. The module both sides build against

**Becomes true**
- the shared module exists and exports the contract

**Changes**
- `src/shared/contract.ts` — the type and its guard

**How**
- plain TypeScript, for example:
```
**Changes**
- `src/fenced/never-a-write.ts`
```
- no runtime dependency is added

**Do not touch**
- —

**Frozen for later phases**
- `UserRecord` — the shape both sides read

**Verification**
- cases: TC-1

**Steps**
- [ ] write the module

### Phase 2. One side of the contract

**Becomes true**
- the client returns `UserRecord`

**Changes**
- `src/api/client.ts` — the fetch and its parse
- `src/api/client.test.ts` — its tests

**How**
- use `UserRecord` from `src/shared/contract.ts`

**Do not touch**
- —

**Frozen for later phases**
- —

**Verification**
- cases: TC-2

**Steps**
- [ ] write the client

### Phase 3. The other side of the contract

**Becomes true**
- the view renders a `UserRecord`

**Changes**
- `src/ui/UserCard.tsx` — the component
- `src/ui/UserCard.test.tsx` — its tests

**How**
- use `UserRecord` from `src/shared/contract.ts`

**Do not touch**
- —

**Frozen for later phases**
- —

**Verification**
- cases: TC-3

**Steps**
- [ ] write the component

### Phase 4. A phase that collides with phase 2

**Becomes true**
- the client retries once on a timeout

**Changes**
- `src/api/client.ts` — the retry
- `src/api/retry.ts` — the policy

**How**
- no new dependency

**Do not touch**
- —

**Frozen for later phases**
- —

**Verification**
- cases: TC-4

**Steps**
- [ ] add the retry
