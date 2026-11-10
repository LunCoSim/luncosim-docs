---
title: Parameters
chapter: 6
section: 1
---

# Parameters

A dynamic shader declares its own material parameters. The engine reads the
layout out of the WESL source, so no parameter names, ranges, or defaults are
hardcoded in Rust. Adding a parameter means editing a `.wesl` file. It never
means editing the renderer.

## The material block

A shader declares a struct named exactly `Material` at
`@group(2) @binding(0)`:

```wgsl
//!@ui      dust_density 0 1      "Dust density"
//!@default dust_density 0.35
//!@ui      clump_scale  0 64     "Clump scale (/m)"
//!@default clump_scale  8
//!@ui      tint         color    "Tint"
//!@default tint         0.6,0.6,0.62,1.0
//!@engine  sun_dir
//!@default sun_dir      0,1,0

struct Material {
    dust_density: f32,
    clump_scale: f32,
    tint: vec4<f32>,
    sun_dir: vec3<f32>,
}

@group(2) @binding(0) var<uniform> material: Material;
```

The struct field order and WESL types define the layout. The annotations are
metadata for the Inspector and the runtime; they do not change the GPU layout.

## Annotation vocabulary

Annotations are `//!@` comments outside the struct, one per field:

| Annotation | Form | Meaning |
|---|---|---|
| `//!@ui` | `name min max "Label"` | Floating-point slider bounds and label |
| `//!@ui` | `name color "Label"` | Color picker |
| `//!@ui` | `name int min max "Label"` | Integer field bounds |
| `//!@default` | `name value` | Value used when the author sets none |
| `//!@engine` | `name` | Field is filled by the engine, not authored |
| `//!@interface` | `identifier` | Shader ABI identifier, such as a continuation contract |
| `//!@capability` | `identifier` | Optional shader feature declaration |

A field with no `//!@ui` annotation gets a default presentation from its type:
`f32` becomes a `0..1` slider, integer types become `0..32`, `vec3`/`vec4`
become a color picker, and `vec2` is free-form.

`//!@engine` is a statement of ownership, not a hidden default. A field marked
engine-filled is written by the runtime; authoring it from USD would fight the
engine writer.

## Supported types and layout

| WESL type | Size | Alignment | Rhai/USD shape |
|---|---|---|---|
| `f32` | 4 | 4 | Number |
| `i32` | 4 | 4 | Integer |
| `u32` | 4 | 4 | Unsigned integer |
| `vec2<f32>` | 8 | 8 | Two-number array |
| `vec3<f32>` | 12 | 16 | Three-number array |
| `vec4<f32>` | 16 | 16 | Four-number array or color |

Offsets follow std140 / WESL uniform rules: a field starts at the next multiple
of its alignment, and the total size is rounded up to 16 bytes. A `vec3` occupies
12 bytes but aligns to 16.

The packed block is **512 bytes**, or 32 `vec4` lanes. A struct that reflects
past that size logs a warning and clips the extra fields. Split a large material
into a smaller parameter set or move data into a texture instead of relying on
clipping.

A type outside the supported set prevents the struct from reflecting as a
parameter schema. Keep the block to the scalar and vector types above.

## Packing and naming

Values are stored by name and packed at their reflected offsets. A name that is
not in the schema is dropped at pack time with a warning; it is never silently
mis-packed into a neighbouring field.

Parameter spelling is normalized by the shared `to_snake_case` rule used by USD
projection, live authoring, and the render binder. Runtime ports use the exact
keys published by `ListPorts`; geometry connections and commands must use those
WESL keys so wiring, holds, and admission retain one input identity.

A USD-backed parameter edit belongs to the bound `Shader` prim's
`inputs:<name>` attribute:

```usda
float inputs:dust_density = 0.35
float inputs:clump_scale = 8.0
color4f inputs:tint = (0.6, 0.6, 0.62, 1.0)
```

The editor and `SetObjectProperty` follow the composed `material:binding`
network, use the composed `typeName` without collapsing roles or array shape,
validate the USDA literal, and author a typed `UsdOp`.

## Defaults

`//!@default` supplies the value used when the author does not set an input. A
default is part of the shader contract, not a renderer fallback. If a parameter
must have a meaningful value, declare a default and document its units in the
label.

A missing default for a field leaves the packed lane at zero. Prefer an explicit
default for every authored parameter; a zero that means "off" is different from
a zero that means "unset".

## Vertex stages share the ABI

An optional vertex shader is a second stage of the same material, not a second
parameter block. Both stages read `@binding(0)` from the one 512-byte block. The
fragment stage's reflected schema is the layout that gets packed, so the vertex
stage must declare the same `Material` fields, order, and WESL types.

```wgsl
// terrain_geomorph.wesl — vertex-only stage
struct Material {
    // Same fields, order, and types as terrain_layered.wesl.
    // ...
}
```

The terrain pair (`terrain_layered.wesl` plus `terrain_geomorph.wesl`) uses one
canonical fragment layout and a vertex-only geomorph stage. A cross-shader
contract test guards the required ABI at that boundary.

A portable material can keep both entry points in one source asset and use that
same asset for both projected stages.

## Engine-filled fields

Terrain materials expose fields the runtime fills every frame:

| Field family | Filled from |
|---|---|
| `sun_dir`, `sun_dir_world`, `sun_tan_radius` | Active sun and body frame |
| `hf_size`, `hf_res` | Shadow heightfield extent and resolution |
| `csm_far`, `shadow_cache_on`, `horizon_march_steps` | Shadow configuration |
| `morph_start`, `morph_end`, `stitch_edges` | CDLOD morph and edge stitching |
| `site_*` | Site-local continuation and photometry facts |
| `map_texel_size_m`, `derived_*_on`, `authored_*_on` | Active map and source state |

Mark these with `//!@engine` so the Inspector does not present them as editable
authoring knobs.

## Live parameters

A `ShaderLook` carries an open set of parameter values. Identical looks share
one material; the binder caches by a key that quantises floats to `1e-4`.

A parameter that is globally uniform and continuously tuned can be excluded from
the material identity so changing it reuses the same material and writes the new
value in place. This is appropriate only when every look that could share the
material carries the same value, such as a global overlay slider. A per-entity
value belongs in the ordinary parameter set.

## Related sections

- [Texture layers](texture-layers.md) — the raster half of the contract
- [USD materials](usd-materials.md) — how inputs are authored
- [Terrain](terrain.md) — a large real parameter block
- [Authoring](authoring.md) — validate and inspect a parameter schema
