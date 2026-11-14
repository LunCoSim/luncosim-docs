---
title: twin.toml
chapter: 10
section: 3
---

# twin.toml

`twin.toml` is the only file required for a folder to be a Twin. It identifies
the project, selects the entry scene, and declares where the domain sources
live. It does not contain physical equations or scene geometry.

## Minimal manifest

```toml
name = "my-rover-twin"
version = "0.1.0"
description = "A minimal rover project"

[usd]
default_scene = "scene.usda"
```

The current format uses top-level `name`, `version`, and `description`. Unknown
fields are rejected, so a typo fails visibly instead of being silently ignored.

## A fuller manifest

```toml
name = "Lunar Rover Lab"
version = "1.0.0"
description = "Classroom practice project"

[usd]
default_scene = "scene.usda"
scenes = ["scenes/*.usda", "scenes/tests/*.usda"]

[modelica]
paths = ["models"]
externals = [
  { name = "BundledModelicaLibraries", path = "@bundled:source-bundle" },
]

[sysml]
root = "requirements.sysml"
paths = ["."]

[settings]
"ui.lunar_map" = false

[[children]]
name = "engine"
path = "engine"
```

## Fields

| Field | Meaning |
|---|---|
| `name` | Human-readable project name |
| `version` | Manifest/project version |
| `description` | Optional long description |
| `uuid` | Optional stable scenario identity used by networking |
| `default_perspective` | Optional authored initial task layout |
| `[usd].default_scene` | Twin-relative path to the stage opened when the Twin opens |
| `[usd].scenes` | Globs for scenes offered by the Scenarios menu |
| `[modelica].paths` | Twin-relative Modelica search roots; defaults to `["."]` |
| `[modelica].externals` | Additional Modelica libraries, including `@bundled:source-bundle` |
| `[sysml].root` | Optional entry-point `.sysml` or `.kerml` file |
| `[sysml].paths` | Twin-relative SysML source roots; defaults to `["."]` |
| `[settings]` | Scalar project settings read and written by Rhai policy |
| `[[children]]` | Nested Twins composed into this project |
| `[journal].persist` | Persist the edit journal across sessions; off by default |

`[[components]]`, `[verification]`, and `[[native_plugins]]` are advanced
project contracts. Most user Twins do not need them.

## How `default_scene` is chosen

The Twin does not guess a starting scene from a folder of `.usda` files. If
`default_scene` is present, that exact Twin-relative stage becomes the active
world when the Twin opens. If it is absent, the Twin opens like a folder: files
are indexed, but no scene is auto-loaded.

Other `.usda` files in the Twin remain a referenceable library. Only the
declared stage is mounted automatically. A scene can still reference them
through normal USD composition.

`[usd].scenes` controls which files appear as loadable scenes in the Scenarios
menu. If omitted, LunCoSim falls back to the conventional `scenes/**` and
`sim/scenes/**` layouts. Declaring the globs explicitly is safer for a project
that organizes scenes differently.

## Modelica and SysML roots

`[modelica].paths` tells the compiler where to look for `.mo` sources. A path
may be `"."` to make the Twin root a search root. `externals` adds libraries
outside the Twin, such as the bundled source library or a sibling folder.

`[sysml]` is optional. When present, `root` selects the entry-point source and
`paths` narrows the source-set discovery. SysML files remain ordinary Twin
files; the section does not embed model text or duplicate requirements. See
[SysML requirements and structure](../sysml/requirements.md) for authoring and
the [SysML v2 overview](../sysml/index.md) for the supported profile.

## Twin settings

`[settings]` is a flat table of scalar values. Keys are namespaced strings:

```toml
[settings]
"ui.lunar_map" = false
"my_mission.max_speed" = 1.5
```

Rhai reads and writes them through `get_twin_setting(...)` and
`set_twin_setting(...)`. Use this for project policy and preferences, not for
large structured data.

## Children and journal

`[[children]]` composes local child Twins. A child is opened as part of the
parent, and a child can itself have a `twin.toml`.

`[journal].persist = true` writes the edit history to
`<twin>/history/journal.json`. It is off by default; opening a folder should not
start writing history into it unless the project asks for it.

## Related

- [Twin](../general/twins.md) — the project folder and lifecycle
- [Assets.toml](assets-toml.md) — external bytes used by the Twin
- [Create a Twin](../tutorials/create-a-twin.md) — a hands-on walkthrough
