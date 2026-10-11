# Layout & Interaction Reference

Which tool to reach for when a layout has to adapt, the page breakpoint convention, capability queries, `:has()`, and `text-wrap`. Read when implementing responsive layout.

## Order of tools

Go down this list and stop at the first one that does the job.

1. **Intrinsic layout.** Content and available space decide, with no query: `flex-wrap`, `auto-fit`/`auto-fill` grid tracks with `minmax()`, `min()`/`max()`/`clamp()`.
2. **Container query.** A component's internal layout depends on the space it is given, and it appears in more than one slot (a card in a sidebar and in a main column).
3. **Page breakpoint.** The change belongs to the page as a whole: nav collapse, the overall grid going from one column to three. Only this step uses the breakpoint scale below.

A viewport media query inside a reusable component is a finding. Move it to a container query.

## Page breakpoints

```css
/* documented convention, not live tokens */
sm:  560px  /* compact/mobile layout switch */
md:  900px  /* nav/menu collapse point */
lg:  1024px /* desktop layout switch */
```

`@media` conditions can't read `var()`, and `@custom-media` ships in no browser (checked 2026-10, Firefox has it behind a flag). With a build step (`postcss-custom-media`, Sass variables), define the three values there. Without one, keep them in a single comment block at the top of the main stylesheet and reference that comment wherever a breakpoint is used, so they can be found and changed together.

Write range syntax (`width < 900px`, `400px <= width < 900px`), not `min-width`/`max-width` pairs.

## Capability queries

```css
@media (hover: hover) and (pointer: fine) {
  .element:hover {
    transform: scale(1.05);
  }
}
```

Gate every hover-only affordance behind both features: `hover: hover` means the primary input can hover (mouse, trackpad), `pointer: fine` means it is precise (mouse, stylus) and not touch. Without the gate, a tap on a touch screen leaves the hover state stuck. Gate UI that needs press precision (small drag handles) behind `pointer: fine` alone. A touchscreen laptop with a mouse plugged in, or a tablet in a keyboard case, are the cases this catches and a breakpoint misses.

## Container queries

`container-type: inline-size` goes on the slot, `@container (width > Npx)` styles the component inside it. Name the container only where nested containers could collide. `container-type: size` needs an explicit block size on the container, so use it only when the query is about height.

`cqi` inside a `clamp()` scales a component's type with its slot instead of the viewport: `font-size: clamp(1rem, 5cqi, 1.5rem)`.

## `:has()`

Use it for parent styling that follows child state, in place of a class toggled from JS.

```css
.field-group:has(:user-invalid) {
  border-color: var(--color-error);
}

.card:has(img) {
  grid-template-rows: auto 1fr;
}
```

Match `:user-invalid`, not `:invalid`, so a group is not marked wrong before the user has typed. `:has()` re-evaluates on any change in the subtree it watches. That is fine for a form, and worth measuring on a large list that changes often.

## `text-wrap`

- `balance` on headings and other short text. Browsers stop balancing after about six lines.
- `pretty` on body paragraphs. It costs more to compute, so set it on the elements that need it, not on a page with hundreds of paragraphs.

**Browser support**, checked 2026-10 against MDN browser-compat-data: `balance` is in Chrome 114, Firefox 121, Safari 17.5. `pretty` is in Chrome 117 and Safari 26. Firefox does not support it. Both degrade to normal wrapping, so neither needs a fallback.
