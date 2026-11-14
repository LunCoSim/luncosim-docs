---
title: Texture layers
chapter: 7
section: 2
---

# Texture layers

A texture layer is a raster the shader samples. The engine exposes a fixed set of
**13 named roles**. A shader opts in by declaring the binding; a shader that does
not declare it is unaffected by that layer being set. One role set serves every
shader, so a new look does not create a new material type.

## The roles

| Role | Content | Typical format |
|---|---|---|
| `Height` | World heights for ray-marched sun shadows | `R32Float`, non-filterable |
| `Albedo` | Body-wide colour raster, such as a lunar mosaic | RGBA8, linear light |
| `Mineral` | Class-id or composition raster, tinted through a palette LUT | RGBA8 |
| `Surface` | Packed scalars: R roughness, G ambient occlusion, B rock density, A hazard | RGBA8 |
| `Normal` | Tangent- or world-space normals from DEM relief | RGBA8 |
| `ShadowCache` | Pre-baked sun visibility | `R8Unorm` |
| `ContinuationAlbedo` | Site-local albedo for a lunar-surface continuation shader | RGBA8 |
| `ContinuationSurface` | Site-local packed roughness/AO for a continuation shader | RGBA8 |
| `SurfaceAnnotations` | Sparse terrain-local vector annotations, read with `textureLoad` | Typed |
| `DetailAlbedo` | Repeatable colour detail, independent of the georeferenced raster | RGBA8 |
| `DetailNormal` | Repeatable tangent-space normal detail | RGBA8 |
| `DetailSurface` | Repeatable packed scalars: R roughness, G ambient occlusion | RGBA8 |
| `Displacement` | Authored scalar displacement, separate from the runtime shadow heightfield | Scalar |

`Height` is a slot precisely because `R32Float` is non-filterable and cannot be
packed with filterable colour data. `ShadowCache` is a separate slot because it
has its own single-channel format and refresh cadence.

## Authorable inputs

A USD material addresses the authorable roles through asset-typed `inputs:`
properties:

| USD input | Role |
|---|---|
| `inputs:albedo_map` | `Albedo` |
| `inputs:mineral_map` | `Mineral` |
| `inputs:surface_map` | `Surface` |
| `inputs:normal_map` | `Normal` |
| `inputs:detail_albedo_map` | `DetailAlbedo` |
| `inputs:detail_normal_map` | `DetailNormal` |
| `inputs:detail_surface_map` | `DetailSurface` |
| `inputs:displacement_map` | `Displacement` |

`height_map` and `shadow_cache` are deliberately **not** addressable from USD.
They are engine-filled by the horizon-shadow system; authoring them would fight
the engine writer.

`ContinuationAlbedo`, `ContinuationSurface`, and `SurfaceAnnotations` are also
runtime-owned. The DEM-to-globe continuation compositor clones the body look and
supplies the site-local maps. Terrain annotations publish sparse vector data
through the annotation path.

A connected `inputs:` property is skipped by the texture reader; it is fed by a
producer node, not by an authored file.

## Spend a channel before a slot

`Surface` is one texture carrying four independent scalar layers:

| Channel | Layer |
|---|---|
| R | Roughness |
| G | Ambient occlusion |
| B | Rock density |
| A | Hazard |

A new scalar layer should take a spare channel, not a new slot. Four scalars for
one binding is a 4× win on the scarce resource, and it costs one texture fetch
instead of four.

`DetailSurface` follows the same rule for repeatable detail: R is roughness and
G is ambient occlusion. A single-channel roughness image requires
`detail_ao_weight = 0`.

Reach for a new slot only when the layer is genuinely not a scalar: a colour, a
normal, something with its own format, or something with different filtering
rules.

## Formats and filtering

The role determines the prepared image contract:

| Family | Filtering |
|---|---|
| `Albedo`, `Mineral`, `ContinuationAlbedo` | Linear light, sRGB decode on load |
| `Surface`, `ContinuationSurface`, `DetailSurface` | Scalar channels averaged |
| `Normal`, `DetailNormal` | Vectors averaged and renormalized |
| `Height`, `ShadowCache`, `SurfaceAnnotations` | Dedicated native-image access |
| `Displacement` | Authored scalar range |

Prepared RGBA8 rasters are filtered inside the native asynchronous asset
pipeline. Each role has its own native root type and labeled image identity, so
one source file can supply different roles without settings races. Requests use
native asset paths and `ImageLoaderSettings`; decoding stays in Bevy's native
loader.

The CPU mip chain follows the GPU extent rule: every axis becomes
`max(1, floor(previous / 2))`. Non-power-of-two authored and derived maps are
valid inputs and remain renderable.

## Albedo is not a grayscale orthophoto

An authored grayscale orthophoto is not intrinsic albedo. Its broad brightness
field contains acquisition illumination, and the runtime would light it a second
time. The asset pipeline has a distinct `kind = "albedo"` processor that removes
the low-frequency illumination field, anchors the remaining local variation at
an authored neutral regolith value, and sRGB-encodes the result.

A generic `kind = "map"` output is analysis or display data and must not be bound
directly as `inputs:albedo_map`. A calibrated reflectance raster may use the
`texture` pipeline when its colour-space contract is declared by the asset.

## Detail maps

The canonical DEM material can combine georeferenced site rasters with optional
repeatable material scans:

- `detail_albedo_map` multiplies the site albedo by scan luminance relative to
  `detail_albedo_mean` in linear light.
- `detail_normal_map` perturbs the existing DEM or procedural normal. It uses
  +X/-Z tangent axes and fades below the resolved pixel footprint.
- `detail_surface_map` supplies independent roughness and ambient-occlusion
  weights.

`detail_tile_size_m` defines one repeat in terrain-local metres. Coordinates
remain stable as tiles and the camera move, and explicit gradients select mip
levels across wrap boundaries. Detail maps never replace the DEM normal map or
change height queries and colliders.

All detail weights default to zero, so an existing scene does not request detail
maps or change appearance.

## Continuation roles

A body fragment shader that accepts site-local maps declares:

```wgsl
//!@interface lunco.lunar-surface-continuation.v1
```

and the USD Shader prim authors the same identifier as `info:wesl:interface`.
The DEM collar supplies `ContinuationAlbedo` and `ContinuationSurface` while the
body-wide `Albedo` and `Surface` remain the globe appearance. The exterior
composes the site base colour with its authored raster weight before fading to
the body appearance.

This is visualization only. It never resamples, blends, edits, or replaces DEM
heights, terrain queries, or colliders.

## Per-tile quality

Terrain is tiled, and each tile carries its own `ShaderLook`, hence its own
texture handles. Per-place quality is therefore a matter of giving the near tile
a larger albedo and the far tile a smaller one. The same roles are used; only
the images differ. Tiles at the same quality still share one material.

This is the answer for "higher quality near the rover" and for "this landing site
has a real orbital raster, the rest of the Moon does not."

## When 13 roles are not enough

In order of cost:

1. **Channel-pack.** Almost always the right answer for a scalar.
2. **Add a role.** The set is a conservative choice, not a hardware wall. A new
   role is a change to `TextureLayer` plus a binding in the material; every
   existing shader ignores it unless it declares the binding.
3. **Use a `texture_2d_array`.** One binding, N layers of the same kind and
   format. This converts the budget from per-layer to per-kind.
4. **Virtual texturing or a clipmap.** A fixed physical cache plus an
   indirection table. This is a serious streaming and eviction project; do not
   reach for it until the simpler options are exhausted.

Thirteen sampled roles remain within the portable sixteen-texture limit. Check the
actual binding budget before adding a role that must run on every target.

## Do not bake overlays into a texture

Bake the **data**. Derive the **view**.

Normals, heights, and DEM-derived slope are expensive and do not change when a
user drags a slider: bake them. Hazard colours, traversability bands, and
science-zone tints are views: derive them in the shader from a data layer, gated
by uniforms.

Baking an overlay makes a slider drag a multi-second re-bake of every resident
tile. It also freezes a presentation choice into the data, so the same raster
cannot be re-interpreted for a different analysis.

## Related sections

- [Parameters](parameters.md) — the uniform half of the contract
- [USD materials](usd-materials.md) — how texture inputs are authored
- [Terrain](terrain.md) — the layered terrain material
- [Quality](quality.md) — renderer budgets and per-tile quality
