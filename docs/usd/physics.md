---
title: Physics
chapter: 4
section: 2
---

# Physics

LunCoSim projects standard `UsdPhysics` schemas onto the Avian physics engine.
There is no LunCoSim-only body object and no parallel physics scene. A prim
either carries the standard schemas the adapter understands, or it remains
visual geometry.

The projection is intentionally narrow. Avian is a rigid-body engine; it does
not implement reduced-coordinate articulations, general USD collections, or
skinned deformation. The adapter advertises the schemas it can realize and
rejects the ones it cannot. Authoring a schema that does nothing is treated as
a defect, not as harmless metadata.

## Bodies, colliders, and mass

A movable part generally has four pieces:

| Purpose | Schema | Notes |
|---|---|---|
| Make the prim a dynamic body | `PhysicsRigidBodyAPI` | Mass and inertia come from `PhysicsMassAPI` or from colliders |
| Give it a collision surface | `PhysicsCollisionAPI` plus a `UsdGeom` shape | The shape is cooked into an Avian collider |
| Set mass properties | `PhysicsMassAPI` | Explicit mass, center of mass, diagonal inertia, and principal axes |
| Attach it to another body | A `Physics*Joint` prim | Being a child in the hierarchy is not an attachment |

A minimal dynamic cube:

```usda
def Cube "Crate" (
    prepend apiSchemas = ["PhysicsRigidBodyAPI", "PhysicsCollisionAPI", "PhysicsMassAPI"]
)
{
    double size = 0.5
    double3 xformOp:translate = (0, 1.2, 0)
    uniform token[] xformOpOrder = ["xformOp:translate"]

    float physics:mass = 12.0
    point3f physics:centerOfMass = (0, 0, 0)
    float3 physics:diagonalInertia = (0.5, 0.5, 0.5)
    quatf physics:principalAxes = (1, 0, 0, 0)
}
```

If `physics:mass` is omitted, the adapter uses the collider's density and
volume. If the mass is authored, it must be positive and finite; the native
reciprocal and the rotated inverse inertia tensor must also be valid. A
failure raises a typed diagnostic and holds physics rather than admitting a
body with a degenerate tensor.

### Collider geometry

Primitive colliders keep their authored dimensions and axis. A finite
`UsdGeomPlane` has no invented thickness: its width and length map onto the
schema-defined perpendicular axes before the surface is rotated onto the
authored normal. Mesh colliders support `none`, `convexHull`, and
`convexDecomposition`; unsupported approximation modes reject instead of
substituting a different shape.

`UsdGeomNurbsPatch` is not directly a mesh collider. The generic
`PlanNurbsCollisionProxy` query and `nurbs.rhai` authoring tool derive an
invisible, source-linked `UsdGeomMesh` through the same geometry cook used by
Avian. Projection re-cooks deterministically and rejects stale proxy data.

## Joints

All USD-authored joints are translated by `lunco-usd-avian` from standard
`UsdPhysics` joint prims. Endpoints are `physics:body0` and `physics:body1`
relationships; anchors are `physics:localPos0` and `physics:localPos1`.

| USD prim | Avian joint | Notes |
|---|---|---|
| `PhysicsRevoluteJoint` | `RevoluteJoint` | 1-DOF hinge; `angle` (rad), `angular_velocity` (rad/s), reaction `torque` (N m) |
| `PhysicsPrismaticJoint` | `PrismaticJoint` | 1-DOF slider; `displacement` (m), `velocity` (m/s), reaction `force` (N) |
| `PhysicsFixedJoint` | `FixedJoint` | Rigid weld; no co-simulation port |
| `PhysicsSphericalJoint` | `SphericalJoint` | Ball joint; cone limits map to swing, lower and upper limits to twist |
| `PhysicsDistanceJoint` | `DistanceJoint` | Tether within `[minDistance, maxDistance]`; no co-simulation port |
| `PhysicsD6Joint` / `PhysicsJoint` | Reduced per-DOF joint | Per-DOF `PhysicsLimitAPI`; genuinely multi-DOF warns |

Only revolute and prismatic joints expose co-simulation ports. `angle` and
`displacement` are bidirectional: the input side commands the native motor
target, and the output side measures the solved coordinate. The rate and
reaction ports are outputs only.

A revolute or prismatic joint can carry a `UsdPhysicsDriveAPI`:

```usda
def PhysicsRevoluteJoint "Shoulder"
{
    rel physics:body0 = </Rover/Chassis>
    rel physics:body1 = </Rover/Arm>
    point3f physics:localPos0 = (0.3, 0.2, 0)
    point3f physics:localPos1 = (0, 0, 0)
    uniform token physics:axis = "Y"

    float drive:angular:physics:targetPosition = 30.0
    float drive:angular:physics:targetVelocity = 0.0
    float drive:angular:physics:maxForce = 40.0
}
```

`physics:targetPosition` enables the motor at load, so an Omniverse-authored
mechanism seeks its setpoint with no wire. A co-simulation wire on the joint's
`angle` or `displacement` port overrides the target per tick.

D6 joints are reduced to the matching primitive when only one DOF remains
free. A genuinely multi-DOF joint warns rather than pretending to be exact.

### Seating and readiness

Joints are seated after the initial body poses are validated and are installed
disabled. `PhysicsJointPrepared` keeps their measurements available while body
readiness prevents solver-island admission. Activation waits for real Avian
body nodes and removes only the owner's temporary disable.

Seating preserves world, static, and kinematic endpoint authority. A declared
`Mobility::Dynamic` endpoint is treated as movable even while initial admission
holds its native body kinematic. The owner moves endpoint 1 when eligible,
otherwise endpoint 0 with reversed frames and signed slider bounds.

The complete seated pose and velocity are validated before publication.
Incompatible prescribed endpoints, incompatible hinge axes, and coincident
distance anchors that require positive separation report
`physics-joint-seating-invalid`, appear in Recent Events, and hold physics
without constructing a constraint. Compatible all-static definitions remain
native-disabled because they have no solver island.

## Gravity

`lunco-usd-avian` owns standard `PhysicsScene` gravity admission and live
refresh. Magnitude converts from stage units per second squared to metres per
second squared; direction converts from stage axes to canonical axes.

Omitted or finite negative magnitude selects standard Earth gravity. An
omitted or zero direction selects stage down. Malformed, non-finite, or
out-of-range values, and conflicting scenes in one physical world, report
`usd-physics-gravity-invalid` with the offending prim, property, and value.
The previous valid environment remains intact.

A celestial body takeover retains its `Gravity::Surface` model while the
refreshed `PhysicsScene` facts remain available for diagnostics.

## Collision filtering

Two mechanisms exist, and only one is automatic.

**Jointed pairs** are filtered by Avian: every joint built by the loader
carries `JointCollisionDisabled`, so a body never collides with the body it is
jointed to. That covers parent and child and stops there.

**Everything else is authored**, through `PhysicsFilteredPairsAPI`:

```usda
def Cube "Pad" (
    prepend apiSchemas = ["PhysicsCollisionAPI", "PhysicsFilteredPairsAPI"]
)
{
    rel physics:filteredPairs = </Lander/Hull>
}
```

Filtering is symmetric: one opinion is the whole pair. A body endpoint filters
every attached collider; a collider endpoint filters only that authored
surface. Resolution runs in `PhysicsSystems::Prepare`, ahead of the narrow
phase, because Avian's broad phase skips any pair already in the contact graph.
A filter applied later does not remove an existing contact.

**Group-versus-group** filtering uses `PhysicsCollisionGroup`:

```usda
def PhysicsCollisionGroup "Wheels"
{
    prepend rel collection:colliders:includes = </Rover/Wheels>
    prepend rel physics:filteredGroups = </Scene/Groups/Chassis>
}
```

Membership is a `UsdCollectionAPI` with the standard `expandPrims` rule.
`physics:mergeGroup` lets groups in different layers share one bit.
`physics:invertFilteredGroups` makes the listed groups the only ones the group
collides with, read literally. Ungrouped bodies keep colliding: groups take
bits from 1 up, never bit 0 and never the trigger layer.

Nothing is inferred beyond joint adjacency. There is no "a vehicle does not
collide with itself" rule, because *vehicle* is not a fact the physics knows.
A rover on a lander deck is one or two bodies depending on the minute, and an
arm should collide with its own base.

## Wheels

Wheel kind is selected by standard USD authoring, not by a LunCo-specific
token. Every wheel prim applies `PhysxVehicleWheelAPI`. If any
`PhysicsRevoluteJoint` in the stage names the wheel through `physics:body1`,
the wheel is realized as a **physical wheel**: an Avian `RigidBody`, a
`Collider`, the authored joint, and the generic Modelica/engine shaft boundary.
Otherwise it is realized as a **raycast wheel**: `WheelRaycast`, `RayCaster`,
and entity splitting.

Raycast wheels need identity rotation so the ray casts straight down. The
system splits the USD wheel into a physics entity with identity rotation and no
mesh, and a visual child with the correct orientation and mesh. Traction is
decomposed in the actual contact plane, so a leaning single-track vehicle gets
correct lateral grip.

Physical wheel geometry is independent of its shaft axis. Analytic axial
primitives use the USD axis basis because their native meshes and colliders use
local +Y; an authored mesh already contains its local orientation.

The heading axis is `lunco:wheel:headingAxis` (wheel-local `double3`, required).
A raked motorcycle fork can author `(0, 0.91, 0.42)`. The final heading is an
authored output, not a vehicle-type rule in Rust.

## Sensors and observations

The engine exposes Avian's native rigid-body facts directly: position, linear
velocity, quaternion, angular velocity, mass and inertia, and collider contact.
Those ports are not semantic flight sensors. They exist because the physical
component exists.

A mounted single ray applies `LunCoRaycastAPI`. Rust performs the Avian
spatial query and publishes raw distance, validity, hit position, hit normal,
and sample time. It also publishes the effective ray origin and direction in
the rigid body's local frame, composed from the sensor's authored transform
hierarchy. A miss remains invalid; it is never converted to ideal altitude or
another fallback.

IMU, altimeter, attitude estimator, and touchdown logic are ordinary Modelica
programs. USD authors their connections to the raw Avian ports and environment
probe outputs. Adding a new conversion changes a Modelica asset and its USD
topology, not a Rust sensor registry.

## Supported schema boundaries

| Schema | Status | Reason |
|---|---|---|
| `PhysicsArticulationRootAPI` | Authored, deliberately inert | Avian has no reduced-coordinate articulation |
| `UsdGeomPointInstancer` | Composed reader and visual projection | Animated arrays and arbitrary prototype subtrees fail visibly |
| `instanceable = true` | Not read | Every spawned copy is a full prim tree |
| `UsdCollectionAPI` | Read only where `PhysicsCollisionGroup` applies it | Membership resolution is group-specific |
| `UsdGeomSubset` | Not read | No per-face material or collider use case in the fleet |
| `proxyPrim` | Not read | `purpose` covers the proxy-sibling case |
| `extentsHint` | Not read | `extent` itself is read |
| `UsdSkel` | Not read | No skinned geometry in the fleet |

The rule for adding a row is simple: if an asset authors it and the engine
ignores it, it belongs in this table or the authoring should be deleted.
Silence is the failure mode in both directions.

## Rules of thumb

- A movable mounted part needs a body **and** a joint.
- Author mass explicitly when the collider volume is not the real mass.
- Keep joint axes and anchors in the joint's local frames; do not compensate
  with body transforms.
- Filter the pairs you mean. Joint adjacency is the only automatic case.
- Use `PhysicsCollisionGroup` when pair relationships stop scaling.
- Keep semantic sensor logic in Modelica; keep the raw ray in USD.
- Expect unsupported schemas to be rejected or reported, never silently
  approximated.

Continue with [Ports and connections](ports-and-connections.md), where physical
bodies and programs exchange typed values.
