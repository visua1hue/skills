# Architecture principles

Detail for P12 to P16. Examples use TypeScript as the illustration language. The principles apply to any language.

## P12. Name the trade-off

A design choice with a real alternative is a trade-off. Write it where the reviewer reads it: the reply, or the Tradeoffs section of the PR (`git-stack-flow`).

- Name the alternative, what the chosen design gains, and what it costs.
- Name the condition that would change the choice, such as a size, a load, or a new requirement. "Filtering runs in the client. Move it to the server if the list passes 10k rows."
- A choice with no real alternative needs no entry. Don't invent options to compare.
- Technical debt is a shortcut taken on purpose. Before taking it, open an issue that names the shortcut, its cost, and the event that should trigger the fix. Link the issue from the PR.

### Reversibility

- Rate each choice by the cost of undoing it. A function name or an internal file layout is cheap to undo, so decide and move on.
- A database schema, a public API, a message format, a vendor, or a module boundary that other teams build on is expensive to undo. Sketch two or three different designs, recommend one, and get the user's approval before building it (P2).

### Decision records

- Write one when a choice is hard to undo, would surprise a later reader, and had a real alternative. If any of the three is missing, the PR text is enough.
- Use the project's location and format. Without one, use `docs/adr/YYYY-MM-DD-slug.md`. Date names don't collide when two people write records at the same time.
- A paragraph is enough: the context, the decision, the reason, and the condition that should reopen it.
- Draft the record in the PR that carries the change. It counts once the team merges it. One developer's approval in a session is not a team decision.
- Before proposing a design, read the records for the code it touches. When a proposal conflicts with an accepted record, cite the record and its reopen condition. Don't drop the proposal without saying so, and don't argue against the record without a new fact.

## P13. Assume overlap and retries

This applies to code that runs on a timer, an event, a request, a queue message, or a user action that can repeat. Networks retry, users double-click, workers crash mid-job, and responses arrive out of order.

### Race conditions

- Check-then-act on shared state needs one atomic step, such as a database constraint, a conditional update, a transaction, or a lock. Reading, deciding, and writing in separate steps loses updates.
- In the UI, cancel or ignore a request whose result is no longer wanted. Abort the previous request, or tag each request and drop responses older than the latest.
- Disable or deduplicate a submit while its request is in flight.

```ts
// Before: a slow response for "ab" can overwrite the result for "abc"
input.oninput = async () => {
  results = await search(input.value);
};

// After: each new query aborts the one before it
let ctrl: AbortController | undefined;
input.oninput = async () => {
  ctrl?.abort();
  const own = (ctrl = new AbortController());
  try {
    results = await search(input.value, own.signal);
  } catch (e) {
    if (!own.signal.aborted) throw e;
  }
};
```

### Idempotency

- An operation that may run twice gives the same result as running once. This covers webhook handlers, job handlers, payment and email sends, migrations, and setup scripts.
- Use an idempotency key stored with the result, an upsert instead of an insert, or an existence check inside the same transaction as the write.
- Migrations and scripts check the current state before changing it, so a rerun after a partial failure finishes the work.

```ts
// Before: a redelivered webhook charges the customer twice
await payments.charge(event.amount);

// After: the provider treats the second call with the same key as a no-op
await payments.charge(event.amount, { idempotencyKey: event.id });
```

### Queues and async work

- Queues deliver at least once. Consumers are idempotent.
- Messages can arrive out of order. Carry a version or timestamp, and drop a message older than the stored state.
- A message that fails every retry goes to a dead-letter queue or an error log with its payload. It does not block the queue or disappear.
- Bound retries and back off between them. Unbounded retries turn one failure into load on every dependency.
- A promise started without `await` needs its own `catch`. An unhandled rejection is a lost error (P14).

### Consistency versus availability

When the same state lives in two places, such as client and server, cache and database, or two services, a failure between them forces a choice for each piece of state.

- Block when a wrong value causes harm, as with money, permissions, and stock. Wait for the authoritative answer and show an error if it can't be reached.
- Serve stale data when a late update is harmless, as with feeds, counts, and previews. Show the last known value and reconcile later.
- Optimistic UI is the stale choice. It needs a rollback path and a visible message when the server rejects the change.

Record the choice in the code or the PR (P12).

## P14. Make failure visible

- No empty `catch`, no fallback that hides an error, no default value returned in place of one. Catch only where the code can handle the error or add context. Otherwise let it propagate.
- An error message names the operation and the input that failed. "parse /etc/app.json: missing key port" instead of "invalid config".
- Keep the original error when wrapping it: `throw new Error("load user 42", { cause: e })`.
- Log an error once, where it is handled. Logging and rethrowing at every layer repeats the same error.
- Failures on side-effect paths, such as writes, sends, payments, and jobs, reach a log or a monitor. If nothing alerts on a path users depend on, say so in the PR. This is the Detection check in the `git-stack-flow` merge risk score.
- Never log secrets or personal data (P4).

```ts
// Before: the user sees an empty list, and nobody sees the error
const tasks = await loadTasks().catch(() => []);

// After: the UI gets an error state, and the log names the failed operation
const tasks = await loadTasks().then(
  (data) => ({ status: "ok", data }) as const,
  (e) => {
    log.error("load tasks", { cause: e });
    return { status: "error" } as const;
  },
);
```

## P15. Modules hide more than they expose

A caller learns a module's interface. The module pays for itself when that interface is smaller than the work it hides.

- Deletion test: imagine deleting the module. If its logic would reappear in every caller, it earns its place. If the callers would barely change, it is a pass-through. Delete it.
- An interface with one implementation adds a name and an indirection and hides nothing. Add it once a second implementation exists. A test double counts.
- The interface is everything a caller must know: inputs, outputs, errors, invariants, and call order. If a caller has to read the implementation to use the module correctly, the interface is incomplete.
- Prefer one call that handles the common case over several calls the caller must combine in the right order.
- Before adding a module, find the one that already owns the concept. A second module for the same concept splits its rules across two places.

```ts
// Before: three exports that hide nothing, and a fourth file to open
export const getUserId = (u: User) => u.id;
export const isActive = (u: User) => u.status === "active";
if (isActive(user)) await cache.set(getUserId(user), user);

// After: callers read the fields
if (user.status === "active") await cache.set(user.id, user);
```

## P16. Match coupling to distance

Coupling is the knowledge two parts of the code share. From least to most:

1. A published contract: an exported type, an API schema, an event format.
2. Shared domain types.
3. Internals: private fields, the order of internal calls, implementation details.
4. Shared storage, or the same rule written in two places.

Distance is how far apart the parts are: the same module, the same package, separate services, separate teams or release schedules.

- Close parts may share internals. Distant parts share only a contract.
- The costly case is distant parts that share internals in code that changes often. One change then needs edits, reviews, and releases in several places. Fix those first.
- A rule copied into two modules is coupling that no import shows. The copies drift. Move the rule to one owner and have the other module call it (P6).
- Splitting a module raises distance. Split only where the parts already share little.

```ts
// Before: cart and checkout each hold the threshold, and one copy was changed
const freeShipping = subtotal >= 50; // cart.ts
const freeShipping = subtotal > 49.99; // checkout.ts

// After: shipping owns the rule, and both import it
export const qualifiesForFreeShipping = (subtotal: number) => subtotal >= 50; // shipping.ts
```

### Changes across a boundary

When callers can't change in the same release, as with a published package, a public API, stored data, or another team's service, change in three steps. Each step ships and reverts on its own.

1. Expand: add the new form next to the old one.
2. Migrate: move callers and data to the new form.
3. Contract: remove the old form once nothing uses it.

### Boundary checks

Encode each boundary as a check that fails the build (P5). Use the language's module visibility, or a dependency rule tool such as dependency-cruiser, import-linter, or ArchUnit. Write the error message as the fix: which import is forbidden and where the code belongs.
