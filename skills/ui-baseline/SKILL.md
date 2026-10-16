---
name: ui-baseline
description: UI baseline. Type/spacing tokens, component states (hit targets, fields, focus, density, empty/loading/error), and layout that adapts without breakpoint ladders (intrinsic sizing, container queries), and current platform features with browser support (anchor positioning, popover, invoker commands, field-sizing, text-box, @scope, style queries). Use when building or reviewing components, forms, tooltips, menus or dialogs, setting up type/spacing scales, or writing responsive layout. Never invents colors. Animation lives in motion-sense and motion-engine.
---

# UI Baseline

Baseline for type/spacing tokens, component patterns, adaptive CSS, and which current platform features are safe to use. Animation taste lives in `motion-sense`; compositor/perf execution lives in `motion-engine`.

**This skill never invents a color.** No default palette, ever. Values come from the project's own tokens or the user. When writing them down: match an existing project's notation; for a new color system use `oklch()`, `light-dark()` and `color-mix()`. Detail: `references/token-baseline.md`.

## Typography & Spacing Tokens

If the project already defines its own scale (`variables.css`, `DESIGN.md`, or similar), that wins. This baseline is the fallback/starting point, and the thing to reach for when a specific step is missing. Full rationale: `references/token-baseline.md`.

| Category | Baseline | Rule |
| --- | --- | --- |
| Type scale | Step-based `--font-size--2` (12px) → `--font-size-6` (fluid `clamp()`), plus a semantic layer (`--text-h1`…`--text-caption`) built on top | Raw steps are the palette; semantic tokens are what markup actually references. Anything meant to feel "big" at every viewport is `clamp()`-based, not fixed-plus-media-query. A fluid size's maximum is at most 2.5× its minimum |
| Line-height | `tight` 1.1 → `relaxed` 1.7 | Falls as font-size rises. One base value for everything reads loose on big text, cramped on small |
| Letter-spacing | `tight` -0.02em → `wide` 0.02em | Inverse to size. Big text tightens, small/uppercase text loosens |
| Font features | `font-variant-ligatures: none` (code), `tabular-nums` (data) | Body text keeps the browser default. Tabular data without `tabular-nums` visibly jitters as digits change |
| Spacing | `3xs` 2px → `5xl` 128px, near-geometric | Never hardcode a value inline. If something needs a step between two, add the step |

**File organization** (plain-CSS projects only): `variables.css` holds tokens only; `motion.css` holds motion tokens, owned by `motion-sense`; `global.css` imports both and adds resets and base element styles. Full detail: `references/token-baseline.md`.

## Component Building Principles

Non-animation component patterns: native elements first (`<button>`, `<a href>`, `<dialog>`, `popover` before ARIA or a custom rebuild), hit targets (44px touch minimum), touch/interaction (`touch-action`, tap-highlight, `overscroll-behavior`), form/field states (validate inline, four visually distinct states minimum, `:focus-visible` over `:focus`, autocomplete/type/inputmode hygiene, never a disabled submit as validation), user-supplied text and media (truncation with a way back, `aspect-ratio`), density (a deliberate per-surface choice, not compounding accidental padding), and empty/loading/error states (designed, not default-browser). Full list: `references/component-principles.md`.

## Adaptive CSS

### Order of tools

Intrinsic layout first (`flex-wrap`, `auto-fit` grid tracks, `clamp()`), with no query at all. Then a container query, when a component's internal layout depends on the slot it sits in (a card reused in a sidebar and a main column). A page breakpoint comes last and only for page-level changes (nav collapse, overall grid switch). Full conventions: `references/layout-and-interaction.md`.

Layout that holds (logical properties, `dvh`/`svh`, `min-width: 0`, `overflow: clip`, safe areas, 320px and 200% zoom) is in the same file.

### Page breakpoints & capability queries

Documented convention, not live tokens, because `@media` can't read custom properties: `sm` 560px, `md` 900px, `lg` 1024px. Write range syntax (`width < 900px`), not `min`/`max-width` pairs. Gate hover-only affordances behind `(hover: hover) and (pointer: fine)`, not a breakpoint.

### Text flow & `:has()`

`text-wrap: balance` for short headings; `text-wrap: pretty` for body paragraphs (higher cost, no Firefox support as of 2026-10). `:has()` for parent styling that follows child state without JS (e.g. `.field-group:has(:user-invalid)`).

## Platform Features

Before writing a script or pulling a library for positioning, overlays, auto-growing fields or context passed down a tree, check `references/platform-features.md`. It sorts features by engine support, checked 2026-10-10:

- **All three engines, use by default:** anchor positioning, invoker commands (`command`/`commandfor`), `popover`, `field-sizing: content`, `text-box` trim, `@scope`, container style queries, `sibling-index()`, `contrast-color()`, `light-dark()`.
- **Missing one engine, enhancement only:** customizable select (no Firefox), `text-wrap: pretty` (no Firefox), `popover="hint"` and `<dialog closedby>` (no Safari).
- **One engine, not unless asked:** `interpolate-size`, `interestfor`, `@function`, `if()`, scroll-state queries, `corner-shape`.

A project's stated browser floor wins. Tell the user when a feature you used falls below it.

## Review Format (Required)

When reviewing UI code, use a markdown table with Before/After/Why columns, one row per issue found:

| Before | After | Why |
| --- | --- | --- |
| `min-width: 400px` + `max-width: 899px` pair | `@media (400px <= width < 900px)` | Range syntax, no off-by-one hazard |
| Hardcoded `padding: 13px` | `padding: var(--space-sm)` | Spacing scale, not arbitrary values |

A rule that needs a rendered page to judge (overflow at 320px, a stuck hover state, a clipped hit area) and that you could not check in a browser is reported as "Not verified", never as a finding.

## Review Checklist

| Issue | Fix |
| --- | --- |
| Hardcoded font-size/spacing value | Replace with the nearest token; add a step if none fits |
| Fixed heading size across viewports | `clamp()`-based fluid size |
| Same line-height on headings and body | Tighten line-height as size increases |
| Tabular data without `tabular-nums` | Add `font-variant-numeric: tabular-nums` |
| Fluid `clamp()` font size whose maximum is over 2.5× its minimum | Lower the maximum. Past 2.5×, browser zoom cannot double the text (WCAG 1.4.4) |
| Parent styled with `:has(:invalid)` | `:has(:user-invalid)`, so nothing is marked wrong before the user types |
| Default color values proposed by the skill | None. Always defer to the project's own tokens |
| One `oklch()` value in a hex codebase, or a bulk notation change nobody asked for | Match the project's notation |
| Straight quotes (`"`/`'`) or `...` in rendered UI copy | Curly quotes (`“”`/`‘’`), real ellipsis (`…`). Prose and docs keep straight quotes |
| Number/unit or shortcut pair that can line-wrap apart | Non-breaking space (`&nbsp;`) between them |
| `min`/`max-width` pair for a single constraint | Range syntax (`width < 900px`) |
| Hover style with no capability query | Gate behind `(hover: hover) and (pointer: fine)` |
| Breakpoint where intrinsic layout would do (`flex-wrap`, `auto-fit`, `clamp()`) | Drop the query |
| Component's internal layout keyed to viewport width | Container query keyed to its slot's width |
| Tappable element with no `touch-action: manipulation` | Add it. No double-tap zoom on controls, taps stay fast when zoomed |
| `outline: none` with no replacement focus indicator | Ship a `:focus-visible` replacement, never remove outright |
| `:focus` used for a focus ring | `:focus-visible`. `:focus` also fires on mouse click |
| Input missing `autocomplete`/`name`/correct `type` | Add all three; use `inputmode` to match the data |
| `<div>` or `<span>` with a click handler | `<button>`, or `<a href>` when it navigates |
| Submit button disabled until the form is valid | Keep it enabled, validate on submit, focus the first invalid field |
| JS positioning library, auto-grow script or z-index stack for an overlay | Anchor positioning, `field-sizing: content`, `popover`/`<dialog>`. Check `platform-features.md` |
| Feature used that one engine lacks, with no acceptable result there | Fallback, or a feature from the all-engines tier |
| `100vh` on a mobile full-height pane, or `100vw` for full width | `100dvh`; `100%` |
| Physical `margin-left`/`padding-right`/`left` on UI that should mirror | Logical properties |
| Truncated text with no way to the full value | Expand control, detail view, or a keyboard-reachable tooltip |
| Input text under 16px on touch | `font-size: max(16px, 1rem)` |
| Padded parent and child with the same `border-radius` | Outer radius = inner radius + padding |

## External References

- [`text-wrap`](https://developer.mozilla.org/en-US/docs/Web/CSS/text-wrap), MDN
- [browser-compat-data](https://github.com/mdn/browser-compat-data), MDN. Source of every version in `platform-features.md`
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/), W3C. Target size (2.5.8, 2.5.5), focus not obscured (2.4.11), resize and reflow (1.4.4, 1.4.10)
- [Addressing Accessibility Concerns With Using Fluid Type](https://www.smashingmagazine.com/2023/11/addressing-accessibility-concerns-fluid-type/), Maxwell Barvian. Source of the 2.5× cap
- [vojtaholik/good-css](https://github.com/vojtaholik/good-css), Vojta Holik, MIT. Source of the intrinsic patterns, the hit-area inset, the `none` hue rule and several "watch for" notes
- [jakubkrehel/skills](https://github.com/jakubkrehel/skills), Jakub Krehel, MIT. Source of the color notation rule, the WCAG target-size correction, truncation with a way back, the grouping gap and the "Not verified" rule
- [Modern Web Guidance](https://github.com/GoogleChrome/modern-web-guidance), Chrome, Apache-2.0. Source of the validation timing, numeric-code inputs and style query rules
- [ibelick/ui-skills](https://github.com/ibelick/ui-skills), ibelick, MIT. Source of the "existing accessible primitives first" rule
- [Utopia.fyi](https://utopia.fyi/), fluid type & space scale calculator; the convention this baseline's raw step naming is drawn from
