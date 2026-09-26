---
name: ui-baseline
description: visua1's UI baseline. Type/spacing tokens, component patterns (hit targets, field states, density, empty/loading/error), and adaptive CSS (container queries, range media queries, :has()). Use when building or reviewing components, setting up type/spacing scales, or writing responsive CSS. Never proposes colors.
---

# UI Baseline (visua1)

Personal baseline for type/spacing tokens, component patterns, and adaptive CSS. Animation taste lives in `motion-sense`; compositor/perf execution lives in `motion-engine`.

**Color is explicitly out of scope.** No default palette, ever. Always read color from the project's own tokens.

## Typography & Spacing Tokens

If the project already defines its own scale (`variables.css`, `DESIGN.md`, or similar), that wins. This baseline is the fallback/starting point, and the thing to reach for when a specific step is missing. Full rationale: `references/token-baseline.md`.

| Category | Baseline | Rule |
| --- | --- | --- |
| Type scale | Step-based `--font-size--2` (12px) → `--font-size-6` (fluid `clamp()`), plus a semantic layer (`--text-h1`…`--text-caption`) built on top | Raw steps are the palette; semantic tokens are what markup actually references. Anything meant to feel "big" at every viewport is `clamp()`-based, not fixed-plus-media-query |
| Line-height | `tight` 1.1 → `relaxed` 1.7 | Falls as font-size rises. One base value for everything reads loose on big text, cramped on small |
| Letter-spacing | `tight` -0.02em → `wide` 0.02em | Inverse to size. Big text tightens, small/uppercase text loosens |
| Ligatures | `common-ligatures contextual` (body), `none` (code), `tabular-nums` (data) | Invisible detail; tabular data without it visibly jitters as digits change |
| Spacing | `3xs` 2px → `5xl` 128px, near-geometric | Never hardcode a value inline. If something needs a step between two, add the step |

**File organization** (plain-CSS projects only): `variables.css`, tokens only; `motion.css`, motion tokens, owned by `motion-engine`; `global.css`, imports both, plus resets and base element styles. Full detail: `references/token-baseline.md`.

## Component Building Principles

Non-animation component patterns: hit targets (44px touch minimum), touch/interaction (`touch-action`, tap-highlight, `overscroll-behavior`), form/field states (validate inline, four visually distinct states minimum, `:focus-visible` over `:focus`, autocomplete/type/inputmode hygiene), density (a deliberate per-surface choice, not compounding accidental padding), and empty/loading/error states (designed, not default-browser). Full list: `references/component-principles.md`.

## Adaptive CSS

### Breakpoints & responsive queries

Documented convention, not live tokens. Plain CSS can't read custom properties inside `@media` (no build step here for `@custom-media`): `sm` 560px, `md` 900px, `lg` 1024px. Prefer range syntax (`width < 900px`) over `min`/`max-width` pairs. Gate hover-only affordances behind `(hover: hover) and (pointer: fine)`, not just a breakpoint. Full conventions: `references/layout-and-interaction.md`.

### Container queries

Use when a component's internal layout should respond to the space it's given, not the viewport (a card reused in a sidebar vs. a main column). Media queries are for genuinely page-level concerns (nav collapse, overall grid switch). Pattern: `container-type: inline-size` + `@container (width > Npx)`.

### Text flow & `:has()`

`text-wrap: balance` for short headings (avoids an orphaned last word); `text-wrap: pretty` for body paragraphs (no line-count cap, higher cost, no Firefox support yet). `:has()` for parent-aware styling without JS (e.g. `.field-group:has(:invalid)`).

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
| Default color values proposed by the skill | None. Always defer to the project's own tokens |
| Straight quotes (`"`/`'`) or `...` in rendered UI copy | Curly quotes (`“”`/`‘’`), real ellipsis (`…`). Prose and docs keep straight quotes |
| Number/unit or shortcut pair that can line-wrap apart | Non-breaking space (`&nbsp;`) between them |
| `min`/`max-width` pair for a single constraint | Range syntax (`width < 900px`) |
| Hover style with no capability query | Gate behind `(hover: hover) and (pointer: fine)` |
| Component's internal layout keyed to viewport width | Container query keyed to its own width |
| Tappable element with no `touch-action: manipulation` | Add it. Removes the double-tap-zoom delay |
| `outline: none` with no replacement focus indicator | Ship a `:focus-visible` replacement, never remove outright |
| `:focus` used for a focus ring | `:focus-visible`. `:focus` also fires on mouse click |
| Input missing `autocomplete`/`name`/correct `type` | Add all three; use `inputmode` to match the data |

## External References

- [`text-wrap`](https://developer.mozilla.org/en-US/docs/Web/CSS/text-wrap), MDN
- [Utopia.fyi](https://utopia.fyi/), fluid type & space scale calculator; the convention this baseline's raw step naming is drawn from
