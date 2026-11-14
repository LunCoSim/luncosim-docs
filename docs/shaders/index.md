---
title: Shaders
chapter: 7
---

# Shaders

A shader look in LunCoSim is **data**, not a Rust material type. A WESL source
asset declares a parameter block and, optionally, a set of named texture
layers. A USD material selects that source and authors its inputs. The renderer
reflects the source, packs the parameters, binds the textures, and builds the
pipeline.

This is why a new look is usually a new `.wesl` file and a material network, not
a new engine feature. Rust hardcodes no parameter names, ranges, or defaults.

## The two halves

| | What it is | Where it lives | Capacity |
|---|---|---|---|
| **Parameter** | A scalar or vector uniform the shader reads | One opaque 512-byte uniform block | 128 `f32` scalars or 32 `vec4`s, subject to layout alignment |
| **Texture layer** | A raster the shader samples | A bind-group entry | 13 named roles |

Parameters are cheap and open-ended. Texture slots are the scarce resource. Most
"I need another layer" instincts should be spent on a packed channel before a
new slot.

## The data flow

1. A `UsdShade` network binds a material to a prim.
2. The material's `Shader` prim names a WESL fragment source and, optionally, a
   vertex source.
3. The WESL source declares `struct Material` at `@group(2) @binding(0)` and
   `//!@` annotations.
4. The renderer reflects the struct into a `ParamSchema` and the annotations
   into Inspector metadata.
5. The USD projection publishes a `ShaderLook` with the source paths, parameter
   values, and texture handles.
6. The render binder validates the stage contract, packs the parameter block,
   binds the textures, and caches the material by look key.

A material is rejected visibly if the source is missing, the stage contract is
invalid, or a texture cannot load. Rust does not substitute `StandardMaterial`
or a guessed shader.

## What a shader owns

| Fact | Authored as | Consumed by |
|---|---|---|
| Surface appearance | WESL fragment entry point | Render pipeline |
| Parameter set | `struct Material` and annotations | Reflection and Inspector |
| Texture roles | Declared bindings | Material binder |
| Vertex deformation | Optional WESL vertex entry point | Mesh and shadow passes |
| Material selection | USD `UsdShade` network | USD projection |
| Parameter values | USD `inputs:<name>` | `ShaderLook` |
| Renderer budgets | `RenderingQualitySettings` | All GPU-backed views |

A shader does not own scene composition, physics, mission policy, or the
renderer-wide quality preset.

## Sharing

Identical looks share one material and one bind group. The binder caches by the
look key, which quantises floats so a rounding error cannot mint a second
material. Vary a parameter per instance and you get a material per instance: a
draw call and a bind group each. If instances must differ, bucket the value
first.

Per-tile quality is a natural exception: terrain tiles carry their own look and
texture handles, so a near tile can use a larger albedo than a far tile. Tiles at
the same quality still share a material.

## Reading this chapter

| Section | Question it answers |
|---|---|
| [Parameters](parameters.md) | How does a shader declare and receive its uniforms? |
| [Texture layers](texture-layers.md) | Which named rasters can a shader sample? |
| [USD materials](usd-materials.md) | How does a material bind a source and its inputs? |
| [Terrain](terrain.md) | How does the layered terrain material work? |
| [Quality](quality.md) | Which renderer budgets change with the quality preset? |
| [Authoring](authoring.md) | How do I write, validate, and debug a shader look? |

## Practical rules

- Declare every parameter in `struct Material`; do not rely on undeclared
  uniforms.
- Use `//!@ui`, `//!@default`, and `//!@engine` to make the schema readable.
- Keep the vertex stage's `Material` layout identical to the fragment stage's.
- Pack scalar layers into channels before consuming another texture slot.
- Bind textures and parameters through the composed `UsdShade` network.
- Treat a rejected material as an authoring error, not as a reason to add a
  fallback.
- Measure rendering cost separately from a deterministic recording run.
