---
title: Experiments
chapter: 4
section: 5
---

# Experiments

An experiment is one run of a compiled model over an explicit time horizon,
with its own parameter overrides, inputs, solver bounds, status, and result. The
experiments framework exists so that a model can be run many times for
parametric study, regression checks, and comparison, without editing the model
source between runs.

LunCoSim has two execution modes for Modelica. **Live cosimulation** advances a
model at wall-clock pace alongside the scene, physics, and other participants.
**Fast Run** executes a model from `t_start` to `t_end` as quickly as the
machine allows and retains the trajectory. Experiments are the second mode. The
two modes share the compiler and the model source, but not the run lifecycle.

## Why experiments are first-class objects

A result file keyed only by model name forces the user to manage filenames and
to remember which parameter set produced which curve. An experiment instead
carries its own definition next to its result: overrides, inputs, bounds,
status, and trajectory travel together. The comparison view is therefore the
default view, not a separate tool that opens several files.

The framework is backend-agnostic. The current execution backend is Rumoca with
the diffsol solver. The `Experiment` and `RunResult` types do not depend on
Modelica, so an FMU-backed, code-generated, hardware-in-the-loop, or remote
worker backend can be added without changing the registry or the plots.

## The experiment record

An experiment belongs to a Twin and names an opaque model reference:

```text
Experiment
  id             stable UUID
  twin_id        owning Twin
  model_ref      backend-owned reference to the compiled model
  name           editable display name, initially "<model> — N"
  overrides      parameter path -> typed value
  inputs         input path -> typed value
  bounds         run horizon and solver options
  status         Pending, Queued, Running, Done, Failed, Cancelled
  result         retained trajectory, once complete
  created_at     creation time
  color_hint     stable plot color
```

Overrides and inputs are ordered maps keyed by a dotted Modelica path such as
`rocket.engine.thrust`. Values are typed: `Real`, `Int`, `Bool`, `String`,
`Enum`, or `RealArray`. A parameter with a non-literal binding is shown in the
override editor as unsupported; the first version does not rewrite expressions
or records.

The run bounds are:

| Field | Meaning |
|---|---|
| `t_start` | First time point |
| `t_end` | Last time point; must be strictly greater than `t_start` |
| `dt` | Output interval; omitted means a derived grid |
| `n_intervals` | Output interval count; takes precedence over `dt` |
| `tolerance` | Solver tolerance |
| `solver` | Registered solver demand |
| `h0` | Initial step hint |

Bounds are validated before registration, before scheduler admission, and again
at the shared native/browser execution boundary. The horizon must be finite and
strictly increasing. Explicit `dt`, `tolerance`, and `h0` must be finite and
positive. An interval count must be positive and at most 200,000 intervals
(200,001 inclusive points). The runner never silently enlarges an explicit
interval.

The model's own annotation supplies defaults when the experiment does not. An
explicit `Interval` annotation takes precedence over `NumberOfIntervals`. With
no annotation, the Modelica default of 500 intervals applies. An invalid
annotation is a visible failure, not an implicit substitution.

## Running an experiment

A Fast Run compiles the model once, admits the requested output grid, and then
executes the immutable compiled artifact with the experiment's parameter and
input values. The compiled artifact is not mutated per run and the source is not
reflattened for every point. Unsupported bindings are reported as run errors at
the runner boundary.

The run is asynchronous. The registry marks the row `Queued` before dispatch,
then `Running` with a current time, and finally `Done` with a wall-clock
duration, `Failed` with a diagnostic, or `Cancelled`. Progress is throttled to
roughly 10 Hz. Cancellation is polled between solver steps and is available for
queued and running rows.

A completed result contains:

```text
RunResult
  times    monotonically nondecreasing time samples
  series   dotted variable path -> samples
  meta     units, descriptions, and run facts
```

Equal timestamps are valid: a solver event can produce distinct pre-event and
post-event values at the same time. The result is stored as one immutable
`Arc`, so readers capture the exact completed trajectory without copying its
series. A failed run publishes its diagnostic without a trajectory.

The registry retains at most 20 terminal runs per Twin. Pending, queued, and
running rows are not evicted. The completed-run channel uses the scalar budget
captured at admission, so a later settings change cannot alter an in-flight
result boundary. The default result limits are 8,000,000 scalar values and
256 MiB of artifact bytes. A budget failure is a terminal `Failed` state and
releases the scheduler slot.

## The Experiments panel

The Modelica workbench exposes two run controls:

```text
[ Interactive ▶ ]   [ Fast ⏩  0 → 10 s, dt = auto ⚙ ]
```

The bounds shown beside **Fast** come from the current document annotation, or
from the documented defaults when the annotation supplies no horizon. The gear
opens the override editor.

The **Experiments** dock lists the retained runs:

```text
☑ ● rocket — 1     0..10 s   Done       1.2 s
☑ ● rocket — 2     0..10 s   Done       1.3 s
☐ ● rocket — 3     0..30 s   Failed       ⓘ
☑ ● rocket — 4     0..10 s   ▮▮▮▮▱▱ 4.2 s
```

The checkbox toggles plot visibility. The color dot is locked to the run id.
Loading or rerunning a row requires its pinned source document and runtime owner
to remain active; its overrides and bounds apply only to that document's model
draft. The row shows **Queued** when the scheduler is full; the Run button queues
work rather than disabling.

The **Graphs** panel uses one variable picker across experiments. Each selected
variable plots once per checked run, and the legend reads
`<experiment> · <variable path>`. The plot renderer is shared with the live
trajectory view. It supports log-Y, fit/reset, overlays, and scrubbing. Long
series are min-max decimated to about one sample per display point before
drawing, which preserves narrow peaks.

## Parallel execution

A sweep runs several points at once under one bounded scheduler. Two mechanisms
make this efficient and both are part of the current implementation.

**Compile once, sweep many.** Batch and live compilation share admitted source
roots and a bounded compiled-artifact cache keyed by the exact target, document
URI, source bytes, and library generation. The runner applies parameter
overrides and initial inputs to the compiled model without reflattening it per
point. Browser batches compile in the Modelica Web Worker.

**Per-run demultiplexing.** Results route by exact run id and admitted origin.
Native runs use one channel per run handle; the browser build uses a run-id map
in the worker transport. Cancellation is per run.

`max_parallel` bounds the whole scheduler, not one model. The defaults are:

| Platform | Primitive | Default cap |
|---|---|---|
| Native | One thread per run | `available_parallelism() - 1`, clamped to 1–4 |
| Browser | Persistent worker pool | Auto is 1; the pool is clamped to at most 8 workers |

Worker 0 is the primary for parse, compile, and source-library traffic. Every
worker, including worker 0, can execute a Fast Run; dispatch prefers a free
non-primary worker and falls back to worker 0 only when the others are busy.

The native spawn is fallible. A worker panic becomes a terminal `Failed`
diagnostic, and the completion guard releases the scheduling slot on every exit.
A poisoned compiler fails subsequent compilation visibly. Cancelling a queued
job withdraws it immediately; cancelling a running job prevents trajectory
publication. Closing a Twin cancels that owner's queued and executing runs.

The cap is global and deliberately modest: each concurrent run holds its own
result buffers and DAE clone, and the browser additionally holds an MSL copy per
worker. Changing the cap at runtime on the web build requires a page reload to
resize the fixed pool.

## Durable history

Completed runs can be persisted as optional artifacts next to the Twin. The
artifact adapter captures the exact runtime owner, storage root, result limits,
immutable definition, and trajectory. A durable write announces a new manifest
only after storage reports success. Application runs have no Twin artifact
destination.

The persisted envelope is versioned JSON. It does not store raw workspace Twin
IDs or filesystem roots. A compiler-owned content identifier describes the
successful strict target and the participating source contributions before user
overlays are cleared; host paths and mount identifiers do not contribute.
Parsed library records retain their exact source text, so participating library
bytes contribute to the identifier while unused libraries do not.

Storage lists at most the registry's 20 retained entries and reads each
candidate under the captured byte cap. A malformed or missing optional history
warns without failing authored loading or a valid run. Rehydration uses the same
bounded registry, an explicit archived runtime origin, and `restored_history`
metadata; it emits no live completion or playback. An archived trajectory is
queryable without pretending it came from the currently edited document.

## Reproducibility

A run is reproducible when its inputs are fixed:

- the model source and every library that contributes to the compile;
- the exact target and compiler build;
- parameter overrides, inputs, and initial values;
- bounds, tolerance, solver, and initial step;
- the result limits, which determine whether a run completes or fails.

The artifact content identifier covers the compiled target and participating
sources. It does not cover presentation metadata such as the experiment name or
color, which may change without invalidating history.

## Known limits

| Limit | Consequence |
|---|---|
| One global `max_parallel` | A large sweep and a small sweep share the same bound |
| Cold cache race | Two cache-miss runs of one model can compile the same DAE concurrently; the duplicate work is harmless |
| Memory | N concurrent runs hold N result buffers and N DAE clones |
| Registry cap | At most 20 terminal runs per Twin are retained |
| Override scope | Inherited, expression-bound, array, and record parameters are not overridable in the first version |
| Browser pool | A runtime cap change needs a page reload |
| No parameter grid UI | A sweep is currently defined by individual experiment rows |

## Relation to live cosimulation

Experiments do not replace live cosimulation. A live participant keeps a
persistent session and exchanges values at communication points; an experiment
compiles, runs to completion, and retains a trajectory. A model can be exercised
in both modes, but an experiment result is not a live scene state and cannot be
possessed or wired into physics. Use live cosimulation to inspect behavior in
the scene and experiments to compare many parameter sets quickly.

Continue with [Rhai](../rhai/index.md), which owns mission sequencing and the
policy that reacts to simulation state.
