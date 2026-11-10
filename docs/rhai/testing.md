---
title: Testing
chapter: 5
section: 5
---

# Testing

A scenario can be a test. The same Rhai runtime that drives a mission can sample
live state, assert a property, and publish a typed verdict. The production
scene-test runner consumes that verdict and turns it into a process exit code.
No private Rust harness and no rebuilt simulator are required.

## The verdict contract

A test scenario emits a telemetry event on a named channel:

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

`report_verdict(fails, title, channel)` prints the failures, emits a typed
verdict on `channel`, and raises a notification. The runner reads the channel
and returns:

| Exit | Meaning |
|---|---|
| `0` | PASS |
| `1` | FAIL |
| `2` | No verdict was produced |

A test that exhausts its tick budget without a verdict is exit `2`. That is a
failure of the test, not a pass by default.

## Assertion helpers

The `auto_tests.rhai` prelude provides checks that return an empty string on
success and a self-describing message on failure. The caller collects them into
an array, so every check runs and the report names all failures.

| Helper | Checks |
|---|---|
| `t_range(v, lo, hi, what)` | A value lies inside an inclusive range |
| `t_max(v, limit, what)` | An absolute value does not exceed a bound |
| `t_true(cond, what)` | A plain predicate |
| `t_present(v, what)` | A value was measured at all |
| `t_rel(a, b, tol_pct, what)` | Two values agree within a relative tolerance |
| `t_bounded(pos, radius_m, what)` | A body remains at a finite position inside the scene |
| `t_moved(distance_m, min_m, what)` | Something actually moved |

A silent pass is not a pass. A hook that never fires, a `find` that returned
`-1`, and a phase that never advanced all look like a clean run. Pair a
measurement check with `t_present`, and pair a stationary check with `t_moved`,
so a dead command surface cannot produce a meaningless match.

`report_structured_verdict(report, title, channel)` accepts a structured
requirement report with `pass`, `fail`, `inconclusive`, `error`, or `unverified`
evidence. A report with no checks and no results is `inconclusive`, not a pass.

## Negative fixtures

A test that cannot fail is not evidence. Keep a fixture that reproduces the
defect the test is guarding against:

- `expect_fault(port)` declares a deliberately dangling port in a lint fixture.
  The runner asserts that the declared port really dangles.
- `expect_runtime_fault(kind)` declares the terminal runtime fault a negative
  production fixture must reproduce.
- `expect_scene_load_failure(path, detail_contains)` asserts that a later
  `load_scene(path)` fails with the specified terminal detail.

These helpers assert, they do not mute. A fixture that quietly stops
reproducing its defect fails the scene.

## Where tests live

A production scene test keeps the fixture and the observer in the authored
asset tree:

```text
assets/
├── scenes/tests/
│   └── rover_drive.usda
└── scenarios/tests/
    └── rover_drive.rhai
```

The fixture scene carries the geometry, physics, and program attachments. The
observer scenario is attached to a host prim and publishes the verdict. Assert
the public command or query result, not a private script detail.

Do not embed a large USDA string in a Rust test when the behavior can be
observed through the production scene runner. Rust tests remain for low-level
parsing, serialization, lowering, and generic engine seams that Rhai cannot
observe.

## Running a scene test

```bash
luncosim test --scene assets/scenes/tests/rover_drive.usda
luncosim test --list
```

| Option | Meaning |
|---|---|
| `--list` | List discovered test scenes and their execution kind |
| `--verdict-channel NAME` | Accept the verdict only from this channel |
| `--verification QUALIFIED_NAME` | Require a Twin manifest SysML verification mapping |
| `--max-ticks N` | Bound cumulative fixed steps; default 20000 |
| `--tick-hz HZ` | Manual update rate; default 60 |
| `--readiness-timeout SECS` | Bound scene and participant preparation; default 420 |
| `--determinism-reference PATH` | Load a typed JSON state reference for Rhai comparisons |
| `--threads N` | Compute-pool width; `1` is the gate profile |
| `--jitter FRAC` / `--seed U64` | Exercise seeded fractional-`dt` pacing |

The scene runner defaults to four independent headless production processes.
`-j/--jobs N` changes that bound without changing each gate process's
deterministic `--threads 1 --jitter 0`. Use `-j 1` when diagnosing ordering or
resource interactions. Graphics assertions remain a separate serial offscreen
pass.

`--validate` is not a substitute. It proves that files parse and declarations
are structurally valid; it does not prove that a body moved, a joint held, or a
mission completed. See [Validation](../reference/validation.md) for the
evidence layers.

## One-shot checks

For a standalone Rhai assertion that needs a live USD world, keep one API
session open and run the source through `RunRhai`:

```bash
luncosim rhai --api 4101 -f scripts/check.rhai
```

The REPL and the evaluator are deliberately separate. The running host owns the
Rhai engine and the reflected `RunRhai` command; the terminal client only sends
the generic API envelope and formats the result. That means the terminal path
uses the same command path as every other external client.

`RunRhai` is a one-shot evaluation with full world access in a bounded FIFO
cycle. It does not attach a persistent scenario. Use `RunScenario` for a
persistent per-entity observer and `RunRhai` for a quick verdict or inspection.

## Debugging a test

- `print(...)` lands in the console and in the test output.
- `ScriptStatus { target }` reports compile and runtime health, including
  located errors.
- `ScriptInspect { target }` shows the live `this` map, defined hooks,
  generation, and paused/running state.
- `report_verdict` prints `TESTS_OK` or `TESTS_FAIL` and the human title.

```json
{
  "type": "ExecuteCommand",
  "command": "ScriptStatus",
  "params": { "target": 4869542932533563 }
}
```

A function pointer in live state is represented as a read-only map with
`kind: "function"`, `name`, `anonymous`, and `curried_argument_count`. The API
exposes its identity for diagnosis; it does not expose callable function values.

## Sampling with `on_tick`

`on_tick` is reserved for authored tests. It samples state on the authored
cadence and publishes a bounded verdict:

```rhai
fn on_tick(me, ctx) {
    if sim_tick() < 120 { return; }
    if this.reported { return; }
    this.reported = true;

    let fails = [];
    fails.push(t_range(get(me, "Battery.level"), 0.0, 1.0, "battery level"));
    report_verdict(fails, "BATTERY SAMPLE", "BATTERY_SAMPLE");
}
```

Production missions use `task`, `wait_until`, and `on_event` instead. A
hand-written tick loop duplicates the kernel and makes the mission less
deterministic.

## Determinism

A test should produce the same result from the same inputs. Use the fixed clock
(`sim_tick`, `dt`, `elapsed_seconds`) for timing, and use the deterministic
`rand` helpers rather than an external entropy source. When a test needs a
stored state reference, load it with `--determinism-reference` and compare
typed values rather than formatted strings.

## Related sections

- [Lifecycle](lifecycle.md) — readiness and `on_start`
- [Tasks](tasks.md) — task-contract tests
- [Patterns](patterns.md) — mission patterns worth testing
- [Validation](../reference/validation.md) — parse, lint, runtime, and evidence
