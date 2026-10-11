# Component Building Principles Reference

Non-animation component patterns. Native elements, hit targets, form/field states, text and media that come from users, density, empty/loading/error states: the parts of a component that are correct or incorrect independent of any animation. Animation-flavored component patterns (button press feedback, popover origin-awareness, transitions) are covered in `motion-sense`'s `animation-techniques.md`, not here.

## Native elements first

- `<button>` for actions, `<a href>` for navigation, never a `<div>` with a click handler. A native element brings focus, keyboard activation and its role with it.
- `<dialog>` opened with `showModal()` for anything modal. It traps focus, makes the page behind inert and closes on Escape. `popover` for menus, tooltips and other non-modal layers. Open both with invoker commands and position them with anchor positioning, not a script. Support and traps: `platform-features.md`.
- An icon-only button needs an accessible name (`aria-label`), and its icon is `aria-hidden="true"`.
- Add ARIA only where no native element does the job. Where the project already has accessible primitives (Base UI, React Aria, Radix), use those for widgets with keyboard behavior. Never hand-build one.

## Hit targets

- Minimum interactive target: 44×44px on touch, 24×24px on pointer-only surfaces. 24×24 is the WCAG 2.5.8 floor (Level AA). 44×44 is this baseline's convention, taken from WCAG 2.5.5 (Level AAA) and Apple's HIG.
- A visually small icon button (16-20px glyph) still needs a 44px tap area. Pad the hit area, don't scale up the icon to compensate.
- Hit areas of adjacent targets (icon toolbars, table row actions) never overlap, even when the visible icons sit close. Where two padded areas would collide, shrink the padding to the largest size that doesn't.
- To pad a hit area without changing the visual, give the control `position: relative` and a pseudo-element with `position: absolute; inset: min(0px, (100% - 44px) / 2)`. `overflow: hidden` or `clip` on the control cuts it off, and an `<input>` has no pseudo-elements, so wrap that in its `<label>`.
- A decorative layer over a control (glow, gradient scrim) gets `pointer-events: none`, or it swallows the clicks.
- Don't shrink hit targets to fit a dense layout. Increase spacing between components instead. The token scale in `token-baseline.md` exists precisely so "needs more room" has an answer that isn't an arbitrary pixel value.

## Touch & interaction

- `touch-action: manipulation` on tappable elements. It turns off double-tap zoom on the control, so the browser never waits to see if a second tap follows. Pages with a `width=device-width` viewport already get this at initial zoom; this keeps taps fast when the user has zoomed in.
- Set `-webkit-tap-highlight-color` intentionally (usually `transparent`, paired with a real `:active` state) rather than leaving the browser default flash.
- `overscroll-behavior: contain` on modals, drawers, and sheets. Stops a scroll gesture inside them from bleeding into a scroll/bounce on the page behind.

## Form and field states

- Validate inline, not just on submit. A field that only reveals it's wrong after a failed submission attempt wastes a full round trip the user could've avoided. Check when the user leaves the field, clear the error as soon as they start correcting it, and never filter characters while they type.
- Never disable the submit button to gate validation. Keep it enabled, validate on submit, and move focus to the first invalid field.
- A failing field gets `aria-invalid="true"` and `aria-describedby` pointing at its error text. Color alone is never the error signal: pair it with text or an icon.
- Every field needs four visually distinct states at minimum: default, focus, error, disabled. If error and default look the same except for a small text label below, the state isn't visually distinct enough. Change the field's own color/border too, gated behind `:user-invalid` rather than `:invalid` so errors don't show before the user has had a chance to type.
- Disabled fields should look unmistakably inert: reduced contrast, no interactive affordances (no hover states, no focus ring, cursor `not-allowed`). Don't just gray the text slightly; a barely-changed disabled state reads as a bug, not a state.
- Error messages state what's wrong and how to fix it, not just that something is wrong. "Invalid" is not a message. "Must be at least 8 characters" is.
- Success state matters too, not just error: a field that was wrong and is now correct should visibly confirm that, especially for async validation (username availability, etc.). Otherwise the user can't tell if their fix registered.
- Focus state means `:focus-visible`, not `:focus`. `:focus` also fires on click, so a bare `:focus` ring flashes on every mouse click, not just keyboard navigation. Never remove the outline (`outline: none`) without shipping a replacement indicator; a compound control (e.g. a labeled input group) gets `:focus-within` so the whole group indicates focus, not just the inner control.
- Every input needs `autocomplete` and a meaningful `name` attribute, the correct `type` (`email`, `tel`, `url`, `number`) and `inputmode` for the data it collects, and a label that's actually clickable (`<label for>` or wrapping the control), not just visually adjacent. Never block paste (no `onPaste` + `preventDefault`). Disable spellcheck (`spellcheck="false"`) on emails, codes, and other non-prose fields where the red squiggle is just noise.
- Codes, PINs and card numbers are `type="text" inputmode="numeric"`, never `type="number"`, which adds a spinner and drops leading zeros.
- Input text is at least 16px on touch devices (`font-size: max(16px, 1rem)`). iOS Safari zooms the page on focus below that. Never fix the zoom with `user-scalable=no`.
- A textarea that should grow uses `field-sizing: content` with `min-height` and `max-height`, not a script.

## Text and media you don't control

- Decide for every user or CMS string what happens when it is longer than the design: it wraps, it is cut to one line, or it is clamped to a few. Set `overflow-wrap: break-word` where a long word or URL could escape.
- One-line truncation (`white-space: nowrap; overflow: hidden; text-overflow: ellipsis`) goes on the element that holds the text, and every flex ancestor between it and the row needs `min-width: 0`.
- Truncated text needs a way to the full value: an expand control, a detail view, or a tooltip that also opens on keyboard focus. A `title` attribute does not count. Never truncate text the user has to read.
- Every image, video or embed whose file you don't control gets `aspect-ratio` and `object-fit`, so the box has its shape before the file loads. `cover` crops; use `contain` for logos and product shots.

## Surfaces and icons

- Nested rounded corners: outer radius = inner radius + padding. Derive the outer from the inner; the other way round reaches zero once the padding exceeds the radius.
- An icon next to a label takes its size from the text (`1em`, `1cap` or `1lh`), not a px value per variant, and keeps `flex: none`.
- Icons draw with `currentColor`. State changes come from CSS color, not a second asset.

## Density

- Density is a deliberate, named choice (e.g. `compact` / `comfortable` / `spacious`), not the accidental byproduct of nested components each adding their own padding.
- Pick density per surface, not per component: a data table and its surrounding page shouldn't silently disagree about how tight things are.
- When in doubt, err toward more space, not less. Cramped UI reads as unfinished; generous UI reads as intentional, even when the generous version has objectively less content per screen.
- Nested spacing compounds. A card with `--space-lg` padding containing a list with `--space-md` item gaps containing buttons with `--space-sm` internal padding is fine. The same card with each layer independently guessing its own arbitrary value is not. Trace the actual rendered gap top-to-bottom before shipping a dense layout.

## Empty, loading, and error states

- These three states are part of the component, not an afterthought bolted on when a bug report arrives. Design them at the same time as the "happy path with data" state.
- **Empty**: never just blank. Explain why it's empty and what to do next (e.g. "No projects yet. Create your first one" with the actual action, not just descriptive text). A blank state that looks the same as a loading state or a broken state is a real failure mode. A user can't tell "there's nothing here" from "this is broken."
- **Loading**: match the shape of the eventual content (skeleton screens sized to the real layout) rather than a generic centered spinner that causes a layout jump the moment content arrives. If the load is expected to be fast (<500ms), consider no loading state at all. A flash of skeleton for a near-instant load reads as slower than showing nothing.
- **Error**: distinguish between "this specific action failed, retry" and "this whole view is broken." A failed inline action (e.g. one row's save failed) shouldn't take down the entire page. Scope the error state to what actually failed.
- All three states need the same visual polish as the populated state. A beautifully designed data table with an empty state that's just default browser text undoes the work put into the rest of the component.
