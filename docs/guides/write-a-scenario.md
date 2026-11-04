# Write a Rhai scenario

A scenario is an ordinary `.rhai` file attached to an entity. This guide builds
a small mission that drives a rover to a marker, reports arrival, and shows an
objective on the HUD.

## 1. Create the file

Add a scenario inside your Twin:

```text
my-rover-twin/
└── scenarios/
    └── drive.rhai
```

## 2. Write the policy

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

## 3. Attach the scenario

A scenario is not global. Attach it to the entity that owns the behavior, or to
a dedicated mission-control entity that never moves:

```usda
def Scope "Mission" (
    prepend apiSchemas = ["LunCoProgramAPI"]
) {
    uniform asset info:sourceAsset = @twin://my-rover-twin/scenarios/drive.rhai@
}
```

Place this prim under the entity that should be `me`. Use `@twin://...@` for a
file in the open Twin. The scenario must still find its target by name or by
an explicit reference; attachment does not automatically pick a rover.

## 4. Run and iterate

Open the Twin and load its default scene. The scenario starts when the scene is
admitted. To iterate:

- Edit the `.rhai` file; the asset watcher hot-reloads a file-backed scenario.
- The old instance's `on_stop` runs before the new one starts.
- Use **Restart scene** if you changed USD structure rather than script logic.
- Use **Scenarios** to load a different declared scene.

If you need to start a scenario explicitly, use `RunScenario` or
`RunScenarioAsset` from the API or another script. A UI-only scenario can pass
an empty scene asset.

## 5. Observe events

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

## 6. Add a verdict

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

## Common mistakes

| Symptom | Cause |
|---|---|
| Nothing moves | `nav_to` has no authored steering capability, so it brakes safely |
| Rover ignores the script | The scenario is attached to the wrong entity, or a session holds manual control |
| Objective never completes | `done` reads a stale or missing owner value |
| Event handler never runs | The event name differs, or the scenario was replaced before delivery |
| Hot reload does nothing | The script was started from an inline source, not a file-backed asset |

Next: [Inspect telemetry](inspect-telemetry.md) to read the values your
scenario produces.
