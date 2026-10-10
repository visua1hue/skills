---
name: motion-engine
description: Ships performant animation. Compositor-only CSS/WAAPI/Motion.dev, scroll-driven animation, load orchestration, reduced motion, and device scaling incl. WebGL/Three.js tiers. Use when implementing animations, debugging jank, or optimizing for Core Web Vitals or low-power devices.
---

# Motion Engine

An animation execution skill. It assumes what to animate, which easing, and which duration are already decided. It focuses entirely on shipping that animation without blocking the main thread or degrading Core Web Vitals.

The operating principle is progressive enhancement: CSS handles the default state and scroll-driven animations natively, JavaScript orchestrates load sequencing and provides fallbacks. Every animation runs on the GPU compositor thread. Layout-triggering properties are never animated. The target is 120fps with zero render-blocking.

This skill pairs with a design taste skill (such as `motion-sense`) that owns the "should this animate?" and "how should it feel?" decisions. This skill owns the "how do you ship it?"

## Performance Contract

Animations run on the GPU compositor thread by exclusively using properties that bypass the Layout and Paint stages of the rendering pipeline.

### Permitted Properties

These are composited on the GPU and never trigger layout or paint recalculation:

- `transform`. Translate, scale, rotate, skew
- `opacity`. Fade in/out, crossfade
- `filter` (non-blur). Hue-rotate, brightness, contrast

### Conditional Properties

Cheap enough for short, one-off transitions, but not guaranteed to stay on the compositor:

- `clip-path`. Fine for reveals and state changes. Updating it per frame during a drag (comparison slider) repaints every frame.
- `filter: blur()` / `backdrop-filter`. Real GPU cost that scales with radius and area. Keep under 20px, skip on constrained devices.
- Color: `background-color`, `border-color`, `color`. Allowed as a short (≤200ms) state transition on a single element (hover, focus, active). Never for long, looping, or many-element animations. Crossfade two layers with `opacity` instead.

### Prohibited Properties

Animating any of these triggers layout or paint on the main thread every frame. Never animate them:

- Geometry: `width`, `height`, `margin`, `padding`, `border-width` (`height` is allowed for accordions only, see Compositor Hygiene)
- Positioning: `top`, `left`, `bottom`, `right`, `inset`
- Paint: `box-shadow`, `outline`. These repaint every frame without touching layout. For a shadow change, pre-render the second shadow on a pseudo-element and animate its `opacity`.

To animate size or position changes, use `transform: scale()` and `transform: translate()` instead. Where the end size or position is only known after layout, measure once before and once after, then animate the difference with `transform` (FLIP): one layout read, not one per frame.

The three lists condense the six tiers (S to F) of Motion's performance tier list, linked under External References.

### Compositor Hygiene

- **`will-change`**: a fix for a problem you have observed, never a default. A CSS or WAAPI animation of `transform`/`opacity` gets its own layer without it. Add it for per-frame JS style writes, or after you see first-frame stutter or a 1px shift at the start or end. Name the animated property, set it when the animation starts, remove it when it ends. Each layer costs GPU memory. On a transform or `filter` it also makes the element the containing block for `position: fixed` descendants and creates a stacking context.
- **CSS variable caveat**: updating a custom property recalculates styles for every element that inherits it, and Motion's tier list ranks an animated variable as paint-triggering even when it only feeds `transform` or `opacity`. During active animation (drag, scroll-linked), set `transform` directly on the element. Where a variable is needed, set it on the nearest element and register it with `@property` and `inherits: false`, which limits the recalculation to that element.
- **Layout thrashing**: never interleave DOM reads and writes in one frame. Reading layout (`offsetWidth`, `getBoundingClientRect`) after a style write forces a synchronous layout, and in a loop it is the most expensive pattern there is. Batch every read, then every write.
- **Height animation**: animating `height` or `max-height` triggers layout every frame. Use `transform: scaleY()` with `transform-origin: top`, `clip-path: inset()`, or measure once then animate `translateY` on a clip wrapper. Never animate `height: 0` to `height: auto`. The one exception is an accordion, where no transform equivalent exists: animate to a measured height and keep it short (about 200ms), since it costs layout on every frame.
- **Focus rings**: never animate the focus indicator itself. It triggers paint. Animate the element's background or shadow via opacity crossfade instead.
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

  /* Easing. Reference tokens, never inline keywords. `standard` equals the `ease` keyword */
  --motion-ease-standard: cubic-bezier(0.25, 0.1, 0.25, 1);
  --motion-ease-out: cubic-bezier(0.23, 1, 0.32, 1);
  --motion-ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);
  --motion-ease-drawer: cubic-bezier(0.32, 0.72, 0, 1); /* iOS-like drawer curve */

  /* Spring approximations. cubic-bezier overshoots once but can't settle; for real spring motion use `linear()` (motion-sense) */
  --motion-spring-bounce: cubic-bezier(0.34, 1.56, 0.64, 1); /* overshoots: only after a gesture (flick, drag release), see motion-sense Spring Feel */
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

All animation presets read values from these tokens via `getComputedStyle`. Never hardcode durations, distances, or easing curves in JavaScript. Pull them from CSS custom properties so the design system remains the single source of truth.

If the project has a `DESIGN.md` or equivalent design system file, reference it for motion token values. The token names above are the recommended vocabulary. The specific values are project-dependent.

## Execution Tiers

Use the simplest tool that meets the requirement. Each tier adds capability at the cost of complexity. For full code patterns and caveats, read `references/animation-patterns.md`.

| Tier | Tool                                 | Use When                                                                                                                      |
| ---- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| 1    | CSS Transitions                      | State changes: hover, focus, active, class toggle. Interruptible by default.                                                  |
| 2    | CSS Keyframes + `animation-timeline` | Scroll-driven animations. Zero JS, full compositor. Gate with `@supports`.                                                    |
| 3    | WAAPI                                | Programmatic control, single element. Hardware-accelerated, no library needed.                                                |
| 4    | Motion.dev                           | Orchestration, stagger, sequencing, scroll fallbacks, View Transitions orchestration (`animateView()`). Thin WAAPI wrapper.   |
| 5    | Motion springs                       | Drag, gesture, interruptible physics. Shorthand props (`x`, `y`) are NOT hardware-accelerated. Use full `transform` strings. |

**Key rules across all tiers:**

- Avoid `transition: all`. Always specify exact properties.
- `@starting-style` replaces the React `useEffect(() => setMounted(true))` pattern for CSS-native entry animations. Pattern: `motion-sense/references/native-transitions.md`.
- Gate hover animations behind `@media (hover: hover) and (pointer: fine)`. The rule and its reasoning live in `ui-baseline`.
- CSS animations run off the main thread and remain smooth when the browser is busy. Prefer CSS for predetermined animations; JS for dynamic, interruptible ones.

## Device Capability Scaling

A separate axis from Execution Tiers and from `prefers-reduced-motion`: scale back decorative load when the device or network can't sustain it. Both stack.

- **CSS/WAAPI/Motion.dev**: composited isn't free. Cap stagger group size and concurrent springs, skip parallax layers, shrink or drop blur on low-power devices. Treat mobile as a class-level cap, not a per-animation benchmark. Full detail: `references/device-scaling.md`.
- **WebGL/Three.js**: three tiers (0 static fallback, 1 constrained, 2 full), gated on GPU benchmark and network. Mobile is policy-capped to Tier 1. Hard-cap shader/particle/texture budgets in code. Pre-render non-interactive motion to video. Full blueprint: `references/webgl-device-tiers.md`.

## Paint & Load Strategy

Load animations must not block FCP, delay LCP, or hide content when something fails. For full implementation detail, read `references/load-orchestration.md`.

1. **Hidden state in the keyframe.** The starting state lives in the `from` keyframe, never in a base rule. If the animation never runs (reduced motion, an unsupported browser, a failed script), the element is visible.
2. **CSS first.** A load preset is a CSS keyframe animation that starts at first paint. No script, no wait.
3. **Never animate the LCP element.** Chrome ignores paints at `opacity: 0` when it picks the LCP candidate, so a hero image or headline that fades in records its LCP when the fade shows it, not when it loaded. Keep the largest above-the-fold element static.
4. **JavaScript only where CSS can't express it.** Sequences computed at runtime wait for `document.fonts.ready` and first contentful paint, then run through WAAPI. Use them for content that is not visible at first paint. Anything above the fold takes the CSS path.

```css
@media (prefers-reduced-motion: no-preference) {
  [data-motion="fade-up"] {
    animation: motion-fade-up var(--motion-dur-slow) var(--motion-ease-out) both;
  }
}

@keyframes motion-fade-up {
  from {
    opacity: 0;
    transform: translateY(var(--motion-dist-md));
  }
}
```

**Declarative API**: `data-motion="preset-name"` for load animations, `data-motion-scroll="preset-name"` for scroll animations, `data-motion-delay="0.2"` for timing overrides on JavaScript presets. JavaScript presets are functions in a centralized TypeScript registry that read motion tokens from CSS custom properties at runtime.

## Gesture Best Practices

Minimal performance guardrails for drag and swipe interactions, not a full implementation guide.

- **Compositor-only during gesture**: only update `transform`. Cache layout reads (`getBoundingClientRect`) before drag starts. Never read them during the gesture loop.
- **Pointer capture**: `el.setPointerCapture(e.pointerId)` on drag start. Ensures events continue even if the pointer leaves element bounds.
- **Velocity over threshold**: dismiss based on flick velocity (`distance / elapsed time`), not just distance. A quick flick should dismiss regardless of travel.
- **Multi-touch protection**: ignore additional touch points after drag begins.
- **Boundary damping**: increasing friction past the natural limit, not hard stops.
- **Selection/interaction guard**: disable text selection (`user-select: none`) and set `inert` on the dragged element for the duration of the drag. Without it, a fast drag can select surrounding text or let a pointerup land on whatever's underneath.

## Accessibility

Non-negotiable requirements, not optional enhancements.

### Reduced Motion

Reduced motion means fewer and gentler animations, not zero. Keep opacity and color changes that aid comprehension. Remove movement, scale and blur.

Author it opt-in. The fade applies to everyone, and movement is added inside `prefers-reduced-motion: no-preference`. Nothing has to be undone under `reduce`, and a browser that doesn't know the query gets the static version.

```css
/* Component transition: fade for everyone, movement is opt-in */
.popover {
  transition: opacity var(--motion-dur-base) var(--motion-ease-out);
}
.popover[data-starting-style],
.popover[data-ending-style] {
  opacity: 0;
}

@media (prefers-reduced-motion: no-preference) {
  .popover {
    transition-property: opacity, transform;
  }
  .popover[data-starting-style],
  .popover[data-ending-style] {
    transform: scale(var(--motion-scale-sm));
  }
}

/* Scroll presets declared outside the query: switch them off */
@media (prefers-reduced-motion: reduce) {
  [data-motion-scroll] {
    animation: none !important;
  }
}
```

Load presets sit inside the `no-preference` query (see Paint & Load Strategy). Their hidden state is in the keyframe, so under `reduce` they don't run and the content is in its final state.

A JavaScript animation ignores the CSS query. Check `window.matchMedia('(prefers-reduced-motion: reduce)').matches` before triggering it, or use the library's own setting (`<MotionConfig reducedMotion="user">` in Motion). Skip load presets entirely; for interactive animations, run opacity-only variants.

Never block user interaction during stagger animations. Stagger is decorative. All elements must be interactive immediately. Keep stagger delays short (30–80ms between items) and cap the group at 6-8 items; the rest enter together.

## Review Checklist

Performance only. Feeds the Performance tier of `motion-sense`'s review, which owns posture, output format, and the verdict.

| Issue                                | Fix                                              | Why                                            |
| ------------------------------------ | ------------------------------------------------ | ---------------------------------------------- |
| `transition: all`                    | Specify exact properties                         | Transitions layout-triggering properties       |
| Layout property animated             | Use `transform` equivalent                       | Triggers layout recalculation on every frame   |
| Animating `height`/`max-height` outside an accordion | `scaleY`, `clip-path`, or measure + `translateY` | Layout on every frame |
| `will-change` set preemptively, left on after, or naming a property that never composites | Add only for observed first-frame stutter or a 1px shift, or for per-frame JS style writes; remove when the animation ends | Each layer costs GPU memory; CSS and WAAPI `transform`/`opacity` animations get a layer without it |
| `will-change` on disabled elements   | Remove it                                        | Wastes GPU memory on inert elements            |
| Hardcoded values in JS               | Read from CSS custom properties                  | Design system is the single source of truth    |
| Motion `x`/`y`/`scale` props         | Use `transform: "translateX()"`                  | Shorthand is not hardware-accelerated          |
| CSS var update during drag           | Set `transform` directly                         | Variable inheritance recalculates all children |
| Animated custom property set on an ancestor, or registered as inherited | Set it on the nearest element; `@property` with `inherits: false` | Every inheriting element recalculates each frame |
| `box-shadow` animated | Second shadow on a pseudo-element, animate its `opacity` | Shadow repaints every frame |
| Layout read after a style write inside an animation or loop | Batch reads, then writes; measure once and animate `transform` | Each read forces a synchronous layout |
| `useEffect` + `setMounted` for entry | Use `@starting-style`                            | CSS-native, no extra render cycle              |
| Focus ring animated                  | Animate element background/shadow instead        | Focus indicator triggers paint                 |
| Color animated long, looping, or on many elements | Crossfade two layers with `opacity` | Color repaints every frame; only short single-element state transitions are cheap |
| `clip-path` updated every frame during a drag | `transform` on a clip wrapper | Per-frame clip updates repaint |
| Hidden state in a base rule that only an animation or script reveals | Move it into the `from` keyframe | Content must never depend on motion to become visible |
| Entrance animation on the LCP element (hero image, headline) | Leave it static | Chrome ignores `opacity: 0` paints for LCP, so the fade delays the metric and the content |
| Large stagger group or many concurrent springs, unscaled | Cap group size / spring count on low-power devices | Main-thread physics cost scales with element count, not free just because it targets `transform` |
| Heavy blur/backdrop-filter with no device check | Reduce or skip on constrained devices | Real GPU cost regardless of compositing |
| Full-quality WebGL served unconditionally | Gate behind device tier (0/1/2), static fallback at Tier 0 | No WebGL context or a weak GPU crashes/thermal-throttles instead of degrading |
| Live-rendered non-interactive WebGL motion | Pre-render to video instead | Nothing needs live simulation if it never responds to input |
| Draggable element with no selection/interaction guard | `user-select: none` + `inert` for the drag's duration | Fast drags otherwise select surrounding text or leak pointerup to elements underneath |

### Debugging

**Slow-motion testing**: increase duration to 3–5x to spot easing, sync, and transform-origin issues invisible at full speed.

**Frame-by-frame**: Chrome DevTools Animations panel. Reveals timing mismatches between coordinated properties.

**Record and replay**: screen-record the animation, play back at reduced speed. Shifts perception from experiencing to analyzing.

**Real device testing**: for touch gestures, test on physical hardware. Simulators don't replicate gesture latency or frame pacing.

**Automated verification**: Chrome DevTools MCP (`chrome-devtools-mcp`): run `performance_start_trace` / `performance_stop_trace` and `lighthouse_audit` to validate compositor-only rendering.

## External References

- [Web Animation Performance Tier List](https://motion.dev/blog/web-animation-performance-tier-list). Motion.dev
- [`animateView()`](https://motion.dev/docs/animate-view). Motion.dev docs
- [CSS animation-timeline](https://developer.mozilla.org/en-US/docs/Web/CSS/animation-timeline). MDN
- [easing.dev](https://easing.dev/). Custom easing curve playground
- [detect-gpu](https://github.com/pmndrs/detect-gpu). GPU benchmark/tier classification, pmndrs
- [Scaling performance](https://r3f.docs.pmnd.rs/advanced/scaling-performance). React Three Fiber
- [`will-change`](https://developer.mozilla.org/en-US/docs/Web/CSS/will-change). MDN
- [Don't hide the LCP image behind animations](https://shopify.dev/docs/storefronts/themes/best-practices/performance/dont-hide-lcp-image-behind-animations). Shopify
- [jakubkrehel/skills](https://github.com/jakubkrehel/skills). Jakub Krehel. Source of the keyframe hidden-state pattern and the `will-change` side effects
