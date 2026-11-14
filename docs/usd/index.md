---
title: USD
chapter: 4
---

# USD

OpenUSD is LunCoSim's scene and composition format. It describes **what the
world is made of**: hierarchy, transforms, geometry, materials, physics
schemas, and the typed connections between parts. Integration, continuous
equations, and mission policy live in the runtime, Modelica, and Rhai.

The distinction matters because USD is often asked to do too much. A USD stage
can carry a reference to a Modelica model, but it does not contain the model's
equations. It can carry a rigid body and a joint, but it does not integrate
them. It can carry a connection between two ports, but it does not decide what
value should flow. Those jobs belong to the runtime, to Modelica, and to Rhai
respectively.

## What USD owns

| Fact | Authored as | Consumed by |
|---|---|---|
| Prim hierarchy and identity | `def` prims under a `defaultPrim` | Projection, selection, authoring tools |
| Placement | `xformOp:translate`, `xformOp:orient`, `xformOp:scale` | Rendering, physics, mounts |
| Geometry | `Mesh`, `Cube`, `Sphere`, `Cylinder`, `Capsule`, `Plane`, `NurbsPatch` | Rendering and collision cooking |
| Appearance | `UsdShade` material networks and WESL sources | Render binder |
| Physics | `UsdPhysics` bodies, colliders, masses, joints, drives | Avian projection |
| Typed ports | `inputs:<name>`, `outputs:<name>`, `connectors:<name>` | Co-simulation and telemetry |
| Connections | `.connect` on a consuming property | Co-simulation wiring |
| Programs | `LunCoProgramAPI` prims | Modelica, Rhai, Python runtimes |
| Composition | Sublayers, references, payloads, variants, inherits | Stage resolver |
| Scene policy | `LunCoPolicy`, `LunCoEnvironment`, `LunCoUiSchemaAPI` | Authored runtime policy |

## Units and orientation

A LunCoSim scene uses metres and a Y-up, right-handed world. A normal root stage
declares that explicitly:

```usda
#usda 1.0
(
    defaultPrim = "MyTwin"
    upAxis = "Y"
    metersPerUnit = 1
)

def Xform "MyTwin" (kind = "assembly")
{
}
```

The `defaultPrim` matters: it gives the stage a stable root for references and
for the runtime projection. A stage without one is still readable, but a
reference to it cannot omit the target prim path.

The engine converts a supported non-canonical stage once, at the importer. A
Z-up or centimetre stage is valid interchange content; it is not a valid
runtime frame. `metersPerUnit`, `upAxis`, and `kilogramsPerUnit` are read at the
stage boundary, and unsupported values reject projection instead of being
silently approximated. Authoring a non-SI document is allowed; admitting it as
a live world is not.

## The three document layers

A running scene is not one editable file. The document system keeps three
authored layers over one composed stage:

| Layer | Lifetime | Saved to | Purpose |
|---|---|---|---|
| **base** | Durable | The source `.usda` file | The authored scene |
| **runtime** | Durable | `.lunco/runtime/<scene>` when enabled | Edits that must survive but stay out of the source file |
| **view** | Disposable | Never | Derived presentation such as route ribbons |

The composed `CanonicalStage` resolves references, sublayers, variants, and
the three layers in strength order. It is the projection engine: an authored
operation replayed onto it fires the change sink, and the runtime reconciles
the ECS world from that notice. The stage is thread-affine and lives on the
main thread; the serializable layers are what save, journal, and network sync
touch.

This is why editing a large scene does not re-flatten it on every change. The
typed operation is applied to the document, journaled with its inverse, and
replayed onto the live stage. A full reload is a separate contract and does not
invent an authored edit.

## Compose, do not duplicate

USD composition is how large scenes stay maintainable. A scene can reference a
reusable rover, place two instances with different transforms, and select a
variant without copying its geometry:

```usda
#usda 1.0
(
    defaultPrim = "PracticeYard"
    upAxis = "Y"
    metersPerUnit = 1
)

def Xform "PracticeYard"
{
    def Xform "RoverA" (
        prepend references = @lunco://vessels/rovers/skid_rover.usda@
    )
    {
        double3 xformOp:translate = (0, 0, 0)
        uniform token[] xformOpOrder = ["xformOp:translate"]
    }

    def Xform "RoverB" (
        prepend references = @lunco://vessels/rovers/skid_rover.usda@
    )
    {
        double3 xformOp:translate = (8, 0, 4)
        uniform token[] xformOpOrder = ["xformOp:translate"]
    }
}
```

`lunco://` addresses the installed asset library. `twin://` addresses a file in
the open Twin. Use the narrowest authority that owns the file; do not escape an
asset root with `..`.

## Physics is authored as SPD schemas

LunCoSim uses standard USD physics schemas rather than custom body objects.
A movable part generally has:

- a rigid body (`UsdPhysics.RigidBodyAPI`)
- one or more colliders (`UsdPhysics.CollisionAPI` and a shape)
- mass properties (`UsdPhysics.MassAPI`)
- a joint when it is attached to another body

A movable mounted part needs both a rigid body and a joint. Being a child in
the hierarchy is not an attachment. The scene linter reports a nested body
without a joint.

## Programs are prims

A Modelica model or Rhai scenario is attached through the `LunCoProgramAPI`
schema. The schema applies to the physical prim itself when the behavior is
intrinsic, or to a child `Scope` when the behavior is separable. The example
uses a child `Scope`, so deleting it removes the behavior without deleting the
rover:

```usda
def Xform "Rover" (kind = "assembly")
{
    def Scope "Controller" (
        prepend apiSchemas = ["LunCoProgramAPI"]
    )
    {
        uniform token info:implementationSource = "sourceAsset"
        uniform asset info:sourceAsset = @twin://my-rover/models/Drive.mo@
        uniform bool lunco:program:realtimeSafe = true
    }
}
```

A shipped model uses `@lunco://models/...@`; a Twin-owned model uses
`@twin://...@`. The source path is an asset address, not a relative path from
the current working directory.

## Connections are USD facts

A connection is authored on the prim that consumes the value:

```usda
def Xform "DescentLander" (
    prepend apiSchemas = ["PhysicsRigidBodyAPI", "LunCoProgramAPI"]
)
{
    uniform token info:implementationSource = "sourceAsset"
    uniform asset info:sourceAsset = @lunco://models/Lander.mo@
    uniform bool lunco:program:realtimeSafe = true

    float inputs:external_throttle = 0.0
    float outputs:throttle

    def Scope "MainPropulsion"
    {
        float inputs:valve_opening.connect = </DescentLander.outputs:throttle>
    }
}
```

The composed stage resolves references, payloads, variants, and the connection
graph. The runtime then derives a `SimConnection` from the authored wire. A
model output becomes externally connectable only when the component prim
declares the matching `outputs:<name>` property; a connection target alone does
not create a public port.

## Reading this chapter

| Section | Question it answers |
|---|---|
| [Composition](composition.md) | How do layers, references, payloads, and variants form one stage? |
| [Physics](physics.md) | How do bodies, colliders, joints, and gravity become a live simulation? |
| [Ports and connections](ports-and-connections.md) | How does a value travel from one component to another? |
| [Programs](programs.md) | How is a Modelica model or Rhai scenario attached to a prim? |
| [Materials](materials.md) | How does a prim get a shader, and how are parameters authored? |
| [Addresses and assets](addresses-and-assets.md) | What do `lunco://` and `twin://` mean, and where do bytes come from? |
| [Authoring](authoring.md) | How do the Editor and Build perspectives change a stage safely? |

The composed stage is inert. It becomes a live world only when the runtime
projects it and the admitted programs start.
