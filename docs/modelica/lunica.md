---
title: Lunica
chapter: 4
section: 3
---

# Lunica

Lunica is the Modelica workbench. It runs as the **∿ Lunica** perspective in
the simulator and as the standalone `lunica` application. Both hosts embed the
same compiler, execution, and workbench plugins, so a model behaves the same
way in either one.

Lunica edits the same `ModelicaDocument` that the Twin uses, compiles through
the same Rumoca session, and runs the same worker. The difference is
presentation: Lunica adds the model browser, diagram, icon and documentation
views, parameter inspector, and plots.

## The layout

| Area | Contents |
|---|---|
| **Twin browser** | Project files and the **Modelica** section with packages, classes, and libraries |
| **Component palette** | Insertable components, below the Twin browser |
| **Center** | Welcome page or open model tabs |
| **Model views** | **Text**, **Diagram**, **Icon**, **Docs** |
| **Model Inspector** | Parameters, real-time inputs, variables, and the selected component |
| **Graphs** | Live and completed-run trajectories |
| **Experiments** | Batch runs and parameter sweeps |

The default Lunica perspective docks the Twin browser and component palette on
the left, the model workspace in the center, and the Model Inspector on the
right. **Graphs**, **Experiments**, **Diagnostics**, and **Journal** open from
the **View** menu and default to the bottom dock.

A model opens in its own tab. Switching views does not remount the document;
the text, diagram, icon, and docs views all read the same source.

## Opening and creating models

To open an existing model:

1. Switch to **∿ Lunica**.
2. Open the **Modelica** section in the Twin browser.
3. Expand a library or workspace document, then choose a class.

To create a model, use **File → New → Modelica Model**, the **New Model**
button on the welcome page, or **New Model** in an empty Modelica workspace.
Lunica creates an untitled in-memory document with the skeleton

```modelica
model Untitled
end Untitled;
```

and opens it in a tab. There is no setup dialog. Rename the draft in the Twin
browser by double-clicking its row, or edit the declaration in **Text**. For an
untitled document the tab title follows the first top-level class name, and
**Save As** proposes `<class>.mo` starting from the Twin root.

## Text view

The text view is a plain source editor over the authoritative `.mo` text. It
supports word wrap, auto indent, and text scale in **Settings → Modelica →
Code Editor**. The preferences persist under `modelica_code_editor`.

Editing text produces a typed `ModelicaOp`. The document reparses at a defined
boundary, and the diagram, inspector, and compiler see the same change. There is
no second source buffer.

## Diagram view

The diagram is a thin view over the document. It renders authored Modelica
icons, routed connections, and editable placements on the workbench canvas.
Dragging a component or a connection produces an operation; it does not write
text directly.

| Action | Result |
|---|---|
| Drag from the palette | Add a component |
| Drag a component | Change its placement |
| Drag between ports | Add a `connect` equation |
| Select a component | Inspect its parameters |
| Double-click a component | Drill into its class |
| Scroll | Zoom the canvas; with semantic zoom enabled, reveal nested diagrams |

The add-component menu hides `partial` classes by default. **Settings →
Modelica → Show partial classes** includes them. A class without authored
placement uses a deterministic grid; a class without an icon uses the
renderer's named component presentation. These are presentation defaults.

Semantic zoom is opt-in. Enable **Modelica semantic zoom** in **Settings →
Appearance** to scroll into a component and reveal its nested diagram and
source equations; double-click still opens the component for editing.

A conditional declaration is marked as conditional, including a literal
`if true`. The compiler owns condition evaluation and compiled instance
presence; the diagram does not infer active instances from a Boolean
expression.

## Icon and docs views

The **Icon** view edits the class's `Icon` annotation. The **Docs** view renders
the class's `Documentation` annotation and the selected documentation
fragments.

Both are views over authored source. An edit in the icon view changes the
`Icon` annotation in the model text.

## Compile

**Compile** builds the selected class through Rumoca. A successful compile
leaves the model ready and paused. A failed compile reports the phase
diagnostic with its source location; the previous artifact is not used as a
silent fallback.

The compiler admits each unique URI once and installs the paired source and
definition as one batch. Single-source and multi-source compilation share that
boundary. A changed owned source, mixed ownership, or conflicting contents under
one URI fails before overlay installation.

Compilation is asynchronous. A heartbeat reports progress, and the worker
catches panics and reports them as solver errors rather than crashing the
application. This tolerance is essential for interactive parameter tuning: an
unstable parameter should not kill the whole simulation.

## Run and Fast Run

| Action | Clock | Use |
|---|---|---|
| **Run** | Wall-clock simulation | Inspect a live model, tune parameters, watch plots |
| **Fast Run** | Batch, as fast as possible | Parameter studies, regression checks, comparisons |

Run starts a live session. The model advances with the simulation clock and can
be paused, resumed, or reset. Fast Run executes from `t_start` to `t_end`
through the experiment runner and produces a trajectory.

Fast Run uses the model's `experiment` annotation for default bounds. Invalid
annotation bounds return an error through the same resolver; they do not select
the default. The shared bounds guard rejects invalid explicit inputs and grids
beyond the sample cap before solver allocation.

A live solver step failure keeps the solver error and lists the values that
were not produced by the failed step, with their last accepted samples.

## Parameters

The **Model Inspector** edits live parameters through `SetModelicaParameter`.
The command edits the declaration in the participant's selected class, leaves
the document dirty, and reinitializes the participant with the checked
replacement. Saving the document makes the new value the type default; other
instance overrides remain intact.

USD-backed controls require editing their authored USD binding and are disabled
in the document-only inspector path. A value that belongs to one scene instance
belongs in USD; a value that belongs to the type belongs in the `.mo` file.

## Inspector and plots

The **Model Inspector** lists parameters, real-time inputs, and variables.
Ticking a variable routes its samples to the active plot, or to the plot chosen
in **Plot in**. The **Graphs** panel renders live and completed-run trajectories
through the shared visualization layer.

History is retained by the Modelica telemetry plane using the shared recording
rate, channel limit, and retention settings. The same retention plane is
installed for standalone Modelica hosts and the full mission sampler.

## Document identity

A Modelica document has three identity views:

| Tier | Source of truth | Used by |
|---|---|---|
| **File** | Document origin (untitled or file path) | Save, dirty check, file browser |
| **Workspace entry** | `DocumentEntry.title`, derived from the first top-level class | Recents and workspace lists |
| **Modelica class** | AST top-level class name | Compile, references, class browser, journal |

The class name is authoritative for compilation and references, as in Dymola
and OMEdit. For an untitled draft the origin name follows the first top-level
class, so the tab title does too. A saved file keeps its file stem as the tab
title; a drilled-in tab shows the class short name.

Renaming a class rewrites the declaration and its `end OLD;` closer. Renaming
an untitled draft in the Twin browser also updates the draft origin, so the tab
title follows. Renaming a saved `.mo` file in the Twin browser updates the open
document's top-level class to the new stem and saves it, keeping the `Foo.mo` /
`model Foo` convention when the class still matches the old stem. Renaming the
class inside the editor does not rename the file.

## A practical workflow

1. Open or create the model.
2. Work in **Diagram** for structure and **Text** for equations.
3. **Compile** and fix diagnostics before attaching the model to a scene.
4. **Run** live to inspect behavior and tune parameters.
5. Use **Fast Run** to compare variants or check a bound.
6. Save the document, then attach it to a USD prim through
   `LunCoProgramAPI`.
7. Run the scene and inspect the authored ports in **Analyze**.

The model is ready to attach when it compiles cleanly and its public outputs
are declared. A model that only runs in Lunica but has no declared outputs
cannot drive anything in the scene.

## Rules of thumb

- Treat the class as the identity; the file is an implementation detail.
- Compile before attaching. The scene runs the compiled artifact.
- Keep type defaults in the `.mo` file and instance overrides in USD.
- Use Fast Run for comparisons and Run live for inspection.
- Fix the source diagnostic; do not tune around a failed compile.
- Save before closing a tab with a dirty marker.

Continue with [Libraries](libraries.md), which explains where packages and the
standard library come from.
