# USD

OpenUSD is LunCoSim's scene and composition format. It describes **what the
world is made of**: hierarchy, transforms, geometry, materials, physics
schemas, and the typed connections between parts. It is not the physics engine
and it is not a scripting language.

## What USD owns

- The prim hierarchy: assemblies, parts, mounts, sensors, and scene roots
- Transforms and units
- Mesh, curve, and primitive geometry
- Materials and shader bindings
- `UsdPhysics` rigid bodies, colliders, masses, and joints
- Typed `inputs:` / `outputs:` ports and their connections
- References, payloads, sublayers, and variants used for composition

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
for the runtime projection.

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
the hierarchy is not an attachment. LunCoSim's scene linter reports a nested
body without a joint.

## Programs are prims

A Modelica model or Rhai scenario is attached to a prim through the
`LunCoProgramAPI` schema. The program is a child prim, so deleting the prim
removes the behavior:

```usda
def Xform "Rover" (kind = "assembly")
{
    def Scope "Controller" (
        prepend apiSchemas = ["LunCoProgramAPI"]
    )
    {
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
def Xform "DescentLander"
{
    uniform asset info:sourceAsset = @lunco://models/Lander.mo@
    uniform bool lunco:program:realtimeSafe = true

    float inputs:force_y.connect = </DescentLander.outputs:force_y>
    float inputs:q_w.connect = </DescentLander.outputs:quat_w>
}
```

The composed stage resolves references, payloads, variants, and the connection
graph. The runtime then derives a `SimConnection` from the authored wire. A
model output becomes externally connectable only when the component prim
declares the matching `outputs:<name>` property; a connection target alone does
not create a public port.

## Editing

Use the **Build** and **Editor** perspectives for normal authoring. The Editor
opens one explicit USD document, previews changes, and saves through the
document journal. The runtime does not rewrite authored USD to hide a bug. See
[Perspectives](../getting-started/perspectives.md#editor-edit-one-usd-document)
for the Editor layout and workflow.

The composed stage is inert. It becomes a live world only when the runtime
projects it and the admitted programs start.
