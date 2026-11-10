---
title: Add a Modelica model
chapter: 2
section: 4
---

# Add a Modelica model

Modelica gives a scene continuous behavior: a motor response, a battery
discharge, a thermal network, or a control law. This tutorial adds a small
drive model to a rover, attaches it to a USD program prim, wires its output to
a consumer port, and observes the result.

The example is intentionally simple: a first-order response that demonstrates
the contract without pretending to be a realistic rover controller.

## Write the model

Create a file under the Twin:

```text
my-rover-twin/
└── models/
    └── Drive.mo
```

A first-order drive response looks like this:

```modelica
within MyRover;

model Drive
  input Real throttle;
  output Real speed;
  parameter Real timeConstant = 1.0;

initial equation
  speed = 0.0;

equation
  der(speed) = (max(-1.0, min(1.0, throttle)) - speed) / timeConstant;
end Drive;
```

The pieces are:

| Element | Meaning |
|---|---|
| `within MyRover;` | The package namespace for this class |
| `model Drive` | A reusable model class |
| `input Real throttle` | A value supplied by the surrounding system |
| `output Real speed` | A value exposed to the surrounding system |
| `parameter Real timeConstant` | A tunable value that is constant during a run |
| `initial equation` | The initial condition |
| `equation` | The continuous relationship |
| `der(speed)` | The time derivative of `speed` |

This model does not find prims, read the scene, or decide when a mission is
complete. It turns a throttle command into a first-order speed response.

## Declare the source root

The compiler must be able to find the model. Add the directory to the Twin
manifest:

```toml
[modelica]
paths = ["models"]
```

`paths` is relative to the Twin root. If the model uses a package structure,
keep the `within` declarations and the directory layout consistent. For a
multi-file package, open the directory as a workspace or Twin root; opening a
single `package.mo` does not recursively import every file in its folder.

## Compile the model

Open the **∿ Lunica** perspective, choose the **Modelica** section in the Twin
browser, and open `Drive.mo`. Choose **Compile**.

A successful compile leaves the model ready and paused. A failed compile
reports a diagnostic with the source location. Fix the source and compile
again; the scene runs the compiled artifact.

You can also preflight the file without opening the application:

```bash
luncosim --validate path/to/my-rover-twin/models/Drive.mo
```

`--validate` proves that the file parses and its declarations are structurally
valid. It does not run the model or prove that its behavior is correct.

## Attach the model to a prim

A Modelica class becomes a simulation participant when a USD prim carries
`LunCoProgramAPI` and names the source:

```usda
def Xform "Rover"
{
    def Scope "Controller" (
        prepend apiSchemas = ["LunCoProgramAPI"]
    )
    {
        uniform token info:implementationSource = "sourceAsset"
        uniform asset info:sourceAsset = @twin://my-rover-twin/models/Drive.mo@
        uniform bool lunco:program:realtimeSafe = true
    }
}
```

Use `@twin://...@` for a model inside the open Twin. Use
`@lunco://models/...@` for a model shipped in the installed asset library.

The program here is a child `Scope`, so deleting the Scope removes the
behavior without deleting the rover. The source path is an asset address, not a
relative path from the current working directory.

## Declare the ports

A model output becomes externally connectable only when the prim carrying
`LunCoProgramAPI` declares the matching `outputs:<name>` property. A connection
target alone does not create a public port.

```usda
def Xform "Rover"
{
    def Scope "Controller" (
        prepend apiSchemas = ["LunCoProgramAPI"]
    )
    {
        uniform token info:implementationSource = "sourceAsset"
        uniform asset info:sourceAsset = @twin://my-rover-twin/models/Drive.mo@
        uniform bool lunco:program:realtimeSafe = true

        float inputs:throttle = 0.0
        float outputs:speed
    }
}
```

The names must match the Modelica declarations exactly. The runtime resolves
the typed port through the program and the composed stage; it does not guess a
port from a display name.

## Wire the model to a consumer

A connection is authored on the prim that consumes the value. Here the chassis
declares the speed it consumes from the controller:

```usda
def Xform "Rover"
{
    def Scope "Controller" (
        prepend apiSchemas = ["LunCoProgramAPI"]
    )
    {
        uniform token info:implementationSource = "sourceAsset"
        uniform asset info:sourceAsset = @twin://my-rover-twin/models/Drive.mo@
        uniform bool lunco:program:realtimeSafe = true

        float inputs:throttle = 0.0
        float outputs:speed
    }

    def Xform "Chassis" (
        prepend apiSchemas = ["PhysicsRigidBodyAPI"]
    )
    {
        float inputs:drive_speed.connect = </Rover/Controller.outputs:speed>
    }
}
```

The composed stage resolves references, payloads, variants, and the connection
graph. The runtime derives a `SimConnection` from the authored wire and samples
the output at the declared communication point.

If the model drives a force or torque port on a client-predicted body, it must
declare `lunco:program:realtimeSafe = true`. The runtime rejects that edge at
wire-build time when the declaration is missing, because a late or
nondeterministic program would diverge from the server.

## Run and observe

1. Open the Twin and load the scene.
2. Wait for readiness. A model can be compiling while the scene is already
   visible.
3. Switch to **Analyze**.
4. Select the rover in **Entities** or **Telemetry**.
5. Add `speed` and `throttle` to a graph.
6. Command a throttle through the UI, a script, or the API.
7. Watch the speed settle toward the commanded value.

A missing port is not a zero. Use **Ports** or `ListPorts` to confirm that the
port exists and has the direction and kind you expect.

## Tune a parameter

Parameters are constant during a run. Change `timeConstant` in the source and
recompile, or override it through an experiment. Do not hide a tuning value in
a script when the model owns it; a parameter is a model fact.

Lunica's **Experiments** panel can override parameters and compare several
runs without editing the source. See [Experiments](../modelica/experiments.md).

## Common problems

| Symptom | Cause | Fix |
|---|---|---|
| The model does not appear | `[modelica].paths` does not include its root | Add the path and reopen the Twin |
| Compile fails | Syntax or type error | Read the diagnostic; run `--validate` |
| The value does not reach the consumer | The output is not declared or not connected | Declare `outputs:speed` and author the connection |
| The connection is rejected | The target input does not exist | Check the exact `inputs:` name |
| The force edge is rejected | Missing `realtimeSafe` on a predicted body | Declare the program realtime-safe or move it off the prediction path |
| The value never changes | The model is paused or not admitted | Check readiness and the participant status |
| A parameter change has no effect | The model was not recompiled | Recompile; the scene runs the compiled artifact |

## Related sections

- [Modelica](../modelica/index.md) — the format and runtime contract
- [Cosimulation](../modelica/cosimulation.md) — communication points and wiring
- [Lunica](../modelica/lunica.md) — the workbench
- [Ports and connections](../usd/ports-and-connections.md) — the USD side
- [Programs](../usd/programs.md) — `LunCoProgramAPI`
