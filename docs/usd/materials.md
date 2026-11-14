---
title: Materials
chapter: 4
section: 5
---

# Materials

A material is the authored answer to "what does this surface look like?" In
LunCoSim it is also the answer to "how does this surface behave physically?"
Both answers use standard USD material binding, with different purposes.

The renderer does not choose a shader by prim name or folder. A `UsdShade`
network selects a WESL source, the source declares its parameters, and the
runtime projects that into a `ShaderLook`. If the network is invalid, the
material is rejected visibly; Rust does not substitute `StandardMaterial` or a
guessed shader.

## The material network

A minimal authored material:

```usda
def Material "HullPaint"
{
    token outputs:surface.connect = </Looks/HullPaint/Surface.outputs:surface>

    def Shader "Surface"
    {
        uniform token info:implementationSource = "sourceAsset"
        uniform asset info:wesl:sourceAsset = @lunco://shaders/mli_foil.wesl@

        color3f inputs:base_color = (0.72, 0.74, 0.78)
        float inputs:roughness = 0.35
        float inputs:metallic = 0.1
        token outputs:surface
    }
}
```

Bind it to a prim:

```usda
def Mesh "Hull" (
    prepend apiSchemas = ["MaterialBindingAPI"]
)
{
    rel material:binding = </Looks/HullPaint>
}
```

The pieces:

| Element | Meaning |
|---|---|
| `Material` | The bindable material prim |
| `outputs:surface` | The material's surface terminal |
| `Shader` | A source-backed shader node |
| `info:implementationSource` | Selects a source asset rather than an inline implementation |
| `info:wesl:sourceAsset` | The WESL fragment stage |
| `info:wesl:vertexAsset` | Optional WESL vertex stage |
| `inputs:<name>` | Authored parameter or texture input |
| `material:binding` | The all-purpose visual binding |
| `material:binding:physics` | The physics-purpose binding |

## Source-backed shaders

`info:implementationSource = "sourceAsset"` is the standard `UsdShade`
selector. `info:wesl:sourceAsset` follows the standard source-type convention;
`vertexAsset` is a LunCo renderer extension because `UsdShade` has no second
stage selector.

A portable material can keep both entry points in one source asset and use
that same asset for both stages. The terrain pair uses separate files:

```usda
uniform token info:implementationSource = "sourceAsset"
uniform asset info:wesl:sourceAsset = @lunco://shaders/terrain_layered.wesl@
uniform asset info:wesl:vertexAsset = @lunco://shaders/terrain_geomorph.wesl@
```

A source used as `sourceAsset` must declare a callable `@fragment` entry point.
An optional `vertexAsset` must declare a callable `@vertex` entry point. One
module may declare both and is valid for either role.

The render binder validates the requested stage after the asset loads. An
invalid contract rejects the owning material and publishes a structured
`RuntimeDiagnostics` error. An authored Rhai policy may observe that diagnostic
and explicitly author a replacement or stop the scenario; recovery is visible
and overrideable, not hidden in the renderer.

## Parameters

A shader declares its own parameter block. Rust reflects it into a schema at
load time, so adding a parameter means editing a `.wesl` file, never editing
Rust:

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

A USD-backed parameter edit belongs to the bound `Shader` prim's
`inputs:<name>` attribute. The editor and `SetObjectProperty` share the
bound-Shader resolver: it follows the composed `material:binding` network, uses
the composed `typeName` without collapsing USD roles or array shape, validates
the USDA literal, and authors a typed `UsdOp`.

A name that is not in the schema is dropped at pack time with a warning. It is
never silently mis-packed into a neighbouring field.

See [Shader parameters](../shaders/parameters.md) for the annotation language
and the uniform block contract.

## Texture inputs

Texture inputs are asset-typed `inputs:` properties:

```usda
asset inputs:albedo_map = @twin://terrain/apollo15/albedo.png@
asset inputs:normal_map = @twin://terrain/apollo15/normals.png@
asset inputs:surface_map = @twin://terrain/apollo15/surface.png@
```

The projection maps the authored role to the named `TextureLayer` the shader
declares. A shader that does not declare a binding is unaffected by that layer
being set. The same slot set serves every shader.

Rasters used as material data must be produced by the correct asset pipeline.
A grayscale orthophoto is not intrinsic albedo; the `albedo` processor removes
the low-frequency illumination field before encoding the material colour. A
generic `map` output is analysis/display data and must not be bound directly as
`inputs:albedo_map`.

See [Texture layers](../shaders/texture-layers.md) for the role list and the
channel-packing rules.

## Physics materials

Friction and restitution are not bare properties on a body. They are
`UsdPhysicsMaterialAPI` opinions on a `Material` prim, bound through the
physics-purpose relationship:

```usda
def Scope "PhysicsMaterials"
{
    def Material "Regolith" (
        prepend apiSchemas = ["PhysicsMaterialAPI"]
    )
    {
        float physics:dynamicFriction = 1.0
        float physics:staticFriction = 1.0
    }
}

def Cube "Ground" (
    prepend apiSchemas = ["PhysicsCollisionAPI"]
)
{
    rel material:binding:physics = </World/PhysicsMaterials/Regolith>
}
```

Friction comes off the bound material, never off a bare `physics:friction` on
the body prim. That name is not defined by `UsdPhysics`, so no other
physics-aware consumer reads it.

Binding resolution — namespace inheritance and the purpose-to-all-purpose
fallback — is shared with the renderer. One material can drive both look and
friction when it carries both sets of opinions.

## Binding strength and purpose

`material:binding` is the all-purpose visual binding. `material:binding:physics`
is the physics-purpose binding. A purpose-specific binding wins over the
all-purpose binding for that purpose; the fallback lets a single material serve
both.

Bindings compose through references like any other relationship. An instance
can override the material without editing the referenced asset:

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

The binding cache is shared across prim and purpose resolution in an immutable
snapshot. A resolved binding that targets a missing or non-material prim
rejects admission visibly.

## Display color

`primvars:displayColor` is a standard `UsdGeom` primvar, not a shader
parameter namespace. It is appropriate for simple unlit markers, debug
geometry, and assets that must render without a material network. It is not a
generic place to put shader inputs.

Route markers are a good example: their unvisited color is authored in
`primvars:displayColor` and `primvars:displayOpacity`, and the generic
`route_follow` policy changes the visited state through the transient view
layer.

## Failure behavior

| Failure | Result |
|---|---|
| Shader source missing | Material rejected, `RuntimeDiagnostics` error |
| No fragment entry point | Material rejected, stage contract error |
| Parameter name not in schema | Dropped with a warning at pack time |
| Binding targets a non-material prim | Admission rejected |
| Malformed authored literal | Typed edit rejected before authoring |
| Unsupported texture format | Asset load fails |

The renderer never repairs a malformed material by guessing. An authored Rhai
policy can observe the diagnostic and choose a replacement; that choice is
visible policy, not a renderer fallback.

## Rules of thumb

- Use one `Material` per appearance, not one per prim.
- Prefer `sourceAsset` over inline shader text.
- Declare every parameter in the WESL `Material` block; do not rely on
  undeclared uniforms.
- Bind physics friction through `material:binding:physics`.
- Keep display color for markers, not for material parameters.
- Treat a rejected material as an authoring error, not as a reason to add a
  fallback.

Continue with [Addresses and assets](addresses-and-assets.md), which explains
where the referenced files live.
