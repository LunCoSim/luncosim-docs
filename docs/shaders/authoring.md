---
title: Authoring
chapter: 7
section: 6
---

# Authoring

A shader look is authored in two files: a WESL source and a USD material. The
source declares the parameter block and texture bindings; the material selects
the source and authors the inputs. The runtime reflects the rest.

## Create the source

Put the source inside the Twin when it belongs to the Twin:

```text
my-rover-twin/
└── shaders/
    └── dusty_surface.wesl
```

Use `@twin://my-rover-twin/shaders/dusty_surface.wesl@` to address it. A source
shipped with the engine uses `@lunco://shaders/...@`.

A minimal fragment source:

```wgsl
//!@ui      dust_density 0 1      "Dust density"
//!@default dust_density 0.35
//!@ui      clump_scale  0 64     "Clump scale (/m)"
//!@default clump_scale  8
//!@ui      tint         color    "Tint"
//!@default tint         0.62,0.62,0.64,1.0

struct Material {
    dust_density: f32,
    clump_scale: f32,
    tint: vec4<f32>,
}

@group(2) @binding(0) var<uniform> material: Material;

@fragment
fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    // Sample the base colour and apply the authored parameters.
    // ...
}
```

The exact imports and entry-point signature depend on the Bevy/WESL pipeline
you are extending. Copy the structure of a shipped shader that already targets
the pass you need.

## Declare the contract

Every field must use a supported type and be reflected in `struct Material`:

- `f32`, `i32`, `u32`, `vec2<f32>`, `vec3<f32>`, `vec4<f32>`
- std140 alignment, total block at most 512 bytes
- `@group(2) @binding(0)` for the material uniform
- `//!@ui` for the Inspector presentation
- `//!@default` for the authored default
- `//!@engine` for runtime-filled fields

A name that is not in the schema is dropped at pack time with a warning. A
struct that exceeds 512 bytes is clipped with a warning. Both are authoring
errors in practice, not silent feature extensions.

If the shader needs a second stage, declare the same `Material` fields, order,
and types in the vertex source. Both stages read the same block; the fragment
schema is the layout that gets packed.

## Bind the source in USD

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

Add `info:wesl:vertexAsset` only when the default mesh vertex stage is not
sufficient. Add `info:wesl:interface` only when the shader declares a named ABI
such as the lunar-surface continuation contract.

Texture inputs are asset-typed properties:

```usda
asset inputs:albedo_map = @twin://my-rover-twin/terrain/albedo.png@
asset inputs:normal_map = @twin://my-rover-twin/terrain/normals.png@
```

## Bind the material

```usda
def Xform "Rover" (
    prepend apiSchemas = ["MaterialBindingAPI"]
)
{
    rel material:binding = </World/Looks/DustyMaterial>
}
```

The editor and `SetObjectProperty` follow the composed binding network. A
parameter edit authors a typed `UsdOp` on the bound `UsdShade.Shader` prim's
`inputs:<name>` attribute.

Use `material:binding:physics` for a physics-purpose material. A purpose-specific
binding wins over the all-purpose binding for that purpose.

## Validate before running

```bash
luncosim --validate path/to/my-rover-twin/shaders/dusty_surface.wesl
```

`--validate` checks source syntax and material facts. It is preflight evidence,
not a GPU compile. The renderer still owns pipeline specialization and GPU
validation.

A graphics gate must reject shader compilation errors in the process log as
well as domain runtime diagnostics. A captured image can retain stale pixels
after a failed submission, so an image alone is not proof that the shader
compiled.

## Reload and inspect

The native desktop asset watcher reloads a changed `.wesl` source without
relaunching the application. The render binder waits for prepared sources and
refreshes affected looks on asset events.

To inspect the result:

1. Select the prim in **Build** or **Editor**.
2. Open the **Inspector**.
3. Find the material parameters. Slider bounds and labels come from the
   reflected schema, not a hand-written list.
4. Change a value and observe the viewport.

If the shader fails to compile, the owning material is rejected and a structured
runtime diagnostic is published. Fix the source and reload; do not hide the
error by switching to a different material.

## Keep the look shared

Identical looks share one material and one bind group. The binder caches by the
look key, which quantises floats so a rounding error cannot mint a second
material.

Vary a parameter per instance and you get a material per instance. If instances
must differ, bucket the value first. For per-place texture quality, give tiles
different rasters rather than a different scalar for every tile.

## Common problems

| Symptom | Cause | Fix |
|---|---|---|
| Material rejected | No callable fragment entry point | Declare `@fragment` or correct the source role |
| Vertex stage fails | Its `Material` layout differs from the fragment stage | Use the same fields, order, and types |
| Parameter missing from Inspector | Field is not in `Material` or has an unsupported type | Add the field with a supported type and annotation |
| Parameter change does nothing | Input name does not match the reflected field | Author `inputs:<name>` with the canonical snake-case name |
| Parameter silently ignored | Name is not in the schema | Check the struct and the pack warning |
| Shader compiles but looks wrong | Texture role missing or mis-bound | Check the material's texture inputs and the role |
| Two instances create many materials | A per-instance float varies the look key | Bucket the value or share the look |
| Overlay drag causes a stall | An overlay was baked into a texture | Derive the view in the shader from a data layer |

## Rules of thumb

- Use one `Material` per appearance, not one per prim.
- Prefer `sourceAsset` over inline shader text.
- Declare every parameter in the `Material` block; do not rely on undeclared
  uniforms.
- Mark engine-filled fields with `//!@engine`.
- Pack scalar layers into channels before adding a texture role.
- Keep the vertex ABI identical to the fragment ABI.
- Treat a rejected material as an authoring error, not as a reason to add a
  fallback.
- Validate syntax, then verify the GPU pipeline in a graphics gate.

## Related sections

- [Parameters](parameters.md) — the annotation and layout contract
- [Texture layers](texture-layers.md) — the role list
- [USD materials](usd-materials.md) — the binding contract
- [Author a shader](../tutorials/author-a-shader.md) — a guided build
