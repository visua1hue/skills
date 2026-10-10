# Animation Technique Library Reference

CSS technique patterns for shipping the feel decisions in `animation-decisions.md`. Discrete-property transitions (`allow-discrete` + `@starting-style`) and the `linear()` spring-approximation easing are covered in `native-transitions.md`, not repeated here.

## CSS Transform Mastery

### `translateY` with percentages

Percentage values in `translate()` are relative to the element's own size, not the viewport. `translateY(100%)` moves an element by its own height regardless of actual dimensions. This is how Sonner positions toasts and how Vaul hides a drawer before animating it in.

```css
.drawer-hidden { transform: translateY(100%); } /* works regardless of drawer height */
.toast-enter { transform: translateY(-100%); }   /* works regardless of toast height */
```

Prefer percentages over hardcoded pixel values. They're less error-prone and adapt to content automatically.

### `scale()` scales children too

Unlike `width`/`height`, `scale()` scales an element's children along with it. Scaling a button on press scales its font size, icons, and content proportionally. That's a feature, not a bug: it reinforces the "this is one physical object being pressed" feeling.

### 3D transforms for depth

`rotateX()`/`rotateY()` with `transform-style: preserve-3d` create real 3D effects (orbiting motion, coin flips, depth) without JavaScript:

```css
.wrapper { transform-style: preserve-3d; }

@keyframes orbit {
  from { transform: translate(-50%, -50%) rotateY(0deg) translateZ(72px) rotateY(360deg); }
  to   { transform: translate(-50%, -50%) rotateY(360deg) translateZ(72px) rotateY(0deg); }
}
```

### `transform-origin`

Every element has an anchor point transforms execute from. Default is center. Set it explicitly to match where the interaction actually originates (see popover origin-awareness below).

SVG elements default to a viewport-relative `transform-origin`, not their own box. Set `transform-box: fill-box` for own-bounding-box origin.

## `clip-path` for Animation

`clip-path` is not just for shapes. It's one of the most versatile animation tools in CSS.

### The inset shape

`clip-path: inset(top right bottom left)` clips a rectangular region; each value eats into the element from that side.

```css
.hidden  { clip-path: inset(0 100% 0 0); } /* fully hidden from the right */
.visible { clip-path: inset(0 0 0 0); }    /* fully visible */

.overlay {
  clip-path: inset(0 100% 0 0);
  transition: clip-path 200ms var(--motion-ease-out);
}
.button:active .overlay {
  clip-path: inset(0 0 0 0);
  transition: clip-path 2s linear; /* reveal on hold, see hold-to-delete below */
}
```

### Tabs with perfect color transitions

Duplicate the tab list. Style the copy as "active" (different background/text color). Clip the copy so only the active tab is visible, and animate the clip on tab change. This produces a seamless color transition that animating individual tab colors can never match. The "active" look is always one continuous shape sliding under the labels, not N separate color transitions racing each other.

### Hold-to-delete pattern

Colored overlay starts at `clip-path: inset(0 100% 0 0)`. On `:active`, transition to `inset(0 0 0 0)` over 2s linear (deliberate, prevents accidental deletes). On release, snap back with 200ms ease-out (system responds instantly). Pair with `scale(0.97)` on the button itself for press feedback.

### Image reveals on scroll

Start at `clip-path: inset(0 0 100% 0)` (hidden from bottom), animate to `inset(0 0 0 0)` when the element enters the viewport. Use `IntersectionObserver` or a scroll-triggered animation library with `{ once: true, margin: "-100px" }` so it only fires once, slightly before the element is fully in view.

### Comparison sliders

Overlay two images. Clip the top one with `clip-path: inset(0 50% 0 0)`, then adjust the right-inset value based on drag position. No extra DOM elements. Cheap for occasional updates, but a per-frame drag repaints; for heavy use, `transform` a clip wrapper instead (see `motion-engine`).

## Component Patterns (Animation-Flavored)

Motion-specific component craft. Pairs with the non-animation craft in `ui-baseline`'s `component-principles.md`.

### Buttons must feel responsive

```css
.button { transition: transform 160ms var(--motion-ease-out); }
.button:not(:disabled):active { transform: scale(0.97); }
```

Instant feedback on `:active` makes the UI feel like it's actually listening. Applies to any pressable element; keep the scale subtle (0.95-0.98). A disabled button never scales. One that still presses reads as a bug.

### Never animate from `scale(0)`

Nothing in the real world disappears and reappears from nothing. Start from `scale(0.9)` or higher combined with opacity. Even a barely-visible initial scale reads as more natural, like a balloon that still has a shape when deflated.

```css
/* Bad */
.entering { transform: scale(0); }
/* Good */
.entering { transform: scale(0.95); opacity: 0; }
```

Per component: popover, dropdown and menu `0.95`, tooltip `0.97`, modal `0.96`. A large surface already travels far in pixels, so it starts closer to `1`.

### Make popovers origin-aware

Popovers should scale in from their trigger, not from center. The default `transform-origin: center` is wrong for almost every popover. **Exception: modals.** They aren't anchored to a trigger, so centered is correct for them.

```css
.popover { transform-origin: var(--radix-popover-content-transform-origin); } /* Radix */
.popover { transform-origin: var(--transform-origin); }                       /* Base UI */
```

### Tooltips: skip delay on subsequent hovers

Tooltips should delay before appearing (prevents accidental activation on a stray hover), but once one tooltip is open, adjacent tooltips should open instantly with no delay or animation. Feels faster without losing the point of the initial delay.

```css
.tooltip {
  transition: transform 125ms var(--motion-ease-out), opacity 125ms var(--motion-ease-out);
}
.tooltip[data-starting-style],
.tooltip[data-ending-style] {
  opacity: 0;
  transform: scale(0.97);
}
.tooltip[data-instant] { transition-duration: 0ms; } /* subsequent hovers */
```

### Transitions over keyframes for rapidly-triggered UI

CSS transitions can be interrupted and retargeted mid-flight; keyframes restart from zero. For anything triggered rapidly (adding toasts, toggling states repeatedly), transitions produce smoother results: no visible restart glitch when the user re-triggers before the previous animation finished.

### Use blur to mask imperfect transitions

When a crossfade between two states looks off no matter what easing/duration is tried, add a subtle `filter: blur(2px)` during the transition. Without it, a crossfade shows two distinct objects overlapping; blur bridges the gap, tricking the eye into perceiving one smooth transformation instead of a swap. Keep blur under 20px. Heavy blur is expensive, especially in Safari.

```css
.button-content { transition: filter 200ms ease, opacity 200ms ease; }
.button-content.transitioning { filter: blur(2px); opacity: 0.7; }
```

### Skip state animations on first render

A toggle, tab, segmented control or swapped icon shows its default state on page load without animating into it. Motion on load is reserved for intentional entrances.

- CSS transitions don't fire on first render, as long as the state is in the initial HTML. Setting it in an effect after mount triggers the transition, so render the state on the server or before first paint.
- `@starting-style` and keyframe animations do run on first render. Don't use them for a control's default state.
- In Motion, set `initial={false}` on the `AnimatePresence` that wraps a state swap. Never set it around an intentional entrance such as a staggered hero: it skips that entrance too.

### Suppress transitions on theme switch

Only where colors have transitions and the fade is unwanted. Without this, every color transition fires at once and the switch smears.

```js
function switchTheme(apply) {
  const style = document.createElement("style");
  style.textContent = "*,*::before,*::after{transition:none !important}";
  document.head.append(style);

  apply();                         // flip the theme class or attribute
  void document.body.offsetHeight; // commit the new colors while transitions are off

  requestAnimationFrame(() => requestAnimationFrame(() => style.remove()));
}
```

The new colors resolve while the override is in the document, so no transition starts. The nested `requestAnimationFrame` removes the override only after that paint. An OS-level change needs the same steps on the `prefers-color-scheme` change event. `next-themes` ships this as `disableTransitionOnChange`.
