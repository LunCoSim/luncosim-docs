---
title: Glossary
chapter: 1
section: 9
---

# Glossary

This glossary defines the terms as they are used in this document. Where a
term has a broader meaning in another standard, the definition here is the
LunCoSim-specific one.

## A–C

**Asset address.** A logical URI that names bytes managed by the asset system.
`lunco://` addresses the installed engine library; `twin://` addresses a file
inside the open Twin. Authored files should not use physical cache paths.

**Authority.** The right to write a control input or structural fact. Selection
is not authority. A session must claim an endpoint before its input reaches it.

**Avian.** The rigid-body physics engine used by the LunCoSim runtime. Avian
integrates bodies and joints; it is not where a particular rover or mission is
authored.

**Build.** The perspective used to compose the live scene from assemblies and
entities. It edits the running world, not an isolated document.

**Communication point.** A simulation time at which Modelica participants
exchange inputs and outputs. Values are held between communication points.

**Composition arc.** A USD relationship that combines layers or prims:
subLayers, references, payloads, inherits, specializes, and variants.

**Connection.** An authored USD relationship that carries a value from an
`outputs:` property to an `inputs:` property. The runtime derives a
`SimConnection` from it.

**Cosimulation.** Running two or more participants together on a shared clock,
exchanging values at communication points. LunCoSim uses the term for the
Modelica-to-physics loop and for the broader participant fabric.

## D–H

**Default prim.** The root prim a USD stage declares as its reference target.
LunCoSim uses it as a stable root for composition and projection.

**Dock panel.** A workbench panel placed in a dock rectangle. Runtime UI
surfaces can align to a dock panel but do not own the dock tree.

**Editor.** The perspective that opens one explicit USD document in an
isolated preview. Saving and undo apply to that document, not to the live
scene.

**Entity.** A runtime object projected from the composed scene. An entity has a
stable identity, a name, components, and possibly ports. The entity tree is a
runtime view, not the authored prim hierarchy.

**Exposure.** A typed, named snapshot published by an engine producer for
presentation consumers. Runtime UI templates and API readers consume
exposures; they do not query ECS state directly.

**Fixed step.** A simulation update at a deterministic interval. The task
kernel, physics, and realtime-safe Modelica programs advance on fixed steps.

**FMU.** A Functional Mock-up Unit packaged for FMI. LunCoSim can import FMI
3.0 Co-Simulation FMUs with scalar `Float64` ports on desktop builds.

**glTF.** An external mesh and scene format. A `.gltf` or `.glb` file is
referenced from a USD payload or reference and loaded by the glTF importer; it
is not a USD layer.

**HUD.** A heads-up display surface over the viewport. LunCoSim has both
workbench HUDs (graphs, performance, input overlay) and authored runtime
surfaces (rover, camera, terrain progress).

## I–M

**Input hold.** A live value written to a port by a session. It overrides the
authored source until released. `SetPorts` creates a hold; `ReleasePort` and
`ReleaseControl` remove it.

**Lunica.** The Modelica perspective and workbench. It provides the model
browser, diagram, text editor, compile and run controls, plots, and
experiments.

**Manifest.** `twin.toml`, the file that makes a folder a Twin. It declares
the project identity, entry scene, source roots, and settings.

**Modelica participant.** A compiled Modelica class admitted into the running
simulation. It has typed inputs and outputs and advances at communication
points.

**Modelica source root.** A directory declared in `[modelica].paths` where the
compiler looks for `.mo` sources.

## N–R

**OpenUSD.** The scene description and composition standard used for the
world. LunCoSim uses standard USD physics schemas and a small set of LunCoSim
schema extensions.

**Perspective.** A task layout over the same Twin. The five main layouts are
View, Build, Analyze, Editor, and Lunica.

**Port.** A typed scalar input or output at a component boundary. A port has a
name, direction, kind, and owner. Ports are the vocabulary of the connection
fabric.

**Prim.** A node in a USD stage. A prim can carry schemas, attributes,
relationships, and children.

**Program.** A Modelica model or Rhai scenario attached to a prim through
`LunCoProgramAPI`. The program is a child prim, so deleting the prim removes
the behavior.

**Projection.** The runtime process that turns a composed USD stage into live
entities, components, physics bodies, and renderable objects.

**Realtime-safe.** A declaration (`lunco:program:realtimeSafe = true`) that a
program may drive force or torque ports on a client-predicted body. It is a
promise that the program is fixed-step deterministic, not a quality rating.

**Rhai.** The embedded scripting language used for scenario policy, tutorial
flow, and authored tests.

**Rumoca.** The Modelica compiler and runtime used by LunCoSim. It parses,
type-checks, compiles, and integrates the authored models.

## S–Z

**Scene test.** A headless, deterministic run of an authored Rhai observer
against a scene. The exit code is the verdict: `0` pass, `1` fail, `2` no
verdict.

**Shader look.** A material intent that names a WESL source, parameter values,
and texture layers. It is projected from an authored USD material or created
by a tool.

**SimConnection.** The runtime representation of an authored USD connection.
It carries a typed value from a producer to a consumer at a communication
point.

**Stage.** A composed USD scene. The stage is inert until the runtime projects
it.

**SysML v2.** The textual systems-modeling language used for requirements,
logical structure, typed values, and verification links. LunCoSim supports a
bounded profile; see [SysML v2](../sysml/index.md).

**Texture layer.** A named raster role a shader can sample: Height, Albedo,
Mineral, Surface, Normal, ShadowCache, and related roles. Texture slots are
the scarce resource; scalar layers should usually share a packed channel.

**Twin.** A project folder containing `twin.toml`. It is the unit of saving,
versioning, sharing, and opening.

**Typed command.** A write operation with a reflected name and validated
parameters. The UI, Rhai, and HTTP API use the same command surface.

**Typed query.** A read operation with a reflected name and typed result. A
missing value is not silently replaced with zero.

**USD.** See OpenUSD.

**Verdict.** The typed result a test scenario publishes. A test that ends
without a verdict is not a pass.

**WESL.** The shader source language used for LunCoSim materials. A WESL
material declares its parameters in a `struct Material` block.

**World hold.** A runtime state in which simulation advancement is paused
because required preparation is incomplete. A world hold is not a slow world.

## Related sections

- [Formats](formats.md) — the authored layers in detail
- [How it fits together](how-it-fits-together.md) — the runtime flow
- [Reference](../reference/index.md) — manifests, commands, and file formats
