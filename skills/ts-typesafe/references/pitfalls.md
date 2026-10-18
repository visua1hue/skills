# Pitfalls and version facts

Claims about TS that are wrong, or were true only in older versions. Each fact was checked with `tsc --strict`. Before stating a behavior that depends on the version, read it with `npx tsc -v`.

## Narrowing

| Wrong claim | Fact | Since |
| --- | --- | --- |
| A check stored in a `const` boolean doesn't narrow | `const isStr = typeof v === "string"; if (isStr)` narrows `v`. Works for type predicate calls too | 4.4 |
| Narrowing is always lost inside callbacks | Kept for `const` and for parameters never assigned. Since 5.4, also kept for `let` and reassigned parameters when the closure is created after the last assignment | 5.4 |
| A guard needs an explicit `x is T` | An arrow such as `(x) => x !== undefined` infers the predicate. `.filter(Boolean)` and `!!x` still don't narrow | 5.5 |
| `obj[key]` can't be narrowed | Narrows when `obj` and `key` are both `const` or never reassigned | 5.5 |
| `"key" in value` only works for keys the type lists | On an unlisted key it narrows to `{ key: unknown }`, so a guard can check `typeof value.key` | 4.9 |

```ts
function inClosure(input: string | undefined) {
  let current = input;
  if (current !== undefined) {
    // Created after the last assignment: narrowing holds.
    setTimeout(() => current.length);
  }
}

function reassignedLater(input: string | undefined) {
  let current = input;
  if (current !== undefined) {
    // @ts-expect-error current is assigned below, so the closure can see undefined
    queueMicrotask(() => current.length);
  }
  current = undefined;
}

function indexed(record: Record<string, unknown>, key: string) {
  if (typeof record[key] === "string") record[key].toUpperCase();
}
```

The second function is also a runtime bug, because the microtask runs after `current = undefined`. Adding `!` silences the error and keeps the crash. Copy the value into a `const` before creating the closure.

## Inference and literals

| Wrong claim | Fact | Since |
| --- | --- | --- |
| `const status = "active"` widens to `string` | `const` keeps `"active"`. `let` widens, and so do object properties | all |
| `const` type parameters need a `readonly` array constraint | A mutable constraint such as `string[]` also infers a tuple | 5.3 |
| `const T` narrows any argument | It narrows only literals written at the call site. A variable keeps its declared type | 5.0 |
| An unused type parameter still distinguishes `C<A>` from `C<B>` | Types compare by structure. An unused parameter makes all instantiations equal, so a phantom check passes everything | all |
| `Parameters<typeof overloaded>` covers every overload | It sees only the last overload | all |

## Guards and assertions

| Wrong claim | Fact | Since |
| --- | --- | --- |
| A type predicate is checked | TS trusts the body. A guard that checks only key presence is a cast | all |
| Assertion functions must be `function` declarations | An arrow works when its variable has an explicit type. Without one, calls fail with TS2775 | 3.7 |
| A naive `A extends B ? B extends A ? true : false : false` checks equality | It treats `any` as equal to everything. Use the `Equal` in [type-tests.md](type-tests.md) | all |

## Mapped, conditional, and template literal types

| Wrong claim | Fact | Since |
| --- | --- | --- |
| Key remapping with `as` drops `?` and `readonly` | A remap over `keyof T` keeps both. `+?` adds `?` to every key | 4.1 |
| A recursive mapped type with no primitive base case recurses forever | Mapped types return primitives unchanged | all |
| A recursive mapped type handles every value | Functions lose their call signatures. Stop the recursion at functions | all |
| Template literal `infer` is greedy | Each hole takes text up to the first match of the literal after it. A literal at the end of the pattern matches at the end of the string | 4.1 |
| `Omit<T, K>` rejects unknown keys | `K` is any `PropertyKey`, so a typo compiles. It isn't distributive over unions either | all |
| Template literal inference splits by UTF-16 code unit | TS 7 splits by Unicode code point | 7.0 |

## Configuration and tooling

| Wrong claim | Fact | Since |
| --- | --- | --- |
| Without `"strict": true` the project isn't strict | `strict` is the default | 6.0 |
| `@types/*` packages load automatically | `types` defaults to `[]`. List the packages | 6.0 |
| `tsc file.ts` checks one file with the project's config | Fails with TS5112 when a `tsconfig.json` is present. Use `-p` or `--ignoreConfig` | 6.0 |
| `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` are part of `strict` | Neither is. Set them explicitly | all |
| typescript-eslint works with any TS version | 8.71 requires `typescript` below 6.1. On TS 7, keep a TS 6 package for typed linting | 7.0 |
| `Object.keys(obj)` should return `(keyof T)[]` | It returns `string[]` because objects can carry extra keys at runtime | all |
| Excess property checks catch every extra field | Only on fresh literals. A literal stored in a variable first passes | all |
