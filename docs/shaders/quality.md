---
title: Quality
chapter: 6
section: 5
---

# Quality

Rendering quality is a **budget choice**, not a shader-identity switch. The
`RenderingQualitySettings` resource owns budgets that affect all GPU-backed
views. USD remains the authority for the scene's `ShaderLook` and authored WESL
source.

A scene can therefore keep its authored lunar terrain and starfield shaders
while the High preset supplies the largest renderer budgets around them.

## Presets

| Preset | Intent |
|---|---|
| `Low` | Lowest-cost shadow and lighting budgets |
| `Balanced` | The default interactive balance |
| `High` | Largest shipped shadow, lighting, derived-map, rock, and tessellation budgets |

The stable policy keys are `low`, `balanced`, and `high`. The Graphics settings
menu presents the same three choices. The CLI can select one for a process:

```bash
luncosim --render-quality high
```

The setting is persisted with the other graphics settings. It is not a
per-material property and it does not replace the shader authored by the scene.

## What the preset budgets

`RenderingQualitySettings` covers:

| Family | Examples |
|---|---|
| Shadow maps | Directional, point, and spot map sizes; cascade count; caster limits; shadow storage budget |
| Shadow filtering | Hardware 2×2 or Gaussian 5×5 |
| Horizon cache | Enablement, sun-angle invalidation threshold, march steps, bake supersampling |
| Camera | MSAA, tone mapping, exposure, bloom |
| Sky | Dome cubemap face size |
| Terrain LOD | Tile resolution, pixel error, maximum depth, tile budget, bake cadence, hysteresis, morph band |
| Terrain derived maps | Roughness/AO/normal resolution, AO directions and steps, anisotropy |
| Terrain rocks | Maximum instances, mesh buckets, LOD fade distances |
| Geometry | Sphere, cylinder, capsule, NURBS, and curve tessellation |
| Editor preview | Preview key light, local-light defaults, render-failure recovery |

The exact numeric values belong to the shipped profile and may change between
releases. Read the current settings in **Settings → Graphics** rather than
copying a table from a version of the documentation.

## Shadow filtering

The Graphics settings expose two shadow filters:

| Filter | Character |
|---|---|
| Hardware 2×2 | Four comparison samples with hardware filtering; lower cost |
| Gaussian 5×5 | A wider nine-sample footprint; highest quality without temporal anti-aliasing |

The default is Gaussian. The terrain material's normal bias is scaled by the
shadow texel size so grazing-angle terrain does not sample its own surface inside
the filter footprint.

## Terrain quality

The High preset keeps the interactive terrain CDLOD envelope at the proven
Balanced bound: 49-vertex tiles, depth 8, a 768-tile cover, and the corresponding
sampling and bake cadence. High increases the surrounding lighting, derived-map,
rock, and tessellation budgets; it does not double terrain cover merely to spend
the frame budget on duplicate geometry.

Per-tile texture quality is authored separately. A near tile can use a 2048²
albedo and a far tile a 256² one, with the same roles and different images. This
is the right way to spend quality where the camera actually looks.

## Quality does not change material identity

The quality preset does not rewrite a `ShaderLook`. It changes renderer budgets
around the authored material. A material that is invalid at Low is still invalid
at High; a shader that fails to compile is a shader error, not a quality
setting.

Likewise, changing a quality setting does not repair a missing texture or a
malformed parameter. Those are authoring errors and remain visible.

## Measuring cost

A deterministic recording run is not a profiling run. Use a separate session
when measuring frame time:

```bash
luncosim --no-vsync --no-throttle --log-diag
```

`--log-diag` reports FPS, frame time, and physics diagnostics. Compare presets
in the same scene, camera, and resolution; a different view invalidates the
comparison.

For a headless gate, keep the deterministic `--threads 1 --jitter 0` profile.
Graphics assertions are a separate serial offscreen pass because GPU state and
driver behavior are not part of the fixed-step determinism contract.

## Material sharing and quality

Identical looks share one material and one bind group. The look key includes
texture handles, so two tiles at different texture resolutions correctly get two
materials, while tiles at the same quality share one.

Varying a scalar per instance mints a material per instance. If a quality choice
must vary continuously, bucket it into a small set of values rather than giving
every instance a unique float.

## Related sections

- [Settings](../ui/settings.md) — the Graphics settings page
- [Terrain](terrain.md) — LOD, shadow, and derived-map budgets
- [Texture layers](texture-layers.md) — per-tile texture quality
- [Command line](../reference/cli.md) — render-quality flags
