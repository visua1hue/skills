# Layout & Interaction Reference

Which tool to reach for when a layout has to adapt, intrinsic patterns, the page breakpoint convention, capability queries, the rules that keep a layout from breaking, `:has()`, and `text-wrap`. Read when implementing responsive layout.

## Order of tools

Go down this list and stop at the first one that does the job.

1. **Intrinsic layout.** Content and available space decide, with no query: `flex-wrap`, `auto-fit`/`auto-fill` grid tracks with `minmax()`, `min()`/`max()`/`clamp()`.
2. **Container query.** A component's internal layout depends on the space it is given, and it appears in more than one slot (a card in a sidebar and in a main column).
3. **Page breakpoint.** The change belongs to the page as a whole: nav collapse, the overall grid going from one column to three. Only this step uses the breakpoint scale below.

A viewport media query inside a reusable component is a finding. Move it to a container query.

## Intrinsic patterns

- **Card grid.** `grid-template-columns: repeat(auto-fit, minmax(min(100%, 16rem), 1fr))`. The `min(100%, …)` keeps one column from overflowing a narrow container. Use `auto-fill` when the item count changes (a filtered list), so cards keep their size.
- **Sidebar that wraps.** A `flex-wrap: wrap` row. The side gets `flex-basis: 20rem; flex-grow: 1`, the main part `flex-basis: 0; flex-grow: 999; min-inline-size: 50%`. It wraps when the main part would drop under half the container. Change `min-inline-size` to move that point.
- **Stacked layers.** `display: grid` on the parent and `grid-area: 1 / 1` on each child, placed with `place-self`. Use it for text over an image or a badge on a card. Keep `position: absolute` for a layer that must not affect the parent's size.
- **Card parts that line up.** `grid-template-rows: subgrid` with `grid-row: span N` on each card, where N is the number of parts. Set `row-gap` on the card, or it inherits the parent's gap.
- **Page container with breakouts.** One grid with named lines (`content`, `breakout`, `full-width`) in place of a `section > .container` pair, so any child can go wider with one `grid-column` value.

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

Where they fail:

- A query styles descendants of the container, never the container itself.
- A container cannot take its width from its content. `container-type` on a shrink-to-fit box (a flex item with no width, an inline-block, an absolutely positioned element) collapses it to zero. Give it a definite width.
- A container cannot also be a subgrid. Use separate elements.
- With no container above it, a query never matches, and `cqi` measures the viewport.

## Layout that holds

- **Logical properties** for anything that should mirror in a right-to-left layout: `margin-inline`, `padding-block`, `inset-inline-start`, `text-align: start`. The four-value `margin`, `padding` and `inset` shorthands stay physical. Safe-area insets are physical too.
- **Viewport units.** `100dvh` for an app shell or full-height pane, `100svh` for a hero, never `100vh` on mobile. `100%` for full width, never `100vw`, which includes the scrollbar.
- **Shrinking.** A flex child or `1fr` track will not shrink below its content. Set `min-width: 0` on the flex child, `minmax(0, 1fr)` on the track. Size text boxes with `min-height`, never a fixed `height`.
- **Clipping.** `overflow: clip` when nothing should scroll. `hidden` still creates a scroll container that scripts and focus can move. `scrollbar-gutter: stable` on a scroller whose content can grow, so the layout does not shift.
- **Safe areas.** `env(safe-area-inset-*)` on fixed headers, bottom bars and sheets. It resolves to `0` unless the viewport meta has `viewport-fit=cover`.
- **Sticky headers.** `scroll-padding-block-start` on the scroller, equal to the header height, so anchor targets and focused elements never sit under it (WCAG 2.4.11).
- **Zoom.** Nothing clips or overlaps at 320px width or 200% zoom (WCAG 1.4.10, 1.4.4). Never set `user-scalable=no` or `maximum-scale=1`.

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
