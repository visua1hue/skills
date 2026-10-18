# Compiler and lint settings

Rule TS12. Each flag turns a class of runtime bug into a compile error. Turn a flag on to catch that class. Never turn one off, or add `@ts-nocheck`, to clear errors.

## Baseline for new code

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "skipLibCheck": true
  }
}
```

Add `target`, `module`, `moduleResolution`, `lib`, and `types` for the runtime. `verbatimModuleSyntax` needs an ESM `module` such as `esnext`, `preserve`, or `nodenext`. On TS 5.x, where `module` defaults to `commonjs`, every `export` fails with TS1287 until `module` is set. For Node with type stripping, also set `erasableSyntaxOnly`. Every `ts` block in this skill compiles under this baseline.

## What `strict` turns on

`strict` turns on a family of flags, and new versions of TS add to it. It is the default from TS 6.

| Flag | Catches |
| --- | --- |
| `strictNullChecks` | Using a value that can be `null` or `undefined` without checking |
| `noImplicitAny` | Parameters and variables that become `any` with no error |
| `strictFunctionTypes` | Passing a callback that accepts a narrower parameter than callers give it |
| `strictBindCallApply` | Wrong arguments to `.bind`, `.call`, `.apply` |
| `strictPropertyInitialization` | Class fields read before the constructor assigns them |
| `noImplicitThis` | `this` typed `any` in functions |
| `useUnknownInCatchVariables` | Reading `.message` on a thrown value that may not be an `Error` |
| `alwaysStrict` | Code that behaves differently outside JS strict mode |
| `strictBuiltinIteratorReturn` (5.6) | Using the `TReturn` of built-in iterators as `any` |

## Flags outside `strict`

| Flag | Catches | Cost |
| --- | --- | --- |
| `noUncheckedIndexedAccess` | `arr[i]` and `record[key]` read as defined when they may be missing | Many errors in existing code. Loops over `for...of` stay clean |
| `exactOptionalPropertyTypes` | Writing `undefined` to a key declared optional, where code checks `"key" in obj` | Some library types need updates |
| `noImplicitOverride` | A subclass method that stops overriding after the base renames it | Add `override` once |
| `noImplicitReturns` | A code path that falls off the end of a function that returns a value | Low |
| `noFallthroughCasesInSwitch` | A `case` that runs into the next one by mistake | Low |
| `noPropertyAccessFromIndexSignature` | `obj.typo` on an index signature, by requiring `obj["key"]` | Style cost. Optional |
| `verbatimModuleSyntax` | Type-only imports that a bundler or Node would keep as runtime imports | Use `import type` |
| `isolatedModules` | Code a single-file transpiler (esbuild, swc, Babel) can't compile | Low |
| `erasableSyntaxOnly` (5.8) | `enum`, value `namespace`, parameter properties, which Node's type stripping can't run | Rewrite those constructs |
| `noUncheckedSideEffectImports` (5.6) | `import "./typo.css"` that resolves to nothing | Default from TS 6 |
| `isolatedDeclarations` (5.5) | Exports whose types must be inferred, which blocks fast declaration emit | For libraries. Annotate exports |

`skipLibCheck: true` skips checking `.d.ts` files. It hides conflicts between dependency types but saves time. Keep it on unless debugging a declaration conflict.

## TS 6 and 7 defaults and removals

TS 6 changed defaults and deprecated old options. TS 7, the native compiler, removes the deprecated options. A config that worked on 5.x can fail or behave differently.

| Change | Effect | Fix |
| --- | --- | --- |
| `strict` defaults to `true` | A config without `strict` gets new errors | Fix them, or set `strict` explicitly during migration |
| `types` defaults to `[]` | `@types/node` and other global types stop loading, so `process` and `describe` are unknown | List them: `"types": ["node"]` |
| `module` defaults to `esnext`, `target` to the latest ES version | Output changes when these were unset | Set both explicitly |
| `rootDir` defaults to the tsconfig's folder | Output paths shift when it was inferred before | Set `rootDir` |
| `baseUrl` removed | Bare imports resolved through `baseUrl` fail | `paths` entries relative to the tsconfig, or `#/` subpath imports |
| `moduleResolution: node` (`node10`) and `classic` removed | Config error | `bundler` for bundled apps, `nodenext` for Node |
| `esModuleInterop: false`, `allowSyntheticDefaultImports: false` disallowed | Config error | Remove them |
| `target: es5`, `downlevelIteration`, `outFile`, AMD, UMD, SystemJS removed | Config error | A bundler for old targets and single-file output |
| `import x from "y" assert {}` removed | Syntax error | `with { type: "json" }` |
| `tsc file.ts` next to a `tsconfig.json` | TS5112 | `tsc -p .`, or `--ignoreConfig` for a scratch file |

TS 7 ships without the old compiler API. Tools that need it, including typescript-eslint, run on `@typescript/typescript6` installed alongside. typescript-eslint 8.71 requires `typescript` below 6.1, so check a repo with typed lint rules before moving its `typescript` dependency to 7.

## Tightening an existing codebase

1. Turn on one flag at a time, in its own PR.
2. Start with `strictNullChecks`. It finds the most real bugs and the most errors. `noImplicitAny` comes next.
3. When a flag yields too many errors for one PR, add a second tsconfig whose `include` lists only the converted folders, and run it in CI next to the main one. Grow the list until it covers everything, then move the flag to the main config.
4. Fix each error at its cause. Mass-adding `!`, `as`, or `@ts-expect-error` to get a flag on trades a visible error for a hidden one.

## Lint rules that enforce this skill

The compiler can't see every escape hatch. typescript-eslint's typed rules can. Checked against typescript-eslint 8.71.

| Skill rule | typescript-eslint rule | In `strict-type-checked` |
| --- | --- | --- |
| TS1, TS13 | `no-unsafe-assignment`, `no-unsafe-member-access`, `no-unsafe-call`, `no-unsafe-return`, `no-unsafe-argument` | Yes |
| TS2 | `no-explicit-any`, `no-non-null-assertion`, `ban-ts-comment`, `no-unnecessary-type-assertion` | Yes |
| TS2 | `no-unsafe-type-assertion`, which reports only narrowing assertions | No, add it |
| TS4 | `switch-exhaustiveness-check` | No, add it |
| TS7 | `no-unnecessary-type-parameters` | Yes |
| TS13 | `use-unknown-in-catch-callback-variable`, `only-throw-error` | Yes |
| Modeling | `no-empty-object-type`, `no-wrapper-object-types`, `no-unsafe-function-type` | Yes |

When a mistake from this skill keeps coming back in a repo, add the matching rule instead of another comment (`eng-principles` P5).
