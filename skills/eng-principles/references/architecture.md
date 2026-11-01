# Architecture principles

Detail for P12 to P14. Examples use TypeScript as the illustration language. The principles apply to any language.

## P12. Name the trade-off

A design choice with a real alternative is a trade-off. Write it where the reviewer reads it: the reply, or the Tradeoffs section of the PR (`git-stack-flow`).

- Name the alternative, what the chosen design gains, and what it costs.
- Name the condition that would change the choice, such as a size, a load, or a new requirement. "Filtering runs in the client. Move it to the server if the list passes 10k rows."
- A choice with no real alternative needs no entry. Don't invent options to compare.
- Technical debt is a shortcut taken on purpose. Before taking it, open an issue that names the shortcut, its cost, and the event that should trigger the fix. Link the issue from the PR.

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
