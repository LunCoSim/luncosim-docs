# Modelica

Modelica is LunCoSim's language for **continuous behavior**: motion, power,
thermal flow, fluid systems, and control laws. A `.mo` file contains equations,
not a sequence of commands. The solver advances the equations over time.

## What Modelica owns

- Differential and algebraic equations
- Continuous state and parameters
- Acausal connections between physical ports
- Inputs and outputs exchanged with physics or other domains
- Solver-facing behavior at declared communication points

Modelica does not own scene traversal, mission sequencing, or user input. Those
belong in USD and Rhai.

## A small model

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

The pieces:

| Keyword | Meaning |
|---|---|
| `within MyRover;` | The package namespace for this class |
| `model Drive` | A reusable model class |
| `input Real throttle` | A value supplied by the surrounding system |
| `output Real speed` | A value exposed to the surrounding system |
| `parameter Real timeConstant` | A tunable value that is constant during a run |
| `initial equation` | The initial condition |
| `equation` | The continuous relationship |
| `der(speed)` | The time derivative of `speed` |

This model turns a throttle command into a first-order speed response. It does
not find prims, read the scene, or decide when a mission is complete.

## Attaching a model to USD

A Modelica class becomes a simulation participant when a USD prim carries
`LunCoProgramAPI` and names the source:

```usda
def Scope "Controller" (
    prepend apiSchemas = ["LunCoProgramAPI"]
) {
    uniform asset info:sourceAsset = @twin://my-rover/models/Drive.mo@
    uniform bool lunco:program:realtimeSafe = true
}
```

Use `@twin://...@` for a model inside the open Twin. Use
`@lunco://models/...@` for a model shipped in the installed asset library.

## How cosimulation works

When a Modelica model drives a physical body, LunCoSim runs the two sides
together:

1. The fixed master clock reaches a communication point.
2. Model outputs are sampled.
3. The values cross the authored USD connections as `SimConnection`s.
4. Physics applies the resulting forces or reads the new state.
5. The new state becomes the next input sample.

Outputs are held between communication points. A script does not step this
loop; the wiring and the runtime do. This is why a component must declare its
`outputs:<name>` ports in USD before another component can consume them.

The rule of thumb:

- **Modelica owns the condition.** A model computes `low_fuel = 1` when its
  state crosses a threshold.
- **USD owns the wire.** A `LunCoEvent` prim connects that output to a named
  event.
- **Rhai owns the response.** A scenario listens for `lander_low_fuel` and
  displays a warning.

## The Lunica workbench

Open the **Lunica** perspective to work on Modelica directly. It provides the
model browser, diagram view, equation view, parameter editing, compilation,
run controls, plots, and experiments. See
[Perspectives](../getting-started/perspectives.md#lunica-engineer-a-modelica-model)
for the layout and workflow.

Use it to:

- inspect a model before attaching it to a scene
- change parameters and compare runs
- run a model in real time or as a fast batch
- plot and compare experiment results

The simulator embeds the same workbench, so you do not need a separate
application to edit a model used by a Twin.

## Practical rules

- Put equations and state in Modelica.
- Put discrete decisions, mission phases, and event responses in Rhai.
- Declare every value another component consumes as a USD `outputs:` property.
- Keep parameters in the model or the manifest, not in a hidden script.
- Recompile after changing a model; a stale artifact is not a valid run.
