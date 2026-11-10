---
title: Introduction
chapter: 1
section: 1
---

# Introduction

LunCoSim is an open-source space mission workbench. It is used to assemble a
vehicle and its environment, connect continuous models to the assembled
physics, script an operation, and observe the result in one running
simulation. The application is built on Rust and Bevy, with Avian for rigid
body physics and an embedded Modelica toolchain built on the Rumoca compiler.

The project is not a CAD program, a general-purpose game engine, or a
certified flight-dynamics package. It is a place where a scene, a set of
equations, and a mission policy can be authored in standard formats and then
run together with a shared notion of time, identity, and authority.

## The problem the workbench addresses

A space mission study usually spans several tools. Geometry lives in a 3D
content tool, equations live in a modeling environment, mission logic lives in
a scripting or ground-system tool, and the results are compared in yet another
application. The interfaces between those tools are often files, spreadsheets,
or hand-copied constants. The copies drift, and the drift is hard to see
because each tool is internally consistent.

LunCoSim takes a different position: keep the domain formats, but give them
explicit ownership and one runtime that composes them. A USD stage is still a
USD stage. A Modelica class is still a Modelica class. A Rhai script is still a
Rhai script. The workbench adds the project manifest, the asset addressing
scheme, the typed connection fabric, and the runtime that makes the combination
observable.

## Design principles

The following principles explain most of the behavior described in this
document.

**One fact, one owner.** Geometry, mass, and joint topology belong in USD.
Continuous equations belong in Modelica. Mission decisions belong in Rhai.
Project configuration belongs in TOML. The runtime projects these facts; it
does not maintain a second editable copy of them.

**Compose, do not duplicate.** A reusable rover is referenced into a scene, not
copied into it. A variant selects an authored alternative, not a second
hand-maintained assembly. A route is composed from ordered USD prims, not
pasted into every lesson script.

**The authored document is the source of truth.** The runtime does not rewrite
authored USD to hide a problem. An editor preview is a preview; saving goes
through the document owner and its journal. Generated or cached assets are
products of a pipeline, not files to hand-edit.

**Continuous and discrete behavior are different.** Modelica advances
equations at communication points. Rhai reacts to events and advances a task
tree. A per-tick script loop is not a substitute for a solver, and a Modelica
model is not a mission sequencer.

**Evidence is layered.** A parse check, a live lint, a scene test, a
requirement verification, and a physical accuracy claim answer different
questions. The application reports what it actually observed and does not
upgrade a green check into a certificate.

## What the workbench contains

The desktop application combines five task layouts over one project:

- **View** operates the running mission.
- **Build** composes the live scene from assemblies and entities.
- **Analyze** reads telemetry, ports, and graphs.
- **Editor** edits one explicit USD document in isolation.
- **Lunica** develops, compiles, and runs Modelica models.

The same Twin can be opened in any of these layouts without reloading the
world. A lesson can pin the layout its steps depend on, and a Twin can declare
an initial layout in its manifest. The [Perspectives](perspectives.md) section
describes each task in detail.

## Relationship to standards

LunCoSim uses standard formats wherever a standard exists:

| Standard | Use in LunCoSim |
|---|---|
| OpenUSD | Scene description, composition, physics schemas, shader networks, and typed ports |
| glTF 2.0 | External mesh and scene assets referenced from USD payloads |
| Modelica | Continuous and discrete-equation models, packages, and acausal connectors |
| FMI 3.0 Co-Simulation | Optional native import of scalar `Float64` FMUs on desktop builds |
| SysML v2 / KerML | Requirements and verification mappings, with bounded support |
| WESL | Shader source assets and material parameter declarations |
| TOML | Project and asset manifests |

The workbench adds conventions on top of these standards, but it does not
replace their syntax. A `.mo` file remains usable in another Modelica tool, and
a `.usda` file remains readable in another USD application, provided the
LunCoSim-specific schemas and asset addresses are available.

## What LunCoSim is not

- It is not a CAD replacement. Use a content tool to author detailed geometry,
  then bring the result in as USD or as a glTF payload referenced from USD.
- It is not a certified flight-dynamics or thermal-analysis package. Model
  coverage and numerical fidelity vary by domain.
- It is not a mission-control system. It exposes a typed API that an operator
  adapter can drive; it does not ship a ground-segment product.
- It is not a general game engine. The runtime is specialized for engineered
  systems, authored documents, and evidence.
- It is not a converter for every robot description. URDF, SDF, and MJCF are
  not imported directly; convert them to USD first.

## Development status

LunCoSim is under active development. The core authoring loop, the USD
projection, the Rhai task kernel, and the Modelica cosimulation path are
implemented and exercised by authored tests. Other areas are partial or
platform-specific. Native FMI import is desktop-only. The browser build does
not load native FMU binaries. ROS 2, URDF, and ground-system adapters are not
bundled.

The documentation states these limits where they matter. When a workflow
depends on a capability that is not shipped, the text says so rather than
describing an intended future feature as if it were available.

## Where to go next

Continue with [How it fits together](how-it-fits-together.md) for the runtime
flow, or read [Formats](formats.md) for a side-by-side comparison of the
authored layers. A reader who wants to start using the application should go
to [Installation](install.md).
