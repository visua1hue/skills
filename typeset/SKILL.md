---
name: typeset
description: Encodes visua1's personal typography and spacing token baseline — raw and semantic type scale (font-size steps through a fluid clamp()-based upper range), line-height and letter-spacing curves, font-feature-settings/ligature and tabular-nums conventions, a near-geometric spacing scale, and plain-CSS token file organization (variables.css/global.css). Deliberately excludes color (always project-specific) — never proposes a default palette. Use when setting up a new project's type/spacing system, auditing an existing one for gaps, or choosing type or spacing tokens for a component.
---

# Typeset (visua1)

Personal typography and spacing token baseline — the fallback/starting point to reach for when a project's own type or spacing scale is missing a step. Component craft lives in `adaptive-layout`; animation taste lives in `motion-sense`.

## Typography & Spacing Token Baseline

If the project already defines its own scale (`variables.css`, `DESIGN.md`, or similar), that wins — this baseline is the fallback/starting point, and the thing to reach for when a specific step is missing. Full rationale: `references/token-baseline.md`.

| Category | Baseline | Rule |
| --- | --- | --- |
| Type scale | Step-based `--font-size--2` (12px) → `--font-size-6` (fluid `clamp()`), plus a semantic layer (`--text-h1`…`--text-caption`) built on top | Raw steps are the palette; semantic tokens are what markup actually references. Anything meant to feel "big" at every viewport is `clamp()`-based, not fixed-plus-media-query |
| Line-height | `tight` 1.1 → `relaxed` 1.7 | Falls as font-size rises — one base value for everything reads loose on big text, cramped on small |
| Letter-spacing | `tight` -0.02em → `wide` 0.02em | Inverse to size — big text tightens, small/uppercase text loosens |
| Ligatures | `common-ligatures contextual` (body), `none` (code), `tabular-nums` (data) | Invisible detail; tabular data without it visibly jitters as digits change |
| Spacing | `3xs` 2px → `5xl` 128px, near-geometric | Never hardcode a value inline — if something needs a step between two, add the step |

**Color is explicitly out of scope.** No default palette, ever — always read color from the project's own tokens.

**File organization** (plain-CSS projects only): `variables.css` — tokens only; `motion.css` — motion tokens, owned by `motion-engine`; `global.css` — imports both, plus resets and base element styles. Full detail: `references/token-baseline.md`.

## Review Format (Required)

When reviewing UI code, use a markdown table with Before/After/Why columns — one row per issue found:

| Before | After | Why |
| --- | --- | --- |
| Hardcoded `padding: 13px` | `padding: var(--space-sm)` | Spacing scale, not arbitrary values |

## Review Checklist

| Issue | Fix |
| --- | --- |
| Hardcoded font-size/spacing value | Replace with the nearest token; add a step if none fits |
| Fixed heading size across viewports | `clamp()`-based fluid size |
| Same line-height on headings and body | Tighten line-height as size increases |
| Tabular data without `tabular-nums` | Add `font-variant-numeric: tabular-nums` |
| Default color values proposed by the skill | None — always defer to the project's own tokens |
| Straight quotes (`"`/`'`) or `...` in UI copy | Curly quotes (`"`/`'`), real ellipsis (`…`) |
| Number/unit or shortcut pair that can line-wrap apart | Non-breaking space (`&nbsp;`) between them |

## External References

- [Utopia.fyi](https://utopia.fyi/) — fluid type & space scale calculator; the convention this baseline's raw step naming is drawn from
