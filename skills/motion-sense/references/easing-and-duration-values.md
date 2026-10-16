# Easing and duration values

The only table of motion values. Prose and code elsewhere use the tokens. Which curve and which duration to pick: `animation-decisions.md`.

## Tokens

Define motion parameters as CSS custom properties so animations read from one source instead of hardcoded values.

```css
:root {
  /* Timing */
  --motion-dur-fast: 120ms;
  --motion-dur-base: 180ms;
  --motion-dur-slow: 300ms;
  --motion-dur-long: 600ms; /* marketing and explanatory motion only, never product UI */

  /* Easing. Reference tokens, never inline keywords. `standard` equals the `ease` keyword */
  --motion-ease-standard: cubic-bezier(0.25, 0.1, 0.25, 1);
  --motion-ease-out: cubic-bezier(0.23, 1, 0.32, 1);       /* strong ease-out for UI */
  --motion-ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);   /* on-screen movement */
  --motion-ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);    /* iOS-like drawer curve */

  /* Spring approximations. cubic-bezier overshoots once but can't settle; for real spring motion use --motion-ease-spring */
  --motion-spring-bounce: cubic-bezier(0.34, 1.56, 0.64, 1); /* overshoots: only after a gesture (flick, drag release), see SKILL.md Spring Feel */
  --motion-spring-smooth: cubic-bezier(0.22, 1, 0.36, 1);
  --motion-spring-snappy: cubic-bezier(0.16, 1, 0.3, 1);

  /* Distance & Scale */
  --motion-dist-sm: 10px;
  --motion-dist-md: 30px;
  --motion-dist-lg: 60px;
  --motion-scale-sm: 0.95;
  --motion-scale-lg: 1.05;

  /* Scroll animation ranges */
  --motion-range-default: entry 10% cover 30%;
  --motion-range-slow: entry 10% cover 50%;
  --motion-range-late: entry 40% cover 60%;
}
```

`--motion-ease-spring` is the `linear()` curve sampled from a real spring, with overshoot and settle. Its value and how to generate it: `native-transitions.md`.

If the project has a `DESIGN.md` or an equivalent design system file, its motion values win. The token names above are the recommended vocabulary. The specific values are project-dependent.

## Durations

| Element | Duration | Token |
| --- | --- | --- |
| Button press feedback | 100-160ms | `--motion-dur-fast` |
| Tooltips, small popovers | 125-200ms | `--motion-dur-fast`, `--motion-dur-base` |
| Dropdowns, selects | 150-250ms | `--motion-dur-base` |
| Modals | 200-300ms | `--motion-dur-slow` |
| Drawers, on `--motion-ease-drawer` only | up to 500ms | none, set per drawer |
| Page and full-view changes | 250-400ms | `--motion-dur-slow` |
| Marketing, explanatory | can be longer | `--motion-dur-long` |

Product UI stays under 300ms. Drawers and full-view changes are the two exceptions, and `animation-decisions.md` gives the reason for each.
