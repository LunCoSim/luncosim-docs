---
title: Patterns
chapter: 5
section: 6
---

# Patterns

The patterns below are compositions of the same small surface: a task tree, an
event reaction, a query, and a typed command. They are policy, not engine
features. Copy the shape, then put the vehicle-specific numbers in the Twin.

## Route following

A route is an ordered set of USD points plus a sibling program. The program
resolves its subject, reads the point poses, and advances only when the matching
sensor event arrives:

```rhai
fn task(me, ctx) {
    let points = ctx.points;
    let steps = [];
    for point in points {
        steps.push(step(
            |m| nav_to(m, point, 1.0, 2.0),
            |m| arrived(m, point, 2.0),
        ));
    }
    seq(steps)
}
```

A file-backed route program resolves its ordered point scope from USD and passes
the poses into the same task shape. The reusable `route_follow` policy records
only the next unvisited point in USD order. Out-of-order arrivals do not mark
later points. A visited point is turned gray through the transient USD view; the
authored `route_point.usda` marker owns the standard translucent, unlit,
shadowless visual.

Route points are not stored on a vessel-owned list. The scene owns the route,
and the program owns the traversal policy.

## Coordinator and workers

Use one coordinator when several workers must not race for assignments:

```rhai
// Coordinator
fn on_event(me, evt, ctx) {
    if evt.name == "WORKER_READY" {
        let worker = evt.value.worker;
        emit("ASSIGNMENT", #{ worker: worker, task: this.next_task });
        this.next_task += 1;
    }
}
```

```rhai
// Worker
fn on_start(me, ctx) {
    emit("WORKER_READY", #{ worker: me });
}

fn on_event(me, evt, ctx) {
    if evt.name == "ASSIGNMENT" && evt.value.worker == me {
        this.task = evt.value.task;
    }
}
```

The workers never call each other. They publish readiness and completion, and
the coordinator owns the assignment order. This is the multi-robot mission
pattern used by the example coordinator and worker scenarios.

## Reactive obstacle avoidance

A reactive selector prefers avoidance while an obstacle is present and falls
back to the route:

```rhai
fn task(me, ctx) {
    reactive_sel([
        seq([
            check(|m| obstacle_ahead(m, 8.0, 50.0)),
            once(|m| brake(m)),
        ]),
        forever(step(
            |m| nav_to(m, [120.0, 0.0, 50.0], 0.7, 3.0),
            |m| false,
        )),
    ])
}
```

`obstacle_ahead` is a sensing helper, not a native autopilot. The policy decides
whether to brake, steer, or wait. Continuous steering remains in the authored
drive law.

## Phases and durable checkpoints

Keep the phase in `this` for the current run and checkpoint it in USD when the
mission must survive a reload:

```rhai
fn on_start(me, ctx) {
    this.phase = mission_checkpoint_read(me, "phase");
    if this.phase == () { this.phase = "descent"; }
}

fn on_event(me, evt, ctx) {
    if evt.name == "TOUCHDOWN" && this.phase == "descent" {
        this.phase = "surface";
        mission_checkpoint(me, mission_document(me), "@root@", "phase", "surface");
    }
}
```

`mission_document(me)` returns the explicit document id supplied by
`ListOpenDocuments`. The checkpoint helper writes a `lunco:mission:checkpoint:`
attribute through `ApplyUsdOp`; it does not invent a second persistence file.

## Controller claim

A vessel that drives itself through an authored program has three layers:

- the control law in Modelica;
- the mission logic in Rhai;
- the structure and authority in USD.

Claim authority before commanding a vessel that expects an external pilot:

```rhai
fn on_start(me, ctx) {
    claim_control(me);
}

fn on_stop(me, ctx) {
    brake(me);
    release_control_claim(me);
}
```

`AcquireControl` composes the claim with an avatar `ControlLink` and optional
camera binding. `ClaimControl` updates the session authority table without an
avatar, which is what a headless run needs.

Control authority is the wired `piloted` signal. An unpossessed vessel can still
fly its own guidance; it discards external stick writes. If a vehicle "ignores
throttle and just falls", check authority before debugging the command.

## Tutorial flow

A tutorial is a scenario. The HUD prelude exposes the presentation primitives:

| Helper | Presents |
|---|---|
| `hint(msg)` / `clear_hint()` | A sticky instruction |
| `objectives_hud(list)` | An objective list; `mission` auto-publishes |
| `guided_hud_actions(tool, hook, actions)` | Persistent semantic buttons |
| `spotlight(anchor, caption)` | A dimmed, ringed workbench widget |
| `focus_panel(id)` | Opens a singleton workbench panel |
| `coach_step(steps, i)` | One coach-mark tour step |

Tutorial progression is authored in the lesson's `on_event`, where it matches
raw public event names such as `cmd:<Name>`, `key:<Name>`, and authored
simulation events. `coach_step` only presents a step; it does not advance the
cursor.

Keep lesson-specific runtime checks in Rhai observers under
`assets/scenarios/tests/` and run them through `luncosim test`, so changing a
tutorial script does not require rebuilding Rust.

## Tool libraries

Put reusable policy in a tool library rather than copying it into every
scenario:

```rhai
let plan = formation::line(leader, 4, 12.0);
```

A tool is a named bundle callable as `libname::fn(...)` from any hook. Tools can
import other registered tools with ordinary Rhai syntax. A tool that must be
available before the first lifecycle hook should be imported by its explicit
`lunco://` asset URI, because a namespace call does not declare an asset
dependency.

Use a tool for geometry, formation, survey, or authoring policy that several
Twin scenarios share. Keep vehicle-specific limits and mission text in the Twin.

## Script-first authoring

A scenario can build or inspect a USD assembly through explicit document ids:

```rhai
let context = model_authoring::model_context(doc, root, "@root@");
let ready = model_authoring::readiness_report(doc, root, "@root@", policy);
let recipe = model_authoring::scene_recipe(doc, "@root@", scene, context.generation);
```

The sequence is `inspect` → `plan` → `apply` → `checkpoint`. Keep the identity
tuple from the document read: document, root path, edit target, generation.
Apply through `assembly_edit::batch` or the normal proposal/review/commit flow,
then re-read the new generation. Do not write USDA text directly.

## Anti-patterns

| Pattern | Problem | Use instead |
|---|---|---|
| `on_tick` control loop in production | Duplicates the kernel and hurts determinism | `task`, `wait_until`, `on_event` |
| `while true` inside a hook | Blocks the owner and never yields | A task tree with waits |
| Polling a value every tick | Wastes work and hides the real transition | A predicate or event leaf |
| Direct writes from a client script | No prediction or forwarding path | A typed command |
| One scenario for every entity | Shared state and unclear ownership | One program per owner, events between them |
| Hardcoded scene paths | Breaks when the Twin moves | `twin://` and `lunco://` addresses |
| Copying a prelude helper | Drifts from the shared contract | A tool library |

## Related sections

- [Tasks](tasks.md) — the node schema behind these patterns
- [Events](events.md) — coordinator and sensor events
- [Tooling](tooling.md) — prelude, tools, and authoring libraries
- [Script a mission](../tutorials/script-a-mission.md) — a guided build
