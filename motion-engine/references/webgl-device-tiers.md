# WebGL/Three.js Device Tiers. Reference

Blueprint for gating a WebGL/Three.js rendering layer by device and network capability. Only relevant once a WebGL layer exists. CSS/WAAPI/Motion.dev animation doesn't need this, it degrades gracefully on its own by dropping frames. WebGL doesn't degrade gracefully: it either runs or it catastrophically fails (context creation error, blocklisted GPU, thermal throttling, out-of-memory crash). This is a survival gate, not an ergonomics choice.

Pattern distilled from Shopify's Editions Spring 2026 build (Arnaud Tanielian / @Danetag), a production case of exactly this problem: a fullscreen WebGL atmosphere layer behind DOM content, built with Three.js + React Three Fiber.

## Why three tiers, not four

A common variant of this pattern uses four tiers (static / minimal WebGL / reduced textures-effects / full quality). Collapse the two middle tiers: the boundary between "minimal WebGL" and "reduced textures/effects" is a *degree* difference (same code path, different resolution/texture/effect knobs), not a *kind* difference like the Tier 0→1 boundary (no WebGL context at all vs. one exists). Maintaining two separate discrete presets for a knob-only difference is two configs to keep in sync for no real architectural boundary.

```
Tier 0. Static fallback     : no WebGL context
Tier 1. Constrained WebGL   : capped resolution, reduced textures, trimmed effects/post-processing
Tier 2. Full quality        : no caps
```

If finer gradation is ever needed within Tier 1, prefer a continuous "quality budget" scalar (0.0–1.0) driving those same knobs (texture resolution, particle count, post-fx toggles) over adding a 4th named tier. One parametrized preset instead of two hardcoded ones.

## Detection and gating

Gate on GPU **and** network capability, not GPU alone. A capable GPU on a slow/metered connection still shouldn't load full-resolution textures and compressed asset streams.

- **GPU**: benchmark-render on init and classify (`detect-gpu`'s convention: tier 0 for no context/blocklisted/<15fps, higher tiers for higher sustained fps).
- **Network**: check `navigator.connection?.effectiveType` and `navigator.connection?.saveData` where the Network Information API is available; treat its absence as "unknown, don't assume fast."
- **Mobile is a policy cap, not a benchmark result.** Hard-cap phones to Tier 1 regardless of what an individual device's GPU benchmarks at, plus a separate megapixel budget for canvas resolution. Don't try to re-benchmark your way into giving some phones Tier 2. The policy cap exists because thermal throttling and battery cost matter even when the raw fps number looks fine at t=0.

```js
async function resolveDeviceTier() {
  if (isMobileDevice()) return 1; // policy cap, independent of benchmark

  const gpuTier = await getGPUTier(); // e.g. detect-gpu
  const connection = navigator.connection;
  const slowNetwork = connection?.saveData || /2g/.test(connection?.effectiveType ?? '');

  if (gpuTier.tier === 0 || slowNetwork) return 0;
  return gpuTier.tier >= 3 ? 2 : 1;
}
```

## Resource pooling scoped to visibility, not scene count

For scroll-driven multi-section WebGL (a scrollytelling page with many distinct scenes), scope live resource usage to what's actually on screen, not to everything that exists on the page.

- Each visible section leases framebuffers/textures from a shared pool when it enters view.
- Sections release their resources back to the pool as they scroll off.
- Live VRAM tracks the ~3-4 sections actually visible, not all N sections that exist in the document. This is what makes a long scrollytelling page survive on a phone at all. Without this, VRAM usage scales with total page length instead of viewport content, and mobile runs out of memory on any sufficiently long page regardless of per-scene optimization.

## Guardrails baked into the code, not review discipline

Hard-cap expensive parameters (raymarch step count, particle/point count, shader loop bounds) in the rendering code itself, so a creative/art-direction change literally cannot regress performance past the ceiling. The cap is enforced structurally, not caught in review after the fact. This matters most on shared/reusable scene systems where the person authoring a new scene preset isn't necessarily the person who understands the performance budget.

## Authored motion: live vs. baked-to-video

A decision rule worth applying before any WebGL scene gets built at all: **run it live only when interactivity is worth it.**

- Interactive pieces (responds to scroll position, pointer, or app state) stay in a real-time-rendered engine.
- Linear, non-interactive motion that plays the same way every time should be pre-rendered to video instead, exported across responsive encodes/codecs (WebM, AV1, HEVC, H.264 as a compatibility ladder) rather than simulated live on every visitor's device.

This cuts real-time rendering cost down to only the pieces that actually need it, and sidesteps the entire device-tiering problem for everything that doesn't.

## Three.js-specific notes

- Three.js (r171+) code-splits its WebGL and WebGPU entry points; the WebGPU renderer imports with zero extra configuration and falls back to WebGL2 automatically where WebGPU isn't available. Don't hand-roll this fallback detection. Use the library's own split entry points.
- Pair GPU tier with distance-based level-of-detail (Drei's `<Detailed />` component sets this up without extra boilerplate) so quality degrades by both device capability and object distance from camera, not device capability alone.

## What's out of scope here

Bespoke asset-pipeline engineering (custom point-cloud binary compression formats, volumetric-light raymarching via KTX2 array textures, canvas-streaming tricks) is real but far too project-specific to generalize into a blueprint. That level of engineering is justified for a large production build, not a default to reach for. The tiering policy, resource-pooling pattern, and live-vs-baked decision rule above are the parts that generalize; the exact compression format a specific project used to make its point clouds fast doesn't.
