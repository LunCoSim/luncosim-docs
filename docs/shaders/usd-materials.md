---
title: USD materials
chapter: 7
section: 3
---

# USD materials

A material is the authored answer to "what does this surface look like?" The
renderer does not choose a shader by prim name or folder. A `UsdShade` network
selects a WESL source, the source declares its parameters, and the runtime
projects that into a `ShaderLook`.

## The network

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

Bind it to a prim:

```usda
def Mesh "Hull" (
    prepend apiSchemas = ["MaterialBindingAPI"]
)
{
    rel material:binding = </World/Looks/DustyMaterial>
}
```

| Element | Meaning |
|---|---|
| `Material` | The bindable material prim |
| `outputs:surface` | The material's surface terminal |
| `Shader` | A source-backed shader node |
| `info:implementationSource` | Selects a source asset rather than inline text |
| `info:wesl:sourceAsset` | The WESL fragment stage |
| `info:wesl:vertexAsset` | Optional WESL vertex stage |
| `info:wesl:interface` | Optional declared shader ABI |
| `inputs:<name>` | Authored parameter or texture input |
| `material:binding` | The all-purpose visual binding |

## Source selection

`info:implementationSource = "sourceAsset"` is the standard `UsdShade` selector.
`info:wesl:sourceAsset` follows the standard source-type convention;
`vertexAsset` is a LunCo renderer extension because `UsdShade` has no second
stage selector.

A source used as `sourceAsset` must declare a callable `@fragment` entry point.
An optional `vertexAsset` must declare a callable `@vertex` entry point. One
module may declare both and is valid for either role.

A portable material can keep both entry points in one source asset and use that
same asset for both projected stages. The terrain pair uses separate files:

```usda
uniform token info:implementationSource = "sourceAsset"
uniform asset info:wesl:sourceAsset = @lunco://shaders/terrain_layered.wesl@
uniform asset info:wesl:vertexAsset = @lunco://shaders/terrain_geomorph.wesl@
```

The render binder validates the requested stage after the asset loads. An
invalid contract rejects the owning material and publishes a structured
`RuntimeDiagnostics` error. Rust does not substitute `StandardMaterial`, a
guessed terrain shader, or another guessed source.

## Interface declaration

A shader may declare an ABI identifier:

```wgsl
//!@interface lunco.lunar-surface-continuation.v1
```

The USD Shader prim authors the same identifier:

```usda
uniform token info:wesl:interface = "lunco.lunar-surface-continuation.v1"
```

This is validation metadata. It names a shader ABI, never a shader asset; the
asset path remains wholly selected by the composed `UsdShade` binding. The
identifier does not change GPU material identity.

## Parameter inputs

A USD-backed parameter edit belongs to the bound `Shader` prim's
`inputs:<name>` attribute. The editor and `SetObjectProperty` share the
bound-Shader resolver: it follows the composed `material:binding` network, uses
the composed `typeName` without collapsing USD roles or array shape, validates
the USDA literal, and authors a typed `UsdOp`.

The input name must match the WESL field after the shared snake-case
normalization. A name that is not in the reflected schema is dropped at pack time
with a warning; it is never silently mis-packed into a neighbouring field.

Geometry `primvars:` are reserved for standard `UsdGeom` primvars such as
`primvars:displayColor`. They are not a generic shader-parameter namespace.

## Texture inputs

Texture inputs are asset-typed `inputs:` properties:

```usda
asset inputs:albedo_map = @twin://terrain/apollo15/albedo.png@
asset inputs:normal_map = @twin://terrain/apollo15/normals.png@
asset inputs:surface_map = @twin://terrain/apollo15/surface.png@
```

The projection maps the authored role to the named `TextureLayer` the shader
declares. The authorable set is `albedo_map`, `mineral_map`, `surface_map`,
`normal_map`, `detail_albedo_map`, `detail_normal_map`, `detail_surface_map`,
and `displacement_map`.

`height_map` and `shadow_cache` are engine-filled and deliberately not
addressable from USD. Continuation and annotation roles are runtime-owned.

A connected input is skipped by the texture reader because it is fed by a
producer node, not by an authored file.

## Binding strength and purpose

`material:binding` is the all-purpose visual binding.
`material:binding:physics` is the physics-purpose binding. A purpose-specific
binding wins over the all-purpose binding for that purpose; the fallback lets a
single material serve both.

Bindings compose through references like any other relationship. An instance can
override the material without editing the referenced asset:

```usda
def Xform "RoverB" (
    prepend references = @lunco://vessels/rovers/skid_rover.usda@
)
{
    over "Chassis" {
        rel material:binding = </Looks/DustyPaint>
    }
}
```

A resolved binding that targets a missing or non-material prim rejects admission
visibly.

## Display color

`primvars:displayColor` is a standard `UsdGeom` primvar, not a shader parameter
namespace. It is appropriate for simple unlit markers, debug geometry, and
assets that must render without a material network.

Route markers are a good example: their unvisited color is authored in
`primvars:displayColor` and `primvars:displayOpacity`, and the generic
`route_follow` policy changes the visited state through the transient view
layer.

## Sharing and caching

Identical looks share one material and one bind group. The binder caches by the
look key, which quantises floats to `1e-4` so a rounding error cannot mint a
second material. Texture handles are part of the key.

Vary a parameter per instance and you get a material per instance. If instances
must differ, bucket the value first. A per-tile terrain look is a deliberate
exception because the tiles genuinely carry different rasters.

## Failure behavior

| Failure | Result |
|---|---|
| Shader source missing | Material rejected, `RuntimeDiagnostics` error |
| No fragment entry point | Material rejected, stage contract error |
| Parameter name not in schema | Dropped with a warning at pack time |
| Binding targets a non-material prim | Admission rejected |
| Malformed authored literal | Typed edit rejected before authoring |
| Unsupported texture format | Asset load fails |
| Declared interface does not match | Continuation or lint error; the material is not silently accepted |

The renderer never repairs a malformed material by guessing. An authored Rhai
policy can observe the diagnostic and choose a replacement; that choice is
visible policy, not a renderer fallback.

## Related sections

- [Materials](../usd/materials.md) — the scene-authoring view
- [Parameters](parameters.md) — the reflected schema
- [Texture layers](texture-layers.md) — the named roles
- [Terrain](terrain.md) — the canonical layered material
