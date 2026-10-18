# Modeling with types

Rules TS3, TS4, TS5. Name the types before writing logic (`eng-principles` P6). A good model makes an invalid state fail to compile.

## States as discriminated unions

An object of optional fields allows combinations that never happen, and every reader has to guess which ones are real. A union lists the real states, and checking the tag narrows the rest.

```ts
// Allows { loading: true, data, error } and { loading: false } with neither.
interface RequestBag<T> {
  loading?: boolean;
  data?: T;
  error?: Error;
}

type Request<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; error: Error };

function label(req: Request<string[]>): string {
  switch (req.status) {
    case "idle":
      return "Not started";
    case "loading":
      return "Loading";
    case "success":
      return `${req.data.length} items`;
    case "error":
      return req.error.message;
    default:
      // Fails to compile when a new status is added and not handled above.
      req satisfies never;
      throw new Error(`unhandled status: ${JSON.stringify(req)}`);
  }
}
```

`satisfies never` checks without declaring a variable. Projects with typescript-eslint can add `switch-exhaustiveness-check` to catch the same gap in every `switch`.

The tag must be a literal type, such as a string literal, number literal, `true`/`false`, `null`, or `undefined`. Destructuring the tag into a `const` still narrows the object.

```ts
type Result<T, E = Error> = { ok: true; value: T } | { ok: false; error: E };

function unwrap<T>(result: Result<T>): T {
  const { ok } = result;
  if (ok) return result.value;
  throw result.error;
}
```

Boolean parameters have the same problem at call sites. `render(true, false)` says nothing. Use an options object or a union of named modes.

```ts
declare function exportReport(format: "csv" | "pdf", options: { includeArchived: boolean }): void;
exportReport("csv", { includeArchived: true });
```

## Inputs per operation

`Partial<User>` as an update input allows `{}`, and lets callers send `id`. Write the input type each operation accepts.

```ts
interface User {
  id: string;
  name: string;
  email: string;
}
type RenameInput = Pick<User, "id" | "name">;
declare function rename(input: RenameInput): void;
rename({ id: "u1", name: "Ada" });
// @ts-expect-error name is required for a rename
rename({ id: "u1" });
```

## Result instead of throw

Throwing hides the failure from the type. Return a `Result` when the caller is expected to handle the failure, such as validation or a lookup that can miss. Throw when the failure is a bug or can't be handled where it's caught.

```ts
type ParseResult<T> = { ok: true; value: T } | { ok: false; issues: string[] };

function parsePort(input: string): ParseResult<number> {
  const port = Number(input);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    return { ok: false, issues: [`not a port: ${input}`] };
  }
  return { ok: true, value: port };
}

const parsed = parsePort("8080");
if (parsed.ok) console.log(parsed.value + 1);
else console.error(parsed.issues.join("\n"));
```

## IDs and checked values

Two `string` IDs are interchangeable to the compiler, so passing a `PostId` where a `UserId` belongs compiles. Brand them, see [boundaries.md](boundaries.md#brands).

## Literal unions over enums

A union of string literals, or an `as const` object for named values, gives the same checks as an `enum` with no runtime code. `--erasableSyntaxOnly` (TS 5.8) rejects `enum`, `namespace` with values, and constructor parameter properties, because Node's type stripping can't run them. Prefer the union in new code.

```ts
const Status = {
  Active: "active",
  Suspended: "suspended",
} as const;
type Status = (typeof Status)[keyof typeof Status];

function setStatus(status: Status) {}
setStatus(Status.Active);
setStatus("suspended");
// @ts-expect-error not a Status
setStatus("deleted");
```

## Optional versus undefined

`{ name?: string }` and `{ name: string | undefined }` differ. The first allows the key to be missing. The second requires the key, with `undefined` as a value. With `exactOptionalPropertyTypes`, `name?: string` also rejects an explicit `undefined`, so `{ name: undefined }` fails. That matches code that checks `"name" in obj`.

```ts
interface Profile {
  name?: string;
  bio: string | undefined;
}

const a: Profile = { bio: undefined };
// @ts-expect-error with exactOptionalPropertyTypes, a missing key and undefined differ
const b: Profile = { name: undefined, bio: "x" };
// @ts-expect-error bio is required, even though undefined is allowed
const c: Profile = {};
```

## Types to avoid

| Type | Problem | Use |
| --- | --- | --- |
| `{}` | Means any value except `null` and `undefined`, including `0` and `""` | `object`, `Record<string, unknown>`, or the real shape |
| `Object` | Accepts primitives like `{}` does, despite the name | `object` |
| `Function` | Calls return `any` | A signature such as `(...args: never[]) => unknown` |
| `object` as a record | Has no index signature, so reading a key fails | `Record<string, unknown>` |
| Mutable array parameter | The caller can't pass a `readonly` array | `readonly T[]` when the function doesn't mutate |

## Annotate at the edge

Let inference type locals. Annotate exported functions' parameters and return types. The annotation is the contract. A change inside the function that alters the return type then fails at the function, not at a distant caller. It also speeds up checking and is required under `isolatedDeclarations` (TS 5.5).

Pass type arguments to an empty `Map`. `new Map()` without them is `Map<any, any>`, so every `get` returns `any`.

```ts
const byId = new Map<string, { name: string }>();
byId.set("u1", { name: "Ada" });
// @ts-expect-error the value type is checked
byId.set("u2", { title: "Ada" });
```
