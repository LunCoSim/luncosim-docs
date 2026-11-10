---
title: Script a mission
chapter: 2
section: 5
---

# Script a mission

A scenario is an ordinary `.rhai` file attached to an entity. This tutorial
builds a small mission that drives a rover to a marker, reports arrival, and
shows an objective on the HUD. It then turns the same scenario into an authored
test with a verdict.

The tutorial assumes a scene with a rover that has an authored drive law and a
marker at a known position. The [First Drive](../tutorials/first-mission.md)
sandbox is a suitable starting point; use **Save as Twin…** to make an editable
copy.

## Create the file

Add a scenario inside your Twin:

```text
my-rover-twin/
└── scenarios/
    └── drive.rhai
```

## Write the policy

```rhai
fn marker() {
    [12.0, 0.0, 8.0]
}

fn task(me, ctx) {
    let goal = marker();
    seq([
        once(|m| notify("Driving to the marker")),
        step(|m| nav_to(m, goal, 1.2, 2.0),
             |m| arrived(m, goal, 2.0)),
        once(|m| {
            brake(m);
            emit("MARKER_REACHED", goal);
        }),
    ])
}

fn mission(me, ctx) {
    let goal = marker();
    [
        objective("reach_marker", #{
            text: "Drive to the marker",
            done: |m| arrived(m, goal, 2.0),
        }),
    ]
}

fn on_event(me, evt, ctx) {
    if evt.name == "MARKER_REACHED" {
        notify_kind("Marker reached", "success");
    }
}
```

What each part does:

| Part | Role |
|---|---|
| `task(me, ctx)` | Returns a task tree that the native behavior kernel advances |
| `seq([...])` | Runs steps in order |
| `once(...)` | Runs one action and advances |
| `step(act, done)` | Repeats `act` until `done` is true, then advances |
| `wait(secs)` | Suspends for simulation seconds |
| `wait_until(pred)` | Suspends until the predicate becomes true |
| `wait_for("NAME")` | Suspends until a named event arrives |
| `mission(me, ctx)` | Declares objectives checked against live state |
| `on_event(...)` | Reacts to an event outside the task tree |

`nav_to` is a prelude helper that publishes a waypoint to the authored drive
law. It does not integrate motion itself. `arrived` reads the authoritative
pose and checks the radius.

Do not add `on_tick` to a production scenario. The task kernel already advances
steps, waits, and predicates; a hand-written tick loop duplicates it and makes
the scenario less deterministic. `on_tick` is reserved for test sampling.

## Attach the scenario

A scenario is not global. Attach it to the entity that owns the behavior, or to
a dedicated mission-control entity that never moves:

```usda
def Scope "Mission" (
    prepend apiSchemas = ["LunCoProgramAPI"]
) {
    uniform token info:implementationSource = "sourceAsset"
    uniform asset info:sourceAsset = @twin://my-rover-twin/scenarios/drive.rhai@
}
```

Place this prim under the entity that should be `me`. Use `@twin://...@` for a
file in the open Twin. The scenario must still find its target by name or by
an explicit reference; attachment does not automatically pick a rover.

A scenario can also be started explicitly with `RunScenario` or
`RunScenarioAsset` from the API or another script. A UI-only scenario can pass
an empty scene asset.

## Run and iterate

Open the Twin and load its default scene. The scenario starts when the scene is
admitted. To iterate:

- Edit the `.rhai` file; the asset watcher hot-reloads a file-backed scenario.
- The old instance's `on_stop` runs before the new one starts.
- Use **Restart scene** if you changed USD structure rather than script logic.
- Use **Scenarios** to load a different declared scene.

Hot reload applies to file-backed assets. A script started from an inline
source has no file to watch, so editing a file elsewhere does not replace it.

## Observe events

Events are the preferred coordination mechanism:

```rhai
fn on_event(me, evt, ctx) {
    if evt.name == "MARKER_REACHED" {
        this.reached = true;
    }
    if evt.name == "LOW_FUEL" {
        notify_kind("Fuel is low", "warn");
    }
}
```

A script emits with `emit("NAME", value)`. Events are delivered on the next
fixed step, so ordering does not depend on entity iteration order. Scenarios do
not call each other directly; they interact through the event bus and the
shared command/query surface.

Events emitted while a pass is delivering its current batch are queued for the
following pass. A new or restarted program does not receive events accumulated
before its `on_start`; query current state instead of relying on history.

## Add a verdict

A scenario can also be a test. Use the prelude assertions and report one typed
verdict at the end:

```rhai
fn on_start(me, ctx) {
    this.start = world_pos3(me);
    this.reported = false;
}

fn on_event(me, evt, ctx) {
    if evt.name != "MARKER_REACHED" { return; }
    if this.reported { return; }
    this.reported = true;

    let pos = world_pos3(me);
    let distance = if pos == () || this.start == () {
        ()
    } else {
        vlen(vsub(pos, this.start))
    };

    let fails = [];
    fails.push(t_present(pos, "rover position"));
    fails.push(t_moved(distance, 3.0, "rover travel"));
    report_verdict(fails, "DRIVE TEST", "DRIVE_TEST");
}
```

`t_moved` uses the measured distance, not a hardcoded pass value. Pairing it
with `t_present` also proves the test read a real position. Run the scenario
through the production scene-test binary, not a private harness.

## Run the authored test

```bash
luncosim test --scene path/to/my-rover-twin/tests/drive.usda
```

The exit code is the verdict:

| Exit | Meaning |
|---|---|
| `0` | PASS |
| `1` | FAIL |
| `2` | No verdict was produced |

A test that exhausts its tick budget without a verdict is exit `2`. Keep a
negative fixture for the behavior you are guarding; a test that cannot fail is
not evidence.

## Common mistakes

| Symptom | Cause |
|---|---|
| Nothing moves | `nav_to` has no authored steering capability, so it brakes safely |
| Rover ignores the script | The scenario is attached to the wrong entity, or a session holds manual control |
| Objective never completes | `done` reads a stale or missing owner value |
| Event handler never runs | The event name differs, or the scenario was replaced before delivery |
| Hot reload does nothing | The script was started from an inline source, not a file-backed asset |
| Test exits `2` | The scenario never published a verdict |

## Related sections

- [Rhai](../rhai/index.md) — the language and runtime contract
- [Lifecycle](../rhai/lifecycle.md) — `on_start`, `on_event`, `on_stop`
- [Tasks](../rhai/tasks.md) — the task-tree schema
- [Testing](../rhai/testing.md) — verdicts and scene tests
- [Inspect telemetry](../ui/telemetry.md) — read the values your scenario
  produces
