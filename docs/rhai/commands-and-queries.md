---
title: Commands and queries
chapter: 5
section: 3
---

# Commands and queries

A script touches the world through the same typed command and query surface as
the UI, HTTP API, and MCP. It does not receive a private scene-graph pointer and
it does not call Rust functions directly. That restriction is what keeps a
scenario portable, auditable, and safe to hot-reload.

The bridge has two directions:

| Direction | Verb | Contract |
|---|---|---|
| Write with side effects | `cmd(name, params)` | Fires a registered command; returns an acknowledgement |
| Read state | `query(name, params)` | Calls a read-only provider; returns data, `()`, or an error map |
| Tuning write | `set(id, path, value)` | Writes a reflected field or scalar port; not replicated |
| Tuning read | `get(id, path)` | Reads a reflected component field |
| Resource write | `set_setting(path, value)` | Writes a reflected resource field |
| Resource read | `get_setting(path)` | Reads a reflected resource field |

## Commands

```rhai
let result = cmd("SetPorts", #{
    target: rover,
    writes: [["throttle", 0.4], ["steer", -0.1]],
});

if result.ok != true {
    print("command failed: " + result.error);
}
```

`cmd` returns a map with `id`, `ok`, `data`, and `error`. The `id` is the
correlation id for a deferred result and for causal tracing. `data` carries
command-specific result data, such as a spawned entity id.

Commands are the right channel for an operation that must be authoritative,
replicated, undoable, or observed by another subsystem. Examples include
`SetPorts`, `ReleasePort`, `ReleaseControl`, `LoadScene`, `SpawnEntity`,
`SetObjectProperty`, `ApplyUsdOp`, `CompileModel`, `SetModelInput`,
`TeleportToSurface`, `RunScenario`, `RegisterTimeline`, and `CaptureFromCamera`.

Use `command_result(id)` when a command is admitted asynchronously:

```rhai
let pending = cmd("LoadScene", #{ path: "twin://my-twin/scenes/yard.usda" });
let result = command_result(pending.id);
```

`command_result` accepts native unsigned command ids and non-negative integer
literals. A negative id is an evaluation error.

## Queries

```rhai
let hit = query("Raycast", #{ origin: [0.0, 1.0, 0.0], direction: [0.0, -1.0, 0.0] });
let nearest = query("Nearest", #{ position: world_pos(me), radius: 25.0 });
```

A successful query returns its data directly. A successful query with no data
returns `()`. A failure returns a map with `ok: false` and an `error` field, so a
script can distinguish "nothing there" from "the provider rejected the call".

Useful providers include `Raycast`, `Nearest`, `GroundHeight`, `CausalTrace`,
`ListSpawnCatalog`, `ValidateTwin`, `SensorOccupants`, `Links`,
`InspectSelection`, `ListOpenDocuments`, `ListDatasets`, and
`ListToolLibraries`. The exact provider list belongs to the running app; a
scenario should discover rather than assume an optional provider exists.

## Reads and writes by reflected path

`get` and `set` address a reflected component field by name:

```rhai
let battery = get(rover, "Battery.level");
set(rover, "Battery.level", 0.8);
```

Vectors are returned as `[x, y, z]` and quaternions as `[x, y, z, w]`.
Structs are returned as maps. A missing field or an unsupported type returns
`()`, and `set` returns `false` on a bad path or type.

`get_setting` and `set_setting` use the same path shape for reflected resources:

```rhai
let samples = get_setting("RendererSettings.samples_per_pixel");
set_setting("RendererSettings.samples_per_pixel", 256);
```

These are **host-side tuning writes**. They are not replicated, undoable, or a
persistent port hold. A client-targeted script cannot use them because there is
no prediction or forwarding path.

## Ports and control

`set` may fall through to a canonical scalar co-simulation port, but that is a
raw write. Use commands when the value must persist until an explicit release:

```rhai
cmd("SetPorts", #{ target: rover, writes: [["throttle", 0.5]] });
cmd("ReleasePort", #{ target: rover, name: "throttle" });
cmd("ReleaseControl", #{ target: rover });
```

`ReleaseControl` returns every local input hold to authored wiring without
writing replacement values. Send an explicit `SetPorts` value if a safe setpoint
is required.

Control authority is a separate concern:

```rhai
claim_control(me);
drive(me, 0.5, 0.0);
release_control_claim(me);
```

`ClaimControl` and `ReleaseControlClaim` update the session authority table.
`AcquireControl` composes the same transition with an avatar `ControlLink` and
optional camera binding. An unpossessed vessel can still fly its own guidance;
it discards external stick writes.

For discrete controls, use an atomic semantic edge instead of two ordered held
writes:

```rhai
intent_pulse(lander, "release");
```

`intent_edge(target, intent, edge)` accepts `pressed`, `released`, or `pulse`.
The controller publishes `intent.edge`; authored Twin policy decides what the
edge means and which ports it writes. Use `SetPorts` or `SimulateIntent` for
level-triggered and continuous control.

## Identity and hierarchy

| Verb | Returns | Use |
|---|---|---|
| `find(name)` | Entity id, or `-1` | Lookup by canonical `Name` |
| `name(id)` | Presentation label | Human-readable text, not identity |
| `usd_path(id)` | Projected USD prim path | Identity-only lookup, safe during dependency planning |
| `parent(id)` | Parent id or `()` | Hierarchy traversal |
| `children(id)` | Child id array | Hierarchy traversal |
| `list_entities()` | Entity records | Enumerate the live world |
| `owner_of(id)` | Session id or `()` | Which session owns the entity |
| `controller(id)` | Session role or `()` | Controlling role, if any |
| `is_controlled(id)` | Boolean | Whether any session owns it |

`list_entities()` returns records with `id`, `name`, `type`, `catalog_id`,
`input_surface`, `control_bound`, `celestial_body`, and `pos`. `name` is the
human-readable presentation label; `type` is the projected USD kind, not a
control-component heuristic. `input_surface` is the authoritative `InputPorts`
readiness bit.

`find` is a name lookup, not a path lookup. Use an explicit USD path or a
relationship when identity must be stable across renames.

## Pose and spatial values

| Verb | Returns | Frame |
|---|---|---|
| `world_pos(id)` | `[x, y, z]` f64 | Active physics frame |
| `world_pos3(id)` | Native `Vec3` | Active physics frame |
| `world_point(id)` | `point3` map | Explicit frame tag |
| `world_forward(id)` | `[x, y, z]` | Active physics frame |
| `world_forward3(id)` | Native `Vec3` | Active physics frame |
| `world_rotation_quat(id)` | Native `Quat` | Active physics frame |

`world_pos` and `world_forward` are float-origin-correct and independent of
camera recentering and celestial ancestors. Use the native `Vec3`/`Quat` forms
in hot loops and lower them with `vec3_array`/`quat_array` only when a value
crosses a wire or report boundary.

A position that crosses a tool, scene, or authoring boundary must be a `point3`
map with an explicit frame:

```rhai
let rover = world_point(find("/Traverse/Rover"));
let offset = point_offset(rover, [1.0, 0.0, 0.0]);
let distance = point_distance(rover, offset);
```

`point_delta`, `point_distance`, and `point_offset` reject malformed or
cross-frame values. Pointer hits also expose `render_position`, tagged `render`;
that is presentation data and must never be sent to a placement or authoring
command.

## Settings and Twin policy

```rhai
let speed = get_twin_setting("mission.cruise_speed");
set_twin_setting("mission.cruise_speed", 1.4);
```

`get_twin_setting` reads a scalar from the active Twin manifest's generic
`[settings]` table. `set_twin_setting` persists a scalar through the generic
`SetTwinSetting` command. There is no per-setting Rust binding.

`twin_name()` returns the current `twin://` mount authority from the asset
registry; it is empty only when no Twin is active. Reopening a Twin assigns a
fresh authority, so use this value for Twin source queries rather than
reconstructing it from the manifest name.

`get_exposure("namespace", "property")` reads one raw value from the generic
engine exposure registry. Rhai owns selection and presentation policy.

## Clock and execution context

| Verb | Meaning |
|---|---|
| `sim_tick()` | Current fixed simulation tick |
| `dt()` | Configured physics timestep |
| `elapsed_seconds()` | Simulation seconds |
| `execution_context()` | Owner scope, cycle, phase, clock sample, sequence, and producer stamp |

These calls reject use outside the simulation cycle as a Rhai invocation error.
A wrong-cycle call does not fault the simulation or another runtime cycle.
`dt()` reads the configured physics timestep; pause and rate changes do not
rescale it.

`execution_context()` is read-only. It reports the stable Twin id when the
scenario is Twin-owned, the scene generation when one is committed, and the
event producer stamp for an `on_event` pass. Scope, Twin id, cycle, and
generation are unit when no owner route exists.

## Deterministic randomness

`rand()`, `rand_range(lo, hi)`, and `rand_int(lo, hi)` use deterministic
per-hook seeding. The seed is derived from the entity, the event producer or
cycle sequence, and the hook. A re-run with the same inputs produces the same
sequence, so a script does not need to seed explicitly.

## Structural operations

`add(id, "Comp", #{fields})` inserts or replaces a reflected component.
`remove(id, "Comp")` strips one. `despawn(id)` despawns an entity and its
children. These are structural operations and replicate on a host.

Spawning uses the catalog command rather than a generic constructor:

```rhai
let spawned = cmd("SpawnEntity", #{
    entry_id: "skid_rover",
    position: [0.0, 0.0, 0.0],
});
```

Actorless Rhai callers of raw-file scenes also pass a stable nonzero
`producer_id`.

## Structural invalidation

Policy that reads USD topology on a fixed tick should use the owning document's
generation as its invalidation clock:

```rhai
let generation = usd_document_generation(doc_id);
```

The native bridge reads the document host's generation directly. A policy may
cache a route, component, or relationship snapshot and refresh it only when the
generation changes. Runtime transforms, sensor values, and actuation stay on
their live per-tick paths because they are state, not structural invalidation.

## Assets and JSON

`asset_source_relative_uri(document, relative)` resolves a safe
document-relative asset while preserving its registered source authority. It is
URI algebra only and performs no filesystem read.

`parse_json(text)` returns native maps, arrays, and scalars, or `()` for JSON
null. Malformed JSON and integers outside Rhai's signed integer range are
errors.

## Related sections

- [Events](events.md) — how `emit` and `on_event` connect scripts
- [Patterns](patterns.md) — command sequences in context
- [HTTP API](../reference/http-api.md) — the same surface over HTTP
- [Ports and connections](../usd/ports-and-connections.md) — the authored wiring
