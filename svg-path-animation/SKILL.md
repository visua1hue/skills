---
name: svg-path-animation
description: SVG's own coordinate-system and path-data animation territory — line-drawing reveals via stroke-dasharray/dashoffset, path morphing (equal-command-count constraint and its workarounds), motion-along-a-path via the CSS offset-path family and SMIL animateMotion, transform-origin/transform-box coordinate quirks, runtime viewBox pan/zoom, and the SVG-vs-Canvas/WebGL decision. Deliberately excludes non-SVG UI animation taste (motion-sense) and compositor/perf execution mechanics (motion-engine). Use when animating SVG paths or shapes, building icon micro-interactions, line-drawing reveals, motion-along-a-path, or deciding between SVG/Canvas/WebGL for a visual.
---

# SVG Path Animation

The coordinate-system and path-data layer of SVG animation — territory `motion-sense` (HTML/CSS UI-taste) and `motion-engine` (compositor/perf mechanics) don't cover. Pairs with both: use `motion-sense` for the *why/when* of animating a UI element and `motion-engine` for spring-physics/WAAPI execution once something's moving; this skill owns SVG's native primitives (path data, `viewBox`, SMIL) and coordinate-system gotchas.

## Decision Framework

### SMIL vs CSS vs JS library

| Need | Use |
| --- | --- |
| Motion-along-a-path with automatic tangent-following orientation, no JS | SMIL `animateMotion` + `mpath`, or CSS `offset-path` + `offset-rotate: auto` |
| Transform/opacity animation that should integrate with existing CSS transitions, hover states, media queries | CSS (`@keyframes` or `transition`) |
| Path morph between shapes with an unequal number of points/commands | JS library (flubber) — CSS/SMIL `d` interpolation requires matching command counts |
| Complex sequencing, scroll-linked choreography, timeline scrubbing | JS library (GSAP or similar) |
| Simple declarative shape/attribute animation with no build step | SMIL (`animate`, `set`) — still valid, works without JS, but has no place in a build pipeline that needs code review/diffing the way CSS does |

### SVG vs Canvas/WebGL

| Factor | Favors SVG | Favors Canvas/WebGL |
| --- | --- | --- |
| Element count | Small-to-medium (icons, logos, UI graphics) | Hundreds/thousands (particles, dense data viz) |
| Interactivity & accessibility | Native DOM events, ARIA, per-element CSS | Manual hit-testing, no native accessibility |
| Animation type | Path morph, line-draw, motion-along-path, transform | Per-pixel effects, physics, shaders |
| Performance ceiling | DOM overhead limits scale | GPU-bound, scales to thousands of objects |
| Tooling | CSS/SMIL/JS all work directly on markup | Imperative draw loop (`requestAnimationFrame`) |

SVG's actual superpower is being DOM-structural, not pixel-based — every path is an addressable, styleable, accessible element. Reach for Canvas/WebGL only once element count or per-pixel effects genuinely demand it, not by default.

## Technique Library

- **Line-drawing** — `stroke-dasharray`/`stroke-dashoffset` reveals, driven by `getTotalLength()` so dash values are computed, not hand-measured. Path morphing constraints and the flubber fallback for unequal point counts. Full patterns: `references/path-drawing-and-morphing.md`.
- **Motion path** — the CSS `offset-path`/`offset-distance`/`offset-rotate`/`offset-anchor` family, and its SMIL `animateMotion` counterpart. Full patterns: `references/motion-path.md`.
- **Coordinate system & transforms** — `transform-origin`/`transform-box` on SVG shapes, why `viewBox` can't be CSS-animated, and the div-wrapping compositing gotcha. Full patterns: `references/coordinate-and-transforms.md`.

## Accessibility: reduced motion for SMIL

CSS-driven SVG animation already respects `prefers-reduced-motion` the same way any CSS animation does — see `motion-engine`'s Accessibility section for the general policy. SMIL (`<animate>`, `<animateMotion>`, `<animateTransform>`) is attribute-driven, not CSS, so the media query doesn't touch it — it needs explicit JS handling:

```js
const svg = document.querySelector('svg');
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
if (reduceMotion.matches) svg.pauseAnimations();
reduceMotion.addEventListener('change', (e) => {
  e.matches ? svg.pauseAnimations() : svg.unpauseAnimations();
});
```

`pauseAnimations()`/`unpauseAnimations()` are methods on the SVG root element (`SVGSVGElement`) — they pause/resume every SMIL animation in that document at once, not per-element.

## Review Format (Required)

When reviewing SVG animation code, use a markdown table with Before/After/Why columns — one row per issue found:

| Before | After | Why |
| --- | --- | --- |
| Hardcoded `stroke-dashoffset: 847` | `offset = path.getTotalLength()`, set via JS/custom property | Exact value, survives any path edit without re-measuring |
| `<g>` rotating around the SVG viewport origin instead of its own center | `transform-box: fill-box; transform-origin: center` | SVG shapes default to viewport-relative origin, not own-bounding-box |

## Review Checklist

| Issue | Fix |
| --- | --- |
| Hardcoded `stroke-dasharray`/`stroke-dashoffset` numbers | Compute from `element.getTotalLength()` instead |
| Path morph (`d` interpolation) between paths with different command counts | Normalize command counts, or use flubber for arbitrary shapes |
| `transform`/rotation animated directly on the `<svg>` root with no wrapper | Wrap in a `<div>` and animate that — forces a compositor layer many browsers won't grant an inline `<svg>` |
| Unset `transform-box` on an animated SVG shape | `transform-box: fill-box` — SVG children default to viewport-relative origin (`view-box`), not their own bounding box; this is a default-value issue, not a browser-support gap (universal since ~2018) |
| `viewBox` animated via CSS `@keyframes`/`transition` | Won't work — `viewBox` is a presentation attribute, not a CSS property. Use a `requestAnimationFrame` loop, a JS animation library's attribute plugin, or SMIL `<animate attributeName="viewBox">` |
| Motion-along-a-path with no orientation set | Add `offset-rotate: auto` (CSS) or a `rotate` attribute (SMIL) so the element tracks the path's tangent instead of staying axis-aligned |
| `offset-path` and SMIL `animateMotion` both applied to the same element | Don't combine — interaction precedence between the two is undocumented/untested, treat as unsafe until verified |
| SMIL animation with no reduced-motion handling | Check `matchMedia('(prefers-reduced-motion: reduce)')` and call `pauseAnimations()`/`unpauseAnimations()` — the CSS media query alone doesn't stop SMIL |
| Nested `<g>` transforms fighting each other (parent and child both transforming) | Isolate: apply the element's own transform inside an inner `<g>`, keep the outer `<g>` for layout/positioning only |

## External References

- [MDN: `offset-path`](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/offset-path)
- [W3C Motion Path Module Level 1](https://www.w3.org/TR/motion-1/)
- [MDN: SVG animation with SMIL](https://developer.mozilla.org/en-US/docs/Web/SVG/Guides/SVG_animation_with_SMIL)
- [CSS-Tricks Almanac: `offset-path`](https://css-tricks.com/almanac/properties/o/offset-path/)
- [svg.guide](https://svg.guide/) — Nanda, interactive SVG animation course
