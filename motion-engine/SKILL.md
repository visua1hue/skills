---
name: motion-engine
description: Animation execution skill for shipping performant, compositor-only animations using CSS, WAAPI, and Motion.dev. Covers load orchestration, scroll-driven animation, accessibility, and FCP-safe initialization. Use this skill whenever animations need to be implemented, debugged for jank, or optimized for Core Web Vitals. Trigger on any mention of animation performance, WAAPI, Motion.dev, scroll-driven animation, FCP/LCP optimization, compositor-only rendering, animation orchestration, or reduced motion handling. This skill owns the execution layer — pair it with a design taste skill (like emil-design-eng) for animation decision-making.
---

# Motion Engine

An animation execution skill. It assumes the design decision has already been made — what to animate, what easing, what duration — and focuses entirely on shipping that animation without blocking the main thread or degrading Core Web Vitals.

The operating principle is progressive enhancement: CSS handles the default state and scroll-driven animations natively, JavaScript orchestrates load sequencing and provides fallbacks. Every animation runs on the GPU compositor thread. Layout-triggering properties are never animated. The target is 120fps with zero render-blocking.

This skill pairs with design taste skills (such as `emil-design-eng`) that own the "should this animate?" and "how should it feel?" decisions. This skill owns the "how do you ship it?"

## Performance Contract

Animations run on the GPU compositor thread by exclusively using properties that bypass the Layout and Paint stages of the rendering pipeline.

### Permitted Properties

These three property groups are composited on the GPU and never trigger layout or paint recalculation:

- `transform` — translate, scale, rotate, skew
- `opacity` — fade in/out, crossfade
- `filter` — blur, hue-rotate, brightness, contrast

### Prohibited Properties

Animating any of these triggers layout recalculation and blocks the main thread. Never animate them:

- Geometry: `width`, `height`, `margin`, `padding`, `border-width`
- Positioning: `top`, `left`, `bottom`, `right`, `inset`
- Paint: `background-color`, `box-shadow`, `border-color`, `outline`

To animate size or position changes, use `transform: scale()` and `transform: translate()` instead. To animate color, crossfade two layers with `opacity`.

### Compositor Hygiene

- **`will-change`**: declare on elements that will animate. Only apply to active animations — overuse wastes GPU memory. Remove after one-shot animations complete.
- **CSS variable caveat**: updating a custom property on a parent recalculates styles for all children. During active animation (drag, scroll-linked), set `transform` directly on the element.
- **Height animation**: animating `height` or `max-height` triggers layout every frame. Use `transform: scaleY()` with `transform-origin: top`, `clip-path: inset()`, or measure once then animate `translateY` on a clip wrapper. Never animate `height: 0` to `height: auto`.
- **Focus rings**: never animate the focus indicator itself — it triggers paint. Animate the element's background or shadow via opacity crossfade instead.
- **Disabled elements**: remove all transition and `will-change` declarations. They waste compositor layers on elements that can't be interacted with.

## Motion Tokens

Define motion parameters as CSS custom properties so animations read from a single source of truth rather than hardcoding values.

```css
:root {
  /* Timing */
  --motion-dur-fast: 120ms;
  --motion-dur-base: 180ms;
  --motion-dur-slow: 300ms;
  --motion-dur-long: 600ms;

  /* Easing — use custom curves, not built-in keywords */
  --motion-ease-standard: cubic-bezier(0.25, 0.1, 0.25, 1);
  --motion-ease-out: cubic-bezier(0.23, 1, 0.32, 1);
  --motion-ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);

  /* Spring approximations — CSS cubic-bezier curves that mimic spring physics */
  --motion-spring-bounce: cubic-bezier(0.34, 1.56, 0.64, 1);
  --motion-spring-smooth: cubic-bezier(0.22, 1, 0.36, 1);
  --motion-spring-snappy: cubic-bezier(0.16, 1, 0.3, 1);

  /* Distance & Scale */
  --motion-dist-sm: 10px;
  --motion-dist-md: 30px;
  --motion-dist-lg: 60px;
  --motion-scale-sm: 0.95;
  --motion-scale-lg: 1.05;

  /* Scroll animation ranges */
  --motion-range-default: entry 10% cover 30%;
  --motion-range-slow: entry 10% cover 50%;
  --motion-range-late: entry 40% cover 60%;
}
```

All animation presets read values from these tokens via `getComputedStyle`. Never hardcode durations, distances, or easing curves in JavaScript — pull them from CSS custom properties so the design system remains the single source of truth.

If the project has a `DESIGN.md` or equivalent design system file, reference it for motion token values. The token names above are the recommended vocabulary — the specific values are project-dependent.

## Execution Tiers

Use the simplest tool that meets the requirement. Each tier adds capability at the cost of complexity. For full code patterns and caveats, read `references/animation-patterns.md`.

| Tier | Tool                                 | Use When                                                                                                                      |
| ---- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| 1    | CSS Transitions                      | State changes: hover, focus, active, class toggle. Interruptible by default.                                                  |
| 2    | CSS Keyframes + `animation-timeline` | Scroll-driven animations. Zero JS, full compositor. Gate with `@supports`.                                                    |
| 3    | WAAPI                                | Programmatic control, single element. Hardware-accelerated, no library needed.                                                |
| 4    | Motion.dev                           | Orchestration, stagger, sequencing, scroll fallbacks. Thin WAAPI wrapper.                                                     |
| 5    | Motion springs                       | Drag, gesture, interruptible physics. Shorthand props (`x`, `y`) are NOT hardware-accelerated — use full `transform` strings. |

**Key rules across all tiers:**

- Avoid `transition: all` — always specify exact properties.
- `@starting-style` replaces the React `useEffect(() => setMounted(true))` pattern for CSS-native entry animations.
- Gate hover animations behind `@media (hover: hover) and (pointer: fine)` to prevent false-positive touch hover states.
- CSS animations run off the main thread and remain smooth when the browser is busy. Prefer CSS for predetermined animations; JS for dynamic, interruptible ones.

## Paint & Load Strategy

Load animations must not block FCP or degrade LCP. For full implementation detail, read `references/load-orchestration.md`.

The strategy in brief:

1. **CSS initial state**: `[data-motion] { opacity: 0.01; will-change: transform, opacity, filter; }` — elements are painted but invisible. `0.01` not `0` because Lighthouse ignores `opacity: 0` for FCP.
2. **Asset lock**: `await document.fonts.ready` — prevents FOUT during animation.
3. **Paint lock**: check `performance.getEntriesByType('paint')` for existing FCP → `PerformanceObserver` fallback → `requestAnimationFrame` fallback.
4. **Execute**: trigger load animation presets only after both locks clear.

**Declarative API**: `data-motion="preset-name"` for load animations, `data-motion-scroll="preset-name"` for scroll animations, `data-motion-delay="0.2"` for timing overrides. Presets are functions in a centralized TypeScript registry that read motion tokens from CSS custom properties at runtime.

## Gesture Best Practices

Minimal performance guardrails for drag and swipe interactions — not a full implementation guide.

- **Compositor-only during gesture**: only update `transform`. Cache layout reads (`getBoundingClientRect`) before drag starts — never read them during the gesture loop.
- **Pointer capture**: `el.setPointerCapture(e.pointerId)` on drag start. Ensures events continue even if the pointer leaves element bounds.
- **Velocity over threshold**: dismiss based on flick velocity (`distance / elapsed time`), not just distance. A quick flick should dismiss regardless of travel.
- **Multi-touch protection**: ignore additional touch points after drag begins.
- **Boundary damping**: increasing friction past the natural limit, not hard stops.

## Accessibility

Non-negotiable requirements, not optional enhancements.

### Reduced Motion

Respect `prefers-reduced-motion: reduce`. Reduced motion means fewer and gentler animations, not zero. Remove transform-based movement. Keep opacity transitions that aid comprehension.

```css
@media (prefers-reduced-motion: reduce) {
  [data-motion],
  [data-motion-scroll] {
    animation: none !important;
    transition: opacity 0.2s ease !important;
    transform: none !important;
    opacity: 1 !important;
    filter: none !important;
  }
}
```

In JavaScript, check `window.matchMedia('(prefers-reduced-motion: reduce)').matches` before triggering animations. Skip transform-based presets; allow opacity-only presets to run.

Never block user interaction during stagger animations. Stagger is decorative — all elements must be interactive immediately. Keep stagger delays short (30–80ms between items).

## Review Mode

When asked to review animation code, adopt this posture and output format.

**Posture:** default to flagging — approval is earned, not assumed. A transition that "works" but feels sluggish, fires too often, or drops frames is a regression, not a pass.

### Output format

**Part 1 — Findings table** (always present):

| Before | After | Why |
| --- | --- | --- |
| `transition: all 300ms` | `transition: transform 200ms ease-out` | `all` animates layout-triggering properties off-GPU |

**Part 2 — Verdict**, grouped by impact tier (omit empty tiers):

1. **Feel-breaking regressions** — sluggish easing, comes-from-nowhere, fires on high-frequency/keyboard actions
2. **Missed simplifications** — animations that should be removed or drastically reduced
3. **Performance** — non-GPU properties, dropped-frame risks, recalc storms
4. **Interruptibility & timing** — keyframes where transitions/springs belong; symmetric timing that should be asymmetric
5. **Origin, physicality & cohesion** — wrong transform-origin, mismatched personality
6. **Accessibility** — missing reduced-motion or hover gating

Close with an explicit decision:
- **Block** — any feel-breaking regression, animation on keyboard/high-frequency action, `scale(0)`/`ease-in` on UI, non-GPU animation with an easy fix
- **Approve** — no feel-breaking regressions, durations and easing within bounds, interruptibility handled, reduced-motion respected

### Remedial hierarchy

When proposing fixes, prefer earlier moves:

1. Delete the animation (high-frequency / no purpose / keyboard-triggered)
2. Reduce it — shorter duration, smaller transform, fewer properties
3. Fix the easing — swap `ease-in` → `ease-out` / custom curve
4. Fix origin/physicality — correct `transform-origin`; replace `scale(0)` with `scale(0.95)` + opacity
5. Make it interruptible — keyframes → transitions, or a spring for gesture-driven motion
6. Move it to the GPU — layout props → `transform`/`opacity`; WAAPI for programmatic CSS
7. Asymmetric timing — slow the deliberate phase, snap the response
8. Polish — blur crossfades, stagger groups, `@starting-style` for entry
9. Accessibility & cohesion — reduced-motion + hover gating; tune to component personality

### Escalation triggers

Flag these immediately:

- `transition: all`
- `scale(0)` or pure-fade with no initial transform
- `ease-in` on any UI interaction
- Animation on keyboard shortcut or 100+/day action
- UI duration > 300ms with no justification
- `transform-origin: center` on a trigger-anchored popover/dropdown/tooltip
- Keyframes on toasts, toggles, or anything triggered rapidly
- Animating layout properties (`width`/`height`/`margin`/`padding`/`top`/`left`)
- Motion `x`/`y`/`scale` props on animation running while the page is busy
- CSS variable updated on a parent to drive a child transform
- Missing `prefers-reduced-motion` on movement
- Ungated `:hover` motion
- Symmetric enter/exit timing on a press-and-release interaction
- Everything-at-once entrance where a 30–80ms stagger belongs

## Review Checklist

Performance-focused. Taste-level checks (easing selection, duration choice, animation purpose) belong to the design taste skill.

| Issue                                | Fix                                              | Why                                            |
| ------------------------------------ | ------------------------------------------------ | ---------------------------------------------- |
| `transition: all`                    | Specify exact properties                         | Transitions layout-triggering properties       |
| Layout property animated             | Use `transform` equivalent                       | Triggers layout recalculation on every frame   |
| Animating `height`/`max-height`      | `scaleY`, `clip-path`, or measure + `translateY` | Layout on every frame                          |
| Missing `will-change`                | Add on animated elements                         | Browser needs hint for compositor promotion    |
| `will-change` on disabled elements   | Remove it                                        | Wastes GPU memory on inert elements            |
| Hardcoded values in JS               | Read from CSS custom properties                  | Design system is the single source of truth    |
| Missing `prefers-reduced-motion`     | Add media query + JS check                       | Accessibility requirement                      |
| Hover without `(hover: hover)` query | Gate behind media query                          | False-positive hover on touch devices          |
| Motion `x`/`y`/`scale` props         | Use `transform: "translateX()"`                  | Shorthand is not hardware-accelerated          |
| CSS var update during drag           | Set `transform` directly                         | Variable inheritance recalculates all children |
| `useEffect` + `setMounted` for entry | Use `@starting-style`                            | CSS-native, no extra render cycle              |
| Focus ring animated                  | Animate element background/shadow instead        | Focus indicator triggers paint                 |

### Debugging

**Slow-motion testing**: increase duration to 3–5x to spot easing, sync, and transform-origin issues invisible at full speed.

**Frame-by-frame**: Chrome DevTools Animations panel. Reveals timing mismatches between coordinated properties.

**Record and replay**: screen-record the animation, play back at reduced speed. Shifts perception from experiencing to analyzing.

**Real device testing**: for touch gestures, test on physical hardware. Simulators don't replicate gesture latency or frame pacing.

**Automated verification**: Chrome DevTools MCP (`chrome-devtools-mcp`) — `performance_start_trace` / `performance_stop_trace` and `lighthouse_audit` to validate compositor-only rendering.

## External References

- [Web Animation Performance Tier List](https://motion.dev/blog/web-animation-performance-tier-list) — Motion.dev
- [CSS animation-timeline](https://developer.mozilla.org/en-US/docs/Web/CSS/animation-timeline) — MDN
- [easing.dev](https://easing.dev/) — Custom easing curve playground
