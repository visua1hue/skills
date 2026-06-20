# Paint & Load Strategy — Reference

Detailed guidance for FCP-safe animation initialization. Read this when building or debugging the load animation orchestration system.

## Initial State

Set animated elements to `opacity: 0.01` in CSS. Lighthouse ignores `opacity: 0` for FCP calculations — setting `0.01` ensures the element registers as painted content without being visible to the user.

```css
[data-motion] {
  will-change: transform, opacity, filter;
  opacity: 0.01;
}
```

This state is defined in CSS, not JavaScript, so it applies immediately during parse without waiting for script execution. Elements are "painted but invisible" from the browser's perspective.

## Orchestration Sequence

The TypeScript controller waits for two conditions before triggering load animations:

1. **Asset lock** — `document.fonts.ready` resolves, ensuring web fonts are loaded. This prevents font-swap glitches during animation (FOUT artifacts mid-transition).
2. **Paint lock** — First Contentful Paint has occurred. Check `performance.getEntriesByType('paint')` for an existing FCP entry. If none exists, observe via `PerformanceObserver`. Fallback to `requestAnimationFrame` if `PerformancePaintTiming` is not supported.

Only after both locks clear does the controller query `[data-motion]` elements and run their animation presets.

## Declarative API

Animations are applied via data attributes. The controller detects and initializes all registered elements automatically.

- `data-motion="preset-name"` — load animation, triggered after FCP
- `data-motion-scroll="preset-name"` — scroll animation (CSS-native with WAAPI fallback)
- `data-motion-delay="0.2"` — timing override in seconds, applied as animation delay

This declarative approach keeps animation intent in the markup, supports SSR and static rendering, and allows the CSS layer to define the initial state independently of JavaScript execution.

## Preset Architecture

Animation presets are defined in a centralized TypeScript registry. Each preset is a function that receives the target element and returns keyframes and options. The element reference allows presets to read motion tokens from CSS custom properties at runtime.

```typescript
const PRESETS = {
  "fade-up": (el: HTMLElement) => ({
    keyframes: {
      opacity: [0.01, 1],
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

Every value the preset uses — duration, distance, easing — is read from CSS custom properties first, with sensible defaults as fallback. This ensures the design system (whether in `DESIGN.md`, `motion.css`, or `variables.css`) remains the single source of truth.
