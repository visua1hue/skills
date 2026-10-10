# Native Transitions Reference

Full patterns for exit animations, spring easing, and view transitions using what the platform now handles natively.

## `allow-discrete` + `@starting-style`

### The problem this solves

Discrete properties (`display`, `content-visibility`, `overlay`) don't interpolate. The browser can't animate "50% between `none` and `flex`," so by default they just flip instantly at the midpoint of any transition. That's why exit animations traditionally need JavaScript: set `opacity: 0`, wait for the transition to finish (`transitionend`), *then* set `display: none`. Get the timing wrong and you either see a flash of the element with `display: none` fighting the fade, or the element stays in layout (and in the accessibility tree, and tab order) after it's visually gone.

`transition-behavior: allow-discrete` fixes this at the CSS level: the discrete property still flips instantly, but the browser delays the flip until the *end* of the transition when going from visible to hidden, and flips it immediately (before the transition starts) when going from hidden to visible. Paired with `@starting-style`, you get both directions, entry and exit, with no JS timing code.

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

Sequence on close (`.is-open` removed): opacity transitions 1→0 normally, `display` only flips to `none` once that transition completes, because `allow-discrete` delays it, so the element stays visible (and in layout) for the full fade-out instead of vanishing at frame one.

### Gating by media query

The pattern combines cleanly with a breakpoint gate, e.g. a panel that's always visible below a breakpoint and only transitions in/out above it:

```css
.panel {
  opacity: 0;
  transition: opacity 0.2s, display 0.2s allow-discrete;
}

@media (width >= 1280px) {
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

- `@starting-style` only has an effect on the *first* style update after an element goes from not-rendered to rendered (or `display: none` to displayed). It does nothing on subsequent updates. That's correct, it's an entry-only hook.
- The `@starting-style` block needs to target the state the element is transitioning *into*, with the starting values, not the base/hidden selector.
- Works with `content-visibility: hidden` the same way as `display: none`, useful when you want the element to stay measurable (`content-visibility` keeps layout box, `display: none` doesn't).
- Baseline Newly Available since Firefox 129 (mid-2024). Chromium 117+, Safari 17.5+, Firefox 129+ all support it, safe to use as a primary code path rather than an escape hatch. Where a fallback still matters (very old browser floors), a no-JS fallback is just "the element pops instead of fading," which is an acceptable degradation, not a broken experience.

## The `linear()` Easing Function

### What it's for

Spring physics (mass/stiffness/damping) doesn't map onto a `cubic-bezier()` curve. Bezier curves are monotonic between two points and can't produce the overshoot-and-settle motion a real spring has. Historically, getting spring-like motion in pure CSS meant multiple `@keyframes` steps approximating the curve by hand. `linear()` does this properly: it's a piecewise-linear easing function defined by an arbitrary list of output values (optionally with position percentages), so a spring's simulated position-over-time curve can be sampled at N points and shipped directly as a CSS value.

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

Values that exceed `1` (like `1.102` above) are the overshoot. The curve bounces past its target before settling, which is what makes it read as a spring rather than an eased approach.

### Generating one

Don't hand-write control points. Generate them from an actual spring simulation:
- Motion.dev/Framer Motion can export a spring config's sampled curve.
- [linear-easing-generator](https://linear-easing-generator.netlify.app/) (or equivalent tools) takes a spring config (mass/stiffness/damping, or duration/bounce) and outputs a ready-to-paste `linear()` value.
- Sample density matters: too few points and the curve looks faceted/linear-segmented rather than smooth; too many and the CSS value gets unwieldy. 15-25 points is typically enough for a UI-scale spring.

### When to use it vs. a JS spring

Use `linear()` when the spring only needs to run once, on a state change, with no interruption mid-animation (e.g. a toast entrance, a button's settle-after-press). Use an actual JS spring (Motion.dev's `useSpring`, etc.) when the animation needs to be interruptible mid-flight with velocity preserved. A `linear()` curve is a fixed, precomputed timeline; it doesn't know about the current velocity if something interrupts it partway through, the same limitation as `@keyframes`.

## View transitions

The browser snapshots the old and new state and animates between them through `::view-transition-*` pseudo-elements, in the top layer. Snapshots are images, not live DOM. Cost and interruption limits: `motion-engine`.

### When to use one

A view transition cannot be interrupted. A second one skips the first, and the snapshots block clicks while it runs. So:

- **Use for navigation-level changes.** A route change, list to detail, a list that reorders or filters.
- **Not for interaction-heavy UI.** Anything hovered, dragged or toggled rapidly needs transitions or springs that retarget.
- **Name what the change says.** A shared element says "same thing, going deeper". Reordered items say "same items, new arrangement". A page crossfade says "a new place". If it says nothing, skip it.
- **Directional slides only where there is a direction.** Hierarchy (list to detail) and ordered sequences (previous, next). Lateral navigation such as tab to tab gets a crossfade or nothing. A slide there implies depth that isn't real.
- **Morph only what the user is tracking.** A hero image, a title. Not every element that exists on both sides.
- **Set the duration from the tokens.** Page-level transitions use `--motion-dur-slow` and `--motion-ease-in-out`.

### Same-document

```js
function navigate(update, type) {
  if (!document.startViewTransition) return update();
  if (!type) return document.startViewTransition(update);
  try {
    return document.startViewTransition({ update, types: [type] });
  } catch {
    return document.startViewTransition(update); // callback-only browsers
  }
}
```

The DOM update must run either way. The object form with `types` is newer than the callback form (see the support table), and an older browser throws on it before anything runs, so the fallback is safe. The default animation is a crossfade on `root`.

### Cross-document

Same-origin navigations between real pages, no client router:

```css
@view-transition {
  navigation: auto;
}
```

- Both pages need the rule.
- `pageswap` fires on the old page and `pagereveal` on the new one. Each exposes `event.viewTransition` (null when no transition runs). Use them to set types or names that depend on where the user came from (`navigation.activation`). Register the listener in a render-blocking script, or the event has already fired.
- The new page is snapshotted as soon as it can render. If above-the-fold content isn't parsed yet, the transition lands on a blank page. `<link rel="expect" href="#main" blocking="render">` holds rendering until that element is parsed. Block only on what the first viewport needs: past about 4 seconds the browser skips the transition.
- `rel="expect"` waits for the element, not for its image. An uncached image in a morph is snapshotted as an empty box. Preload the image and give it `width` and `height`.
- An unsupported browser navigates normally. Ship it unconditionally.

### Naming elements

An element with a `view-transition-name` gets its own layer and morphs from its old box to its new one. A name must be unique in the document at snapshot time, or the whole transition is skipped.

For lists and grids, let the browser name by element identity and style the group through a class:

```css
.card {
  view-transition-name: match-element;
  view-transition-class: card;
}
::view-transition-group(.card) {
  animation-duration: var(--motion-dur-slow);
}
```

- `match-element` works same-document only. Two documents share no element identity, so cross-document morphs need explicit names.
- A list-to-detail morph needs one shared name on two different elements. Set it on the clicked item just before the transition and clear it when `finished` resolves. A stale name joins every later transition and keeps the page out of the back/forward cache.
- `::view-transition-new(.card):only-child` targets an element that enters with no counterpart, `::view-transition-old(.card):only-child` one that leaves.

### Direction

Types label a transition so CSS can pick the animation:

```css
html:active-view-transition-type(forward) {
  &::view-transition-old(root) { animation-name: slide-to-left; }
  &::view-transition-new(root) { animation-name: slide-from-right; }
}
html:active-view-transition-type(back) {
  &::view-transition-old(root) { animation-name: slide-to-right; }
  &::view-transition-new(root) { animation-name: slide-from-left; }
}
```

Set the type through `startViewTransition({ update, types })`, `event.viewTransition.types.add()` in `pagereveal`, or `types:` inside `@view-transition`.

### Morph quality

- **Aspect ratio changes stretch the snapshot.** Give old and new `height: 100%` and an `object-fit`, the same as fitting an image.
- **Text morphs ghost when the size differs.** The old snapshot is a raster that gets scaled. Set `width: fit-content` on both text elements so the box matches the glyphs. For a large size jump, hide the old snapshot and switch off the new one's fade: `::view-transition-old(title) { display: none; }` and `::view-transition-new(title) { animation: none; }`.
- **Running animations freeze.** A snapshot is a still image, so an element with an active animation looks paused for the duration.

### Keeping the page usable

- **Only part of the page changes.** Switch off the root crossfade and let clicks through to what isn't moving:

  ```css
  :root { view-transition-name: none; }
  ::view-transition { pointer-events: none; }
  ```

- **Persistent chrome** (a sticky header, a toolbar) otherwise crossfades with the page. Give it a name and `::view-transition-group(site-header) { animation: none; }`.
- **Focus.** A view transition does not move focus. If the focused element is gone after the update, send focus to the new view's heading when `finished` resolves.

### Reduced motion

The crossfade is a fade and stays. Movement is opt-in, as everywhere else: put names, types and custom keyframes inside the query, so under `reduce` only the crossfade is left.

```css
@media (prefers-reduced-motion: no-preference) {
  .card { view-transition-name: match-element; view-transition-class: card; }
  html:active-view-transition-type(forward) { /* slides */ }
}

/* Names set from script can't sit inside the query: stop their movement here */
@media (prefers-reduced-motion: reduce) {
  ::view-transition-group(*) { animation: none; }
}
```

### Lifecycle

`startViewTransition` returns a `ViewTransition`:

- `updateCallbackDone`: the DOM update ran.
- `ready`: the pseudo-elements exist. Start WAAPI animations on them here.
- `finished`: the new view is live. Clear temporary names and move focus here.
- `skipTransition()`: jump to the end state.
- `waitUntil(promise)`: hold `finished` until the promise settles. Chromium only.

`document.activeViewTransition` is the running transition or `null`.

### Chromium-only refinements

Both degrade to the standard behavior elsewhere.

- **Scoped transitions.** `element.startViewTransition()` limits the transition to a subtree, so several can run at once and the rest of the page stays interactive. Feature-detect and fall back to the document.
- **Nested groups.** By default every group is a flat child of `::view-transition`, so a child escapes its parent's clip and rounded corners mid-transition. `view-transition-group: contain` on the parent keeps its descendants inside.

### Browser support (MDN data, 2026-10-08)

| Feature | Chromium | Firefox | Safari |
| --- | --- | --- | --- |
| `document.startViewTransition`, `view-transition-name` | 111 | 144 | 18 |
| `view-transition-class` | 125 | 144 | 18.2 |
| Types: `{ update, types }`, `:active-view-transition-type()` | 125 | 147 | 18.2 |
| `match-element` | 137 | 144 | 18.4 |
| `document.activeViewTransition` | 142 | 147 | 26.2 |
| Cross-document: `@view-transition`, `pagereveal`, `rel="expect"` | 126 | no | 18.2 |
| `view-transition-group` (nesting) | 140 | no | no |
| `ViewTransition.waitUntil()` | 144 | no | no |
| `element.startViewTransition` (scoped) | 147 | no | no |

Same-document transitions work in all three engines: use them as a primary code path. Everything marked "no" is progressive enhancement. Recheck this table before relying on a row that is older than six months.

### Frameworks

- **React.** `<ViewTransition>` wraps content and is triggered by `startTransition` or Suspense. It shipped in React's canary channel and comes bundled with the Next.js App Router; check react.dev for its current status. Vercel's `react-view-transitions` skill covers it.
- **Motion.** `animateView()` adds springs, enter and exit, stagger and automatic naming. See `motion-engine/references/animation-patterns.md`. A plain crossfade doesn't need it.
