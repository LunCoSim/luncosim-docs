---
title: Language
chapter: 5
section: 1
---

# Language

Modelica is a declarative, equation-based language. A class describes
relationships that must hold at every instant; the solver decides how to
advance them. This is the opposite of a script, where the author decides the
order of assignments.

This section covers the language surface LunCoSim authors use most. It is not a
replacement for the Modelica specification. The compiler is the authority: a
construct that Rumoca does not support fails at compile time, and the failure
names the source location.

## A class is a namespace and a contract

```modelica
within LunarBase.Power;

model Battery
  parameter Real capacity_wh = 1000;
  parameter Real nominal_voltage = 28;
  Real state_of_charge(start = 1.0);
  output Real voltage;
  input Real current;
equation
  voltage = nominal_voltage * (0.9 + 0.1 * state_of_charge);
  der(state_of_charge) = -current / (capacity_wh / nominal_voltage) / 3600;
end Battery;
```

| Part | Meaning |
|---|---|
| `within LunarBase.Power;` | The enclosing package |
| `model Battery` | A reusable class |
| `parameter` | Constant during a run; tunable between runs |
| `Real state_of_charge(start = 1.0)` | A continuous state with an initial guess |
| `output` | Part of the external interface |
| `equation` | A relationship that must hold |

The `start` attribute is a guess, not an initial equation. Use
`initial equation` when the initial value is a constraint.

## Class kinds

| Kind | Purpose |
|---|---|
| `model` | A general behavioral model |
| `block` | A model with a fixed input/output interface |
| `connector` | An interface point for acausal connections |
| `record` | A structured value with named fields |
| `function` | An algorithm with inputs and one output |
| `package` | A namespace for other classes |
| `type` | A constrained scalar type |
| `class` | The general form; the others are restrictions |

Most LunCoSim assets use `model`, `connector`, `record`, and `package`. A
`block` is useful when the direction of every boundary variable is known.

## Built-in types and arrays

| Type | Notes |
|---|---|
| `Real` | Continuous or discrete real value |
| `Integer` | Discrete integer |
| `Boolean` | `true` / `false` |
| `String` | Text; not a continuous variable |
| `enumeration(...)` | Named discrete values |

Arrays are declared with dimensions:

```modelica
parameter Real gains[3] = {1.0, 0.5, 0.1};
Real temperature[2, 2];
```

Array dimensions may be literal or parameter expressions. Indexed structural
overrides are not supported by the root-modifier owner; indexed tunables retain
scalar lowering semantics. A USD scalar port cannot name an indexed Modelica
scalar port.

## Variability and causality

| Prefix | Meaning |
|---|---|
| `parameter` | Constant during a run, settable between runs |
| `constant` | Fixed at compile time |
| `discrete` | Changes only at events |
| `input` | Supplied by the surrounding system |
| `output` | Exposed to the surrounding system |
| `flow` | A conserved quantity through a connector |

A variable with none of these is a local continuous variable. It may still be
readable as an observable, but it is not writable from USD.

## Equations

An `equation` section contains equalities, not assignments:

```modelica
equation
  v = i * r;
  der(q) = i;
```

The solver may solve for either side. This is what makes acausal connectors
work: a connector does not say "this is an input"; the equations decide.

An `initial equation` section constrains the initial state:

```modelica
initial equation
  q = 0;
  der(q) = 0;
```

An `algorithm` section is imperative and is used for discrete logic or
functions. It is not a substitute for an equation section when a continuous
relationship is intended.

## Connectors and acausal connections

A connector declares the variables that cross a boundary:

```modelica
connector HydraulicPort
  flow Real m_flow;
  Real pressure;
end HydraulicPort;

model Pipe
  HydraulicPort inlet;
  HydraulicPort outlet;
equation
  inlet.m_flow + outlet.m_flow = 0;
  outlet.pressure = inlet.pressure - 1000 * inlet.m_flow;
end Pipe;
```

Two connectors are joined with `connect`:

```modelica
model Circuit
  Pipe pipe;
  Tank tank;
equation
  connect(tank.outlet, pipe.inlet);
end Circuit;
```

`connect` generates the equality and conservation equations for the connected
variables. It is not a signal wire in the USD sense. USD `connectors:` exposes
the acausal interface on a component boundary; USD `inputs:` and `outputs:` are
causal.

## Events and discrete behavior

Modelica handles discrete changes with `when`:

```modelica
model Thermostat
  input Real temperature;
  output Boolean heater;
  parameter Real threshold = 20.0;
equation
  heater = temperature < threshold;
end Thermostat;

model Counter
  discrete Integer count(start = 0);
equation
  when sample(0, 1.0) then
    count = pre(count) + 1;
  end when;
end Counter;
```

| Operator | Meaning |
|---|---|
| `when condition then ... end when` | Execute equations at an event |
| `pre(x)` | The value of `x` immediately before the event |
| `edge(x)` | True when `x` changes from false to true |
| `change(x)` | True when `x` changes |
| `reinit(x, value)` | Reset a state at an event |
| `sample(start, interval)` | A periodic event |

Use `when` for discrete state. Do not emulate a mission phase machine with
continuous equations; that belongs in Rhai.

## Functions

A `function` is an algorithm with typed inputs and one output:

```modelica
function saturate
  input Real value;
  input Real limit;
  output Real result;
algorithm
  result := max(-limit, min(limit, value));
end saturate;
```

Functions are useful for reusable math and for expressions that would
otherwise be repeated. They do not own state.

## Packages and lookup

A package groups classes:

```modelica
within LunarBase;

package Power
  model Battery
    // ...
  end Battery;

  model SolarArray
    // ...
  end SolarArray;
end Power;
```

A class is identified by its qualified name, `LunarBase.Power.Battery`. The
`within` clause establishes the enclosing scope. Imports shorten lookup:

```modelica
within LunarBase;

model Rover
  import Modelica.Blocks.Math;
  Math.Max maxBlock;
end Rover;
```

The compiler resolves the full closure from the admitted source roots. A
missing package or class is a compile error, not an empty declaration.

## Inheritance and modifications

`extends` applies a base class and can modify its parameters:

```modelica
model LargeBattery
  extends Battery(capacity_wh = 4000);
end LargeBattery;
```

Inheritance is resolved before the class's own declarations. Missing bases and
inheritance cycles are rejected. A modification changes a parameter default or
a nested declaration; it does not create a second equation system.

## Annotations

Annotations carry presentation and experiment metadata:

```modelica
model Drive
  annotation(
    experiment(StartTime = 0, StopTime = 10, Tolerance = 1e-6),
    Icon(graphics = {Rectangle(extent = {{-100, -100}, {100, 100}})})
  );
end Drive;
```

| Annotation | Used by |
|---|---|
| `Icon` | Diagram and component palette |
| `Diagram` | Authored placement and connections |
| `experiment` | Fast Run default bounds |
| `Documentation` | Class documentation panel |

An invalid annotation is a diagnostic, not a reason to drop the model. The
diagram editor projects the authored placement when present and a deterministic
grid when it is not.

## Source encoding

The parser accepts a single leading UTF-8 BOM and retains source coordinates in
the original text. Loaders, documents, and editor paste preserve the authored
bytes. The production `modelica_source_encoding.rhai` gate verifies exact text,
batch output, and a parser-owned negative diagnostic for the current source
generation.

## What the compiler rejects

Rumoca is strict about the constructs it supports. The following are rejected
rather than approximated:

- missing or cyclic type information;
- unresolved base classes;
- malformed or unbalanced models;
- indexed structural overrides that the root-modifier owner cannot represent;
- aggregate, array, or string values where a scalar run value is required;
- non-finite numeric admission.

A rejected model is a visible compile diagnostic. The runtime does not fall
back to a stale artifact or a default model.

## Rules of thumb

- Prefer equations over algorithms for continuous behavior.
- Use `initial equation` for constraints and `start` for guesses.
- Use connectors for physical conservation; use `input`/`output` for signal
  boundaries.
- Keep discrete mission logic out of Modelica.
- Qualify names with packages; do not rely on a flat global namespace.
- Treat a compile diagnostic as the source of truth.

Continue with [Cosimulation](cosimulation.md), where these equations meet the
fixed-step clock.
