---
title: Lifecycle
chapter: 5
section: 1
---

# Lifecycle

A scenario is compiled once, initialized once, and then advanced by the owner
that invoked it. The lifecycle separates dependency planning, module
initialization, the ready callback, steady-state progression, event reactions,
and teardown. Keeping those stages distinct prevents a script from reading a
participant that has not been admitted or from running two copies of the same
mutable state.

## The hook sequence

| Stage | Hook or body | Runs | Allowed work |
|---|---|---|---|
| Admission plan | `simulation_dependencies(me, ctx)` | Before mutable initialization | Read stable identities and declare required inputs |
| Module body | Top-level statements | Once per instance, after declared inputs are ready | Construct per-instance state in `this` |
| Ready callback | `on_start(me, ctx)` | Once at the ready boundary | Setup that needs the live owner |
| Progression | `task(me, ctx)` | Tree built once; advanced each fixed step | Actions, predicates, waits, event leaves |
| Objectives | `mission(me, ctx)` | Declared once; evaluated by the runtime | Objective state and completion conditions |
| Reaction | `on_event(me, evt, ctx)` | Next eligible pass after an event arrives | Discrete policy and state updates |
| Sampling | `on_tick(me, ctx)` | Each authored cadence tick | Test sampling only |
| Teardown | `on_stop(me, ctx)` | Hot reload, detach, despawn, scene teardown | Release control and stop actuators |

A script may define any subset. The runtime treats a missing hook as absent; it
does not invent a default task or a default teardown.

## Initialization and readiness

Scenario admission waits until all world and entity readiness holds clear,
because a program can reference entities outside its own hierarchy. After
admission, a later entity hold idles scenarios attached in that subtree and
release resumes them without restarting.

`simulation_dependencies` is the place to declare what the scenario needs. It
runs before mutable initialization and may use only stable identities,
parameters, and its declared read surface. It must not read facts from the
inputs it requires before they are admitted.

The top-level module body then initializes per-instance scope with its stable
scenario identity. Declared `query_reads` work during initialization as well as
in later hooks. `on_start` follows before the activation pass advances its task
or tick hook.

`on_start` is the ready boundary. It runs after applicable scene admission and
after the owner's required inputs are ready. A new or restarted program does not
receive events accumulated before its `on_start`; startup policy queries current
state instead of relying on history. For sensors, use `SensorOccupants` in
`on_start` when the initial occupancy matters.

## Scenario parameters

One source can serve many entities. Pass one natural typed object as `params`:

```json
{
  "type": "ExecuteCommand",
  "command": "RunScenario",
  "params": {
    "target": 4869542932533563,
    "source": "<rhai source text>",
    "params": { "speed": 1.5 }
  }
}
```

```rhai
fn task(me, ctx) {
    let speed = if ctx.speed == () { 0.6 } else { ctx.speed };
    forever(once(|m| drive(m, speed, 0.0)))
}
```

Omitting `params` means an empty map. Rhai owns the default for each key, so a
scenario chooses the default that fits its policy. The command boundary rejects
a scalar, array, `null`, non-finite number, or a value outside the shared
telemetry range. Rust validates and transfers the typed map once per program
instance.

`param(id, key, default)` is a separate helper: it reads a
`lunco:param:<key>` attribute authored on the prim and does not read launch
parameters.

## Owner scope and clocks

The runtime assigns persistent scenario hooks to the cycles owned by the
selected application plugins. The script does not choose its `Core`,
`Application`, or `Twin` owner; Rust assigns that owner and the schedules that
invoke it.

Use directives to select the network peer and the cadence:

```rhai
// @peer host|client|both
// @timing simulation|presentation
```

`host` includes the standalone authoritative process. Omitted timing is
`simulation`. A `presentation` program runs the same task interpreter on
application frames with presentation-clock waits, including while the
simulation is paused or manually held. It submits typed domain commands and
cannot perform direct reflection or structural world writes.

An unsupported target or timing value, or an unknown metadata directive,
disables only that scenario and publishes a document diagnostic for that source
revision. Editing the source reparses its directives before the new program
runs. Timing metadata does not install schedules, and it does not choose the
script's owner.

A standalone Twin presentation program can start and handle navigation without
a scene. Its Twin lease and its own declared inputs remain mandatory.
Scene-owned programs retain the scene readiness gate.

## Presentation preparation

`on_visualization(me, ctx)` runs once in `PreUpdate`, after lifecycle,
document, and terrain admission scans and time-spine projection, but before the
first fixed tick. Scene-dependent programs wait for scene, reference, document,
and terrain preparation holds; Modelica holds do not block this visual path.
Independent presentation programs do not require scene admission.

Its context uses presentation time and has no simulation tick, so it can prepare
disposable visual state while Modelica participants are loading. Rhai blocks
world writes and events in this phase; only `ApplyUsdTransientOps` can update
the disposable USD view.

## Hot reload and teardown

Rhai is designed for a fast edit-run loop:

- The native app loads the prelude and authored scripts from disk.
- Editing a file-backed scenario can reload it without rebuilding Rust.
- The outgoing program's `on_stop` runs before the new one starts.
- On Twin close or scene replacement, the owner retires its scripts and state.

Always release control, stop actuators, and clear owned state in `on_stop` when
the script acquired them:

```rhai
fn on_stop(me, ctx) {
    brake(me);
    release_control_claim(me);
}
```

An inline `RunScenario` source has no file to watch. Re-issue the command with
the updated text to hot-reload it. A file-backed program is replaced by the
asset pipeline.

## Failure and diagnostics

Runtime errors stay visible through the script diagnostics and do not become
successful no-ops. A compile error or runtime fault is reported through
`ScriptStatus` with file, line, and column where available. `ScriptInspect`
shows the live `this` map, defined hooks, generation, and paused/running state.

A malformed directive or an invalid parameter disables only the affected
scenario. It does not fault the simulation or another runtime cycle.

## Related sections

- [Tasks](tasks.md) — the progression contract
- [Events](events.md) — delivery and event ordering
- [Commands and queries](commands-and-queries.md) — the host surface
- [Testing](testing.md) — `ScriptStatus`, `ScriptInspect`, and verdicts
