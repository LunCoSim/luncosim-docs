---
title: Formats
chapter: 1
section: 3
---

# Formats

LunCoSim uses four core authored formats, one optional requirements format, and
one external asset format. Each format has a different job, a different editing
tool, and a different runtime consumer. Understanding the division is more
important than memorizing the syntax of any one of them.

## The authored formats

| Format | File types | Owns | Edited in |
|---|---|---|---|
| **USD** | `.usda`, `.usdc` | Hierarchy, transforms, geometry, materials, physics, typed ports, connections, program attachments | **Build**, **Editor**, or an external USD tool |
| **Modelica** | `.mo` | Continuous equations, state, parameters, acausal connectors | **Lunica** or an external Modelica editor |
| **Rhai** | `.rhai` | Events, commands, tasks, objectives, tutorial flow, test verdicts | A text editor, the Rhai editor, or the REPL |
| **TOML** | `twin.toml`, `Assets.toml` | Project identity, entry scene, source roots, settings, external asset declarations | A text editor or the Twin settings panel |
| **SysML** | `.sysml`, `.kerml` | Requirements, structure, and verification mappings | A text editor; support is bounded |

The first four are the core. SysML is optional and is described in
[Validation](../reference/validation.md) and
[Integrate your stack](integrate-your-stack.md).

## The external asset format

glTF carries mesh geometry, materials, and a node hierarchy produced by a
content tool. It is not a USD layer: USD composition does not parse `.gltf` or
`.glb`. A USD prim points at the file with a `payload` or `reference` arc, and
the renderer imports that file through the glTF loader.

| Format | File types | Owns | Produced in |
|---|---|---|---|
| **glTF** | `.gltf`, `.glb` | Mesh geometry, materials, node hierarchy | Blender or another content tool |

The default `lunco:assetMode = "scene"` attaches the whole glTF scene and keeps
its hierarchy, materials, and lights. `lunco:assetMode = "mesh"` attaches one
mesh primitive as `Mesh3d`, which a mesh collider can consume.
`lunco:assetLabel` selects a named sub-asset. See
[Addresses and assets](../usd/addresses-and-assets.md#gltf-payloads).

## Ownership in detail

### USD owns the world

A USD stage describes what exists and where it is. It contains the prim
hierarchy, the transforms that place parts, the geometry that is rendered and
collided, the materials that shade it, the physics schemas that make it move,
and the typed `inputs:` and `outputs:` properties that connect it to other
components.

USD does not contain the equations that decide how a motor responds to a
throttle command. It may contain a reference to a Modelica source, but the
source itself is a separate file. USD also does not decide when a mission is
complete; that is Rhai policy.

### Modelica owns continuous behavior

A `.mo` file contains classes, equations, parameters, and connectors. The
solver advances the equations over time. Modelica is the right place for a
motor curve, a battery model, a thermal network, a control law, or a fluid
system.

Modelica does not traverse the scene, find prims by name, or react to a
keypress. It exposes inputs and outputs; the USD wiring decides what those
values connect to, and Rhai decides when a mission phase changes.

### Rhai owns discrete policy

A `.rhai` file is a program attached to an entity. It observes the simulation,
reacts to events, issues typed commands, advances a task tree, and publishes
objectives or verdicts. It is the right place for a waypoint sequence, a
tutorial step, an authority handoff, or a test assertion.

Rhai does not integrate physics or replace a controller. A per-tick script
loop that reimplements a solver duplicates the runtime and makes the scenario
less deterministic.

### TOML owns configuration

`twin.toml` identifies the project, selects the default scene, declares the
Modelica and SysML source roots, and stores project settings. `Assets.toml`
declares external bytes such as libraries, rasters, textures, and fonts.

TOML does not contain geometry or equations. It is a manifest, not a scene
file and not a cache. The actual downloaded bytes live in a cache addressed
through logical URIs.

## How a change travels

A typical edit crosses several layers. Consider changing the rover's drive
behavior:

1. The author edits `Drive.mo` in **Lunica** and compiles it.
2. The Twin's `[modelica].paths` makes the source discoverable.
3. A USD program prim names the source with `info:sourceAsset`.
4. The component's `outputs:` properties expose the values other components
   may consume.
5. A connection on the consuming prim names the source port.
6. The runtime admits the participant, samples outputs at communication
   points, and applies the resulting forces.
7. Rhai observes the motion and decides whether the mission objective is met.

At no point does the author copy the motor equation into USD or the waypoint
list into Modelica. Each file keeps its own fact.

## Choosing the right format

Use the following questions as a guide:

| Question | Format |
|---|---|
| Where is the part, how is it shaped, and how is it attached? | USD |
| Which mesh or scene did a content tool export? | glTF, referenced from USD |
| What equations govern its continuous behavior? | Modelica |
| What should happen when a condition becomes true? | Rhai |
| Which scene opens, and where are the sources? | `twin.toml` |
| Where does the terrain raster or library come from? | `Assets.toml` |
| Which requirement does this test verify? | SysML plus a Twin verification mapping |

If a fact seems to belong in two places, the usual answer is that one place
owns the data and the other owns a reference to it. A USD connection owns the
wire; the Modelica class owns the equation that produces the value. A Rhai
scenario owns the mission decision; USD owns the marker prim the decision
refers to.

## Portability

The domain files remain in their standard syntax. A `.mo` file can be opened
in another Modelica tool, a `.usda` file can be opened in another USD
application, and a `.gltf` or `.glb` file can be opened in any glTF viewer.
LunCoSim-specific behavior is carried in:

- `LunCoProgramAPI` and related program attributes;
- typed `inputs:` / `outputs:` properties and USD connections;
- `lunco://` and `twin://` asset addresses;
- the `twin.toml` manifest and its settings table;
- LunCoSim schema extensions such as `lunco:suspension:restLength`.

A file that uses these extensions is still a valid file in its base format,
but another tool will not interpret the extensions. That is expected: the
extensions are the workbench's contract, not a replacement for the standard.

## What not to do

- Do not encode equations in USD attributes.
- Do not put mission decisions or timers in Modelica.
- Do not integrate physics in Rhai.
- Do not treat a `.gltf` or `.glb` file as a USD layer; reference it from USD
  and let the renderer import it.
- Do not hardcode a cache path in a USD layer; use `lunco://` or `twin://`.
- Do not add a Rust special case for a particular rover, lesson, or asset.
- Do not hand-edit generated or cached assets; author the source and let the
  pipeline produce the result.

## Related sections

- [How it fits together](how-it-fits-together.md) — the runtime flow
- [USD](../usd/index.md) — the scene and topology
- [Addresses and assets](../usd/addresses-and-assets.md#gltf-payloads) — glTF payloads and binary arcs
- [Modelica](../modelica/index.md) — continuous behavior
- [Rhai](../rhai/index.md) — scenario policy
- [twin.toml](../reference/twin-toml.md) — the project manifest
- [Assets.toml](../reference/assets-toml.md) — external assets
