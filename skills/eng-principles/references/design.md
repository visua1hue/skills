# Design principles

Detail for P6 to P9. Examples use TypeScript as the illustration language. The principles apply to any language.

## P6. Data shape first

Pick the shape before the logic. The shape decides how many states the code can be in, and every extra state is a branch someone has to handle.

- Model mutually exclusive states as a tagged union, not a set of booleans and optionals.
- Use a lookup table instead of a growing `switch` or `if` chain keyed on the same value.
- Parse untrusted input once at the boundary into a typed value. Code past the boundary trusts the type and does not re-check.
- Derive related types and values from one source, so a rename fails the build instead of drifting.

```ts
// Before: 8 combinations, 3 of them valid
type Req = { loading: boolean; error?: string; data?: User };

// After: exactly 3 states, the compiler enforces the rest
type Req =
  | { status: "loading" }
  | { status: "error"; error: string }
  | { status: "ok"; data: User };
```

## P7. Separation of concerns

A module should have one reason to change. When a fix for a display bug touches the fetch code, the concerns are mixed.

| Layer | Owns | Does not |
| --- | --- | --- |
| UI | Rendering, user events, local view state | Fetch, persist, or transform domain data |
| Data | Types, pure transforms, validation, business rules | Touch the screen, network, disk, or framework lifecycle |
| IO | Network, storage, file access, framework lifecycle | Hold business rules |

Keep the data layer pure, so it runs and tests without the framework or the network.

```ts
// Before: fetch, rule, and rendering in one function
async function renderOverdue(el: HTMLElement) {
  const tasks = await (await fetch("/api/tasks")).json();
  el.textContent = tasks.filter((t) => t.due < Date.now() && !t.done).length + " overdue";
}

// After: IO, data, and UI each change for one reason
const loadTasks = async (): Promise<Task[]> => (await fetch("/api/tasks")).json();
const overdue = (tasks: Task[], now: number) => tasks.filter((t) => t.due < now && !t.done);
const renderCount = (el: HTMLElement, n: number) => { el.textContent = `${n} overdue`; };

renderCount(el, overdue(await loadTasks(), Date.now()).length);
```

## P8. Hot-path discipline

Hot code runs per frame, per keystroke, per event, per item, or per request. Find it before optimizing, then keep avoidable work out of it:

- Hoist constants, compiled patterns, formatters, and lookup tables out of the function.
- Replace repeated searches inside a loop with an index built once. That turns O(n·m) into O(n + m).
- Batch reads before writes when both touch the same expensive resource. Never interleave them in a loop.
- Cache derived values keyed on their inputs, and invalidate on change.
- Debounce or throttle high-frequency events when the work does not need every event.
- Flag O(n²) or worse on input with no upper bound.

```ts
// Before: O(n·m)
const rows = tasks.map((t) => ({ ...t, owner: users.find((u) => u.id === t.ownerId) }));

// After: O(n + m)
const byId = new Map(users.map((u) => [u.id, u]));
const rows = tasks.map((t) => ({ ...t, owner: byId.get(t.ownerId) }));
```

Outside hot paths, readability wins (P9). For a non-obvious perf change, measure a baseline first (P11).

## P9. Minimize reader load

The reader should hold as little in their head as possible at any line.

- Guard clauses and early returns. The main path stays at the lowest indentation.
- One level of abstraction per function. If a function mixes "what" and "how", extract the "how".
- Name things after the domain (`unpaidInvoices`), not the mechanism (`filteredArr2`).
- No clever one-liners that need decoding. Two plain lines beat one dense one.
- Comments explain why: a constraint, a workaround, a non-obvious tradeoff. Delete comments that restate the code.
- Delete dead code and unused exports. Git keeps the history.
- Extract a shared helper on the third real use, not the first (P1).

```ts
// Before
function archive(order?: Order) {
  if (order) {
    if (order.status === "paid") {
      // archive the order
      return store.archive(order.id);
    }
  }
}

// After
function archive(order?: Order) {
  if (order?.status !== "paid") return;
  return store.archive(order.id);
}
```
