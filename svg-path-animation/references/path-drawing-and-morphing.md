# Line-Drawing & Path Morphing — Reference

## Line-drawing via `stroke-dasharray`/`stroke-dashoffset`

Set `stroke-dasharray` to the path's total length (one dash covering the whole path) and `stroke-dashoffset` to the same value (pushing the dash fully off-path, so nothing is visible). Animate `stroke-dashoffset` to `0` to "draw" the path.

Compute the length from the path itself rather than hand-measuring or guessing:

```js
const path = document.querySelector('.draw-path');
const length = path.getTotalLength();
path.style.strokeDasharray = length;
path.style.strokeDashoffset = length;
```

```css
.draw-path {
  transition: stroke-dashoffset 800ms ease-out;
}
.draw-path.revealed {
  stroke-dashoffset: 0;
}
```

`getTotalLength()` keeps the value exact and self-correcting — any edit to the path data (a redrawn icon, a resized logo) recomputes automatically instead of leaving a stale hardcoded number that under- or over-draws.

Use `stroke-linecap: round` on dash-drawn strokes; a `butt` cap on a partially-revealed dash reads as a flat cut-off rather than a pen actively drawing.

**Scroll-triggered line-draws**: toggle a `.revealed` class via `IntersectionObserver` (`{ once: true, margin: "-100px" }`, same pattern as `motion-sense`'s scroll image-reveals) rather than a scroll-linked library — a line-draw is a one-shot reveal, not something that should track scroll position continuously. Reach for GSAP `ScrollTrigger` only if the draw genuinely needs to scrub with scroll position instead of firing once.

### Recipes

- **Checkmark draw-on**: two-segment path (short stroke + long stroke), stagger the second segment's `transition-delay` so it starts as the first finishes — reads as one continuous pen stroke, not two shapes appearing.
- **Spinner**: animate `stroke-dashoffset` on a circle path in a `linear` infinite loop; pair with a slow `rotate` on the parent so the dash gap itself appears to travel.
- **Hamburger-to-X**: don't morph the whole icon as one path — three independent lines (paths), each with its own `transform` (translate/rotate) to converge into an X. Cleaner and more controllable than `d`-interpolation for this shape.

## Path morphing (`d` interpolation)

Both CSS (animating the `d` property directly) and SMIL (`<animate attributeName="d">`) require the start and end paths to have the **same number of path commands, in the same order, with compatible command types** (e.g., both paths must use `C` at the same index, not one `C` and one `Q`). Mismatched command counts produce broken or glitchy interpolation, not an error — this is the most common cause of "morph looks wrong" bugs.

```css
.shape {
  d: path("M10 10 C 20 20, 40 20, 50 10");
  transition: d 400ms ease-in-out;
}
.shape.morphed {
  d: path("M10 10 C 15 30, 45 30, 50 10"); /* same command structure, different points */
}
```

### Arbitrary shapes (unequal point counts)

No pure-CSS/SMIL technique reliably solves morphing between paths with genuinely different command counts. Two options, in order of effort:

1. **Manual normalization** — resample both paths to the same number of cubic-bezier segments (SVG editors or tools like paper.js/`svg-path-properties` can do this), then interpolate as above. No dependency, more manual work.
2. **flubber** — a JS library built specifically for arbitrary-shape interpolation; doesn't require matching point counts. Reach for this once manual normalization becomes impractical (frequently-changing shapes, many shape pairs, designer-supplied paths you don't want to hand-edit).

Don't present a "pure CSS" solution to this as if it exists for arbitrary shapes — it doesn't. Either normalize by hand or take the library dependency.

## Animation principles applied to SVG

Traditional animation vocabulary (squash & stretch, secondary motion, overlapping action) is useful shorthand for making generated SVG motion feel less mechanical:

- **Secondary motion** — a checkmark's tail overshooting slightly past its final point before settling reads as more alive than a linear stop.
- **Overlapping action** — in a multi-path icon (e.g., three lines converging to an X), don't animate all paths on identical timing; offset each by 20-40ms so they don't move as one rigid unit.
