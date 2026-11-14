---
title: Programs
chapter: 4
section: 4
---

# Programs

A program is the behavior attached to a prim. Modelica, Rhai, and optionally
Python programs all use the same `LunCoProgramAPI` schema and the same
source-backed lifecycle. The schema applies directly to the physical prim when
the behavior is intrinsic, or to a child `Scope` when the behavior is
separable.

This is a deliberate simplification. There is no global script list, no
scene-level controller registry, and no hidden behavior that survives deleting
the program prim or the object that owns it.

## The program prim

```usda
def Xform "Rover" (kind = "assembly")
{
    def Scope "Controller" (
        prepend apiSchemas = ["LunCoProgramAPI"]
    )
    {
        uniform token info:implementationSource = "sourceAsset"
        uniform asset info:sourceAsset = @twin://my-rover/models/Drive.mo@
        uniform bool lunco:program:realtimeSafe = true
    }
}
```

| Property | Meaning |
|---|---|
| `info:implementationSource` | `"sourceAsset"` for a file, `"sourceCode"` for inline text, `"id"` for a runtime-implemented driver |
| `info:sourceAsset` | Asset address of the source file |
| `info:sourceCode` | Inline source text, when using `sourceCode` |
| `lunco:program:realtimeSafe` | Declares that the program can meet the real-time step budget |

The example uses a child `Scope`, the separable placement: the controller is
bolted onto the rover and can be removed without removing the airframe. Apply
the same schema directly to the physical prim when the program is the thing
itself — a lander's flight-control system, for example — so its `inputs:` are
the vehicle's control surface. In both placements the ports live on the prim
that carries the schema, and a connection targets those ports.

For a source asset, the backend is selected from its extension:

| Extension | Backend |
|---|---|
| `.mo` | Modelica |
| `.rhai` | Rhai |
| `.py` | Python, when the optional feature is built |

A missing or unrecognized extension is an explicit program error. It is not
guessed from the prim name or the folder.

## Implementation arms

Use `sourceAsset` for anything a person will edit, review, or reuse:

```usda
uniform token info:implementationSource = "sourceAsset"
uniform asset info:sourceAsset = @lunco://models/RoverDrive.mo@
```

Use `sourceCode` only for small, generated, or test-only programs:

```usda
uniform token info:implementationSource = "sourceCode"
uniform string info:sourceCode = "fn on_start(me, ctx) { notify(\"ready\"); }"
```

Use `id` for a driver the runtime already implements, such as `range_beam`.
The selected arm is authoritative: exactly one of `info:id`,
`info:sourceAsset`, or `info:sourceCode` may be populated. A populated
non-selected arm is an authoring conflict, not a fallback.

A file-backed program participates in the asset pipeline: it reloads when the
file changes, resolves its imports through the asset owner, and can be opened
in the appropriate editor. Inline source has none of that provenance. It is
appropriate for a fixture, not for a project a team maintains.

## Attaching a program

The typed authoring intent is `AttachProgram`. It authors the child prim,
declared scalar ports, defaults, and USD connections as one change set. The
same operation is exposed to scripts as `assembly_edit::attach_program` and to
the UI as the program attachment flow.

Attaching a program is an ordinary USD edit. It enters the journal, can be
undone, and is saved with the document. The runtime does not create a program
prim behind the author's back.

`AttachProgram` attaches a child program to any prim that can own one. The
common choices are the assembly root, a controller scope, or a dedicated
behavior prim. Keep the program near the thing it controls so deleting the
assembly deletes the behavior. For an intrinsic program, apply
`LunCoProgramAPI` to the physical prim directly; that is a schema application
rather than the child-prim flow.

## The realtime promise

`lunco:program:realtimeSafe = true` is a declaration, never an inference. No
amount of reading a model's source establishes how long it takes to step.

The promise matters when a program writes a force or torque port on a
client-predicted body. Without it, the wiring pass refuses that wire and
reports the reason. This prevents a slow solver from being admitted into a
path that must meet the presentation clock.

Absent or `false` means "not promised." A malformed value is ignored with a
warning; it does not become `true`.

## Program lifecycle

A source-backed program follows the same sequence in every backend:

1. The program prim is discovered during projection. For a child program, the
   owning prim is projected first.
2. The source asset is resolved through the asset owner.
3. The source is compiled or parsed into an interface.
4. Declared ports and authored defaults are checked against that interface.
5. Connected inputs are admitted, possibly through coupled initialization.
6. The program starts and participates in the fixed-step clock.
7. On detach, hot reload, or scene teardown, the old program stops before a
   replacement starts.

A terminal interface error faults the participant instead of leaving an
unresolved readiness wait. Source replacement refreshes the same checked
interface through its owner.

### Hot reload

Editing a file-backed program can reload it without rebuilding Rust. The
outgoing program's stop hook runs before the new one starts. For Rhai this is
`on_stop`; for Modelica it is session retirement and recompilation.

Hot reload is not a scene restart. The document, the stage, and unrelated
participants stay live. A program that acquired control must release it in its
stop hook.

## Modelica programs

A `.mo` program is a Modelica class compiled by Rumoca and run on a background
worker. Its public ports come from the checked DAE, not from the source text
alone:

- runtime inputs are writable;
- numeric observables, including authored outputs and local states, are
  readable;
- constants, runtime inputs, and parameters are not published as outputs.

The program prim's `inputs:` and `outputs:` properties are the external
contract. They must match the compiled interface. See
[Modelica](../modelica/index.md) for the language and
[Cosimulation](../modelica/cosimulation.md) for the step contract.

## Rhai programs

A `.rhai` program is a scenario with lifecycle hooks. It observes the
simulation, reacts to events, and issues typed commands. It does not integrate
physics or replace a Modelica model.

```usda
def Scope "Mission" (
    prepend apiSchemas = ["LunCoProgramAPI"]
) {
    uniform token info:implementationSource = "sourceAsset"
    uniform asset info:sourceAsset = @twin://my-rover/scenarios/drive.rhai@
}
```

The asset source is loaded and hot-replaced by the asset layer. A scenario can
also be run directly against an entity with `RunScenario`, or run as a
file-backed asset with `RunScenarioAsset`. See [Rhai](../rhai/index.md).

## Python programs

Python is an optional feature. When built, a `.py` program is loaded through
the same source-backed path. Python does not implement the scenario lifecycle
hooks; it supports the one-shot `RunPython` command and a participant source
seam. A build without the feature cannot execute or register Python
participants.

## Several programs on one prim

A prim may own several program children, and it may also carry one intrinsic
program of its own. Each program prim is an independent participant with its
own source, session, and lifecycle. They interact through the same typed ports
and event bus as any other components.

Do not use several programs to express one behavior that should be a single
model. Split only when the pieces have genuinely different clocks, languages,
or ownership.

## Deleting a program

Deleting the child prim removes the behavior. Deleting the owning prim removes
the program with it. There is no separate "stop script" registry to clean up.

If a program acquired control, its stop hook runs during removal. A program
that fails to release control leaves the runtime in a visible held state rather
than silently continuing with stale authority.

## Rules of thumb

- Put the program under the object it controls.
- Prefer `sourceAsset` over inline `sourceCode`.
- Declare `realtimeSafe` only when the program can meet the budget.
- Match the prim's `inputs:` and `outputs:` to the compiled interface.
- Release control and stop actuators in the stop hook.
- Treat a source reload as a replacement, not as a mutation of the old
  program.

Continue with [Materials](materials.md), which bind appearance to the same
composed prims.
