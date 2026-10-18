# Boundaries and escape hatches

Rules TS1, TS2, TS3, TS13. Data from outside the program has no type until code checks it. Inside the boundary, types carry the proof and nothing re-checks.

## Where the boundary is

`JSON.parse`, `Response.json()`, `postMessage` and `MessageEvent.data`, `localStorage`, `process.env`, CLI arguments, queue and webhook payloads, files, and database rows from an untyped driver. Third-party types that lie are a boundary too.

`JSON.parse` and `Response.json()` return `any`, and `any` spreads to every value computed from it with no error. Assign the result to `unknown` first.

## Checking parser

A type predicate is trusted, not checked. TS accepts `value is User` even when the body checks nothing, so a loose guard is a cast. Check each value type, not only that the key exists.

```ts
interface User {
  id: string;
  name: string;
  posts: string[];
}

// Wrong: `{ id: 1, name: null, posts: "x" }` passes.
function isUserLoose(value: unknown): value is User {
  return typeof value === "object" && value !== null && "id" in value && "name" in value && "posts" in value;
}

// Since TS 4.9, `"id" in value` narrows to `{ id: unknown }`, so each check reads the property without `as`.
function isUser(value: unknown): value is User {
  return (
    typeof value === "object" &&
    value !== null &&
    "id" in value &&
    typeof value.id === "string" &&
    "name" in value &&
    typeof value.name === "string" &&
    "posts" in value &&
    Array.isArray(value.posts) &&
    value.posts.every((post) => typeof post === "string")
  );
}

export async function getUser(id: string): Promise<User> {
  const res = await fetch(`https://api.example.com/users/${encodeURIComponent(id)}`);
  if (!res.ok) throw new Error(`GET user ${id}: HTTP ${res.status}`);
  const body: unknown = await res.json();
  if (!isUser(body)) throw new Error(`GET user ${id}: unexpected response shape`);
  return body;
}
```

## Schema libraries

For more than a few fields, or nested data, use a schema library. It checks the data and derives the type from one definition, so the two can't drift apart. Don't hand-write an interface next to the schema. Zod, Valibot, and ArkType implement [Standard Schema](https://standardschema.dev), so code that accepts a schema can take any of them. Use the library the project already has. Don't add one for a single check.

A schema with transforms or defaults has an input type and a different output type. Type the parsed value with the output type (`z.output`, `StandardSchemaV1.InferOutput`). A generic helper over Standard Schema must handle a `validate` that returns a Promise, and treats a result without `issues` as success.

```ts skip
import { z } from "zod";

const User = z.object({ id: z.string(), name: z.string(), posts: z.array(z.string()) });
type User = z.infer<typeof User>;

const user = User.parse(await res.json()); // throws on a bad shape
const result = User.safeParse(raw); // returns { success, data | error } instead
```

## Outbound boundaries

A value can carry more properties than its type lists, so returning `user` typed as `PublicProfile` still sends `passwordHash` through `JSON.stringify`. At serialization and logging boundaries, build a new object with the fields to send.

```ts
interface PublicProfile {
  id: string;
  name: string;
}
interface UserRow extends PublicProfile {
  passwordHash: string;
}

// Compiles, and leaks passwordHash into the response body.
function toProfileLeaky(row: UserRow): PublicProfile {
  return row;
}

function toProfile(row: UserRow): PublicProfile {
  return { id: row.id, name: row.name };
}
```

## Escape hatches

| Hatch | Replace with |
| --- | --- |
| `any` | `unknown`, then narrow or parse |
| `as T` that narrows | A checking parser, a guard that checks value types, or a schema |
| `as unknown as T` | Nothing. Fix the types. In tests, see below |
| `!` | An explicit check that handles or throws |
| `@ts-ignore` | A fix. If one can't land now, `@ts-expect-error` with the reason, so the comment fails once the error is gone |
| `as` in test data | `fromPartial` from `@total-typescript/shoehorn` |

An upcast, from a narrower type to a wider one, is safe. An annotation says the same thing without `as`, so a later edit can't turn it into a downcast.

```ts
const ROLES = ["admin", "editor", "viewer"] as const;
type Role = (typeof ROLES)[number];

// ROLES.includes(value) fails: the parameter type is Role, not string.
const roleNames: readonly string[] = ROLES;

function isRole(value: string): value is Role {
  return roleNames.includes(value);
}
```

A `!` is a claim that the value exists. Replace it with code that decides what happens when the value is missing.

```ts
declare const cache: Map<string, { name: string }>;

function nameOf(id: string): string {
  const user = cache.get(id);
  if (user === undefined) throw new Error(`user ${id} not loaded`);
  return user.name;
}
```

## Assertion functions

An assertion function narrows its argument for the rest of the scope, or throws. A `function` declaration works as is. An arrow function works only when its variable has an explicit type annotation. Without the annotation, the call fails with TS2775.

```ts
function assertString(value: unknown): asserts value is string {
  if (typeof value !== "string") throw new TypeError(`expected string, got ${typeof value}`);
}

const assertNumber: (value: unknown) => asserts value is number = (value) => {
  if (typeof value !== "number") throw new TypeError(`expected number, got ${typeof value}`);
};

const assertBoolean = (value: unknown): asserts value is boolean => {
  if (typeof value !== "boolean") throw new TypeError(`expected boolean, got ${typeof value}`);
};

declare const input: unknown;
assertString(input);
assertNumber(input);
// @ts-expect-error TS2775: the variable needs an explicit type annotation
assertBoolean(input);
```

## Brands

A brand marks a value that passed a check, so a function can require the checked form. The parser holds the brand's only `as`. A `unique symbol` key doesn't show up in autocomplete and can't clash with a real property.

```ts
declare const brand: unique symbol;
type Brand<T, Name extends string> = T & { readonly [brand]: Name };

type Email = Brand<string, "Email">;

function parseEmail(input: string): Email | undefined {
  // The one `as` for Email: the regex check above it is what makes it true.
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(input) ? (input as Email) : undefined;
}

declare function sendInvite(to: Email): void;

const email = parseEmail("ada@example.com");
if (email) sendInvite(email);
// @ts-expect-error a plain string is not an Email
sendInvite("ada@example.com");
```

A brand proves the check ran, nothing more. It doesn't stop a secret from being logged.

## Lib defaults that lie

- **Catch variables.** Under `strict`, `catch (e)` gives `e: unknown`. Narrow with `e instanceof Error` before reading `.message`. Don't annotate `catch (e: any)`.
- **`Array.isArray`.** On an `unknown` value it narrows to `any[]`. Check each element before using it.
- **Index access.** `arr[i]` and `record[key]` return `T`, not `T | undefined`, unless `noUncheckedIndexedAccess` is on.
- **`Object.keys`.** It returns `string[]` because an object can carry more keys than its type lists. Casting the result to `(keyof T)[]` is a claim that can be false.

```ts
interface Point {
  x: number;
  y: number;
}
const point3d = { x: 1, y: 2, z: 3 };
const point: Point = point3d; // allowed: excess property checks apply only to fresh literals
const keys = Object.keys(point); // ["x", "y", "z"] at runtime
```

- **`.filter(Boolean)`.** It doesn't narrow. Since TS 5.5, an arrow that returns a narrowing check infers a type predicate, so `.filter((x) => x !== undefined)` does narrow. TS infers the predicate only when the check returns `false` for no value of the narrowed type. `.filter((x) => !!x)` on `(number | undefined)[]` doesn't narrow, because it also returns `false` for `0`.

```ts
const raw = ["a", undefined, "b"];

const kept = raw.filter((s) => s !== undefined);
const strings: string[] = kept;

const truthy = raw.filter(Boolean);
// @ts-expect-error filter(Boolean) keeps (string | undefined)[]
const notNarrowed: string[] = truthy;
```

`@total-typescript/ts-reset` changes these globals for a whole app. `JSON.parse` and `.json()` return `unknown`, and `.filter(Boolean)` narrows. Use it in applications only. In a library it changes the global types of every consumer.
