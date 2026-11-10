---
title: File formats
chapter: 8
section: 5
---

# File formats

A LunCoSim project is a set of authored sources plus a small amount of runtime
state. The authored sources keep their native formats. LunCoSim extensions are
carried in standard USD, Modelica, Rhai, TOML, JSON, and WESL constructs rather
than in a private project archive.

This page is the extension-and-owner index. For the conceptual division between
USD, Modelica, Rhai, and TOML, see [Formats](../general/formats.md).

## Authored domain files

| Extension | Format | Owns | Consumer |
|---|---|---|---|
| `.usd`, `.usda`, `.usdc` | USD stage | Hierarchy, transforms, geometry, materials, physics, typed ports, connections, program attachments | USD composition, renderer, physics, co-simulation |
| `.usdz` | Packaged USD | A self-contained USD package, when the registered USD file-format plugin is available | USD composition |
| `.gltf`, `.glb` | glTF 2.0 asset | Mesh geometry, materials, node hierarchy | Bevy glTF loader through the USD render adapter |
| `.mo` | Modelica source | Continuous equations, parameters, state, acausal connectors | Modelica compiler and solver |
| `.fmu` | FMI 3 Co-Simulation archive | An external co-simulation participant | Native FMI 3 CS importer; scalar `Float64` profile |
| `.rhai` | Rhai script | Events, commands, tasks, objectives, tutorial flow, test verdicts | Rhai runtime and tool hooks |
| `.wesl` | WESL shader source | Parameter block, texture bindings, fragment and optional vertex entry points | Shader reflection and render pipeline |
| `.sysml`, `.kerml` | SysML/KerML source | Requirements, structure, verification mappings | Bounded SysML validation and Rhai analysis |
| `twin.toml` | TOML | Project identity, entry scene, source roots, settings, children, journal policy | Workspace and Twin loader |
| `Assets.toml` | TOML | External bytes, hashes, processing recipes, cache placement | Asset registry and downloader |

The native FMI importer is deliberately narrow. It supports scalar `Float64`
signals and rejects Event Mode, early return, Model Exchange, arrays, Scheduled
Execution clocks, and externally hosted FMUs. A `.fmu` that loads is not a claim
of broad FMI conformance; state the tested profile when reporting a result.

glTF is an external asset format, not a USD layer. A USD `payload` or
`reference` arc names the file, and the render adapter reads that arc from the
composed prim and loads the asset through Bevy's glTF loader. The default
`lunco:assetMode = "scene"` attaches the whole scene; `"mesh"` attaches one mesh
primitive as `Mesh3d`. `lunco:assetLabel` selects a named sub-asset. The same
asset path works in native and browser builds. See
[Addresses and assets](../usd/addresses-and-assets.md#gltf-payloads).

## Engine and policy manifests

These files are authored data, even when they ship with the engine:

| Path | Kind or format | Purpose |
|---|---|---|
| `assets/manifests/*.toml` | TOML | Grouped engine asset declarations for Modelica, fonts, terrain, celestial data, and environment data |
| `assets/scripting/policy/index.toml` | TOML with `kind = "lunco.policy.v1"` | Binds hook ids to Rhai sources and entry points |
| `assets/config/keybindings.json` | JSON with `kind = "lunco.input-bindings.v1"` | Authored default input bindings |
| `assets/config/program_contracts.json` | JSON with `kind = "lunco.program-contracts.v1"` | Program contract declarations |
| `assets/ui/runtime_surfaces.json` | JSON with `kind = "lunco.runtime-ui-manifest.v1"` | Shipped runtime UI surfaces |

A Twin can carry its own `Assets.toml`, policy manifest, input bindings, program
contracts, and runtime UI manifest. The engine discovers authored documents by
kind, not by a compiled-in filename.

## Runtime UI documents

A runtime UI manifest names its templates and stylesheets:

| Extension | Role |
|---|---|
| `.json` | `lunco.runtime-ui-manifest.v1` surface registration |
| `.html` | HUI template: retained tree, declared properties, callbacks |
| `.css` | Flair stylesheet: appearance, internal layout, custom properties |
| `.ttf` | Bundled font asset referenced by `runtime_fonts.css` |

Paths in a manifest are relative to that scope's asset root. The runtime
qualifies them with `lunco://` or `twin://` before publishing the retained tree.
See [Runtime UI](../ui/runtime-ui.md).

## User and workspace state

These files are written by the application, not authored by hand:

| Path | Content |
|---|---|
| `<OS config dir>/lunco/settings.json` | User-global typed settings sections |
| `<OS config dir>/lunco/settings.json.bad` | Preserved copy of an unreadable settings file |
| `<OS config dir>/lunco/recents.json` | Bounded recent Twin and file lists |
| `<OS config dir>/lunco/workspace-state/<fnv1a-hex>.json` | Per-Twin workspace state: active perspective, open documents, dock layout, draggable runtime-window overrides |
| `<project>/.lunco/settings.json` | Project-local settings override |
| `<twin>/history/journal.json` | Edit journal, when `[journal].persist = true` |

`LUNCOSIM_CONFIG` replaces the user configuration directory.
`LUNCOSIM_CACHE` replaces the asset cache root. Do not hardcode either path in a
USD layer; use `lunco://` or `twin://`.

A project-local `.lunco/settings.json` is excluded from Twin distribution. A
workspace-state file is keyed by a hash of the project path and is not written
into the Twin folder. That keeps personal layout state out of a shared project.

## Evidence and capture outputs

| Output | Produced by | Use |
|---|---|---|
| `.png` sequence | `--record-offline <dir>` | Deterministic frame capture |
| `.mp4` | `--record-offline <file>.mp4` | Video capture through ffmpeg |
| `.png` | `CaptureScreenshot` | Visual evidence from the visible production window |
| `.lcsin` | `ExportSessionInputCapture` | Bounded session input archive on a native host |
| JSON state reference | Authored test fixture | Determinism comparison for Rhai tests |

An `.lcsin` archive is an input record, not a complete replay package. It does
not contain a baseline manifest or a playback consumer, and not every command is
in the input slice. Do not claim bit-reproducible mission replay from it.

## JSON kind discriminators

A JSON document that participates in a registry declares its contract in a
`kind` field. The important user-facing kinds are:

| Kind | Document |
|---|---|
| `lunco.runtime-ui-manifest.v1` | Runtime UI surface manifest |
| `lunco.input-bindings.v1` | Authored input bindings |
| `lunco.program-contracts.v1` | Program contract catalog |
| `lunco.tutorial-catalog.v1` | Tutorial catalog |
| `lunco.policy.v1` | Policy manifest (TOML) |
| `lunco.lunar-surface-continuation.v1` | Lunar surface continuation recipe |
| `lunco.surface-annotations.v1` | Surface annotation data |
| `lunco.volume-depth.v1` | Volume depth data |
| `lunco.shadow-receiver.surface.v1` | Shadow-receiver surface data |

A document with the wrong kind is not silently accepted by another registry.
Unknown fields are rejected by the manifest loaders that use strict schemas.

## Rules

- Keep the native format valid. A `.mo` file should still open in another
  Modelica tool, and a `.usda` file should still open in another USD application.
- Reference glTF through a USD payload or reference. It is an external asset,
  not a composable USD layer.
- Do not edit a generated or cached artifact by hand. Author the source and let
  the pipeline produce the result.
- Do not hardcode a cache path in a scene. Use `lunco://` or `twin://`.
- Do not put equations in USD, mission policy in Modelica, or physics
  integration in Rhai.
- Do not add a Rust special case for one rover, lesson, or asset. Use the
  authored contract.

## Related

- [Formats](../general/formats.md) — which format owns which fact
- [twin.toml](twin-toml.md) — the project manifest
- [Assets.toml](assets-toml.md) — external bytes
- [Runtime UI](../ui/runtime-ui.md) — manifest, templates, and stylesheets
- [Command line](cli.md) — recording and validation flags
