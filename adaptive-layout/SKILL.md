---
name: adaptive-layout
description: Encodes visua1's personal component-craft and adaptive CSS baseline — component building principles (hit targets, form/field states, density, empty/loading/error states) and context-aware CSS mechanics (container queries, :has(), range media queries, breakpoint and capability-query conventions, text-wrap). Deliberately excludes color (always project-specific), typography/spacing tokens (see typeset), and animation/motion taste (see motion-sense). Use when building or reviewing UI components or implementing adaptive/responsive layout.
---

# Adaptive Layout (visua1)

Personal component-craft and adaptive CSS baseline — component building principles and context-aware CSS mechanics. Typography/spacing tokens live in `typeset`; animation taste lives in `motion-sense`; compositor/perf execution lives in `motion-engine`.

## Component Building Principles

Non-animation component craft: hit targets (44px touch minimum), touch/interaction (`touch-action`, tap-highlight, `overscroll-behavior`), form/field states (validate inline, four visually distinct states minimum, `:focus-visible` over `:focus`, autocomplete/type/inputmode hygiene), density (a deliberate per-surface choice, not compounding accidental padding), and empty/loading/error states (designed, not default-browser). Full list: `references/component-principles.md`.

## Modern CSS Mechanics

The "how do you ship it" layer for layout and newer platform features.

### Breakpoints & responsive queries

Documented convention, not live tokens — plain CSS can't read custom properties inside `@media` (no build step here for `@custom-media`): `sm` 560px, `md` 900px, `lg` 1024px. Prefer range syntax (`width < 900px`) over `min`/`max-width` pairs. Gate hover-only affordances behind `(hover: hover) and (pointer: fine)`, not just a breakpoint. Full conventions: `references/layout-and-interaction.md`.

### Container queries

Use when a component's internal layout should respond to the space it's given, not the viewport (a card reused in a sidebar vs. a main column). Media queries are for genuinely page-level concerns (nav collapse, overall grid switch). Pattern: `container-type: inline-size` + `@container (width > Npx)`.

### Text flow & `:has()`

`text-wrap: balance` for short headings (avoids an orphaned last word); `text-wrap: pretty` for body paragraphs (no line-count cap, higher cost, no Firefox support yet). `:has()` for parent-aware styling without JS (e.g. `.field-group:has(:invalid)`).

## Review Format (Required)

When reviewing UI code, use a markdown table with Before/After/Why columns — one row per issue found:

| Before | After | Why |
| --- | --- | --- |
| `min-width: 400px` + `max-width: 899px` pair | `@media (400px <= width < 900px)` | Range syntax, no off-by-one hazard |

## Review Checklist

| Issue | Fix |
| --- | --- |
| `min`/`max-width` pair for a single constraint | Range syntax (`width < 900px`) |
| Hover style with no capability query | Gate behind `(hover: hover) and (pointer: fine)` |
| Component's internal layout keyed to viewport width | Container query keyed to its own width |
| Tappable element with no `touch-action: manipulation` | Add it — removes the double-tap-zoom delay |
| `outline: none` with no replacement focus indicator | Ship a `:focus-visible` replacement, never remove outright |
| `:focus` used for a focus ring | `:focus-visible` — `:focus` also fires on mouse click |
| Input missing `autocomplete`/`name`/correct `type` | Add all three; use `inputmode` to match the data |

## External References

- [`text-wrap`](https://developer.mozilla.org/en-US/docs/Web/CSS/text-wrap) — MDN
