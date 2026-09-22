# Animation Decision Framework, Reference

The "should this animate, and how" taste layer. Springs (JS-based, `useSpring`, physics config) are intentionally out of scope. Execution/performance mechanics (GPU properties, compositor hygiene) stay in `motion-engine`. This file is the decision logic in between: given that something is going to animate, what should it do.

## Should this animate at all?

**Ask:** how often will the user see this animation?

| Frequency | Decision |
| --- | --- |
| 100+ times/day (keyboard shortcuts, command palette toggle) | No animation. Ever. |
| Tens of times/day (hover effects, list navigation) | Remove or drastically reduce |
| Occasional (modals, drawers, toasts) | Standard animation |
| Rare/first-time (onboarding, feedback forms, celebrations) | Can add delight |

Never animate keyboard-initiated actions. They're repeated hundreds of times a day, and animation makes them feel slow and disconnected from the action that triggered them. Raycast has no open/close animation; for something used hundreds of times a day, that absence is the correct choice, not an oversight.

## What is the purpose?

Every animation needs a clear answer to "why does this animate?" Valid purposes:

- **Spatial consistency.** A toast enters/exits from the same direction, making swipe-to-dismiss feel intuitive
- **State indication.** A morphing button shows the state actually changed
- **Explanation.** A marketing animation shows how a feature works
- **Feedback.** A button scales down on press, confirming the interface heard the input
- **Preventing jarring changes.** Elements popping in/out without transition feel broken

If the only answer is "it looks cool" and the user will see it often, don't animate.

## What easing should it use?

```
Entering or exiting?
  Yes → ease-out (starts fast, feels responsive)
  No →
    Moving/morphing on screen? → ease-in-out
    Hover/color change? → ease
    Constant motion (marquee, progress bar)? → linear
    Default → ease-out
```

**Never use `ease-in` for UI animations.** It starts slow, so the interface feels sluggish at the exact moment the user is watching most closely, the start of the motion. A 300ms dropdown with `ease-in` *feels* slower than the same 300ms with `ease-out`, even though the duration is identical.

Use custom easing curves. The built-in CSS keywords are too weak to feel intentional:

```css
--ease-out: cubic-bezier(0.23, 1, 0.32, 1);       /* strong ease-out for UI */
--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);   /* on-screen movement */
--ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);    /* iOS-like drawer curve */
```

Don't hand-derive curves. Pull stronger variants of standard easings from [easing.dev](https://easing.dev/) or [easings.co](https://easings.co/).

## How fast should it be?

| Element | Duration |
| --- | --- |
| Button press feedback | 100-160ms |
| Tooltips, small popovers | 125-200ms |
| Dropdowns, selects | 150-250ms |
| Modals, drawers | 200-500ms |
| Marketing/explanatory | Can be longer |

**UI animations stay under 300ms.** A 180ms dropdown feels more responsive than a 400ms one at the same easing.

## Perceived performance

Speed in animation isn't just about feeling snappy. It directly shapes how fast the app *seems*, independent of actual load time:

- A fast-spinning spinner makes loading feel faster at an identical load time
- A 180ms select feels more responsive than a 400ms one
- Instant tooltips after the first one is open (skip delay and animation on adjacent hovers) make a whole toolbar feel faster

Easing amplifies this: `ease-out` at 200ms feels faster than `ease-in` at 200ms, because the user sees movement immediately instead of after a slow start.

## Building components people actually reach for

Distilled from what makes small, widely-loved components (toast libraries, drawer primitives) work, beyond any single animation decision:

1. **Developer experience is the product.** No hooks, no context, no setup ceremony. Insert the component once, call it from anywhere. Friction to adopt is friction against ever getting used.
2. **Good defaults beat more options.** Most people never customize. The default timing, easing, and visual design need to be excellent out of the box, because that's what almost everyone ships with.
3. **Handle edge cases invisibly.** Pause timers when the tab is hidden. Capture pointer events during drag. Fill visual gaps between stacked elements so hover state doesn't break. Nobody notices these when they're handled. That's the point.
4. **Transitions over keyframes for anything added rapidly.** Toasts, list items, keyframes restart from zero on interruption; transitions retarget smoothly.
5. **Cohesion matters more than any single value being "correct."** A slightly slower, `ease`-based (rather than `ease-out`) animation can feel more elegant if it matches the personality of the rest of the component. A playful component can be bouncier, a dashboard should be crisp. Match the motion to the mood, not to a universal rule.
6. **The opacity + height combination for lists is trial and error.** When items enter/exit a list, getting opacity and height animating in sync has no formula. Adjust until it feels right, then lock it in.
7. **Review your own work the next day.** Fresh eyes catch imperfections that are invisible mid-build. Play back in slow motion or frame-by-frame to spot timing issues invisible at full speed.
8. **Asymmetric enter/exit timing.** Slow where the user is deciding, fast where the system is responding. A hold-to-delete gesture can take 2s (deliberate, prevents accidents) but should release/cancel in ~200ms (the system confirming instantly). The same asymmetry applies broadly: press slow, release fast.
