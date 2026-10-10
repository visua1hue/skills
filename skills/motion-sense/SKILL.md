---
name: motion-sense
description: visua1's animation taste. Whether/how to animate, easing and duration, transform/clip-path technique, press/popover/tooltip feel, native CSS entry/exit and View Transitions. Spring feel and animation review. Use when deciding or reviewing how something should animate. Perf mechanics live in motion-engine.
---

# Motion Sense (visua1)

Personal animation-taste judgment, covering *why* (philosophy, decision framework), *how* (CSS transform/clip-path technique, animation-flavored component patterns), and native CSS entry/exit and page transitions. Also owns spring feel and the animation review verdict. Pairs with `motion-engine`, which owns compositor/perf execution once something is animating, including spring runtime cost.

## Core Philosophy

Taste is trained, not innate. It's an instinct for what elevates, built by studying good work, reverse-engineering why something feels right, and practicing relentlessly. Don't just make something work; study why the best version of it feels the way it does.

Most details compound invisibly. A user who never consciously notices a detail is the goal, not a failure to draw attention to it. The aggregate of a hundred small correct decisions is what separates software that feels right from software that merely functions.

Beauty is leverage. People choose tools based on the whole experience, not just the feature list. Good defaults and a considered feel are real, underused differentiators.

*Starting point, not final. Update this section directly as your own opinions solidify or diverge from the above.*

## Animation Decision Framework

Before writing animation code, work through these in order. Full rationale, curves, and duration tables: `references/animation-decisions.md`.

Three rules hold for every step:

- **No approximated values.** Curves, durations and spring settings come from the tables here. Never substitute a familiar-looking guess.
- **Extend the project's motion tokens.** If the project has easing or duration tokens, use them. A parallel set is a defect.
- **Make the call.** Pick one answer, give the reason in one line, write the code. No menu of options.

| Question | Rule |
| --- | --- |
| Should this animate at all? | Never for 100+/day actions (keyboard shortcuts); standard for occasional UI (modals, toasts); delight is fine for rare/first-time moments |
| What's the purpose? | Spatial consistency, state indication, explanation, feedback, or preventing a jarring change. Delight only for rare/first-time moments. "Looks cool" alone doesn't qualify for frequent UI, and data the user reads or acts on never moves for style |
| What easing? | Entering/exiting → `ease-out`; on-screen movement → `ease-in-out`; hover/color → `ease`; constant motion → `linear`. Never `ease-in` on UI. |
| How fast? | Button feedback 100-160ms, tooltips/popovers 125-200ms, dropdowns 150-250ms, modals 200-500ms. UI stays under 300ms. The 500ms end is the drawer on `--motion-ease-drawer`, whose steep start keeps it from reading as slow |
| How does it leave? | The way it entered, same edge and path. Shorter and smaller than the enter: about half to three quarters of the duration, a small fixed offset. Slide fully out only where the destination means something (a drawer closing, a card returning to its list) |

Also in the reference: perceived-performance notes (fast spinners, instant subsequent tooltips) and a distilled set of principles for building components people actually reach for (DX-first, good defaults over options, invisible edge-case handling, cohesion over isolated "correct" values, asymmetric enter/exit timing).

## Animation Technique Library

CSS technique for shipping the decisions above. Full patterns: `references/animation-techniques.md`.

- **Transform mastery.** `translateY(%)` for size-independent motion, `scale()` scales children too (a feature, not a bug), 3D transforms (`rotateX`/`rotateY` + `preserve-3d`) for depth, explicit `transform-origin` matching where the interaction actually originates.
- **`clip-path`.** Inset-shape reveals, tab color transitions via a clipped duplicate layer, hold-to-delete (2s linear press, 200ms ease-out release), scroll reveals, comparison sliders.
- **Component feel patterns.** Buttons scale `0.97` on `:active`, and a disabled button never scales; never animate entry from `scale(0)` (start from opacity plus popover `0.95`, tooltip `0.97`, modal `0.96`); popovers scale in from their trigger via `transform-origin` (modals stay centered because they aren't trigger-anchored); tooltips skip delay/animation on hovers after the first is open; prefer transitions over keyframes for anything triggered rapidly; mask an imperfect crossfade with a subtle `filter: blur(2px)`, never above 20px; a toggle, tab or icon never animates into its default state on first render; where colors have transitions, switch them off for the moment the theme flips.

## Spring Feel

Springs for anything the user can grab, flick, or interrupt. Duration + easing for everything else. Think in Motion's `{ type: "spring", visualDuration, bounce }`, not mass/stiffness/damping: two numbers that map to what you actually perceive. `visualDuration` is when the element visually arrives; any bounce settles after it, so the UI budget (under 300ms) applies to `visualDuration`.

| Situation | Bounce | Visual duration |
| --- | --- | --- |
| Default (move, resize, settle into place) | `0` | 0.2-0.3s |
| After momentum (flick, throw, drag release) | 0.1-0.3 | 0.2-0.3s |
| Rare delight moment (the one exception to earned bounce) | up to 0.3 | can be longer |

- **Bounce is earned by momentum.** Overshoot on a card the user flicked feels physical. Overshoot on a menu that just appeared, with no gesture behind it, feels wrong. Rare delight moments are the only exception.
- **Match personality.** Crisp dashboard: `bounce: 0` everywhere. Playful consumer UI: allow bounce on gestures.
- **One-shot vs. interruptible.** A spring that runs once with no interruption ships as CSS `linear()`. One that must keep velocity when interrupted needs a JS spring. Detail: `references/native-transitions.md`. Runtime cost and hardware-acceleration caveats: `motion-engine`.

## Native CSS Transitions

The "how do you ship it natively" layer for entry/exit and page-level motion, no JS orchestration required.

### Discrete-property transitions

`transition-behavior: allow-discrete` + `@starting-style` transitions properties that don't normally interpolate, most usefully `display`, so an element animates out before leaving layout, no JS unmount-timing listener needed:

```css
.panel {
  opacity: 0;
  transition: opacity 0.2s, display 0.2s allow-discrete;
}
@media (width >= 1280px) {
  .panel { display: flex; opacity: 1; }
  @starting-style { .panel { opacity: 0; } }
}
```

Entry and exit both live here, and `motion-engine` links to this. Full pattern: `references/native-transitions.md`.

### View transitions

Same-document `document.startViewTransition()` works in all three engines. Cross-document `@view-transition { navigation: auto; }` works in Chromium and Safari and falls back to a normal navigation. Full reference: `references/native-transitions.md`.

- **Navigation-level only.** Route changes, list to detail, a list that reorders. A view transition can't be interrupted, so it is wrong for anything hovered, dragged or toggled rapidly.
- **Slides need a direction.** Hierarchy and ordered sequences slide. Tab to tab crossfades.
- **Morph what the user tracks**, a hero image or a title, not everything present on both sides.
- **Lists and grids:** `view-transition-name: match-element` plus `view-transition-class`, no per-item names.
- **Direction:** transition types and `:active-view-transition-type()`, not classes swapped from script.
- **Reduced motion:** the crossfade stays; names, types and custom keyframes go inside `no-preference`.
- **Focus** moves to the new view when the transition finishes. The API doesn't do it.

For springs, separate enter and exit, or a staggered shared-element morph, Motion's `animateView()` removes the naming and pseudo-element bookkeeping. Detail: `motion-engine/references/animation-patterns.md`.

### The `linear()` easing function

CSS-native spring approximation: a piecewise easing function sampled from a real spring simulation, so overshoot-and-settle motion ships as a plain CSS value with no JS. Generate control points from a spring simulator, don't hand-write them. Full detail: `references/native-transitions.md`.

## Review

When asked to review animation code, this skill owns the verdict. Run `motion-engine`'s Review Checklist for the Performance tier.

**Posture:** default to flagging. Approval is earned, not assumed. A transition that "works" but feels sluggish, fires too often, or drops frames is a regression, not a pass.

### Output

**Part 1: findings table**, one row per issue:

| Before | After | Why |
| --- | --- | --- |
| `ease-in` on dropdown | `cubic-bezier(0.23, 1, 0.32, 1)` | `ease-in` delays the moment the user watches most |

**Part 2: verdict**, grouped by impact tier (omit empty tiers):

1. **Feel-breaking regressions.** Sluggish easing, comes-from-nowhere, fires on high-frequency/keyboard actions
2. **Missed simplifications.** Animations that should be removed or drastically reduced
3. **Performance.** From `motion-engine`'s checklist
4. **Interruptibility & timing.** Keyframes where transitions/springs belong; symmetric timing that should be asymmetric
5. **Origin, physicality & cohesion.** Wrong `transform-origin`, unearned bounce, mismatched personality
6. **Accessibility.** Missing reduced-motion or hover gating

Close with an explicit decision:
- **Block.** Any feel-breaking regression, animation on keyboard/high-frequency action, `scale(0)`/`ease-in` on UI, non-GPU animation with an easy fix
- **Approve.** No feel-breaking regressions, durations and easing within bounds, interruptibility handled, reduced-motion respected

### When asked what could animate

Report candidates, don't implement them. Each one must pass the Decision Framework: frequency, a named purpose, a duration inside budget, and no motion on data the user is reading. Cap the list at 5-7 for a whole app, fewer for one view, ordered by impact. Give exact values for each. Also list 2-5 places considered and rejected, with the question that ruled each out. If nothing passes, say so. That is a valid result.

### Remedial hierarchy

Prefer earlier moves:

1. Delete the animation (high-frequency / no purpose / keyboard-triggered)
2. Reduce it. Shorter duration, smaller transform, fewer properties
3. Fix the easing. `ease-in` → `ease-out` / custom curve
4. Fix origin/physicality. Correct `transform-origin`; `scale(0)` → `scale(0.95)` + opacity
5. Make it interruptible. Keyframes → transitions, or a spring for gesture-driven motion
6. Move it to the GPU (see `motion-engine`)
7. Asymmetric timing. Slow the deliberate phase, snap the response
8. Polish. Blur crossfades, stagger groups, `@starting-style` for entry
9. Accessibility & cohesion. Reduced-motion + hover gating; tune to component personality

### Checklist

| Issue | Fix |
| --- | --- |
| Animation on a keyboard-triggered or 100+/day action | Remove it entirely |
| `ease-in` on a UI animation | Switch to `ease-out` or a custom curve |
| Duration > 300ms on a UI element with no justification | Reduce to 150-250ms |
| `scale(0)` entry animation | Start from `scale(0.95)` with `opacity: 0` |
| `transform-origin: center` on a trigger-anchored popover | Set to the trigger location (modals are exempt) |
| Keyframes on toasts, toggles, or anything triggered rapidly | CSS transitions |
| Bounce on an element with no gesture behind it | `bounce: 0` |
| Symmetric enter/exit timing on a press-and-release interaction | Make release/exit faster than press/enter |
| Everything-at-once entrance | 30-80ms stagger, capped at 6-8 items; the rest enter together |
| Movement, scale or blur outside `@media (prefers-reduced-motion: no-preference)` | Move it inside the query; the opacity fade stays for everyone. Gentler, not zero |
| `:active` scale that also fires on a disabled button | `:not(:disabled):active` |
| Exit as long or as large as the enter, or leaving by a different edge | Same path, about half to three quarters of the duration, small offset |
| Toggle, tab or icon animating into its default state on page load | Render the state before first paint; `initial={false}` on the Motion presence wrapper |
| Every color transition firing at once on theme switch | Disable transitions for the swap, restore after the next frame |
| Ungated `:hover` motion | `@media (hover: hover) and (pointer: fine)` |
| View transition on hover, drag or a rapidly toggled control | CSS transition or spring that can retarget |
| Directional slide between sibling tabs or other lateral views | Crossfade, or no transition |
| Per-item `view-transition-name` written by hand for a list | `match-element` + `view-transition-class` |
| View transition names or slides outside `no-preference` | Move them inside the query; the crossfade stays |
| Focus left on a removed element after a view transition | Focus the new view's heading when `finished` resolves |
| Load animations that don't replay after a client-side route change | Reinit on the router's post-navigation lifecycle event |
| Abrupt state change with no transition where one would aid comprehension (instant visibility toggle, jarring content swap) | Add a purposeful transition, still gated by the Decision Framework above, not a license to animate everything |

## External References

- [`@starting-style`](https://developer.mozilla.org/en-US/docs/Web/CSS/@starting-style) / [`transition-behavior`](https://developer.mozilla.org/en-US/docs/Web/CSS/transition-behavior), MDN
- [View Transitions API](https://developer.chrome.com/docs/web-platform/view-transitions) / [What's new in view transitions (2025)](https://developer.chrome.com/blog/view-transitions-in-2025), Chrome for Developers
- [Modern Web Guidance](https://github.com/GoogleChrome/modern-web-guidance), Chrome. Source of the cross-document render-blocking, focus and partial-page rules
- [react-view-transitions](https://github.com/vercel-labs/agent-skills/tree/main/skills/react-view-transitions), Vercel. React `<ViewTransition>`
- [`animateView()`](https://motion.dev/docs/animate-view), Motion.dev docs
- [`linear()` easing function](https://developer.mozilla.org/en-US/docs/Web/CSS/easing-function/linear), MDN
- [easing.dev](https://easing.dev/) / [easings.co](https://easings.co/), custom easing curve playgrounds
- [emilkowalski/skills](https://github.com/emilkowalski/skills), Emil Kowalski. Source of the decision framework, curves, durations and component patterns
- [jakubkrehel/skills](https://github.com/jakubkrehel/skills), Jakub Krehel. Source of the exit-size, first-render and theme-switch rules
