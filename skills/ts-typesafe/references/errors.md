# Diagnosing type errors

Find the cause before changing code. A fix that makes the error disappear without explaining it usually moves the bug somewhere else.

## Reading an error

The first line names the outer mismatch. Each indented line goes one level deeper. The last line names the specific property or type that fails, so read it first, then walk up to see where it sits.

```
error TS2322: Type '{ name: string; tags: number[]; }' is not assignable to type 'Post'.
  Types of property 'tags' are incompatible.
    Type 'number[]' is not assignable to type 'string[]'.
      Type 'number' is not assignable to type 'string'.
```

The cause here is `tags`. Fix the code that produces `number[]`, or the type, depending on which one is wrong.

## Printing a type

An agent can't hover in an editor. To see what TS inferred, assign the value to a type it can't match. The error prints the full type. Remove the probe once read.

```ts
declare const value: { id: number; tags: readonly string[] };
// @ts-expect-error probe: the error message shows typeof value
const probe: { __probe: true } = value;
```

For a type alias, compare it against a guess with `Equal` from [type-tests.md](type-tests.md). When the error shows an alias name or `A & B` instead of the shape, wrap the type in `Prettify` from [type-level.md](type-level.md).

## Isolating

Copy the failing code into a scratch file, replace imports with `declare` statements, and cut code until the error is as small as possible. Check it with `npx tsc --noEmit --strict scratch.ts`, adding `--ignoreConfig` on TS 6 and later when a `tsconfig.json` sits in the same folder. Match the project's flags, since `exactOptionalPropertyTypes` and `noUncheckedIndexedAccess` change results.

Test a hypothesis with `@ts-expect-error`. If the comment is reported as unused (TS2578), the line compiles and the hypothesis is wrong.

## Widening

A `let` declaration widens a literal to its base type, because the variable can be reassigned. A `const` keeps the literal type. Object and array properties widen even under `const`, since they are mutable.

```ts
type Status = "active" | "inactive";
declare function setStatus(s: Status): void;

const fixed = "active";
setStatus(fixed);

let changing = "active";
// @ts-expect-error let widens to string
setStatus(changing);

let annotated: Status = "active";
annotated = "inactive";
setStatus(annotated);

const config = { status: "active" };
// @ts-expect-error the property widens to string
setStatus(config.status);
```

Fix a widened `let` with an annotation. `as const` on a `let` initializer keeps only that literal, so a later assignment of another member fails. For an object, use an annotation or `satisfies`, or `as const` when the object never changes.

## Excess property checks

TS rejects unknown properties only on a fresh object literal, written directly where the type is expected. A literal stored in a variable first passes, because the variable is a subtype. `satisfies` on the declaration brings the check back.

```ts
interface Point {
  x: number;
  y: number;
}

// @ts-expect-error z is not in Point
const direct: Point = { x: 1, y: 2, z: 3 };

const stored = { x: 1, y: 2, z: 3 };
const passes: Point = stored;

// @ts-expect-error satisfies checks the literal
const checked = { x: 1, y: 2, z: 3 } satisfies Point;
```

## "Could be instantiated with a different subtype"

Inside a generic function, `T extends X` means T is some subtype of X, maybe with more properties or narrower literals. A fresh object of type X is not a T, so returning one fails with TS2322. Return a value built from the T the caller passed, or change the return type to X.

```ts
interface Options {
  retries: number;
}

function withDefaults<T extends Options>(opts: Partial<T>): T {
  // @ts-expect-error T could be instantiated with a different subtype of Options
  return { retries: 3, ...opts };
}

function withDefaultsHonest(opts: Partial<Options>): Options {
  return { retries: 3, ...opts };
}
```

## Common codes

| Code | Meaning | Usual cause and fix |
| --- | --- | --- |
| TS2322 | Type not assignable | Read the last line. Widening, a missing property, or a wrong generic |
| TS2345 | Argument not assignable | Same as TS2322, at a call. Check which overload TS tried |
| TS2339 | Property doesn't exist | The value is a union or `unknown`. Narrow first |
| TS18047, TS18048 | Possibly `null`, possibly `undefined` | Handle the missing case. Not `!` |
| TS18046 | Value is `unknown` | Narrow or parse it |
| TS2353 | Object literal has unknown property | A typo, or the type is missing a field |
| TS2741 | Property missing | The value lacks a required field |
| TS2367 | Comparison has no overlap | The check can never be true. Often a stale union member |
| TS2769 | No overload matches | Errors list each overload. Find the intended one |
| TS7006, TS7053 | Implicit `any` parameter or index | Annotate the parameter, or type the key as `keyof` |
| TS2589 | Instantiation excessively deep | Recursive type without a base case, or not tail-recursive |
| TS2590 | Union too complex | A template literal or mapped type over large unions |
| TS2775 | Assertion needs explicit annotation | Annotate the variable holding an arrow assertion function |
| TS1360 | Doesn't satisfy | `satisfies` failed, or `satisfies never` found an unhandled case |
| TS2578 | Unused `@ts-expect-error` | The line compiles now. Remove the comment or fix the test |
| TS5112 | tsconfig present with file arguments (TS 6+) | Use `-p`, or `--ignoreConfig` |
| TS1287 | `export` in a CommonJS module under `verbatimModuleSyntax` | Set an ESM `module` |

## When the library's types are wrong

Don't edit `node_modules` or cast at every call site. Wrap the call once at the boundary and parse the result, see [boundaries.md](boundaries.md). Add a missing member with module augmentation. Report the bug upstream.

```ts skip
declare module "some-lib" {
  interface Options {
    timeoutMs?: number;
  }
}
```
