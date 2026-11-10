---
title: Tooling
chapter: 5
section: 7
---

# Tooling

The Rhai runtime is deliberately small. Most authoring convenience comes from
three editable layers: the **prelude**, **tool libraries**, and **authoring
tools**. All three are Rhai policy over the same command and query bridge, and
all three can change without rebuilding the engine.

## The prelude

The prelude is a directory of `.rhai` files, one per topic. It provides vector
math, navigation, sensing, task constructors, mission helpers, HUD helpers,
input automation, and control wrappers:

```text
assets/scripting/prelude/
├── nav.rhai
├── sensing.rhai
├── control.rhai
├── tasks.rhai
├── mission.rhai
├── science.rhai
├── links.rhai
├── math.rhai
├── select.rhai
├── hud.rhai
├── coordinates.rhai
├── ports.rhai
├── vessel.rhai
├── input.rhai
├── authoring.rhai
├── recording.rhai
├── auto_tests.rhai
└── …
```

On native, the prelude is read from the runtime asset tree at startup. Edit a
helper and restart the app; no rebuild is required. A missing or unreadable
directory is reported as an error; the runtime does not substitute a compiled
snapshot. On wasm, the normal Bevy asset pipeline fills the same script-source
registry. A parse error is reported and the app does not silently run stale
helpers.

The prelude is part of each scenario's compiled AST. A changed prelude
invalidates compiled scenarios; a static tool-module rebinding does not.

## Tool libraries

A tool library is a named bundle of reusable policy, callable as
`libname::fn(...)` from any hook:

```rhai
let plan = formation::line(leader, 4, 12.0);
```

Author one by dropping a `.rhai` file in `assets/scripting/tools/`, or register
it at runtime:

```rhai
cmd("RegisterToolLibrary", #{ name: "survey", source: source });
```

| Command or query | Purpose |
|---|---|
| `RegisterToolLibrary { name, source }` | Install or replace a tool library |
| `ListToolLibraries` | Discover registered libraries and their scope |
| `GetToolLibrary { name }` | Read one library's source and metadata |

A library may lazily import another registered tool with ordinary Rhai syntax.
The resolver uses the registry and does not read dependency files. A scenario
that needs a source-defined tool before its first lifecycle hook should import
the explicit `lunco://` asset URI instead, because a namespace call does not
declare an asset dependency.

Each result includes the winning `standard`, `core`, `application`, or
`twin:<id>` scope. A Twin can replace an application tool without restarting
Core or Application scenario state. A changed authored prelude still invalidates
compiled scenarios.

Registered libraries are mirrored to `<twin>/tools/*.rhai`. On Twin mount,
`twin.lifecycle` selects indexed tool files and requests their loading through
typed commands.

## Discovery

`ScriptingCatalog` aggregates the full callable surface: verbs, hooks, prelude,
tools, commands, and queries. A full catalog value can exceed the shared sandbox
size limit, so Rhai callers use a bounded query:

```rhai
let matches = query("ScriptComplete", #{ prefix: "Set", limit: 20 });
```

The same catalog is available to external authoring clients. Use it instead of
guessing a command name from a version of the documentation.

## Structured UI tools

A Rhai tool can be invoked by a pointer or menu action through
`RunRhaiTool { tool, args }`. The tool receives typed arguments and runs its
`on_click(context)` entry point:

```rhai
fn on_click(context) {
    if pointer_intent(context, "route.add_point") {
        return add_route_point(context);
    }
}
```

A scene context includes the picked point, the diagnostic `button`
(`primary`, `secondary`, or `middle`), and `pointer_intents` derived from the
active keymap. Use `pointer_intent(context, name)` rather than matching raw
modifier chords; the binding stays remappable.

`RunRhaiToolHook { tool, hook, args }` invokes a persistent callback through an
explicit binding. The runtime pins the committed scene generation and retires
queued calls on reload, scene transition, or Twin close.

Continuous pointer-move hooks are opt-in through
`SetScenePointerMoveHook { doc_id, interaction_id, tool, hook, context }` and
cleared with `ClearScenePointerMoveHook { doc_id, interaction_id }`. One
interaction owns a document at a time.

## Input automation

Rhai can drive the actual application input path through `InjectWindowInput` and
the helpers in `input.rhai`:

```rhai
input_key_press("AltLeft");
input_click("primary", 960.0, 540.0);
input_key_release("AltLeft");
```

The helpers emit the same aggregate window events and typed Bevy messages that
the native backend produces. Egui, picking, focus, key bindings, and authored
tools all observe one canonical path. Rhai owns the gesture sequence; Rust owns
event validation and fan-out.

Use `input_pointer_move`, `input_pointer_press`, `input_pointer_release`, and
`input_scroll` for drag and viewport workflows. Coordinates are logical pixels
in the primary window. The command does not warp the OS pointer.

A frame wait is not a gesture-duration guarantee. Slow rendering can stretch a
held press beyond egui's click limit. Split press and release across frames when
the held state matters.

## Authoring tools

The authoring libraries are policy over the explicit document commands. They do
not parse USDA, maintain a second document, or write ECS state directly.

| Library | Purpose |
|---|---|
| `assembly_builder` | Semantic frames, shapes, placement, alignment, collision clearance, and body/joint plans |
| `assembly_edit` | Explicit-document USD edits, components, programs, and connections |
| `model_authoring` | Assembly context, readiness reports, scene recipes, and port graphs |
| `modelica_editor` | Generation-checked AST, diagram, and text batches |
| `sysml_editor` | Source-range edits and semantic checkpoints |
| `rhai_editor` | Generation-checked script source edits |
| `authoring_session` | Cross-domain capability discovery, dry plan, grouped apply, checkpoint, undo, redo |
| `editor_workflow` | Inspect/projection/lint checkpoints and opt-in autosave |
| `physics_acceptance` | Contact, motion, settling, joint, and runtime-evidence checks |

The common editing contract is:

```rhai
let state = authoring_session::inspect("sysml", sysml_doc);
let dry = authoring_session::plan("sysml", ops, "update contract", state.generation);
let applied = authoring_session::apply(
    "sysml", sysml_doc, ops, dry.label, dry.parent_generation);
let checked = authoring_session::checkpoint("sysml", sysml_doc);
```

`plan` is pure. `apply` sends one reviewed group to the format owner and never
chooses an active tab or writes a source file directly. `checkpoint` reads the
owner's current generation and diagnostics. `undo` and `redo` use the same
explicit document id.

USD, Modelica, SysML/KerML, and Rhai each provide a thin typed adapter for their
parser or projection semantics. WESL remains renderer-owned until it receives
the same document adapter; generic tools must not write shader files directly.

## Inspection and diagnostics

| Query | Answers |
|---|---|
| `ScriptStatus { target }` | Is the scenario healthy? Compile and runtime diagnostics |
| `ScriptInspect { target }` | What is it doing? Live `this`, hooks, generation, paused/running |
| `ScriptingCatalog` | What can be called? The full surface for external clients |
| `ScriptComplete { prefix, limit }` | Bounded completion over the same owner |

`print(...)` lands in the console. A compile error includes file, line, and
column where available. Runtime errors remain visible and do not become
successful no-ops.

## Running a scenario

| Transport | How |
|---|---|
| Scene asset | `LunCoProgramAPI` with `info:sourceAsset` |
| HTTP API | `ExecuteCommand` with `RunScenario` |
| MCP | The `run_scenario` tool |
| One-shot eval | `RunRhai { code }` |
| Structured click tool | `RunRhaiTool { tool, args }` |
| Control | `SetScenarioPaused`, `StopScenario` |

`RunScenario.source` is Rhai source text, not a filesystem path. For a
file-backed script, read the file into the request body. `RunScenarioAsset`
accepts an asset address and rejects empty or whitespace-only source input before
URI conversion, asset loading, or pending-host publication.

The terminal client is a thin API consumer:

```bash
luncosim rhai --api 4101
luncosim rhai --api 4101 -e 'print(find("Rover"))'
luncosim rhai --api 4101 -f scripts/check.rhai
```

The REPL evaluates against the live app. Authored tests belong in a scene test,
not in the REPL.

## Related sections

- [Lifecycle](lifecycle.md) — source admission and hot reload
- [Commands and queries](commands-and-queries.md) — the bridge beneath every helper
- [Testing](testing.md) — the scene-test runner
- [Authoring](../usd/authoring.md) — the document workflow
