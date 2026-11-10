---
title: Author a shader
chapter: 2
section: 6
---

# Author a shader

A shader look is authored as data: a WESL source asset declares its material
parameters, and a USD material binds the source and its texture inputs. The
renderer reflects the parameter schema and builds the pipeline; Rust does not
hardcode the parameter set.

This tutorial adds a simple surface look to a prim and exposes one parameter in
the Inspector. It assumes a Twin with a scene and a basic USD material.

## Create the WESL source

Add a source asset under the Twin:

```text
my-rover-twin/
└── shaders/
    └── dusty_surface.wesl
```

A material declares its parameters in a `struct Material` block:

```wgsl
//!@ui      dust_density 0 1      "Dust density"
//!@default dust_density 0.35
//!@ui      clump_scale  0 64     "Clump scale (/m)"
//!@default clump_scale  8
//!@ui      tint         color    "Tint"
//!@default tint         0.6,0.6,0.62,1.0

struct Material {
    dust_density: f32,
    clump_scale: f32,
    tint: vec4<f32>,
};

@group(2) @binding(0) var<uniform> material: Material;
```

The `//!@` annotations are the authoring contract:

| Annotation | Meaning |
|---|---|
| `//!@ui name min max "Label"` | The slider bounds and label the Inspector uses |
| `//!@ui name color "Label"` | A color picker |
| `//!@ui name int min max "Label"` | Integer bounds |
| `//!@default name value` | The value used when the author does not set one |
| `//!@engine name` | A field filled by the runtime |

The uniform block is deliberately opaque. The same 512 bytes are reinterpreted
by each shader through its own `struct Material`. A name that is not in the
schema is dropped at pack time with a warning; it is never silently mis-packed
into a neighbouring field.

A linked vertex stage shares the same material ABI. Both stages read
`@binding(0)` from the one 512-byte block, and the fragment stage's reflected
schema is the layout that gets packed. A vertex shader must declare the same
`Material` fields, order, and WESL types as its fragment shader.

## Add a texture layer (optional)

A shader can sample named texture roles. The authorable roles are:

| Role | Content |
|---|---|
| `Albedo` | Colour raster, such as a lunar mosaic |
| `Mineral` | Class-id or composition raster, tinted through a palette LUT |
| `Surface` | Packed scalars: R roughness, G ambient occlusion, B rock density, A hazard |
| `Normal` | Tangent- or world-space normals |
| `DetailAlbedo` | Repeatable colour detail |
| `DetailNormal` | Repeatable tangent-space normal detail |
| `DetailSurface` | Repeatable packed roughness and AO |
| `Displacement` | Authored scalar displacement |

`Height` and `ShadowCache` are engine-filled and not authorable from USD.
Continuation and annotation roles are runtime-owned. See
[Texture layers](../shaders/texture-layers.md) for the full role list and
channel-packing rules.

A shader that does not declare a binding is unaffected by that layer being set.
This is why one slot set serves every shader; a new look does not create a new
material type.

Scalar layers should usually share a packed channel rather than consume a new
texture slot. `Surface` is the reference example: four independent scalar
layers in one texture fetch.

## Bind the source in USD

A USD material names the shader source with the standard `UsdShade` selector
and the LunCoSim WESL properties:

```usda
def Material "DustyMaterial"
{
    token outputs:surface.connect = </World/Looks/DustyMaterial/Shader.outputs:surface>

    def Shader "Shader"
    {
        uniform token info:implementationSource = "sourceAsset"
        uniform asset info:wesl:sourceAsset = @twin://my-rover-twin/shaders/dusty_surface.wesl@

        float inputs:dust_density = 0.35
        float inputs:clump_scale = 8.0
        color4f inputs:tint = (0.62, 0.62, 0.64, 1.0)
    }
}
```

`info:implementationSource = "sourceAsset"` is the standard `UsdShade`
selector. `info:wesl:sourceAsset` follows the standard source-type convention.
An optional `info:wesl:vertexAsset` names a second stage when the default mesh
vertex stage is not sufficient:

```usda
uniform asset info:wesl:vertexAsset = @twin://my-rover-twin/shaders/dusty_surface_vertex.wesl@
```

A portable material can keep both entry points in one source asset and use that
same asset for both projected stages.

## Bind the material to a prim

Bind the material through the standard `material:binding` relationship:

```usda
def Xform "Rover"
{
    rel material:binding = </World/Looks/DustyMaterial>
}
```

The editor and `SetObjectProperty` follow the composed binding network. A
parameter edit authors a typed `UsdOp` on the bound `UsdShade.Shader` prim's
`inputs:<name>` attribute. Geometry `primvars:` are reserved for standard
`UsdGeom` primvars such as `primvars:displayColor`; they are not a generic
shader-parameter namespace.

## Reload and inspect

The native desktop asset watcher reloads a changed `.wesl` source without
relaunching the application. The render binder waits for prepared sources and
refreshes affected looks on asset events.

To inspect the result:

1. Select the prim in **Build** or **Editor**.
2. Open the **Inspector**.
3. Find the material parameters. The slider bounds and labels come from the
   reflected schema, not from a hand-written list.
4. Change a value and observe the viewport.

If the shader fails to compile, the owning material is rejected and a
structured runtime diagnostic is published. The renderer does not substitute a
`StandardMaterial` or a guessed shader. Fix the source and reload; do not hide
the error by changing the material to a different one.

## Validate before running

```bash
luncosim --validate path/to/my-rover-twin/shaders/dusty_surface.wesl
```

`--validate` checks source syntax and material facts. It is preflight evidence,
not a GPU compile. The renderer still owns pipeline specialization and GPU
validation. A graphics gate must reject shader compilation errors in the
process log as well as domain runtime diagnostics.

## Keep the look shared

Identical looks share one material and one bind group. The binder caches by the
look key, which quantises floats so a rounding error cannot mint a second
material.

Vary a parameter per instance and you get a material per instance: a draw call
and a bind group each. If instances must differ, bucket the value first — snap
it to a small set — rather than giving every instance a unique float.

## Common problems

| Symptom | Cause | Fix |
|---|---|---|
| The material is rejected | The source has no callable fragment entry point | Declare `@fragment` or correct the source role |
| A parameter is missing from the Inspector | It is not in `struct Material` or has no reflected type | Add the field and its annotation |
| A parameter change does nothing | The value is not bound to the authored shader input | Author `inputs:<name>` on the bound Shader prim |
| The shader compiles but looks wrong | A texture role is missing or mis-bound | Check the material's texture inputs and the role |
| Two instances create many materials | A per-instance float varies the look key | Bucket the value or share the look |
| The vertex stage fails | Its `Material` layout differs from the fragment stage | Use the same fields, order, and types |

## Related sections

- [Shaders](../shaders/index.md) — the shader system overview
- [Parameters](../shaders/parameters.md) — the reflected schema
- [Texture layers](../shaders/texture-layers.md) — the named roles
- [USD materials](../shaders/usd-materials.md) — the binding contract
- [Quality](../shaders/quality.md) — renderer budgets
