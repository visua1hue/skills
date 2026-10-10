# Paint & Load Strategy. Reference

Detailed guidance for FCP-safe animation initialization. Read this when building or debugging the load animation orchestration system.

## Initial State

The hidden state lives in the `from` keyframe, never in a base rule. A base rule such as `[data-motion] { opacity: 0 }` leaves content invisible whenever the animation or script that reveals it does not run.

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

`animation-fill-mode: both` holds the `from` state through any delay. With no `to` keyframe, the animation ends at the element's own styles. Under reduced motion the rule does not apply, so the element is in its final state from the start.

## LCP element

Chrome ignores paints at `opacity: 0` when it picks the LCP candidate. An element that fades in becomes a candidate only when a later paint shows it, so its LCP time is the fade, not the load. Leave the largest above-the-fold element (hero image, headline) out of the preset system.

## Orchestration Sequence

JavaScript presets are for sequences CSS can't express: values computed at runtime, chained steps. Use them for content that is not visible at first paint. The TypeScript controller waits for two conditions before it runs them:

1. **Asset lock.** `document.fonts.ready` resolves, ensuring web fonts are loaded. This prevents font-swap glitches during animation (FOUT artifacts mid-transition).
2. **Paint lock.** First Contentful Paint has occurred. Check `performance.getEntriesByType('paint')` for an existing FCP entry. If none exists, observe via `PerformanceObserver`. Fallback to `requestAnimationFrame` if `PerformancePaintTiming` is not supported.

Only after both locks clear does the controller query its elements and run their presets through WAAPI. A WAAPI `transform`/`opacity` animation gets a compositor layer without `will-change`.

## Declarative API

Animations are applied via data attributes. The controller detects and initializes all registered elements automatically.

- `data-motion="preset-name"`. Load animation. A CSS keyframe by default, a JavaScript preset where one is registered
- `data-motion-scroll="preset-name"`. Scroll animation (CSS-native with WAAPI fallback)
- `data-motion-delay="0.2"`. Timing override in seconds for JavaScript presets, applied as animation delay

This declarative approach keeps animation intent in the markup, supports SSR and static rendering, and allows the CSS layer to define the initial state independently of JavaScript execution.

## Preset Architecture

Animation presets are defined in a centralized TypeScript registry. Each preset is a function that receives the target element and returns keyframes and options. The element reference allows presets to read motion tokens from CSS custom properties at runtime.

```typescript
const PRESETS = {
  "fade-up": (el: HTMLElement) => ({
    keyframes: {
      opacity: [0, 1],
      transform: [
        `translateY(${getCSSVar(el, "--motion-dist-md") || "30px"})`,
        "translateY(0)",
      ],
    },
    options: {
      duration: parseDuration(getCSSVar(el, "--motion-dur-base")) || 0.18,
      easing: [0.25, 0.1, 0.25, 1],
    },
  }),
};
```

The preset reads duration, distance, and easing from CSS custom properties first, with sensible defaults as fallback. This ensures the design system (whether in `DESIGN.md`, `motion.css`, or `variables.css`) remains the single source of truth.
