---
name: ts-typesafe
description: TypeScript type safety, with types that match runtime and that the compiler proves. Use whenever writing, editing, or reviewing TypeScript (.ts, .tsx), when tsc or the editor reports a type error, when adding or removing `any`, `as`, `!`, or `@ts-ignore`, when parsing JSON, API responses, or other untrusted input, when designing types, generics, or type guards, when changing tsconfig, or when type checking is slow.
---

# ts-typesafe

A type is a claim about runtime. The compiler proves the claim, or a check at the boundary verifies it. Code that trusts a type backed by neither fails on the first input that breaks the claim.

## Modes

- **Fix.** A type error. Read [references/errors.md](references/errors.md).
- **Harden.** Remove `any`, `as`, `!`, and suppressions. Read [references/boundaries.md](references/boundaries.md).
- **Design.** Types for a new API or module. Read [references/modeling.md](references/modeling.md) and [references/generics.md](references/generics.md).
- **Review.** Check a diff against the rules below. Cite rule ids (`TS2`) and [references/pitfalls.md](references/pitfalls.md) entries.

## Workflow

1. Run the type check and keep the output. Use the project's script if it has one, such as `npm run typecheck`, else `npx tsc --noEmit -p .`. On TS 6 and later, `tsc file.ts` fails with TS5112 when a `tsconfig.json` is present. Pass `-p`, or `--ignoreConfig` for a scratch file.
2. Read the version with `npx tsc -v`. Advice that depends on a version says which one, see [references/pitfalls.md](references/pitfalls.md).
3. Find the root cause. Read the last line of the error first. When a type is unclear, print it with the probe in [references/errors.md](references/errors.md) instead of guessing.
4. Make the smallest type change that removes the cause (`eng-principles` P1, P10). Don't silence the error with `as`, `any`, or a suppression.
5. When a contract type changed, add a type test with a case that must compile and a case that must fail, see [references/type-tests.md](references/type-tests.md). A contract type is anything callers depend on, such as an exported signature, a public generic, or a builder.
6. Run the type check again. The reply shows the command and its result.

A clean type check proves types, not behavior. Behavior still needs a test or a run (`eng-principles` P11, `tests-by-contract`).

## Rules

Numbers are stable ids. Cite them in replies and reviews (`TS7`). A removed rule leaves a gap.

1. **Parse untrusted input once, at the boundary.** Data from `JSON.parse`, `Response.json()`, `postMessage`, storage, env vars, and queues is `unknown` until a schema or a checking parser returns a typed value. A guard checks value types, not only that keys exist.
2. **No unchecked escape hatch.** In production code, each `any`, narrowing `as`, `!`, and `@ts-expect-error` carries a comment that says why it holds. `@ts-ignore` and `as unknown as T` don't appear. An upcast such as `as readonly string[]` is safe, but an annotation or `satisfies` states it without `as`.
3. **Brand values that passed a check.** The brand's parser or constructor holds the only `as` for that brand.
4. **Model states as discriminated unions,** not objects of optional fields. End each `switch` over a union with `satisfies never` in the default branch.
5. **Infer inside, annotate at the edge.** Let inference type locals. Annotate the parameters and return types of exported functions.
6. **Use `satisfies` to check a literal and keep its literal type.** Use an annotation when the value should widen to the declared type.
7. **A type parameter links two positions,** an input to the output or two inputs. A parameter that appears once, or only in the return type, is a cast in disguise. Remove it.
8. **Steer inference on purpose.** A `const` type parameter keeps literal types without `as const` at the call site. `NoInfer` stops a parameter from widening the inferred type. A phantom type parameter must appear in the type's structure, or it checks nothing.
9. **Prefer a union or a generic over overloads.** Use overloads only when the return type depends on the input in a way neither can express.
10. **Type-level code pays off at call sites or goes.** Prefer a built-in (`Awaited`, `NoInfer`, `ReturnType`) or a plain union over a custom recursive type. Measure deep recursion with `--extendedDiagnostics`.
11. **Contract types get type tests,** including a case that must fail.
12. **Start from the strict baseline** in [references/tsconfig.md](references/tsconfig.md). Turn a flag on to catch a bug class. Never turn a flag off to clear an error.
13. **Don't trust lib defaults.** `JSON.parse` and `Response.json()` return `any`. Index access returns `T`, not `T | undefined`, without `noUncheckedIndexedAccess`. `Object.keys` returns `string[]` on purpose. `.filter(Boolean)` doesn't narrow.

## References

| File | Read when |
| --- | --- |
| [references/errors.md](references/errors.md) | A type error needs a diagnosis |
| [references/boundaries.md](references/boundaries.md) | Data enters from outside, or `any`, `as`, `!` need to go |
| [references/modeling.md](references/modeling.md) | Designing the types for states, IDs, results, or options |
| [references/generics.md](references/generics.md) | Writing or fixing a generic, inference, or overloads |
| [references/type-level.md](references/type-level.md) | Writing conditional, mapped, or template literal types |
| [references/type-tests.md](references/type-tests.md) | A contract type changed |
| [references/tsconfig.md](references/tsconfig.md) | Setting up or tightening compiler options |
| [references/pitfalls.md](references/pitfalls.md) | A claim about TS behavior needs checking, or advice depends on the version |
| [references/performance.md](references/performance.md) | Type checking or the editor is slow |

Every `ts` block in this skill was compiled on TS 5.5 and 7.0 with the baseline in [references/tsconfig.md](references/tsconfig.md). Blocks marked `ts skip` need a library and were not compiled. Sources and licenses are in [SOURCES.md](SOURCES.md).

## Related skills

- `eng-principles`. P6 (data shape first) decides what the types model. This skill decides how.
- `tests-by-contract`. Runtime tests. Type tests here follow the same value bar.
