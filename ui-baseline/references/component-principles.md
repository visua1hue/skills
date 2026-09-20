# Component Building Principles — Reference

Non-animation component craft — hit targets, form/field states, density, empty/loading/error states: the parts of a component that are correct or incorrect independent of any animation. Animation-flavored component patterns (button press feedback, popover origin-awareness, transitions) are covered in `motion-sense`'s `animation-techniques.md`, not here.

## Hit targets

- Minimum interactive target: 44×44px on touch, 24×24px on pointer-only surfaces with adequate spacing between adjacent targets (WCAG 2.5.8 Target Size, Level AA).
- A visually small icon button (16-20px glyph) still needs a 44px tap area — pad the hit area, don't scale up the icon to compensate.
- Adjacent small targets (icon toolbars, table row actions) need at least 8px of gutter between hit areas even if the visible icons sit closer — otherwise mis-taps become a real failure mode on touch, not just a theoretical one.
- Don't shrink hit targets to fit a dense layout. Increase spacing between components instead — the token scale in `token-baseline.md` exists precisely so "needs more room" has an answer that isn't an arbitrary pixel value.

## Touch & interaction

- `touch-action: manipulation` on tappable elements — removes the ~300ms double-tap-to-zoom delay browsers otherwise wait out on every tap.
- Set `-webkit-tap-highlight-color` intentionally (usually `transparent`, paired with a real `:active` state) rather than leaving the browser default flash.
- `overscroll-behavior: contain` on modals, drawers, and sheets — stops a scroll gesture inside them from bleeding into a scroll/bounce on the page behind.

## Form and field states

- Validate inline, not just on submit. A field that only reveals it's wrong after a failed submission attempt wastes a full round trip the user could've avoided.
- Every field needs four visually distinct states at minimum: default, focus, error, disabled. If error and default look the same except for a small text label below, the state isn't visually distinct enough — color/border alone, gated behind `:user-invalid` rather than `:invalid`, so errors don't show before the user has had a chance to type.
- Disabled fields should look unmistakably inert — reduced contrast, no interactive affordances (no hover states, no focus ring, cursor `not-allowed`). Don't just gray the text slightly; a barely-changed disabled state reads as a bug, not a state.
- Error messages state what's wrong and how to fix it, not just that something is wrong. "Invalid" is not a message. "Must be at least 8 characters" is.
- Success state matters too, not just error: a field that was wrong and is now correct should visibly confirm that, especially for async validation (username availability, etc.) — otherwise the user can't tell if their fix registered.
- Focus state means `:focus-visible`, not `:focus` — `:focus` also fires on click, so a bare `:focus` ring flashes on every mouse click, not just keyboard navigation. Never remove the outline (`outline: none`) without shipping a replacement indicator; a compound control (e.g. a labeled input group) gets `:focus-within` so the whole group indicates focus, not just the inner control.
- Every input needs `autocomplete` and a meaningful `name` attribute, the correct `type` (`email`, `tel`, `url`, `number`) and `inputmode` for the data it collects, and a label that's actually clickable (`<label for>` or wrapping the control) — not just visually adjacent. Never block paste (no `onPaste` + `preventDefault`). Disable spellcheck (`spellcheck="false"`) on emails, codes, and other non-prose fields where the red squiggle is just noise.

## Density

- Density is a deliberate, named choice (e.g. `compact` / `comfortable` / `spacious`), not the accidental byproduct of nested components each adding their own padding.
- Pick density per surface, not per component: a data table and its surrounding page shouldn't silently disagree about how tight things are.
- When in doubt, err toward more space, not less — cramped UI reads as unfinished; generous UI reads as intentional, even when the generous version has objectively less content per screen.
- Nested spacing compounds. A card with `--space-lg` padding containing a list with `--space-md` item gaps containing buttons with `--space-sm` internal padding is fine — the same card with each layer independently guessing its own arbitrary value is not. Trace the actual rendered gap top-to-bottom before shipping a dense layout.

## Empty, loading, and error states

- These three states are part of the component, not an afterthought bolted on when a bug report arrives. Design them at the same time as the "happy path with data" state.
- **Empty**: never just blank. Explain why it's empty and what to do next (e.g. "No projects yet — create your first one" with the actual action, not just descriptive text). A blank state that looks the same as a loading state or a broken state is a real failure mode — a user can't tell "there's nothing here" from "this is broken."
- **Loading**: match the shape of the eventual content (skeleton screens sized to the real layout) rather than a generic centered spinner that causes a layout jump the moment content arrives. If the load is expected to be fast (<500ms), consider no loading state at all — a flash of skeleton for a near-instant load reads as slower than showing nothing.
- **Error**: distinguish between "this specific action failed, retry" and "this whole view is broken." A failed inline action (e.g. one row's save failed) shouldn't take down the entire page — scope the error state to what actually failed.
- All three states need the same visual polish as the populated state. A beautifully designed data table with an empty state that's just default browser text undoes the work put into the rest of the component.
