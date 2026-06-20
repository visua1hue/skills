# Execution Tiers — Reference

Detailed guidance for each animation execution tier. Read this when implementing animations and you need the full code patterns and caveats.

## Tier 1: CSS Transitions

For predetermined, non-interactive state changes. Hover effects, color transitions, simple toggles. CSS transitions are interruptible by default — triggering a new state mid-transition retargets smoothly rather than restarting from zero.

```css
.button {
  transition: transform var(--motion-dur-fast) var(--motion-ease-out);
}
.button:active {
  transform: scale(var(--motion-scale-sm));
}
```

Use when the animation is a direct response to a state change (hover, focus, active, class toggle). Avoid `transition: all` — always specify exact properties.

### Interaction State Performance Rules

These rules exist for performance reasons, not aesthetics:

- **Focus**: never animate the focus ring itself. Focus indicators trigger paint. Animate the element's `background` or `box-shadow` via opacity crossfade instead.
- **Disabled**: remove all transition and `will-change` declarations. Disabled elements with animation properties waste compositor layers on elements that can't be interacted with.
- **Hover**: gate behind `@media (hover: hover) and (pointer: fine)` to avoid false-positive hover states on touch devices that waste compositor work.

### `@starting-style` for Entry Animations

The modern CSS way to animate element entry without JavaScript. Replaces the common React pattern of `useEffect(() => setMounted(true))` which requires an extra render cycle. Use when browser support allows; fall back to a `data-mounted` attribute pattern otherwise.

```css
.toast {
  opacity: 1;
  transform: translateY(0);
  transition:
    opacity 400ms ease,
    transform 400ms ease;

  @starting-style {
    opacity: 0;
    transform: translateY(100%);
  }
}
```

## Tier 2: CSS Keyframes + Scroll Timeline

For scroll-driven animations with zero JavaScript. Native compositor performance. Gate behind `@supports` so non-supporting browsers get a graceful fallback.

```css
@supports (animation-timeline: view()) {
  [data-motion-scroll="fade-up"] {
    animation-name: motion-fade-up;
    animation-timeline: view();
    animation-range: var(--motion-range-default);
    animation-fill-mode: both;
    animation-timing-function: linear;
  }
}

@keyframes motion-fade-up {
  from {
    opacity: 0;
    transform: translateY(var(--motion-dist-md));
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
```

Use `animation-timeline: view()` for viewport-entry animations. Use `animation-timeline: scroll()` for scroll-progress effects:

```css
/* Scroll progress bar — fills as user scrolls the page */
.progress-bar {
  transform-origin: left;
  animation: progress-fill linear both;
  animation-timeline: scroll(root);
}

@keyframes progress-fill {
  from {
    transform: scaleX(0);
  }
  to {
    transform: scaleX(1);
  }
}
```

Read scroll ranges from motion tokens. Define keyframes that are shared between the CSS and WAAPI paths — write them once as `@keyframes`, reference the same values in JS presets for the fallback.

## Tier 3: Web Animations API (WAAPI)

For programmatic control with CSS-level performance. Hardware-accelerated, interruptible, no library needed. Use when you need JavaScript control over a single animation but don't need orchestration.

```javascript
element.animate(
  [
    { opacity: 0, transform: "translateY(30px)" },
    { opacity: 1, transform: "translateY(0)" },
  ],
  {
    duration: 180,
    easing: "cubic-bezier(0.25, 0.1, 0.25, 1)",
    fill: "forwards",
  },
);
```

WAAPI runs on the compositor thread like CSS animations but provides JavaScript handles for play/pause/cancel/reverse and finish promises.

## Tier 4: Motion.dev

For orchestration, sequencing, stagger, and scroll fallbacks. Motion.dev is a thin wrapper over WAAPI — it adds a better API for coordinating multiple elements without sacrificing compositor performance.

```typescript
import { animate, stagger, inView } from "motion";

// Staggered entrance
animate(
  "[data-motion='fade-up']",
  { opacity: [0.01, 1], transform: ["translateY(30px)", "translateY(0)"] },
  { duration: 0.18, delay: stagger(0.05) },
);

// Scroll-triggered (WAAPI fallback for browsers without animation-timeline)
inView("[data-motion-scroll]", (el) => {
  animate(el, { opacity: [0, 1] }, { duration: 0.3 });
});
```

Use Motion.dev when you need to coordinate multiple elements, build a preset system, or provide WAAPI-based fallbacks for CSS scroll timeline. For a single element with no orchestration, raw WAAPI (Tier 3) is sufficient.

## Tier 5: Spring Physics (Motion)

For drag interactions, gesture-driven animation, and elements that need to feel physically alive. Springs don't have fixed durations — they settle based on physical parameters, making them ideal for interruptible gestures.

```tsx
import { motion, useSpring } from "motion";

// Spring-based drag
<motion.div
  drag="y"
  dragConstraints={{ top: 0, bottom: 300 }}
  animate={{ transform: "translateY(0px)" }}
/>;

// Mouse-tracking with spring interpolation
const springX = useSpring(mouseX, { stiffness: 100, damping: 10 });
```

**Critical caveat:** Motion's shorthand properties (`x`, `y`, `scale`) use `requestAnimationFrame` on the main thread and are NOT hardware-accelerated. Under load (page transitions, heavy rendering), they drop frames. Use the full `transform` string for hardware acceleration:

```tsx
// Drops frames under load
<motion.div animate={{ x: 100 }} />

// Hardware accelerated
<motion.div animate={{ transform: "translateX(100px)" }} />
```

Use springs for drag-to-dismiss, momentum-based interactions, and decorative mouse-tracking. For predetermined UI animations (enter/exit, hover, state change), springs add unnecessary complexity — use CSS transitions or WAAPI.

## Scroll Fallback Pattern

For browsers without `animation-timeline` support. Use Motion.dev's `inView()` (or raw `IntersectionObserver`) to detect viewport entry, then trigger WAAPI animations.

The fallback initializer checks for native support first and only activates if absent:

```typescript
function initScrollFallback() {
  if (CSS.supports?.("animation-timeline: view()")) return;
  // ... IntersectionObserver or inView() based fallback
}
```

This ensures browsers with native support never load the fallback code path.
