---
name: visua1-design-eng
description: Encodes visua1's personal design-engineering taste — when and why to animate, easing/duration decisions, CSS transform and clip-path animation technique, component-feel patterns, typography/spacing token baseline, and modern CSS/HTML platform mechanics (transition-behavior allow-discrete with @starting-style, the linear() easing function, container queries, :has(), range media queries, breakpoint conventions, page-transition patterns). Deliberately excludes color (always project-specific) and spring-physics animation (out of scope). Use when building or reviewing UI components, deciding whether/how something should animate, choosing type or spacing tokens, or implementing responsive layout or page transitions.
---

# Design Engineering (visua1)

Personal design-engineering taste — covering *why* (philosophy, animation decisions, tokens), *how* (component and CSS technique), and modern platform mechanics in one place. Pairs with `motion-engine` for compositor/perf execution once something is animating. Spring-physics animation guidance (JS `useSpring`, mass/stiffness/damping config) is intentionally out of scope for this skill.

## Core Philosophy

Taste is trained, not innate — a trained instinct for what elevates, built by studying good work, reverse-engineering why something feels right, and practicing relentlessly. Don't just make something work; study why the best version of it feels the way it does.

Most details compound invisibly. A user who never consciously notices a detail is the goal, not a failure to draw attention to it — the aggregate of a hundred small correct decisions is what separates software that feels right from software that merely functions.

Beauty is leverage. People choose tools based on the whole experience, not just the feature list — good defaults and a considered feel are real, underused differentiators.

*Starting point, not final — update this section directly as your own opinions solidify or diverge from the above.*

## Animation Decision Framework

Before writing animation code, work through these in order. Full rationale, curves, and duration tables: `references/animation-decisions.md`.

| Question | Rule |
| --- | --- |
| Should this animate at all? | Never for 100+/day actions (keyboard shortcuts); standard for occasional UI (modals, toasts); delight is fine for rare/first-time moments |
| What's the purpose? | Spatial consistency, state indication, explanation, feedback, or preventing a jarring change — "looks cool" alone doesn't qualify for frequent UI |
| What easing? | Entering/exiting → `ease-out`; on-screen movement → `ease-in-out`; hover/color → `ease`; constant motion → `linear`. Never `ease-in` on UI. |
| How fast? | Button feedback 100-160ms, tooltips/popovers 125-200ms, dropdowns 150-250ms, modals 200-500ms — UI stays under 300ms |

Also in the reference: perceived-performance notes (fast spinners, instant subsequent tooltips) and a distilled set of principles for building components people actually reach for (DX-first, good defaults over options, invisible edge-case handling, cohesion over isolated "correct" values, asymmetric enter/exit timing).

## Typography & Spacing Token Baseline

If the project already defines its own scale (`variables.css`, `DESIGN.md`, or similar), that wins — this baseline is the fallback/starting point, and the thing to reach for when a specific step is missing. Full rationale: `references/token-baseline.md`.

| Category | Baseline | Rule |
| --- | --- | --- |
| Type scale | Step-based `--font-size--2` (12px) → `--font-size-6` (fluid `clamp()`), plus a semantic layer (`--text-h1`…`--text-caption`) built on top | Raw steps are the palette; semantic tokens are what markup actually references. Anything meant to feel "big" at every viewport is `clamp()`-based, not fixed-plus-media-query |
| Line-height | `tight` 1.1 → `relaxed` 1.7 | Falls as font-size rises — one base value for everything reads loose on big text, cramped on small |
| Letter-spacing | `tight` -0.02em → `wide` 0.02em | Inverse to size — big text tightens, small/uppercase text loosens |
| Ligatures | `common-ligatures contextual` (body), `none` (code), `tabular-nums` (data) | Invisible detail; tabular data without it visibly jitters as digits change |
| Spacing | `3xs` 2px → `5xl` 128px, near-geometric | Never hardcode a value inline — if something needs a step between two, add the step |

**Color is explicitly out of scope.** No default palette, ever — always read color from the project's own tokens.

**File organization** (plain-CSS projects only): `variables.css` — tokens only; `motion.css` — motion tokens + the FCP-safe/reduced-motion contract `motion-engine` expects; `global.css` — imports both, plus resets and base element styles. Full detail: `references/token-baseline.md`.

## Component Building Principles

Non-animation component craft: hit targets (44px touch minimum), form/field states (validate inline, four visually distinct states minimum), density (a deliberate per-surface choice, not compounding accidental padding), and empty/loading/error states (designed, not default-browser). Full list: `references/component-principles.md`.

## Animation Technique Library

CSS technique for shipping the decisions above. Full patterns: `references/animation-techniques.md`.

- **Transform mastery** — `translateY(%)` for size-independent motion, `scale()` scales children too (a feature, not a bug), 3D transforms (`rotateX`/`rotateY` + `preserve-3d`) for depth, explicit `transform-origin` matching where the interaction actually originates.
- **`clip-path`** — inset-shape reveals, tab color transitions via a clipped duplicate layer, hold-to-delete (2s linear press, 200ms ease-out release), scroll reveals, comparison sliders.
- **Component feel patterns** — buttons scale `0.97` on `:active`; never animate entry from `scale(0)` (start at `0.95`+opacity instead); popovers scale in from their trigger via `transform-origin` (modals stay centered — they aren't trigger-anchored); tooltips skip delay/animation on hovers after the first is open; prefer transitions over keyframes for anything triggered rapidly; mask an imperfect crossfade with `filter: blur(2px)` under 20px.

## Modern CSS Mechanics

The "how do you ship it" layer for layout, navigation, and newer platform features.

### Breakpoints & responsive queries

Documented convention, not live tokens — plain CSS can't read custom properties inside `@media` (no build step here for `@custom-media`): `sm` 560px, `md` 900px, `lg` 1024px. Prefer range syntax (`width < 900px`) over `min`/`max-width` pairs. Gate hover-only affordances behind `(hover: hover) and (pointer: fine)`, not just a breakpoint. Full conventions: `references/layout-and-interaction.md`.

### Container queries

Use when a component's internal layout should respond to the space it's given, not the viewport (a card reused in a sidebar vs. a main column). Media queries are for genuinely page-level concerns (nav collapse, overall grid switch). Pattern: `container-type: inline-size` + `@container (width > Npx)`.

### Layout & typography mechanics

`text-wrap: balance` for short headings (avoids an orphaned last word); `text-wrap: pretty` for body paragraphs (no line-count cap, higher cost). `:has()` for parent-aware styling without JS (e.g. `.field-group:has(:invalid)`).

### Discrete-property transitions

`transition-behavior: allow-discrete` + `@starting-style` transitions properties that don't normally interpolate — most usefully `display`, so an element animates out before leaving layout, no JS unmount-timing listener needed:

```css
.panel {
  opacity: 0;
  transition: opacity 0.2s, display 0.2s allow-discrete;
}
@media (min-width: 1280px) {
  .panel { display: flex; opacity: 1; }
  @starting-style { .panel { opacity: 0; } }
}
```

`motion-engine` covers `@starting-style` for opacity/transform entry; this is the missing half — exit animations and the `display`/`content-visibility` dimension. Full pattern: `references/native-transitions.md`.

### Page transitions

View Transitions API (`::view-transition-old`/`::view-transition-new`, same- or cross-document) for the primitives — same-document via `document.startViewTransition()`, cross-document via `@view-transition { navigation: auto; }`. Full pattern: `references/native-transitions.md`.

### The `linear()` easing function

CSS-native spring approximation — a piecewise easing function sampled from a real spring simulation, so overshoot-and-settle motion ships as a plain CSS value with no JS. Generate control points from a spring simulator, don't hand-write them. Full detail: `references/native-transitions.md`.

## Review Format (Required)

When reviewing UI code, use a markdown table with Before/After/Why columns — one row per issue found:

| Before | After | Why |
| --- | --- | --- |
| Hardcoded `padding: 13px` | `padding: var(--space-sm)` | Spacing scale, not arbitrary values |
| `display: none` toggled via JS class swap | `allow-discrete` + `@starting-style` | Exit animation without a JS unmount-timing listener |

## Review Checklist

| Issue | Fix |
| --- | --- |
| Animation on a keyboard-triggered or 100+/day action | Remove it entirely |
| `ease-in` on a UI animation | Switch to `ease-out` or a custom curve |
| Duration > 300ms on a UI element with no justification | Reduce to 150-250ms |
| `scale(0)` entry animation | Start from `scale(0.95)` with `opacity: 0` |
| `transform-origin: center` on a trigger-anchored popover | Set to the trigger location (modals are exempt) |
| Symmetric enter/exit timing on a press-and-release interaction | Make release/exit faster than press/enter |
| Hardcoded font-size/spacing value | Replace with the nearest token; add a step if none fits |
| Fixed heading size across viewports | `clamp()`-based fluid size |
| Same line-height on headings and body | Tighten line-height as size increases |
| Tabular data without `tabular-nums` | Add `font-variant-numeric: tabular-nums` |
| Default color values proposed by the skill | None — always defer to the project's own tokens |
| `min`/`max-width` pair for a single constraint | Range syntax (`width < 900px`) |
| Hover style with no capability query | Gate behind `(hover: hover) and (pointer: fine)` |
| Component's internal layout keyed to viewport width | Container query keyed to its own width |
| Load animations that don't replay after a client-side route change | Reinit on the router's post-navigation lifecycle event |

## External References

- [`@starting-style`](https://developer.mozilla.org/en-US/docs/Web/CSS/@starting-style) / [`transition-behavior`](https://developer.mozilla.org/en-US/docs/Web/CSS/transition-behavior) — MDN
- [View Transitions API](https://developer.chrome.com/docs/web-platform/view-transitions) — Chrome for Developers
- [`linear()` easing function](https://developer.mozilla.org/en-US/docs/Web/CSS/easing-function/linear) / [`text-wrap`](https://developer.mozilla.org/en-US/docs/Web/CSS/text-wrap) — MDN
- [easing.dev](https://easing.dev/) / [easings.co](https://easings.co/) — custom easing curve playgrounds
