# Typography & Spacing Token Baseline — Reference

Full rationale for the token baseline summarized in SKILL.md. Read this when setting up a new project's type/spacing system or auditing an existing one for gaps.

## Why a baseline at all

Most projects define *some* type scale early, then stop — a handful of font-size steps and nothing else. The gaps that show up later are consistent: no step below the smallest body size (captions/metadata get a hardcoded value instead), no distinction between heading and body line-height, no letter-spacing tokens at all, and zero `font-feature-settings`/ligature handling. None of these are visible individually. All of them compound into text that reads as slightly generic.

This baseline exists to be the thing you reach for when a project's own scale is missing a step — not to override a project that already has an opinion.

## Type scale (raw layer)

Step-based naming (Utopia.fyi convention) — `0` is the body baseline, negative steps go smaller, positive steps go larger. One continuous scale for fixed and fluid sizes, so there's no separate naming scheme to switch between partway up the scale.

```css
--font-size--2: 0.75rem;   /* 12px */
--font-size--1: 0.875rem;  /* 14px */
--font-size-0:  1rem;      /* 16px — body baseline */
--font-size-1:  1.125rem;  /* 18px */
--font-size-2:  1.25rem;   /* 20px */
--font-size-3:  1.5rem;    /* 24px */
--font-size-4:  1.875rem;  /* 30px */
--font-size-5:  clamp(2.25rem, 1.9rem + 1.5vw, 3rem);  /* 36-48px, fluid */
--font-size-6:  clamp(2.75rem, 2.1rem + 2.8vw, 4rem);  /* 44-64px, fluid */
```

Fixed steps below and around the baseline (`-2` through `4`) are fine — that range doesn't need to visibly change shape across viewports. From `5` up, use `clamp()` instead of a fixed value plus a media-query override. A fixed 48px heading with a mobile override at 32px is two numbers to keep in sync and a visible snap at the breakpoint; a fluid clamp is one declaration and no snap.

Raw steps are rarely applied directly to markup — they're the palette the semantic layer below draws from. Reach for a raw step directly only for a genuine one-off that doesn't fit any semantic role.

## Semantic type layer

Named by what the text *is* (heading level, body, caption), not by its raw size — mirrors the raw/semantic split already used for color tokens (`--color-primary-100` → `--color-text-default`). Apply these in markup; keep the raw `--font-size-N` scale as the thing semantic tokens are built from, not something components reference directly.

```css
--text-h1: var(--font-size-6);       /* 44-64px, fluid */
--text-h2: var(--font-size-5);       /* 36-48px, fluid */
--text-h3: var(--font-size-4);       /* 30px */
--text-h4: var(--font-size-3);       /* 24px */
--text-body: var(--font-size-0);     /* 16px */
--text-caption: var(--font-size--2); /* 12px */
```

Steps `-1`, `1`, and `2` are intentionally left unassigned in the semantic layer — available for a one-off (e.g. a slightly larger body variant) without adding a new semantic name for something that isn't a real recurring role yet. If the same one-off shows up three times, that's the signal to promote it to a named semantic token, not to keep reaching for the raw step.

`clamp(min, preferred, max)` — the preferred value should be a `rem + vw` mix so it scales with both the root font-size and the viewport. Tune the `vw` coefficient by checking the size at your narrowest and widest supported viewport, not by formula alone.

## Line-height

```css
--line-height-tight: 1.1;     /* display/hero text */
--line-height-snug: 1.25;     /* headings */
--line-height-base: 1.5;      /* body text */
--line-height-relaxed: 1.7;   /* long-form prose, article body */
```

The relationship is inverse to font-size: as text gets bigger, lines need to sit closer together, because the eye already has more visual anchor per line. A 48px heading at `1.5` looks like it's floating; a 16px paragraph at `1.1` looks cramped and hard to scan. If a project has only one `--line-height-base` for everything, that's the single most common line-height gap.

## Letter-spacing

```css
--letter-spacing-tight: -0.02em;  /* headings, display text */
--letter-spacing-base: 0;          /* body text */
--letter-spacing-wide: 0.02em;    /* all-caps labels, small UI text */
```

Tracking runs inverse to size, same direction as line-height: big text tightens (negative tracking keeps large glyphs from looking loosely spaced), small or all-caps text loosens (positive tracking keeps small/uppercase glyphs from crowding into each other — uppercase letters have no ascenders/descenders to create visual separation, so they need the extra room).

## font-feature-settings / ligature checklist

```css
/* Body and UI text */
body {
  font-variant-ligatures: common-ligatures contextual;
}

/* Tabular data — tables, stats, prices, timers, anything with columns of digits */
.tabular {
  font-variant-numeric: tabular-nums;
}

/* Code/mono contexts — ligatures off by default */
code, pre {
  font-variant-ligatures: none;
}

/* Numeric contexts where 0/O confusion matters: API keys, license codes, IDs */
.slashed-zero {
  font-variant-numeric: slashed-zero;
}
```

Two failure modes to watch for:
- **Tabular data without `tabular-nums`**: proportional digits have different widths per glyph (`1` is narrower than `8`), so a column of changing numbers visibly jitters as digits change. This is especially noticeable in live-updating UI (timers, live stock prices, counters).
- **Programming ligatures on by default**: fonts like Fira Code or Cascadia Code render `=>`, `!=`, `>=` as single glyphs. This is a legitimate personal preference, not a default — some people read code faster with them, some find they obscure the actual characters being typed (which matters when debugging or teaching). Default off, let it be an explicit choice.

## Typographic characters

Content-level, not CSS — but the same "invisible detail that compounds" logic applies, and it's cheap to get right:

- **Ellipsis**: the real character `…` (U+2026), not three periods `...`. Loading/pending states: `"Loading…"`, not `"Loading..."`.
- **Quotes**: curly/smart quotes (`"` `"` `'` `'`), not straight typewriter quotes (`"` `'`).
- **Non-breaking spaces**: between a number and its unit, a keyboard shortcut's modifier and key, or inside a brand name — anywhere an automatic line-break would land in a visually wrong spot: `10&nbsp;MB`, `⌘&nbsp;K`.

## Spacing scale

```css
--space-3xs: 0.125rem;  /* 2px  — hairline gaps, icon-to-label gaps */
--space-2xs: 0.25rem;   /* 4px  — tight internal padding */
--space-xs:  0.5rem;    /* 8px  — compact component padding */
--space-sm:  0.75rem;   /* 12px — default internal padding */
--space-md:  1rem;      /* 16px — default gap between related elements */
--space-lg:  1.5rem;    /* 24px — gap between distinct groups */
--space-xl:  2rem;      /* 32px — section-level spacing */
--space-2xl: 3rem;      /* 48px — large section breaks */
--space-3xl: 4rem;      /* 64px — page-section spacing */
--space-4xl: 6rem;      /* 96px */
--space-5xl: 8rem;      /* 128px — top-level page rhythm */
```

Near-geometric progression (roughly ×1.5-2 per step) rather than strict doubling from the smallest step — strict doubling from `2px` overshoots fast and skips useful mid-range values like `12px`/`24px` that show up constantly in real layouts.

The scale-adherence rule matters more than the specific numbers: an inline `padding: 13px` isn't wrong because 13 is a bad number, it's wrong because it can't be reasoned about relative to anything else in the interface. If a design genuinely needs a value between two steps repeatedly, add the step to the scale — don't let one-off hardcoded values accumulate.

## Color — explicitly excluded

Deliberately no color guidance here. Color is the token category where personal/brand taste diverges the most between projects, and baking in a default palette (even a "neutral" one) tends to leak into places it doesn't belong. Every project's color tokens should be read from that project's own file — this skill should never be the source of a color value.

## File organization

Where these tokens actually live, for a plain-CSS project (no CSS-in-JS, no utility framework). If the project already has its own file structure, that wins — this is the baseline to reach for when starting fresh or auditing an existing project for a place to put things.

Three files, one import chain:

- **`variables.css`** — tokens only, no selectors. Both layers live here: raw (`--color-primary-100`, `--font-size-0`) and semantic (`--color-text-default`, `--text-body`).
- **`motion.css`** — motion tokens (durations, easings) and their load/accessibility contract; owned by `motion-engine`, not repeated here.
- **`global.css`** — imports both of the above, then universal resets and base element styles (box-sizing, `html`/`body` defaults). The only file with page-wide selectors that aren't scoped to a specific feature.

Not a strict rule for every setup — a project using CSS-in-JS or a utility framework (Tailwind, etc.) won't have a `variables.css` in this shape at all. It's the convention specifically for "plain CSS custom properties, no framework."
