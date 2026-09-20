---
name: motion-sense
description: visua1's animation taste — whether/how to animate, easing and duration, transform/clip-path technique, press/popover/tooltip feel, native CSS entry/exit and View Transitions. Use when deciding or reviewing how something should animate. Springs and perf live in motion-engine.
---

# Motion Sense (visua1)

Personal animation-taste judgment — covering *why* (philosophy, decision framework), *how* (CSS transform/clip-path technique, animation-flavored component patterns), and native CSS entry/exit and page transitions. Pairs with `motion-engine`, which owns compositor/perf execution once something is animating. Spring-physics animation guidance (JS `useSpring`, mass/stiffness/damping config) is intentionally out of scope for this skill.

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

## Animation Technique Library

CSS technique for shipping the decisions above. Full patterns: `references/animation-techniques.md`.

- **Transform mastery** — `translateY(%)` for size-independent motion, `scale()` scales children too (a feature, not a bug), 3D transforms (`rotateX`/`rotateY` + `preserve-3d`) for depth, explicit `transform-origin` matching where the interaction actually originates.
- **`clip-path`** — inset-shape reveals, tab color transitions via a clipped duplicate layer, hold-to-delete (2s linear press, 200ms ease-out release), scroll reveals, comparison sliders.
- **Component feel patterns** — buttons scale `0.97` on `:active`; never animate entry from `scale(0)` (start at `0.95`+opacity instead); popovers scale in from their trigger via `transform-origin` (modals stay centered — they aren't trigger-anchored); tooltips skip delay/animation on hovers after the first is open; prefer transitions over keyframes for anything triggered rapidly; mask an imperfect crossfade with `filter: blur(2px)` under 20px.

## Native CSS Transitions

The "how do you ship it natively" layer for entry/exit and page-level motion — no JS orchestration required.

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

View Transitions API (`::view-transition-old`/`::view-transition-new`, same- or cross-document) for the primitives — same-document via `document.startViewTransition()`, cross-document via `@view-transition { navigation: auto; }`. Full pattern: `references/native-transitions.md`. When the transition needs springs, differentiated enter/exit, or a staggered shared-element morph, Motion.dev's `animateView()` wrapper removes the manual naming/pseudo-element bookkeeping the raw API requires — execution detail lives in `motion-engine/references/animation-patterns.md`.

### The `linear()` easing function

CSS-native spring approximation — a piecewise easing function sampled from a real spring simulation, so overshoot-and-settle motion ships as a plain CSS value with no JS. Generate control points from a spring simulator, don't hand-write them. Full detail: `references/native-transitions.md`.

## Review Checklist

| Issue | Fix |
| --- | --- |
| Animation on a keyboard-triggered or 100+/day action | Remove it entirely |
| `ease-in` on a UI animation | Switch to `ease-out` or a custom curve |
| Duration > 300ms on a UI element with no justification | Reduce to 150-250ms |
| `scale(0)` entry animation | Start from `scale(0.95)` with `opacity: 0` |
| `transform-origin: center` on a trigger-anchored popover | Set to the trigger location (modals are exempt) |
| Symmetric enter/exit timing on a press-and-release interaction | Make release/exit faster than press/enter |
| Load animations that don't replay after a client-side route change | Reinit on the router's post-navigation lifecycle event |
| Abrupt state change with no transition where one would aid comprehension (instant visibility toggle, jarring content swap) | Add a purposeful transition — still gated by the Decision Framework above, not a license to animate everything |

## External References

- [`@starting-style`](https://developer.mozilla.org/en-US/docs/Web/CSS/@starting-style) / [`transition-behavior`](https://developer.mozilla.org/en-US/docs/Web/CSS/transition-behavior) — MDN
- [View Transitions API](https://developer.chrome.com/docs/web-platform/view-transitions) — Chrome for Developers
- [`animateView()`](https://motion.dev/docs/animate-view) — Motion.dev docs
- [`linear()` easing function](https://developer.mozilla.org/en-US/docs/Web/CSS/easing-function/linear) — MDN
- [easing.dev](https://easing.dev/) / [easings.co](https://easings.co/) — custom easing curve playgrounds
