# Type tests

Rule TS11. A type test runs in the compiler, and it passes when the file type-checks. Write one when a contract type changes, meaning an exported signature, a public generic, a builder, or an inferred type callers depend on. Apply the value bar from `tests-by-contract`: each test protects a behavior a caller relies on.

## Two kinds of case

- **Must compile, with the right type.** Check the inferred type with an exact equality, not just assignability. `const x: string = value` also passes when `value` is `any` or `never`.
- **Must fail.** Put `@ts-expect-error` on the line above the call that must be rejected. If that line ever compiles, the unused comment fails with TS2578, so the test breaks when the type gets looser.

A contract test has both. A builder whose tests only cover the valid chain passes even when the type rejects nothing.

## Helpers with no dependencies

```ts
// True only when A and B are identical, including any, never, and readonly.
type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
type Expect<T extends true> = T;

declare function pluck<T, K extends keyof T>(items: readonly T[], key: K): T[K][];
const users = [{ id: 1, name: "Ada" }];

// Must compile, with the exact type.
const names = pluck(users, "name");
type _names = Expect<Equal<typeof names, string[]>>;

// Must fail.
// @ts-expect-error "email" is not a key
pluck(users, "email");

// Assignability alone misses any.
declare const loose: any;
const passes: string[] = loose;
// @ts-expect-error Equal catches it
type _loose = Expect<Equal<typeof loose, string[]>>;
```

A function that leaks `any`, such as a wrapper around `JSON.parse`, passes most checks. Test for it directly.

```ts
type Expect<T extends true> = T;
type IsAny<T> = 0 extends 1 & T ? true : false;
type IsNotAny<T> = IsAny<T> extends true ? false : true;

declare function parseConfig(text: string): unknown;
type _safe = Expect<IsNotAny<ReturnType<typeof parseConfig>>>;
// @ts-expect-error JSON.parse returns any
type _leak = Expect<IsNotAny<ReturnType<typeof JSON.parse>>>;
```

## Keep each failing case narrow

`@ts-expect-error` passes on any error in the next line, including a typo or a missing import. Keep the line to the one expression under test, and write the reason after the comment. When a case could fail for the wrong reason, also assert the passing variant on its own line.

```ts
declare function setPort(port: number): void;

setPort(8080);
// @ts-expect-error a string is not a port
setPort("8080");
```

## Where tests live

Put type tests in `*.test-d.ts` files next to the source, and make sure the type check includes them. A file outside the tsconfig's `include` is never checked, so its tests pass without running. After adding one, break an assertion on purpose once and confirm the type check fails.

## Test runners

Use what the project has. Vitest checks types with `expectTypeOf` in `*.test-d.ts` files only when run with `vitest --typecheck`. Without the flag, `expectTypeOf` does nothing. `expect-type` gives the same API without Vitest, and `tsd` checks `.test-d.ts` files against a package's published declarations.

In `expectTypeOf`, `toEqualTypeOf` checks an exact match and `toExtend` checks assignability. `toMatchTypeOf` is deprecated. `.not.toBeAny()` catches a leaked `any`. Negative matchers such as `.not.toEqualTypeOf` fail on a typo, where `@ts-expect-error` would pass.

```ts skip
import { expectTypeOf, test } from "vitest";

test("pluck keeps the property type", () => {
  expectTypeOf(pluck(users, "name")).toEqualTypeOf<string[]>();
  expectTypeOf(pluck).parameter(1).toEqualTypeOf<"id" | "name">();
});
```

## Test data in runtime tests

Building a full object to satisfy a large type tempts `as`. `fromPartial` from `@total-typescript/shoehorn` takes a partial object and checks the fields it has. Use it in test code only.
