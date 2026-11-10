---
title: Tasks
chapter: 5
section: 2
---

# Tasks

A mission is a **task tree**. `task(me, ctx)` returns pure data once, and the
native behavior kernel advances one deterministic step per fixed tick. The
kernel owns the cursor, dwell timestamps, event delivery, and terminal status.
The script owns which actions, predicates, event names, and compositions the
mission requests.

This split is the reason a production scenario does not need a fixed-tick loop.
A hand-written `on_tick` cursor duplicates the kernel and makes the mission less
deterministic.

## One explicit node schema

Every node is a map with a required string `kind`. There is no inference from
which fields happen to be present, no default leaf, and no fallback spelling.
The prelude constructors are the authoring API. Handwritten maps are useful for
tests and generated policy only when they obey the same schema.

| `kind` | Required fields | Runtime meaning |
|---|---|---|
| `once` | `act` | Call the action once, then succeed |
| `step` | `act`, `done` | Call the action while the predicate is false |
| `act_for` | `act`, `secs` | Call the action while the simulation dwell is active |
| `act_until_event` | `act`, `event`, `src` | Call the action until the named event arrives from the specified gid or path |
| `wait` | `secs` | Succeed after the simulation dwell |
| `wait_until` | `done` | Succeed when the predicate returns true |
| `wait_for` | `event` | Succeed when any emitter produces the event name |
| `wait_for_from` | `event`, `src` | Succeed for the event from the specified gid or path |
| `check` | `check` | Return success or failure immediately from the predicate |
| `seq`, `sel`, `all`, `race`, `reactive_seq`, `reactive_sel` | `items` | Compose child nodes |
| `repeat`, `retry` | `n`, `body` | Repeat a child by count or retry failures |
| `forever`, `invert`, `force_ok`, `force_fail` | `body` | Apply a decorator to one child |

Unknown kinds, missing required fields, wrong field types, and fields belonging
to another kind are compile errors. `__bt` is reserved runtime bookkeeping on
the root map and is not authored policy.

The words in `kind` are schema discriminators, not mission text. Event names
such as `"GO"` and emitted telemetry names remain authored protocol strings.

## Leaf callbacks

Action and predicate fields accept either an anonymous Rhai closure with one
positional argument (`|me| ...`) or a named script function pointer
(`Fn("name")`, declared as `fn name(me)`). `me` is the host entity id. Both
forms access the persistent scenario-state map as the driver-bound `this`.

The native task driver borrows that map directly and owns progression for both
forms. Callback errors propagate as script diagnostics; state mutations already
performed remain in the bound map, as they do for lifecycle hooks.

Rhai maps passed to helper functions are value or copy-on-write values.
Assigning a field in a helper does not update the caller's `this`. A helper that
changes task state must return the updated map or an explicit result, and the
lifecycle callback must assign it back to `this`.

```rhai
fn task(me, ctx) {
    seq([
        once(|m| drive(m, 1.0, 0.0)),
        wait_until(|m| arrived(m, [10.0, 0.0, 0.0], 2.0)),
        wait_for("SAMPLE_READY"),
    ])
}
```

## Constructors

The prelude in `tasks.rhai` exposes the readable constructors:

| Constructor | Composes |
|---|---|
| `once(act)` | One action, then success |
| `step(act, done)` | Drive until a predicate is true |
| `act_for(act, secs)` | Run an action for a simulation dwell |
| `act_until_event(act, event, src)` | Run an action until a scoped event |
| `wait(secs)` | A simulation dwell |
| `wait_until(done)` | A predicate wait |
| `wait_for(event)` | An unscoped event wait |
| `wait_for_from(event, src)` | An event wait scoped to a source |
| `check(pred)` | An immediate pass/fail predicate |
| `seq(items)` | Run children in order |
| `sel(items)` | Select the first child that succeeds |
| `par_all(items)` | Run children in parallel; all must succeed |
| `par_race(items)` | Run children in parallel; the first terminal result wins |
| `reactive_seq(items)` | Re-evaluate children reactively in sequence |
| `reactive_sel(items)` | Re-evaluate children reactively for selection |
| `repeat(n, body)` | Repeat a child a fixed number of times |
| `forever(body)` | Repeat a child indefinitely |
| `retry(n, body)` | Retry a failing child |
| `invert(body)` | Invert success and failure |
| `force_ok(body)` | Treat any result as success |
| `force_fail(body)` | Treat any result as failure |

The kernel emits `TASK_COMPLETE` or `TASK_FAILED` for the native task root.

## A route mission

```rhai
fn task(me, ctx) {
    let goals = [[12.0, 0.0, 0.0], [12.0, 0.0, 25.0]];
    let steps = [];
    for i in 0..goals.len() {
        let goal = goals[i];
        steps.push(step(
            |m| nav_to(m, goal, 1.0, 2.0),
            |m| arrived(m, goal, 2.0),
        ));
    }
    steps.push(wait_for("MISSION_RELEASE"));
    seq(steps)
}
```

`nav_to` publishes a waypoint to the authored drive law; it does not integrate
motion itself. `arrived` reads the authoritative pose and checks the radius.

## Reactive selection

A reactive tree can prefer an avoidance branch while an obstacle is present and
otherwise follow the route:

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

## Objectives

`mission(me, ctx)` is separate from `task`. It declares objective state and
completion conditions that the runtime can display and evaluate:

```rhai
fn mission(me, ctx) {
    let goal = [12.0, 0.0, 8.0];
    [
        objective("reach_marker", #{
            text: "Drive to the marker",
            done: |m| arrived(m, goal, 2.0),
        }),
    ]
}
```

An objective is policy, not a second progression engine. The task tree still
owns the actions and waits that move the mission forward.

## Timelines

A timeline is a mission expressed as pure data. Each step contains exactly one
explicit operation word and only that operation's fields:

| Operation | Meaning |
|---|---|
| `move_to` | Drive to a world position |
| `move_to_entity` | Drive to another entity |
| `possess` | Acquire control of a subject |
| `brake` | Stop a subject |
| `cmd` | Issue a typed command |
| `emit` | Publish a telemetry event |
| `wait` | Dwell for simulation seconds |
| `wait_event` | Wait for a named event |

Common fields such as `subject`, `speed`, `radius`, `secs`, `params`, and
`value` are validated against the selected operation at the command boundary.

`compile_timeline` lowers a timeline onto the same task-tree contract. A
timeline is serializable, so it can run inline with `RunTimeline` or be stored
and run with `RunStoredTimeline`. Stored timelines live under
`<twin>/timelines/*.json` and are discovered with `ListTimelines` and
`GetTimeline`.

Timelines do not create a second progression engine. They lower into the same
`task(me, ctx)` contract.

## Task state and durability

Use `this` for ordinary per-instance task state. For a mission that must resume
after a hot reload or restart, author phase state on the host prim through the
explicit USD document path:

```rhai
fn mission_document(me) {
    // Return the document id supplied by ListOpenDocuments.
    42
}
```

`mission_checkpoint` and `mission_checkpoint_read` write and read USD string
attributes at objective or phase boundaries. This keeps durable state in USD
rather than in a second persistence mechanism.

## Authoring rules

- Return a tree from `task(me, ctx)`; do not implement a fixed-tick loop.
- Use `wait_for` and `wait_until` instead of polling in `on_tick`.
- Keep event names stable; they are the authored protocol between scripts.
- Keep leaf callbacks pure where possible; return state changes explicitly.
- Prefer an existing composite or decorator before adding a new mechanism.
- Use `on_tick` only in authored tests that sample state and publish a verdict.

## Related sections

- [Lifecycle](lifecycle.md) — when the tree is built and retired
- [Events](events.md) — event delivery and ordering
- [Patterns](patterns.md) — route, coordinator, and checkpoint patterns
- [Testing](testing.md) — task-contract tests
