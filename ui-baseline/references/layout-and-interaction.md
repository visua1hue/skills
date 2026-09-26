# Layout & Interaction Reference

Full patterns for breakpoints, container queries, `:has()`, and text-wrap. Read when implementing responsive layout.

## Breakpoint & Responsive Query Conventions

### Breakpoint scale

```css
/* documented convention, not live tokens, see note below */
sm:  560px  /* compact/mobile layout switch */
md:  900px  /* nav/menu collapse point */
lg:  1024px /* desktop layout switch */
```

**Why these aren't CSS custom properties:** `@media` conditions can't read `var()`. Media query values must be literal at parse time, and that's true even for Custom Media Queries proposals still working through standardization. The only way to get real token reuse inside `@media` today is a build-time preprocessor step (PostCSS `postcss-custom-media`, Sass variables, etc.). If a project has that build step, define these as build-time variables and use it; if not, this table is the source of truth to copy from. Keep the values in one place (a comment block at the top of the main stylesheet) and reference that comment everywhere a breakpoint is used, so they can be found and changed together even without live tokens.

### Range media query syntax

```css
/* Preferred: range syntax, one comparison */
@media (width < 900px) { }
@media (400px <= width < 900px) { }

/* Avoid: min/max pair for the same constraint */
@media (max-width: 899px) { }
@media (min-width: 400px) and (max-width: 899px) { }
```

The range syntax also removes the classic off-by-one hazard of `max-width: 899px` (why 899 and not 900? because `max-width` is inclusive). `width < 900px` states the boundary exactly, no subtraction required.

### Capability queries

```css
@media (hover: hover) and (pointer: fine) {
  .element:hover {
    transform: scale(1.05);
  }
}
```

`hover: hover` is true when the primary input can hover without the user taking an explicit action (mouse, trackpad). `pointer: fine` is true when the primary input has high precision (mouse, stylus) as opposed to `pointer: coarse` (touch). Gate hover-only affordances behind both; gate press-precision-dependent UI (small drag handles, etc.) behind `pointer: fine` alone. A touchscreen laptop with a mouse plugged in, or a tablet in a keyboard case, are exactly the cases this catches that a bare breakpoint would miss.

## Container Queries

### Setup

```css
.card-container {
  container-type: inline-size;
  container-name: card; /* optional, disambiguates nested containers */
}

@container card (width > 400px) {
  .card {
    grid-template-columns: auto 1fr;
  }
}
```

`container-type: inline-size` establishes a query container along the inline axis (width, in horizontal writing modes). This is the common case. `container-type: size` queries both axes but requires the container to have an explicit size (it can't size itself based on content that also depends on the query, which is a real constraint, not a bug).

### Container query units

```css
.card-title {
  font-size: clamp(1rem, 5cqi, 1.5rem); /* cqi = % of container's inline size */
}
```

`cqi`/`cqb`/`cqw`/`cqh` scale relative to the *container*, not the viewport. Useful for a component's internal type scale to respond to the space it's actually given (a card in a 300px sidebar vs. a 800px main column) rather than the page width.

### When to reach for a container query vs. a media query

Container query: the component is reused in more than one layout context (sidebar widget that's also a full-width card elsewhere) and needs different internal layout depending on the space available, not the page width.

Media query: the concern is genuinely page-level. Overall grid switching from one column to three, nav collapsing to a hamburger menu. These don't have a "container" in any meaningful sense; they're about the page as a whole.

## `:has()` Parent-Aware Styling

```css
/* Style a form group differently when it contains an invalid field */
.field-group:has(:invalid) {
  border-color: var(--color-error);
}

/* Style a card differently when it contains an image */
.card:has(img) {
  grid-template-rows: auto 1fr;
}

/* Sibling-aware: style a label when its following input is focused */
.label:has(+ input:focus) {
  color: var(--color-interactive-default);
}
```

`:has()` is the first native way to style a parent based on its descendants, or a preceding sibling based on a following one. Previously JS-only territory (add/remove a class based on child state). Use it for state-driven parent styling (validation, "contains media" layout switches) rather than reaching for a JS mutation observer or manually toggled class.

Performance note: `:has()` forces the browser to re-evaluate on any change to the subtree it's watching, which is more expensive than a flat selector. Fine for form-sized subtrees, worth checking before applying to something that watches a large, frequently-changing list.

## `text-wrap`

```css
h1, h2, h3 {
  text-wrap: balance; /* short, multi-line headings */
}

p {
  text-wrap: pretty; /* body paragraphs */
}
```

`balance` distributes text across lines to minimize the difference in line length. Fixes the classic "one orphaned word on its own line" heading problem. Browsers cap the number of lines it'll balance (typically ~6) for performance, so it's only appropriate for short text (headings, callouts), not long-form content.

`pretty` targets a narrower problem (avoiding a short orphan on the final line) without the line-count cap, at a higher computational cost. Reasonable on individual paragraphs, worth avoiding on a page with hundreds of paragraphs rendering at once.

**Browser support**: `balance` is broadly supported (Chromium 114+, Firefox 121+, Safari 17.5+). `pretty` is narrower. Chromium 117+ and Safari 26+, but **no Firefox support at all** as of mid-2026. Both are progressive enhancements (unsupported browsers just get normal wrapping, no breakage), but `pretty` is meaningfully less safe to lean on as a primary fix than `balance` is.
