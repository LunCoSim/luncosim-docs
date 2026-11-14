---
title: Terrain
chapter: 7
section: 4
---

# Terrain

Terrain is the largest authored shader surface in LunCoSim. It combines measured
DEM geometry, procedural regolith detail, georeferenced raster layers, lunar
photometry, and sun visibility in one material contract. It is not a separate
renderer and it is not one shader per layer.

## The canonical sources

| Path | Role | Contract |
|---|---|---|
| `assets/shaders/terrain_layered.wesl` | Authored DEM fragment | The single canonical DEM material: albedo, layers, DEM relief, filtered detail, lunar photometry, and self-shadow |
| `assets/shaders/terrain_geomorph.wesl` | Optional streamed DEM vertex stage | CDLOD morphing and crack-free edge stitching; no fragment entry point and no second appearance law |
| `assets/shaders/terrain_shadow.wesl` | Explicit non-authored terrain material | Plain authored/display albedo, scene PBR, and heightfield sun visibility |
| `assets/shaders/regolith.wesl` | General mesh material | Ordinary regolith meshes, not a terrain source selection |
| `assets/shaders/terrain_debug.wesl` | Diagnostic material | Analysis and debug views outside the production material contract |

USD selects the fragment source and may select the vertex source on the same
Shader prim. The terrain runtime consumes that projected look; it does not
choose a shader filename.

`terrain_shadow.wesl` may be selected by an authored Rhai or tool policy for a
terrain with no authored material. Rust never installs it to hide a missing or
invalid authored source.

## USD authoring

An authored terrain material uses standard `UsdShade` stage metadata:

```usda
def Material "LunarTerrain"
{
    token outputs:surface.connect = </World/Looks/LunarTerrain/Shader.outputs:surface>

    def Shader "Shader"
    {
        uniform token info:implementationSource = "sourceAsset"
        uniform asset info:wesl:sourceAsset = @lunco://shaders/terrain_layered.wesl@
        uniform asset info:wesl:vertexAsset = @lunco://shaders/terrain_geomorph.wesl@
        uniform token info:wesl:interface = "lunco.lunar-surface-continuation.v1"

        float inputs:weight_albedo = 1.0
        float inputs:weight_normal = 1.0
        float inputs:weight_rough = 1.0
        float inputs:weight_ao = 1.0

        asset inputs:albedo_map = @twin://terrain/apollo15/albedo.png@
        asset inputs:normal_map = @twin://terrain/apollo15/normals.png@
        asset inputs:surface_map = @twin://terrain/apollo15/surface.png@
    }
}
```

`sourceAsset` is the canonical fragment and material contract. `vertexAsset` is
optional: omit it for a static or ordinary mesh vertex path, and use it for
streamed CDLOD geometry. The explicit `SpawnDemTerrain` command is a generic
tool API and requires its caller to provide a look.

## One appearance, two delivery paths

Static and streamed terrain differ only in geometry delivery. A static mesh is
effectively the non-morphing root LOD of the same appearance contract. The
streamed ECS quadtree may still manage residency, colliders, and LOD selection
independently.

Both paths use the same material law, the same layer weights, and the same
distance rules. They must not choose different physical surface laws or
distance-dependent colour and normal rules.

The optional vertex stage runs in the main, depth/normal, and native shadow
passes. It selects Bevy's forward or prepass output interface using
`PREPASS_PIPELINE`; the material group remains bound in depth-only passes so the
same morph uniforms are available. CDLOD distance uses the viewing camera's
origin, shared with its shadow cascades. Edge stitching and morph interpolation
therefore describe the same surface in every pass.

## The layer stack

The procedural regolith is the floor. Even where a layer map is low-resolution
or absent, the rover camera still sees real close-range detail. On top ride
UV-registered raster layers, each blended by a reflected `weight_*` knob:

| Weight | Layer |
|---|---|
| `weight_albedo` | Body-wide colour raster |
| `weight_mineral` | Classification or analysis overlay, composited unlit |
| `weight_rough` | Packed surface roughness |
| `weight_ao` | Packed ambient occlusion |
| `weight_normal` | DEM-derived meso-scale normal |

A `weight_* = 0` layer contributes nothing. Maps are sampled by the planar UV
the horizon bake establishes, under `@if(VERTEX_UVS_A)`; without UVs the
material is procedural.

`Mineral` is composited unlit after lighting and shadowing, so an analysis
overlay stays readable in shadow. It is data, not a material tint.

The packed surface map's G channel is ambient occlusion. Both terrain paths
resolve it through the shared terrain-surface helper and apply it to indirect
diffuse light only. AO is not an albedo term and must not be multiplied into the
authored colour raster or direct sunlight.

## Physical-scale detail

The canonical DEM material can combine georeferenced site rasters with optional
repeatable material scans:

| Input | Role |
|---|---|
| `inputs:detail_albedo_map` | Repeatable colour detail |
| `inputs:detail_normal_map` | Repeatable tangent-space normal detail |
| `inputs:detail_surface_map` | Repeatable packed roughness and AO |

`detail_tile_size_m` defines one repeat in terrain-local metres. Coordinates
remain stable as tiles and the camera move; explicit gradients select mip levels
across wrap boundaries.

Detail normals use +X/-Z tangent axes and perturb the existing DEM or procedural
normal, fading below the resolved pixel footprint. They never replace the DEM
normal map or change height queries and colliders.

Colour detail multiplies the site albedo by scan luminance relative to the
USD-authored `detail_albedo_mean` in linear light. This preserves the site's
broad tone while adding photographed variation. All detail weights default to
zero, so an existing scene does not request detail maps or change appearance.

## DEM-to-globe continuation

A measured DEM covers a site, not the whole body. The exterior smoothing
preserves the first native posting and filters only the continuation in its
preparation worker. Geometry and material fades multiply the two axial weights,
keeping corner diagonals smooth.

The generated collar has two independent scene inputs: the DEM prim supplies the
crop dimensions and local map images, while the celestial body's composed
`UsdShade` binding selects the surface appearance. The collar clones the body's
current `ShaderLook` and adds the DEM material base colour, cropped albedo, and
packed surface images in the dedicated continuation roles.

A body fragment shader that accepts these local roles declares
`//!@interface lunco.lunar-surface-continuation.v1` and authors the same
identifier as `info:wesl:interface`. The required Rhai hook
`terrain.lunar_surface_continuation` receives the declaration and reflected
interface and returns `compose`, `wait`, or `hold`.

This composition is visualization only. It never resamples, blends, edits, or
replaces DEM heights, terrain queries, or colliders.

## Sun visibility

Terrain uses two sun-visibility paths:

- A live horizon ray march against the heightfield.
- A pre-baked `ShadowCache` sampled once in the fragment shader.

The quality preset chooses whether the cache is available and how many march
steps are allowed. `shadow_cache_on` selects the path in the material. The cache
is refreshed when the sun direction changes beyond the configured threshold.

`Height` is a non-filterable `R32Float` world-height raster used by the march.
`ShadowCache` is an `R8Unorm` visibility raster. Neither is authorable from USD;
both are engine-filled by the horizon system.

The High profile's Gaussian shadow filter uses a normal bias scaled by each
cascade's shadow texel size to keep grazing-angle terrain from sampling its own
surface inside the filter footprint.

## Quality and budgets

The renderer-wide quality preset owns terrain LOD and cache budgets, derived-map
resolution, rock budgets, and tessellation. It does not choose the terrain
shader. A scene can keep its authored lunar material while the preset supplies
larger budgets around it.

Per-tile quality is a separate, authored choice: give a near tile a larger
albedo and a far tile a smaller one. The same roles are used; only the images
differ. Tiles at the same quality still share one material.

See [Quality](quality.md) for the preset categories and profiling guidance.

## Related sections

- [Texture layers](texture-layers.md) — the role list and channel packing
- [Parameters](parameters.md) — the shared uniform block
- [USD materials](usd-materials.md) — the binding contract
- [Quality](quality.md) — LOD, shadow, and derived-map budgets
