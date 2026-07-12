# Coordinate System & Transforms — Reference

## `transform-origin` / `transform-box` on SVG shapes

SVG elements don't respect `transform-origin` the way HTML elements do by default. Unset `transform-box` on an SVG shape anchors `transform-origin` to the `view-box` — the SVG viewport's coordinate system — not the element's own bounding box. A `<g>` or `<path>` rotating or scaling around an unexpected pivot point is almost always this default.

```css
.icon-part {
  transform-box: fill-box;   /* switch the reference box to the element's own bounding box */
  transform-origin: center;  /* now "center" means the shape's own center, not the viewport's */
}
```

### `transform-box` values

| Value | Reference box |
| --- | --- |
| `border-box` | The element's border box — default for HTML elements |
| `fill-box` | The element's own bounding box (its geometry, ignoring stroke) — what SVG authors almost always want |
| `view-box` | The nearest SVG viewport's `viewBox` coordinate system — the default for SVG child elements, and the actual source of "wrong pivot point" bugs |
| `content-box` | The element's content box, ignoring padding/border |
| `stroke-box` | The element's bounding box including stroke width |

**Browser support (2026)**: `transform-box` itself is universally supported across current evergreen browsers (Chrome/Edge since v64/79, Firefox since v55, Safari since v11) — this is not a compatibility gap. The "Safari doesn't support `fill-box`" caveat repeated in older blog posts and some packaged skills is outdated advice; all five values track the same baseline. The actual bug is a **default-value** issue (browsers default SVG children to `view-box`), not a support issue — `fill-box` is still the right fix, just not because of a browser gap.

## Nested `<g>` transform conflicts

When both a parent `<g>` and its child element carry their own `transform`, they compose — which is often not what's intended when the parent `<g>` exists purely for layout/grouping. Isolate the animated transform in its own inner wrapper so layout and animation don't fight:

```xml
<g class="icon-position">          <!-- layout only, no animation -->
  <g class="icon-animated-part">   <!-- transform-box: fill-box; animated independently -->
    <path d="..." />
  </g>
</g>
```

## `viewBox` can't be CSS-animated

`viewBox` is a presentation **attribute** (`"<minX> <minY> <width> <height>"`), not a CSS property — `@keyframes`/`transition` silently do nothing to it. This is the most common surprise for anyone approaching SVG pan/zoom from a CSS-first workflow.

Three working approaches, no single "pure CSS" option exists:

1. **JS `requestAnimationFrame` loop** — manually interpolate all four numbers per frame and write them to the `viewBox` attribute.
2. **JS animation library's attribute plugin** — e.g. GSAP's `attr` option: `gsap.to(svgEl, { attr: { viewBox: "x y w h" }, ease: "power2.out" })`.
3. **SMIL** — `<animate attributeName="viewBox" from="..." to="..." dur="1s" />` is the only pure-markup way to animate it, no JS required.

For interactive (drag/scroll-driven) pan-zoom rather than a fixed animation, a small dedicated library (e.g. `svg.panzoom.js`) is usually less code than hand-rolling hit-testing and inertia.

## Compositing: wrap `<svg>` before animating with `transform`

Many browsers don't grant a hardware-accelerated compositor layer to `transform` applied directly to an inline `<svg>` element. Wrap it in a `<div>` and animate the wrapper instead:

```html
<div class="svg-wrapper"><svg>...</svg></div>
```

```css
.svg-wrapper { transition: transform 200ms ease-out; will-change: transform; }
.svg-wrapper:hover { transform: scale(1.05); }
```

This is a narrow, specific fact worth applying by default for any SVG element that's frequently transformed (hover scale on an icon, drag-follow), not just when a performance problem is already observed.
