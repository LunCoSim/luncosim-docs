---
title: Events
chapter: 6
section: 4
---

# Events

Events are the coordination mechanism between scenarios. A script does not call
another script directly; it emits a named telemetry event, and interested
scenarios receive it through `on_event` or a task event leaf. This keeps the
scripts isolated, replayable, and independent of entity iteration order.

## Emitting

```rhai
emit("MARKER_REACHED", #{ marker: 3, position: world_pos(me) });
```

`emit` reuses the shared `TelemetryEvent` bus. The name is the YAMCS mnemonic;
the value is a typed scalar, array, or map. External clients receive the same
event through `SubscribeTelemetry`.

Emitting is not a synchronous call into another script. The event is queued and
delivered on the receiver's next eligible pass.

## Receiving

```rhai
fn on_event(me, evt, ctx) {
    if evt.name == "MARKER_REACHED" {
        this.reached = true;
        notify_kind("Marker reached", "success");
    }
}
```

`evt` is a map with `name`, `source` (the emitter gid), `value`, `severity`,
`timestamp`, `sim_secs`, and `sim_tick`. `ctx` carries the scenario parameters
and execution context of the receiving pass.

A task can wait for an event instead of handling it in `on_event`:

```rhai
fn task(me, ctx) {
    seq([
        once(|m| notify("Waiting for the sample")),
        wait_for("SAMPLE_READY"),
        once(|m| notify("Sample is ready")),
    ])
}
```

Use `wait_for_from(event, src)` when the event must come from a specific entity
or path. `act_until_event(act, event, src)` keeps an action running until the
scoped event arrives.

## Delivery and ordering

- A running simulation releases events whose recorded tick precedes the current
  `SimTick` after `SimTickSet`.
- While paused, the next `Update` pass delivers discrete events without
  advancing the fixed tick.
- Events emitted while a pass is delivering its current batch remain queued for
  the following pass. A lifecycle hook can publish a readiness edge without
  losing it at the dispatch boundary.
- Every event carries the simulator's `sim_secs` and `sim_tick` stamp. The
  absolute `timestamp` is only the derived TDB epoch label.
- While the scene-readiness lifecycle gate is closed, events are not buffered
  because no scenario can consume them and the gated driver cannot drain them.
- Scene transitions clear pending events from the outgoing scene.
- A new or restarted program does not receive events accumulated before its
  `on_start`. Query current state instead of relying on history.

Events emitted by `on_start` retain their producer stamp for the next eligible
scenario pass. Inter-script interaction is bus-only because each scenario runs
in an isolated VM.

## Event-driven patterns

### Coordinator and workers

A single coordinator owns assignment; workers own local execution. The
coordinator reacts to worker readiness and publishes one assignment per worker:

```rhai
fn on_event(me, evt, ctx) {
    if evt.name == "WORKER_READY" {
        let worker = evt.value.worker;
        cmd("SetPorts", #{ target: worker, writes: [["assigned", 1.0]] });
        emit("ASSIGNMENT", #{ worker: worker, task: "survey" });
    }
}
```

The workers never address each other. They emit readiness and completion, and
the coordinator decides what happens next.

### Phase transitions

A mission can use events as durable phase boundaries:

```rhai
fn on_event(me, evt, ctx) {
    if evt.name == "DESCENT_COMPLETE" && this.phase == "descent" {
        this.phase = "surface";
        mission_checkpoint(me, mission_document(me), "@root@", "phase", "surface");
        notify("Surface phase");
    }
}
```

The checkpoint writes through the explicit USD document path, so a hot reload
can resume the phase instead of restarting the mission.

### Sensor and collision events

Generic sensor and collision events carry the identities a scenario needs to
decide what happened:

| Event family | Payload use |
|---|---|
| `SENSOR_ENTER` / `SENSOR_EXIT` | Sensor and moving-body identity |
| `COLLISION_START` / `COLLISION_END` | Collision pair |
| `intent.edge` | Target, intent, edge, correlation id |
| `intent.hold` | Held intent with producer and input-order stamp |

The prelude wraps the collision family with `collision_pair`, `collision_other`,
`entered`, and `exited`.

`TriggerZone` labels additionally provide named geofence events. A route program
can advance on the matching named sensor enter without re-creating distance
checks.

### Model events

A Modelica condition becomes an event through USD, not through a script polling
the model:

1. Express the condition in Modelica as a 0/1 output.
2. Connect it to a `def LunCoEvent` prim through `inputs:trigger.connect`.
3. Author the bus-facing `lunco:event:name` and `lunco:event:severity` on the
   event prim.
4. Receive the event in `on_event` on a later eligible pass.

Physical thresholds and hysteresis stay in the model. USD owns the wire. Rhai
owns the response.

## Event names are protocol

Event names are authored strings, not an enum. Treat them as a stable protocol
between the producer and every consumer:

- Keep names uppercase and specific: `DESCENT_COMPLETE`, not `DONE`.
- Put structured data in the value map instead of encoding it in the name.
- Do not rename an event without updating every consumer and test.
- Prefer one meaningful event over a stream of per-tick telemetry when the
  consumer only needs the transition.

## Related sections

- [Lifecycle](lifecycle.md) — when `on_event` runs
- [Tasks](tasks.md) — `wait_for` and `wait_for_from`
- [Commands and queries](commands-and-queries.md) — `emit` and the command bus
- [Telemetry](../ui/telemetry.md) — observing the same events from the UI
