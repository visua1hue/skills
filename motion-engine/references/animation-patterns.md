# Execution Tiers. Reference

Detailed guidance for each animation execution tier. Read this when implementing animations and you need the full code patterns and caveats.

## Tier 1: CSS Transitions

For predetermined, non-interactive state changes. Hover effects, color transitions, simple toggles. CSS transitions are interruptible by default. Triggering a new state mid-transition retargets smoothly rather than restarting from zero.

```css
.button {
  transition: transform var(--motion-dur-fast) var(--motion-ease-out);
}
.button:active {
  transform: scale(var(--motion-scale-sm));
}
```

Use when the animation is a direct response to a state change (hover, focus, active, class toggle). Avoid `transition: all`. Always specify exact properties.

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
/* Scroll progress bar. Fills as user scrolls the page */
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

Read scroll ranges from motion tokens. Define keyframes that are shared between the CSS and WAAPI paths. Write them once as `@keyframes`, reference the same values in JS presets for the fallback.

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

For orchestration, sequencing, stagger, and scroll fallbacks. Motion.dev is a thin wrapper over WAAPI. It adds a better API for coordinating multiple elements without sacrificing compositor performance.

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

### View Transitions with `animateView()`

Motion.dev's wrapper over the browser View Transitions API. It uses the same underlying primitive as the native `document.startViewTransition()` pattern (`motion-sense/references/native-transitions.md`), but it removes the manual bookkeeping that makes the raw API painful to ship: naming every layer by hand, writing `::view-transition-*` pseudo-element CSS, transitions snapping when interrupted, morph targets distorting on aspect-ratio mismatch, and no built-in stagger.

**Not compositor `transform` animation.** This is the one exception to the Performance Contract above. View transitions snapshot the old/new DOM state and crossfade between images; only one view transition can run at a time. Motion's separate "layout animations" feature is the transform-based, fully interruptible, many-at-once alternative. Reach for that for responsive in-page UI, and for `animateView` specifically for page transitions or where filesize is constrained (it ships smaller than a full layout-animation setup).

```typescript
import { animateView, spring, stagger } from "motion";

// Basic. Auto-generates and cleans up view-transition-name
animateView(() => updateDOM()).add(".card");

// Spring-based instead of a fixed duration
animateView(updateDOM, { type: spring, bounce: 0.3 });

// Differentiated enter/exit, not just an old/new crossfade
animateView(updateDOM)
  .add(".panel")
  .enter({ opacity: 1, transform: ["translateY(50px)", "none"] })
  .exit({ opacity: 0 });

// Staggered shared-element transition across a list
animateView(updateDOM)
  .add(".item")
  .enter({ opacity: [0, 1], scale: [0.6, 1] }, { delay: stagger(0.05) });
```

What it solves, concretely:

- **Naming**: assigns/removes `view-transition-name` automatically instead of manual per-element bookkeeping. Native names are globally unique, so a hand-named element joins *every* view transition on the page whether you want it to or not; `animateView` scopes names to the transition and removes them after.
- **Pseudo-elements**: targets are Motion transition objects (springs, custom easing) instead of hand-written `::view-transition-old/new` keyframe CSS. Because pseudo-elements aren't reachable from JS, only CSS-animatable values work. For something like `mask-image`, register it first with `CSS.registerProperty()`.
- **Interruption**: queues an incoming transition until the current one finishes rather than snapping to its end position; opt into `{ interrupt: "immediate" }` to override.
- **Aspect ratio**: auto-crops morphing layers (`object-fit: cover` semantics) so a shared element that changes proportions doesn't stretch; `.crop(false)` disables it. Needed when the shared layer is text, where cropping clips content rather than helping it.
- **Grouping**: nests transition layers to match DOM structure (`view-transition-group: contain`) by default, so a child doesn't break free of an ancestor's clip mid-transition (Safari support for this is still rolling out); `.group(false)` lifts an element free on purpose, e.g. a card's icon that should fly across the whole screen rather than stay clipped to the card.
- **Stagger**: `.add()` accepts a selector matching multiple elements. One call handles the group, `stagger()` staggers them. The selector re-runs after the update function, so elements added by that same DOM update are picked up too.

Defining `.exit()` also sets the `.enter()` animation's initial keyframe from it, when `.enter()` doesn't specify one.

`.class("name")` tags a layer with `view-transition-class` for custom `::view-transition-group(.name)` CSS targeting.

**Tip. Group by direction, not just by "shared element"**: only animate elements moving *the same way* as part of one shared transition. An element that's present in both states but moves differently (e.g. a persistent control that shifts left while the rest of the layout moves up-right) reads better as its own fade-in/fade-out layer than forced into the shared-element group.

Degrades gracefully: on a browser without View Transition API support, the DOM update still runs, just without the animation.

**Browser support**: needs the View Transition API at all (Chromium, Safari 18+). Group-nesting and crop specifically need Chromium 140+. On older Chromium/Safari the transition still runs, just without that refinement. Doesn't yet cancel in-flight scroll-position animations.

Reach for this over raw `document.startViewTransition()` when the transition needs springs, differentiated enter/exit, shared-element morphing, or stagger. A simple crossfade doesn't need it. The raw API (Tier 2/`native-transitions.md`) is enough and avoids the added dependency.

## Tier 5: Spring Physics (Motion)

For drag interactions, gesture-driven animation, and elements that need to feel physically alive. Springs don't have fixed durations. They settle based on physical parameters, making them ideal for interruptible gestures.

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

Use springs for drag-to-dismiss, momentum-based interactions, and decorative mouse-tracking. For predetermined UI animations (enter/exit, hover, state change), springs add unnecessary complexity. Use CSS transitions or WAAPI.

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
