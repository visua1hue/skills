# Generics and inference

Rules TS7, TS8, TS9. A type parameter is worth adding when the caller gets a more precise type out than a non-generic signature would give.

## A type parameter links two positions

Each type parameter should connect an input to the output, or two inputs to each other. A parameter that appears once adds nothing. A parameter that appears only in the return type is a cast the caller writes without seeing it.

```ts
// Cast in disguise: the caller picks T, nothing checks it.
declare function readJson<T>(path: string): T;
const config = readJson<{ port: number }>("config.json");

// Honest: the result is unknown until the caller parses it.
declare function readJsonUnknown(path: string): unknown;

// Linked: T flows from the argument to the result.
function first<T>(items: readonly T[]): T | undefined {
  return items[0];
}
const n = first([1, 2, 3]);
const check: number | undefined = n;

// Linked: K is constrained by T.
function pick<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
const port = pick({ host: "localhost", port: 8080 }, "port");
// @ts-expect-error "user" is not a key
pick({ host: "localhost" }, "user");
```

typescript-eslint's `no-unnecessary-type-parameters` reports parameters used once.

Default a type parameter to `unknown`, not `any`. A constraint (`extends`) limits what callers can pass. A default only fills in when inference has nothing to work with.

## Keeping literal types

Object and array literals widen, so `["a", "b"]` becomes `string[]`. A `const` type parameter keeps the literal types the caller wrote, so the caller doesn't need `as const`. Since TS 5.3 this also works when the constraint is a mutable array type.

```ts
function defineEvents<const T extends Record<string, readonly string[]>>(events: T): T {
  return events;
}

const events = defineEvents({
  click: ["x", "y"],
  key: ["code"],
});

type ClickFields = (typeof events)["click"][number];
const field: ClickFields = "x";
// @ts-expect-error "code" belongs to key, not click
const wrong: ClickFields = "code";
```

`const` affects only literals written at the call site. A variable declared earlier has already widened, and passing it keeps the wide type.

## Blocking an inference site

When a type parameter appears in several arguments, TS infers it from all of them, so a typo in one argument can widen the type instead of failing. `NoInfer` (TS 5.4) removes an argument from inference, so that argument is checked against the type the others produced.

```ts
function createMachine<S extends string>(config: { states: S[]; initial: NoInfer<S> }) {
  return config;
}

createMachine({ states: ["idle", "running"], initial: "idle" });
// @ts-expect-error "stopped" is not one of the states
createMachine({ states: ["idle", "running"], initial: "stopped" });
```

## Phantom type parameters

TS compares types by structure. A type parameter that no member uses leaves every instantiation with the same structure, so they are all assignable to each other, and a check built on the parameter passes for everything. Put the parameter into the structure. A `declare` field adds it with no runtime cost.

```ts
type DoorState = "open" | "closed";

class Door<S extends DoorState> {
  // Type-only field: without it, Door<"open"> and Door<"closed"> are the same type.
  declare private readonly state: S;

  static closed(): Door<"closed"> {
    return new Door<"closed">();
  }

  open(this: Door<"closed">): Door<"open"> {
    return new Door<"open">();
  }

  walkThrough(this: Door<"open">): void {}
}

Door.closed().open().walkThrough();
// @ts-expect-error a closed door can't be walked through
Door.closed().walkThrough();
```

Prove a phantom check with a `@ts-expect-error` case. A builder whose type tests only cover the valid chain passes even when the phantom parameter checks nothing.

## Overloads

Overloads are the last choice. Callers see only the overload signatures, never the implementation signature, and TS picks the first overload that matches, so put the specific ones first. Prefer a union parameter when the return type doesn't depend on the input, and a generic when it does.

```ts
function parse(input: string): unknown;
function parse(input: Uint8Array): unknown;
function parse(input: string | Uint8Array): unknown {
  return JSON.parse(typeof input === "string" ? input : new TextDecoder().decode(input));
}

// Same contract, one signature.
function parseOne(input: string | Uint8Array): unknown {
  return JSON.parse(typeof input === "string" ? input : new TextDecoder().decode(input));
}
```

`Parameters`, `ReturnType`, and any `infer` on an overloaded function see only the last overload. A wrapper typed with them loses the other signatures.

```ts
declare function format(value: string): string;
declare function format(value: number): string;

type Args = Parameters<typeof format>;
const ok: Args = [42];
// @ts-expect-error only the last overload (number) is visible
const lost: Args = ["text"];
```

An overloaded call signature type can't be satisfied by a single arrow function, because the arrow's return type must fit every overload at once. Write overloaded function declarations instead.

```ts
interface Double {
  (value: string): string;
  (value: number): number;
}

// @ts-expect-error string | number is not assignable to string
const double: Double = (value: string | number) => (typeof value === "string" ? value.repeat(2) : value * 2);

function doubleIt(value: string): string;
function doubleIt(value: number): number;
function doubleIt(value: string | number): string | number {
  return typeof value === "string" ? value.repeat(2) : value * 2;
}
const doubled: Double = doubleIt;
```

## Variance annotations

`in` and `out` on a type parameter (TS 4.7) declare how it varies, and TS checks the declaration against the structure. They speed up checking of large generic types and document intent. They don't fix an assignability error: when the annotation is wrong, the declaration itself errors.

```ts
interface Producer<out T> {
  get(): T;
}
interface Consumer<in T> {
  accept(value: T): void;
}

declare const producer: Producer<"a">;
const wide: Producer<string> = producer;
declare const consumer: Consumer<string>;
const narrow: Consumer<"a"> = consumer;
```
