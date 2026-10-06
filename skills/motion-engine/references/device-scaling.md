# Device Capability Scaling. Reference

Scaling back decorative load when the device or network can't sustain the full experience. Distinct from Execution Tiers (which mechanism to use) and from `prefers-reduced-motion` (user preference). For the WebGL/Three.js survival gate, read `webgl-device-tiers.md`.

## CSS/WAAPI/Motion.dev complexity budget

"GPU-composited" isn't the same as "free." It holds for a single isolated `transform`/`opacity` transition; it doesn't hold for cumulative decorative load:

- Heavy `filter`/`backdrop-filter` (blur especially) is real GPU cost. On a constrained device, stay well under `motion-sense`'s 20px blur ceiling or skip blur.
- Motion.dev spring physics run on the main thread per frame per element. A large stagger group is real main-thread work that scales with element count, not free just because each spring individually targets `transform`.
- Motion's shorthand props (`x`/`y`/`scale`) aren't hardware-accelerated. Under main-thread load on a low-power device, this is exactly where frames drop.

Scale down on constrained devices: smaller/fewer stagger groups, skip decorative parallax layers, avoid or shrink blur, cap simultaneous spring count. This is a **different, performance-motivated reason to reduce motion than `prefers-reduced-motion`** (that's about vestibular/motion sensitivity, opt-in by user preference). The two are independent and stack. Use the same policy-cap principle as WebGL (`webgl-device-tiers.md`): treat mobile/low-power as a class-level cap, not something to re-benchmark per animation.
