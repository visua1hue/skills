# Platform Features Reference

Features that replaced a script, a library, or a workaround, sorted by which browser engines ship them. Read before reaching for JS positioning, an auto-grow script, a z-index stack, or a class passed down a tree.

Checked 2026-10-10 against MDN browser-compat-data 8.1.5. Stable on that date: Chrome 155, Firefox 157, Safari 27. Versions are the first with full support; the month is when the feature became Baseline. Re-check anything here that is older than six months: `https://unpkg.com/@mdn/browser-compat-data/data.json`.

A project's stated browser floor wins over these tiers. Say so when a feature you used falls below it.

## All three engines

Use these by default. Add a fallback only when the project's browser floor is older than the month shown.

| Feature | Chrome / Firefox / Safari | Baseline | Use it in place of | Watch for |
| --- | --- | --- | --- | --- |
| Anchor positioning: `anchor-name`, `position-anchor`, `position-area`, `position-try-fallbacks` | 125 / 147 / 26 | 2026-01 | Floating UI or measured coordinates for tooltips, menus, popovers | The positioned element must be `absolute` or `fixed`. A popover opened with `popovertarget` or `commandfor` is anchored to its button without any `anchor-name`. Add `position-try-fallbacks: flip-block` so it flips at the viewport edge |
| Invoker commands: `<button commandfor="id" command="show-modal">` | 135 / 144 / 26.2 | 2025-12 | Click handlers that open or close a dialog or popover | Buttons only. Built in: `show-modal`, `close`, `toggle-popover`, `hide-popover`. A custom command starts with `--` and needs a `command` listener on the target |
| `popover` attribute | 114 / 125 / 17 | 2025-01 | z-index stacks and portal components for menus, tooltips, toasts | Not modal. Anything that must trap focus is a `<dialog>` opened with `showModal()` |
| `field-sizing: content` | 123 / 152 / 26.2 | 2026-06 | Auto-grow scripts for textareas and inputs | Set `min-` and `max-` sizes. A fixed `width` or `height` turns it off. An empty input with no `min-width` is as wide as the caret |
| `text-box: trim-both cap alphabetic` | 133 / 154 / 18.2 | 2026-08 | Uneven padding to make a label look centered in a button, badge or chip | Single-line labels only, never body text or `*`. Not inherited, and it does nothing on a flex or grid container, so set it on the element that wraps the text. The box gets shorter; raise the padding to keep the height |
| `@scope (.card) to (.content)` | 118 / 146 / 26.4 | 2025-12 | Naming prefixes and `:not()` chains that keep component styles from leaking into nested content | Safari 26.0 to 26.3 did not apply scoped rules to `<input>` and `<textarea>` |
| Style queries: `@container style(--variant: featured)` | 111 / 151 / 18 | 2026-05 | Modifier classes handed down a tree so children can react to context | Custom properties only. No `container-type` needed. It styles descendants, never the element that sets the property |
| `sibling-index()`, `sibling-count()` | 138 / 154 / 26.2 | 2026-08 | Inline `--i` variables and `:nth-child` ladders | The index starts at 1. Stagger timing itself belongs to `motion-sense` |
| `contrast-color()` | 147 / 146 / 26 | 2026-04 | A hand-picked text color per background token | Returns only black or white. Measure the result on mid-tone backgrounds |
| `light-dark()` | 123 / 120 / 17.5 | 2024-05 | A second block of color tokens under a media query or `.dark` class | Needs `color-scheme` on the root. Colors only |
| `<details name="group">` | 120 / 130 / 17.2 | 2024-09 | Script that closes the other panels of an accordion | Opening one closes the rest. Animating it belongs to `motion-sense` |

## Missing one engine

Use only where the missing browser still gets an acceptable result with no extra code. Never as the only way to reach content or complete a task.

| Feature | Chrome / Firefox / Safari | Without it |
| --- | --- | --- |
| Customizable select: `appearance: base-select`, `::picker(select)` | 135 / flag / 27 | Firefox shows the native select. Acceptable; never rebuild the select in JS to cover it |
| `text-wrap: pretty` | 117 / no / 26 | Normal wrapping |
| Scroll-driven animations: `animation-timeline` | 115 / preview / 26 | Owned by `motion-engine`, including the fallback |
| Cross-document view transitions: `@view-transition` | 126 / no / 18.2 | Owned by `motion-sense`. Plain navigation |
| `margin-trim` | 155 / no / 16.4 | Not acceptable as is: margins stay. Use `gap` |
| `popover="hint"` | 151 / 153 / preview | Not acceptable as is: Safari treats an unknown value as `manual`. Use `popover` or `popover="manual"` |
| `<dialog closedby="any">` | 134 / 141 / preview | Safari closes only on Escape and the close button. Add a backdrop click handler if light dismiss matters |

## One engine or none

Do not use unless the user asks, or the project targets that one engine.

- Chrome only: `interpolate-size` and `calc-size()`, `interestfor`, `@function`, CSS `if()`, scroll-state container queries, `::scroll-button()` and `::scroll-marker`, `corner-shape`, `reading-flow`.
- Safari only: `display: grid-lanes` (masonry).
- No browser: `@custom-media`, unprefixed `line-clamp`. Multi-line truncation still needs `display: -webkit-box`, `-webkit-box-orient: vertical`, `-webkit-line-clamp` and `overflow: hidden` together.
