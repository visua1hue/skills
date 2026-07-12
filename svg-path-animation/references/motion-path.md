# Motion Path — Reference

## The CSS `offset-path` family

Four properties work together — `offset-path` alone does nothing visible:

- **`offset-path`** — defines the track (static). Accepts `path()`, `ray()`, `url()` (an SVG element's own path), a `<basic-shape>`, or `none`.
- **`offset-distance`** — animates position along that track, `0%` to `100%`.
- **`offset-rotate`** — controls orientation: `auto` follows the path's tangent (the element turns to face its direction of travel, like a car following a winding road), `reverse` flips that, or a fixed angle keeps the element axis-aligned throughout.
- **`offset-anchor`** / **`offset-position`** — control which point of the element sits on the path, and the path's own starting reference point.

```css
.element {
  offset-path: path("M10 80 C 40 10, 65 10, 95 80 S 150 150, 180 80");
  offset-rotate: auto;
  animation: travel 3s linear infinite;
}
@keyframes travel {
  from { offset-distance: 0%; }
  to   { offset-distance: 100%; }
}
```

**Browser support caveat**: `path()` and `none` are the most reliably supported values. `url()` (referencing an SVG path element) and `<basic-shape>` support is less consistent — feature-detect or fall back to a JS library (GSAP's `MotionPathPlugin`) if targeting older/inconsistent browsers.

## SMIL `animateMotion`

The native SVG-markup equivalent, works without any CSS or JS:

```xml
<circle r="5" fill="red">
  <animateMotion dur="3s" repeatCount="indefinite" rotate="auto">
    <mpath href="#track" />
  </animateMotion>
</circle>
<path id="track" d="M10 80 C 40 10, 65 10, 95 80 S 150 150, 180 80" fill="none" />
```

`rotate="auto"` is SMIL's direct counterpart to CSS's `offset-rotate: auto` — same tangent-following behavior. Referencing a separate `<path>` via `<mpath href="#track">` keeps the track reusable/visible independently of the animated element, unlike inlining the path data directly into `animateMotion`'s `path` attribute.

## Don't combine `offset-path` and SMIL `animateMotion` on the same element

No spec, browser docs, or test result confirms defined interaction precedence when both are applied to one element simultaneously. Treat this as untested/unsafe territory — pick one mechanism per element rather than assuming they'll compose predictably.
