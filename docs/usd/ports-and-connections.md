---
title: Ports and connections
chapter: 4
section: 3
---

# Ports and connections

A scene becomes a system when its parts exchange values. LunCoSim expresses
that exchange as typed USD properties and standard USD connections. The same
authored wire feeds co-simulation, telemetry, the Ports panel, and the HTTP
API; there is no second signal graph.

## The three property namespaces

| Namespace | Direction | Meaning |
|---|---|---|
| `inputs:<name>` | Into the prim | A value the component consumes |
| `outputs:<name>` | Out of the prim | A value the component publishes |
| `connectors:<name>` | Acausal | A Modelica connector exposed on the component boundary |

A scalar port is a typed USD attribute. The type is part of the contract:

```usda
def Xform "Rover" (kind = "assembly")
{
    float inputs:throttle = 0.0
    float inputs:steer = 0.0
    float outputs:speed = 0.0
    double outputs:odometer = 0.0
}
```

`inputs:` and `outputs:` are causal: the producer writes, the consumer reads.
`connectors:` describe an acausal Modelica interface, where the equation system
decides the direction. A connector property without a connection is reported
as an orphan warning; it is not silently treated as a causal port.

## Authoring a connection

A connection is authored on the property that consumes the value:

```usda
def Xform "DescentLander" (
    prepend apiSchemas = ["PhysicsRigidBodyAPI", "LunCoProgramAPI"]
)
{
    uniform token info:implementationSource = "sourceAsset"
    uniform asset info:sourceAsset = @lunco://models/Lander.mo@
    uniform bool lunco:program:realtimeSafe = true

    float inputs:external_throttle = 0.0
    float outputs:throttle

    def Scope "MainPropulsion"
    {
        float inputs:valve_opening.connect = </DescentLander.outputs:throttle>
    }
}
```

The target path is the **source**. In the composed stage the connection
resolves to a `SimConnection` with a source prim and property, a sink prim and
property, and a scalar type. The runtime compiles that graph into dense target
indices and propagates values at the fixed step.

A connection is not a value copy. It is a topology fact that survives
recomposition. If the source is renamed or removed, the wire is reported as
invalid rather than silently reading zero.

### The public-output rule

A model output becomes externally connectable only when the component prim
declares the matching `outputs:<name>` property. A path mentioned only as a
connection target does not create a public port.

This rule prevents a connection from reaching into a model's private state.
The model may compute hundreds of local variables; only the declared outputs
are part of its interface.

```usda
def Xform "ReactionWheel" (
    prepend apiSchemas = ["LunCoProgramAPI"]
)
{
    uniform token info:implementationSource = "sourceAsset"
    uniform asset info:sourceAsset = @twin://rover/models/ReactionWheel.mo@

    # Public interface: these are the only values another prim may consume.
    float outputs:torque = 0.0
    float outputs:speed = 0.0
}
```

The matching Modelica class must declare the same names as outputs. A
declaration mismatch is a compile-time interface error, not a runtime
surprise.

## Types, units, and bounds

The scalar port surface is `f64` at the runtime boundary. USD may author a
narrower type (`float`, `double`, `int`, `bool`), and the adapter preserves the
authored type for validation and display. A write that would narrow a value at
the GPU or command boundary is checked there; the port registry itself keeps
the exact sample.

Port metadata carries:

| Field | Purpose |
|---|---|
| `type` | Authored scalar type |
| `unit` | Engineering unit, when known |
| `bounds` | Valid range, when authored or supplied by the owner |
| `source` | Backend label such as Modelica, Avian, or a script |
| `authority` | Which owner may write the port |
| `writable` | Whether a command may write it |

Compatible unit conversions are compiled into the connection fabric. An
incompatible unit is a wiring error, not an invitation to guess a factor.

## Direction and ownership

Every port has exactly one declared owner. The `PortRegistry` selects that
owner from the composed declarations and the live backend state. A source wire
retains the authored prim and port identity; wiring does not redirect a source
around the owner's decision.

A value that is both authored as an output and written by an imperative
producer is a conflict. `OutputPorts` stores values for an imperative producer;
it is not a second signal graph and must not shadow a solver-owned output.

For a Modelica participant:

- Checked DAE runtime inputs define writable ports.
- Numeric observables, including authored outputs and local states, define
  readable values that USD may export.
- Constants, runtime inputs, and parameters are not published as participant
  output samples.
- Reading a local state does not make it writable.

## Initial admission

At `t = 0`, source interfaces and native physical definitions become available
before numerical admission. Acyclic participants initialize from finite
producer samples. Participants with complete initial inputs enter independent
preparation without delaying a separate coupled plan.

Required external outputs still wait for their registered initial expressions
or samples. Absent values remain pending rather than defaulting to zero.

When the remaining participants depend on one another, the owner captures
their exact source, authored bindings, scene generation, and ordered wiring.
The `synth.coupled-initialization` hook emits a Modelica composite containing
those instances, their input bindings, and input probes. The composite is
compiled and initialized as a request-owned job; its finite observations must
agree with the connected graph within solver tolerance before the members are
released together.

A changed source or wire cannot release an old certificate. Failed
certification reports a terminal runtime fault and holds the affected
participants.

## Reading the graph

`QueryUsdPrim` exposes the composed port surface. `ReadPorts` exposes live
values with owner-supplied metadata. `ListPorts` enumerates the declared names
for an entity.

The `CausalTrace` query joins one semantic edge to its authored binding,
selected port owner, USD/Avian admission state, current measured channels,
producer origin, and optional fixed-tick admission stamp:

```rhai
let edge = intent_pulse(target, "release");
let trace = query("CausalTrace", #{
    target: target,
    correlation_id: edge.id,
});
```

An absent or pending stage is an incomplete path, not successful actuation.
Omitting `correlation_id` selects the newest trace for the target.

## Authoring through the document

The Editor and scripts do not rewrite USDA text to add a wire. They use the
typed `SetConnection` operation:

```text
SetConnection {
    edit_target,
    path: "/Rover",
    name: "inputs:throttle",
    type_name: "float",
    sources: ["/Driver.outputs:throttle"],
}
```

`SetConnection` is journaled with its inverse and replayed onto the live stage.
The typed connection preflight resolves referenced providers and applied API
schemas through the edited document's own authoring recipe. Runtime-only
endpoints are checked against the live port registry, so another open Twin
cannot change whether an authored wire is valid.

## Worked example

A drive-by-wire rover has a Modelica controller, a physics chassis, and a Rhai
mission:

```usda
def Xform "Rover" (kind = "assembly")
{
    def Scope "Controller" (
        prepend apiSchemas = ["LunCoProgramAPI"]
    )
    {
        uniform token info:implementationSource = "sourceAsset"
        uniform asset info:sourceAsset = @twin://rover/models/Drive.mo@
        uniform bool lunco:program:realtimeSafe = true

        float inputs:throttle = 0.0
        float inputs:steer = 0.0
        float outputs:left_torque = 0.0
        float outputs:right_torque = 0.0
    }

    def Xform "Chassis" (
        prepend apiSchemas = ["PhysicsRigidBodyAPI"]
    )
    {
        float inputs:left_torque.connect = </Rover/Controller.outputs:left_torque>
        float inputs:right_torque.connect = </Rover/Controller.outputs:right_torque>
    }
}
```

The mission script writes `throttle` and `steer` through `SetPorts`. The
controller reads them, computes wheel torques, and publishes the two outputs.
The chassis consumes the torques. The same values are visible in the Ports
panel and over the API without a second publication path.

## Rules of thumb

- Declare every consumed value as an `outputs:` property on the producer.
- Author the wire on the consumer, pointing at the producer.
- Keep one owner per port. Do not shadow a solver output with an imperative
  write.
- Use `connectors:` only for genuine acausal Modelica interfaces.
- Expect missing initial samples to hold admission; do not substitute zero.
- Inspect a disputed value with `CausalTrace` before adding another wire.
- Add connections through `SetConnection`, never by editing text behind the
  document's back.

Continue with [Programs](programs.md), which attach the behavior that reads and
writes these ports.
