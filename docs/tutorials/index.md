---
title: Tutorials
chapter: 2
---

# Tutorials

The tutorials are guided paths through the workbench. They use the same
production runtime as a normal Twin: a lesson is an ordinary file-backed Rhai
scenario with an optional authored USD scene. Nothing in a lesson is a
simulation shortcut.

## How lessons work

The authored lesson catalog is under **Scenarios → Tutorials**. Each entry
belongs to a track and is one of three lesson types:

| Type | Behavior |
|---|---|
| **Tour** | Explains a workflow and advances with Next and Back. A tour does not certify that you performed an action. |
| **Exercise** | Advances only when the simulation observes the requested result. |
| **Challenge** | A longer open-ended task with an authored success condition. |

Selecting a lesson loads its scene when the lesson needs one, then starts the
lesson's Rhai scenario. A lesson that needs a world names its scene explicitly,
so selecting it cannot accidentally keep an unrelated scene from the previous
lesson.

Lesson cards identify their type. A tour is the right choice when you want to
learn where things are; an exercise is the right choice when you want the
simulator to confirm completion.

## Learning paths

The catalog is organized into tracks. The suggested order is:

1. **Start Here → Lunar Rover Lab** — the hands-on workshop: take control,
   reach a marker, read measured speed, compare two drive runs, move a scene
   object, and save a personal Twin.
2. **Rover Driving → Moon Driving Basics → Slopes & Tip-Over → Rover
   Variants** — build driving skill, then compare authored tire and motor
   settings on one shared chassis. The variants lesson is a guided comparison;
   it does not claim that the rover profiles have different center-of-mass
   settings.
3. **How It Works → Model Meets Physics**, then **Sandbox → Lander & Rover
   Mission** — move from the scene and runtime model to a live Modelica/physics
   connection and then an event-driven mission.
4. **Sandbox → Build a Scene** — a guided tour of placement, editing, and
   saving. The assessed placement exercise is **Build a Lunar Base**.

## The catalog

The shipped catalog contains the following tracks and lessons. Durations are
estimates from the catalog, not timers that gate progress.

| Track | Lesson | Type | Minutes |
|---|---|---|---|
| Start Here | Lunar Rover Lab (featured) | Exercise | 30 |
| LunCoSim | SysML Requirements | Tour | 3 |
| LunCoSim | Read the Sim UI | Tour | 3 |
| LunCoSim | Authority Handoff | Exercise | 3 |
| How It Works | How Simulation Works | Tour | 5 |
| How It Works | Model Meets Physics | Tour | 3 |
| Navigation | Choose a Perspective | Tour | 3 |
| Sandbox | Sandbox Intro | Tour | 3 |
| Sandbox | First Drive | Exercise | 5 |
| Sandbox | Lander & Rover Mission | Exercise | 10 |
| Sandbox | Build a Scene | Tour | 3 |
| Sandbox | Build a Lunar Base | Exercise | 8 |
| Sandbox | Script a Rover | Tour | 3 |
| Sandbox | Rhai Editor & REPL | Tour | 3 |
| Sandbox | Inspect the Simulation | Tour | 3 |
| Rover Driving | Moon Driving Basics | Exercise | 7 |
| Rover Driving | Slopes & Tip-Over | Exercise | 8 |
| Rover Driving | Rover Variants | Tour | 3 |
| Rover Driving | Join a Team Session | Tour | 3 |
| Modelica | Lunica Overview | Tour | 3 |
| Modelica | Your Workspace | Tour | 3 |
| Modelica | Open & View a Model | Tour | 3 |
| Modelica | Compile & Run | Tour | 3 |
| Modelica | Experiments & Sweeps | Tour | 3 |
| Modelica | Plots & Results | Tour | 3 |
| Modelica | Automate with API + MCP | Tour | 3 |

A Twin can contribute its own catalog with the same JSON shape. Its menu is
nested under the Twin's name and its quick action is visible only while that
Twin is active.

## The hands-on tutorials in this chapter

The lessons above are shipped with the application. The tutorials in this
chapter are longer, authoring-oriented walkthroughs that use the same
mechanisms:

| Tutorial | What it builds |
|---|---|
| [First mission](first-mission.md) | A first drive, and the layer model behind it |
| [Create a Twin](create-a-twin.md) | A project folder with a manifest and entry scene |
| [Build a scene](build-a-scene.md) | A composed scene with placed assemblies and saved USD |
| [Add a Modelica model](add-modelica.md) | A continuous model attached to a USD program prim |
| [Script a mission](script-a-mission.md) | A Rhai task tree, objectives, events, and a verdict |
| [Author a shader](author-a-shader.md) | A WESL material with parameters and texture layers |
| [Compose a HUD](compose-ui.md) | A runtime-authored surface with bindings and actions |
| [Validate and share](validate-and-share.md) | Preflight, lint, scene test, evidence, and handoff |

## Before you start

You need a working LunCoSim installation and a scene to edit. If the
application is not installed, start with [Installation](../general/install.md).
If you have never opened the workbench, read [First run](../general/first-run.md)
first.

The tutorials assume that you can create a folder, edit a text file, and open a
terminal. They do not assume prior OpenUSD, Modelica, or Rhai experience. Each
step states what the file is for before showing the source.

## Conventions used in the tutorials

- **Bold** names a UI label or perspective.
- `Monospace` names a file, attribute, command, or value.
- A step that changes a file shows the complete file or the exact fragment to
  add. Do not paste a fragment into the wrong nesting level.
- A step that runs a command shows the command from the Twin root unless stated
  otherwise.
- A **Note** explains a constraint. A **Warning** explains a mistake that is
  easy to make and hard to diagnose.

## What the tutorials do not cover

The tutorials are an authoring path, not a complete reference. They do not
cover every command, every schema, or every Modelica library. When a tutorial
uses a feature, it links to the chapter that documents the full contract. The
[Reference](../reference/index.md) chapter is the place to look up an exact
field or flag.

## Related sections

- [First mission](first-mission.md) — start here
- [Perspectives](../general/perspectives.md) — the five task layouts
- [Twins](../general/twins.md) — the project model
- [Validation](../reference/validation.md) — the evidence layers
- [SysML v2](../sysml/index.md): requirement source, analysis, and verification
