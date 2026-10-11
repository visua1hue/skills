---
name: ui-baseline
description: visua1's UI baseline. Type/spacing tokens, component states (hit targets, fields, focus, density, empty/loading/error), and layout that adapts without breakpoint ladders (intrinsic sizing, container queries). Use when building or reviewing components or forms, setting up type/spacing scales, or writing responsive layout. Never proposes colors. Animation lives in motion-sense and motion-engine.
---

# UI Baseline (visua1)

Personal baseline for type/spacing tokens, component patterns, and adaptive CSS. Animation taste lives in `motion-sense`; compositor/perf execution lives in `motion-engine`.

**Color is explicitly out of scope.** No default palette, ever. Always read color from the project's own tokens.

## Typography & Spacing Tokens

If the project already defines its own scale (`variables.css`, `DESIGN.md`, or similar), that wins. This baseline is the fallback/starting point, and the thing to reach for when a specific step is missing. Full rationale: `references/token-baseline.md`.

| Category | Baseline | Rule |
| --- | --- | --- |
| Type scale | Step-based `--font-size--2` (12px) → `--font-size-6` (fluid `clamp()`), plus a semantic layer (`--text-h1`…`--text-caption`) built on top | Raw steps are the palette; semantic tokens are what markup actually references. Anything meant to feel "big" at every viewport is `clamp()`-based, not fixed-plus-media-query. A fluid size's maximum is at most 2.5× its minimum |
| Line-height | `tight` 1.1 → `relaxed` 1.7 | Falls as font-size rises. One base value for everything reads loose on big text, cramped on small |
| Letter-spacing | `tight` -0.02em → `wide` 0.02em | Inverse to size. Big text tightens, small/uppercase text loosens |
| Font features | `font-variant-ligatures: none` (code), `tabular-nums` (data) | Body text keeps the browser default. Tabular data without `tabular-nums` visibly jitters as digits change |
| Spacing | `3xs` 2px → `5xl` 128px, near-geometric | Never hardcode a value inline. If something needs a step between two, add the step |

**File organization** (plain-CSS projects only): `variables.css` holds tokens only; `motion.css` holds motion tokens, owned by `motion-engine`; `global.css` imports both and adds resets and base element styles. Full detail: `references/token-baseline.md`.

## Component Building Principles

Non-animation component patterns: hit targets (44px touch minimum), touch/interaction (`touch-action`, tap-highlight, `overscroll-behavior`), form/field states (validate inline, four visually distinct states minimum, `:focus-visible` over `:focus`, autocomplete/type/inputmode hygiene), density (a deliberate per-surface choice, not compounding accidental padding), and empty/loading/error states (designed, not default-browser). Full list: `references/component-principles.md`.

## Adaptive CSS

### Order of tools

Intrinsic layout first (`flex-wrap`, `auto-fit` grid tracks, `clamp()`), with no query at all. Then a container query, when a component's internal layout depends on the slot it sits in (a card reused in a sidebar and a main column). A page breakpoint comes last and only for page-level changes (nav collapse, overall grid switch). Full conventions: `references/layout-and-interaction.md`.

### Page breakpoints & capability queries

Documented convention, not live tokens, because `@media` can't read custom properties: `sm` 560px, `md` 900px, `lg` 1024px. Write range syntax (`width < 900px`), not `min`/`max-width` pairs. Gate hover-only affordances behind `(hover: hover) and (pointer: fine)`, not a breakpoint.

### Text flow & `:has()`

`text-wrap: balance` for short headings; `text-wrap: pretty` for body paragraphs (higher cost, no Firefox support as of 2026-10). `:has()` for parent styling that follows child state without JS (e.g. `.field-group:has(:user-invalid)`).

## Review Format (Required)

When reviewing UI code, use a markdown table with Before/After/Why columns, one row per issue found:

| Before | After | Why |
| --- | --- | --- |
| `min-width: 400px` + `max-width: 899px` pair | `@media (400px <= width < 900px)` | Range syntax, no off-by-one hazard |
| Hardcoded `padding: 13px` | `padding: var(--space-sm)` | Spacing scale, not arbitrary values |

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

## External References

- [`text-wrap`](https://developer.mozilla.org/en-US/docs/Web/CSS/text-wrap), MDN
- [Utopia.fyi](https://utopia.fyi/), fluid type & space scale calculator; the convention this baseline's raw step naming is drawn from
