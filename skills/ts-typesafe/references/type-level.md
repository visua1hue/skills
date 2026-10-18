# Type-level code

Rule TS10. Conditional, mapped, and template literal types are code that runs in the compiler. Each one costs check time and reader time, so it must make call sites safer or simpler than a plain type would. Prefer a built-in when one fits. Every recipe below compiles, and each gotcha shows the behavior with a check.

The `Equal` and `Expect` helpers used here are defined in [type-tests.md](type-tests.md).

## Built-ins first

`Partial`, `Required`, `Readonly`, `Pick`, `Omit`, `Record`, `Exclude`, `Extract`, `NonNullable`, `Parameters`, `ReturnType`, `ConstructorParameters`, `InstanceType`, `Awaited`, `NoInfer`, `Uppercase`, `Lowercase`, `Capitalize`, `Uncapitalize`.

`Omit` has two traps. It doesn't check its keys, so a typo omits nothing and compiles. It isn't distributive, so on a union it keeps only the shared keys and drops the tag's narrowing.

```ts
type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
type Expect<T extends true> = T;

interface User {
  id: string;
  name: string;
}
type Typo = Omit<User, "nmae">; // compiles, omits nothing
type _typo = Expect<Equal<Typo, { id: string; name: string }>>;

type StrictOmit<T, K extends keyof T> = Omit<T, K>;
// @ts-expect-error "nmae" is not a key of User
type Caught = StrictOmit<User, "nmae">;

type Shape = { kind: "circle"; r: number; id: string } | { kind: "square"; side: number; id: string };
type Collapsed = Omit<Shape, "id">;
type _collapsed = Expect<Equal<keyof Collapsed, "kind">>;

type DistributiveOmit<T, K extends PropertyKey> = T extends unknown ? Omit<T, K> : never;
type Kept = DistributiveOmit<Shape, "id">;
type _kept = Expect<Equal<Kept, Omit<{ kind: "circle"; r: number; id: string }, "id"> | Omit<{ kind: "square"; side: number; id: string }, "id">>>;
```

## Conditional types

A conditional type whose checked type is a bare type parameter distributes over a union. It runs once per member and unions the results. Wrap both sides in a tuple to check the union as a whole. `never` is the empty union, so a distributive conditional on `never` returns `never` without running. `any` in the checked position returns both branches.

```ts
type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
type Expect<T extends true> = T;

type ToArray<T> = T extends unknown ? T[] : never;
type _dist = Expect<Equal<ToArray<string | number>, string[] | number[]>>;

type ToArrayWhole<T> = [T] extends [unknown] ? T[] : never;
type _whole = Expect<Equal<ToArrayWhole<string | number>, (string | number)[]>>;

type IsNeverWrong<T> = T extends never ? true : false;
type IsNever<T> = [T] extends [never] ? true : false;
type _wrong = Expect<Equal<IsNeverWrong<never>, never>>;
type _right = Expect<Equal<IsNever<never>, true>>;

type IsString<T> = T extends string ? "yes" : "no";
type _any = Expect<Equal<IsString<any>, "yes" | "no">>;
```

`infer` captures part of a matched type. `infer X extends C` (TS 4.8) adds a constraint, so a failed constraint takes the false branch instead of needing a second conditional.

```ts
type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
type Expect<T extends true> = T;

type FirstArg<F> = F extends (first: infer A, ...rest: never[]) => unknown ? A : never;
type _first = Expect<Equal<FirstArg<(name: string, age: number) => void>, string>>;

type NumericId<T> = T extends `id-${infer N extends number}` ? N : never;
type _num = Expect<Equal<NumericId<"id-42">, 42>>;
type _nan = Expect<Equal<NumericId<"id-abc">, never>>;
```

## Mapped types

A mapped type over `keyof T` is homomorphic. It keeps each property's `?` and `readonly`, also when an `as` clause renames the keys. Applied to a primitive, it returns the primitive. Applied to an array or tuple without an `as` clause, it returns an array or tuple.

```ts
type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
type Expect<T extends true> = T;

type Prefixed<T> = { [K in keyof T as `new_${K & string}`]: T[K] };
type P = Prefixed<{ a?: string; readonly b: number }>;
type _mods = Expect<Equal<P, { new_a?: string; readonly new_b: number }>>;

type Nullable<T> = { [K in keyof T]: T[K] | null };
type _prim = Expect<Equal<Nullable<string>, string>>;
type _tuple = Expect<Equal<Nullable<[number, string]>, [number | null, string | null]>>;

type OnlyStrings<T> = { [K in keyof T as T[K] extends string ? K : never]: T[K] };
type _filter = Expect<Equal<OnlyStrings<{ a: string; b: number; c: "x" }>, { a: string; c: "x" }>>;
```

A recursive mapped type turns functions into objects without call signatures. Stop the recursion at functions.

```ts
type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
type Expect<T extends true> = T;

type DeepReadonlyBroken<T> = { readonly [K in keyof T]: T[K] extends object ? DeepReadonlyBroken<T[K]> : T[K] };
declare const broken: DeepReadonlyBroken<{ run: () => void }>;
// @ts-expect-error the function lost its call signature
broken.run();

type DeepReadonly<T> = T extends (...args: never[]) => unknown
  ? T
  : { readonly [K in keyof T]: DeepReadonly<T[K]> };
declare const fixed: DeepReadonly<{ run: () => void; nested: { n: number[] } }>;
fixed.run();
// @ts-expect-error readonly all the way down
fixed.nested.n.push(1);
```

## Template literal types

A template literal type distributes over unions in its holes, so `${A}-${B}` produces every combination. Large unions multiply, and TS stops with TS2590 past 100,000 members.

When TS infers from a template literal pattern, each `infer` hole followed by literal text takes the text up to the first match of that literal. The last hole takes the rest. A pattern that ends in literal text matches that text at the end of the string. Two adjacent holes give the first hole one character.

```ts
type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
type Expect<T extends true> = T;

type Split<S> = S extends `${infer Head}.${infer Tail}` ? [Head, Tail] : never;
type _split = Expect<Equal<Split<"a.b.c">, ["a", "b.c"]>>;

type Stem<S> = S extends `${infer Name}.json` ? Name : never;
type _stem = Expect<Equal<Stem<"data.backup.json">, "data.backup">>;

type FirstChar<S> = S extends `${infer C}${infer Rest}` ? [C, Rest] : never;
type _char = Expect<Equal<FirstChar<"abc">, ["a", "bc"]>>;

type Params<Path> = Path extends `${string}:${infer P}/${infer Rest}`
  ? P | Params<`/${Rest}`>
  : Path extends `${string}:${infer P}`
    ? P
    : never;
type _params = Expect<Equal<Params<"/users/:userId/posts/:postId">, "userId" | "postId">>;
```

TS 7 splits template literal inference by Unicode code point, so `"😀abc"` gives `"😀"` as the first character. TS 6 and earlier split by UTF-16 code unit and give half of the surrogate pair.

## Recursion limits

A conditional type that recurses in tail position, where the recursive call is the whole branch, runs up to 1,000 levels. Other recursion stops much sooner with TS2589, "Type instantiation is excessively deep and possibly infinite". Make long recursions tail-recursive with an accumulator.

```ts
type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
type Expect<T extends true> = T;

type Chars<S extends string, Acc extends string[] = []> = S extends `${infer C}${infer Rest}`
  ? Chars<Rest, [...Acc, C]>
  : Acc;
type _chars = Expect<Equal<Chars<"abc">, ["a", "b", "c"]>>;
```

## Readable hovers

Intersections and mapped types show up in hovers and errors as `A & B` or the alias name. Mapping over the type flattens it into one object for display. Use it in public types that users hover.

```ts
type Equal<A, B> = (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
type Expect<T extends true> = T;

type Prettify<T> = { [K in keyof T]: T[K] } & {};
type Merged = Prettify<{ a: string } & { b: number }>;
type _merged = Expect<Equal<Merged, { a: string; b: number }>>;
```
