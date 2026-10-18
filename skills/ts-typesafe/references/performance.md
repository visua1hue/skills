# Type checking performance

Rule TS10. Measure before changing types for speed, and measure again after. A change that makes types less precise needs a measured gain to justify it.

## Measure

1. `npx tsc --noEmit -p . --extendedDiagnostics` prints check time, the number of types and instantiations, and memory. Record it before the change.
2. `npx tsc --noEmit -p . --generateTrace trace` writes a trace to `trace/`. `npx @typescript/analyze-trace trace` lists the files and expressions that took longest. Both work with TS 7.
3. Change one thing, run step 1 again, and report both numbers.

## TS 7

TS 7 is the native compiler. Full builds are about 8 to 12 times faster than TS 6. It checks files in parallel. `--checkers` sets the number of checker workers (default 4), `--builders` sets parallel project builds under `--build`, and `--singleThreaded` turns parallelism off for debugging. On a slow project, check whether moving to TS 7 is possible before rewriting types, see [tsconfig.md](tsconfig.md#ts-6-and-7-defaults-and-removals).

## Patterns that cost check time

| Pattern | Cost | Change |
| --- | --- | --- |
| Deep or non-tail recursive conditional types | Instantiations grow with depth | Tail recursion with an accumulator, or a plain type when callers don't need the precision |
| Template literal types over large unions | The union size is the product of the parts | Narrow the parts, or use `string` with a runtime check |
| Intersections of object types | TS caches relationships between intersections less well than between interfaces, and a property conflict becomes `never` with no error | `interface B extends A`, which is one flat type and reports conflicts |
| Unannotated return types of large exported functions | Every importer re-infers them, and declaration output grows | Annotate exported return types. `isolatedDeclarations` enforces it |
| Unions of more than a dozen members | Each argument is compared against every member, and removing duplicate members is quadratic | A base type with subtypes, or smaller unions |
| Complex conditional types written inline in a signature | Re-evaluated on every call | Extract a named type alias, which TS can cache |

```ts
interface Base {
  id: string;
  createdAt: Date;
}

// Relationships are cached less well, and conflicting properties become never.
type AuditedIntersection = Base & { updatedBy: string };

// One flat type. A conflicting property is an error at the declaration.
interface Audited extends Base {
  updatedBy: string;
}
```

## Project setup

- `include` lists only source folders, so `dist`, `coverage`, and generated files stay out. Walking extra directories costs time, and stray `.d.ts` files add checking.
- `types` lists the global type packages the code uses. TS 6 and later default to none.
- `skipLibCheck: true` skips checking declaration files from dependencies.
- `incremental: true` stores build info and rechecks only changed files.
- In a monorepo, project references with `composite: true` let each package build once and in parallel with `tsc --build`. Each project adds overhead, so split by package, not by folder. Split an existing project only when a trace shows its size is the cause, not one slow type.

## Editor

A slow editor with a fast `tsc` usually means the editor runs a different TS version or config. Check the version the editor uses. For TS 7, VS Code needs the TypeScript native preview extension (`TypeScriptTeam.native-preview`). Embedded languages such as Vue, Svelte, Astro, and MDX still need TS 6 for editor support.
