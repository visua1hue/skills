# UI change

**You own what the user sees.** Prove it in a running browser, not in the diff.

Use for a visual, layout, or interaction change. For the logic behind it, use `feature.md` and come back here for the visible part.

1. Apply `ui-baseline`: tokens, component states, layout, platform features. Match the project's existing tokens and notation.
2. If the change animates, decide whether and how with `motion-sense`, then build it with `motion-engine`.
3. Build the smallest change (P1). Keep UI, data, and IO apart (P7).
4. Run the app and walk the changed flow, with browser tooling when available (P11).
5. Check keyboard access, focus, and reduced motion on the changed parts.
6. Check the browser console for new errors.
7. Open the PR per `git-stack-flow`, with screenshots.

**Evidence.** Screenshots or DOM state of the changed flow, and a console with no new errors.

**Reply:** what changed for the user, the proof, and any states not checked.
