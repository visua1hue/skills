# Native Transitions — Reference

Full patterns for exit animations, spring easing, and page transitions using what the platform now handles natively — no JavaScript orchestration required.

## `allow-discrete` + `@starting-style`

### The problem this solves

Discrete properties (`display`, `content-visibility`, `overlay`) don't interpolate — the browser can't animate "50% between `none` and `flex`," so by default they just flip instantly at the midpoint of any transition. That's why exit animations traditionally need JavaScript: set `opacity: 0`, wait for the transition to finish (`transitionend`), *then* set `display: none`. Get the timing wrong and you either see a flash of the element with `display: none` fighting the fade, or the element stays in layout (and in the accessibility tree, and tab order) after it's visually gone.

`transition-behavior: allow-discrete` fixes this at the CSS level: the discrete property still flips instantly, but the browser delays the flip until the *end* of the transition when going from visible to hidden, and flips it immediately (before the transition starts) when going from hidden to visible. Paired with `@starting-style`, you get both directions — entry and exit — with no JS timing code.

### Full pattern

```css
.panel {
  /* hidden state */
  display: none;
  opacity: 0;
  transition: opacity 0.2s ease, display 0.2s allow-discrete;
}

.panel.is-open {
  display: flex;
  opacity: 1;
}

/* entry: tells the browser what "opacity" was before this state existed */
@starting-style {
  .panel.is-open {
    opacity: 0;
  }
}
```

Sequence on open (`.is-open` added): `display` flips to `flex` immediately (so opacity has something to transition on), `@starting-style` supplies the "from" value, opacity transitions 0→1 normally.

Sequence on close (`.is-open` removed): opacity transitions 1→0 normally, `display` only flips to `none` once that transition completes — allow-discrete delays it, so the element stays visible (and in layout) for the full fade-out instead of vanishing at frame one.

### Gating by media query

The pattern combines cleanly with a breakpoint gate — e.g. a panel that's always visible below a breakpoint and only transitions in/out above it:

```css
.panel {
  opacity: 0;
  transition: opacity 0.2s, display 0.2s allow-discrete;
}

@media (min-width: 1280px) {
  .panel {
    display: flex;
    opacity: 1;
  }

  @starting-style {
    .panel { opacity: 0; }
  }
}
```

### Gotchas

- `@starting-style` only has an effect on the *first* style update after an element goes from not-rendered to rendered (or `display: none` to displayed). It does nothing on subsequent updates — that's correct, it's an entry-only hook.
- The `@starting-style` block needs to target the state the element is transitioning *into*, with the starting values — not the base/hidden selector.
- Works with `content-visibility: hidden` the same way as `display: none`, useful when you want the element to stay measurable (`content-visibility` keeps layout box, `display: none` doesn't).
- Baseline Newly Available since Firefox 129 (mid-2024) — Chromium 117+, Safari 17.5+, Firefox 129+ all support it, safe to use as a primary code path rather than an escape hatch. Where a fallback still matters (very old browser floors), a no-JS fallback is just "the element pops instead of fading," which is an acceptable degradation, not a broken experience.

## The `linear()` Easing Function

### What it's for

Spring physics (mass/stiffness/damping) doesn't map onto a `cubic-bezier()` curve — bezier curves are monotonic between two points and can't produce the overshoot-and-settle motion a real spring has. Historically, getting spring-like motion in pure CSS meant multiple `@keyframes` steps approximating the curve by hand. `linear()` does this properly: it's a piecewise-linear easing function defined by an arbitrary list of output values (optionally with position percentages), so a spring's simulated position-over-time curve can be sampled at N points and shipped directly as a CSS value.

### Syntax

```css
linear(<value> <percentage>?, ...)
```

Each entry is an output value (0 = start, 1 = end, values outside that range are allowed and represent overshoot); the optional percentage pins that value to a specific point along the duration. Omitted percentages are spaced evenly between their neighbors.

```css
--ease-spring: linear(
  0, 0.009, 0.035 2.1%, 0.141, 0.281 6.7%, 0.723 12.9%, 0.938 16.7%,
  1.026, 1.089 22.3%, 1.102, 1.099 24.4%, 1.09 25.9%, 1.035 31.3%,
  1.007 36.2%, 0.999 40.5%, 0.995 44.1%, 0.998 52.8%, 1
);
```

Values that exceed `1` (like `1.102` above) are the overshoot — the curve bounces past its target before settling, which is what makes it read as a spring rather than an eased approach.

### Generating one

Don't hand-write control points. Generate them from an actual spring simulation:
- Motion.dev/Framer Motion can export a spring config's sampled curve.
- [linear-easing-generator](https://linear-easing-generator.netlify.app/) (or equivalent tools) takes a spring config (mass/stiffness/damping, or duration/bounce) and outputs a ready-to-paste `linear()` value.
- Sample density matters: too few points and the curve looks faceted/linear-segmented rather than smooth; too many and the CSS value gets unwieldy. 15-25 points is typically enough for a UI-scale spring.

### When to use it vs. a JS spring

Use `linear()` when the spring only needs to run once, on a state change, with no interruption mid-animation (e.g. a toast entrance, a button's settle-after-press). Use an actual JS spring (Motion.dev's `useSpring`, etc.) when the animation needs to be interruptible mid-flight with velocity preserved — a `linear()` curve is a fixed, precomputed timeline; it doesn't know about the current velocity if something interrupts it partway through, the same limitation as `@keyframes`.

## Page Transitions

Same-document (SPA-style):

```js
document.startViewTransition(() => {
  // DOM update that should be visually transitioned
  updateContent();
});
```

The browser snapshots the before/after state and exposes them as pseudo-elements to animate:

```css
::view-transition-old(root) {
  animation: fade-out 0.2s ease both;
}
::view-transition-new(root) {
  animation: fade-in 0.2s ease both;
}
```

Cross-document (full MPA navigation, no client-side router needed):

```css
@view-transition {
  navigation: auto;
}
```

Opting a same-origin navigation into a browser-managed cross-document transition — same pseudo-element model as the same-document version.

**Browser support**: same-document transitions ship in Chromium 111+, Safari 18+, and Firefox 144+ — safe as a primary code path. Cross-document is narrower: Chromium 126+ and Safari 18.2+ support it, but Firefox doesn't yet (in development, not shipped). Cross-document transitions are a progressive enhancement by design — an unsupported browser just does a normal navigation with no visual transition, not a broken one, so ship it unconditionally rather than feature-detecting around it.
