---
title: Settings
chapter: 7
section: 1
---

# Settings

LunCoSim settings have three scopes. A user preference belongs to the person at
the machine; a project preference belongs to one checkout; a Twin preference
travels with the Twin. Keeping those scopes separate is what lets a project
enforce behavior without overwriting a user's editor preferences.

| Scope | Stored in | Typical content |
|---|---|---|
| User-global | `<OS config dir>/lunco/settings.json` | Theme, window geometry, HUD visibility, key bindings, editor behavior |
| Project | `<project>/.lunco/settings.json` | Local overrides for the open project; excluded from Twin distribution |
| Twin | `twin.toml` under `[settings]` | Shared project policy that must travel with the Twin |

`LUNCOSIM_CONFIG` replaces the user configuration directory. With
`LUNCOSIM_CONFIG=/tmp/lunco-config`, the settings file is
`/tmp/lunco-config/settings.json`. On Linux the default is normally
`~/.config/lunco/settings.json`.

For a key that exists in all three scopes, the effective value is the Twin
value, then the project value, then the user-global value. An omitted value
inherits from the next scope. An explicit `false` is a value, not an omission.
A command-line flag, where one exists, overrides every persisted scope for that
run.

## Open the Settings menu

**Settings** is a top-level menu. Its first row is the current theme; selecting
it switches between **Dark** and **Light**. The submenus follow, contributed by
the feature that owns each preference.

| Submenu | What it controls |
|---|---|
| **General** | Load the default scene on Twin open; contain bodies outside finite physics worlds |
| **Project** | The active project's local override for those scene and physics choices; reports a Twin or CLI override when one wins |
| **Keybindings** | Opens the application-owned Keybindings perspective |
| **Appearance** | Translucent tab content; Modelica diagram controls, authored colours, hover values, and semantic zoom; egui debug overlays in debug builds |
| **Graphics** | Renderer backend, samples per video frame, rendering-quality preset, and shadow-map budget where the adapter exposes one |
| **HUD** | Visibility of user-controlled heads-up surfaces; read-only inventory of automatic HUDs |
| **Data & libraries** | Download concurrency and retry policy; the registry-backed asset and library catalog |
| **Entity list** | Display preference for system-managed rows |
| **Debug** | Windows console behavior for the next launch |
| **Debug visualization** | Temporary joint, wheel-force, mass, force, and frame diagnostics |
| **Sim Core** | Test-content preference contributed by the application's Rhai policy |
| **Updates** | Build identity, update channel, and update actions |
| **Avatar** | Avatar collision policy for the active Twin, when the avatar feature is present |
| **Performance** | The status-bar performance HUD |
| **Modelica** | Code editor, component palette, diagram projection, and source-library preferences |
| **Collaboration** | Presence cursors and teach mode, when the networking UI is built |

Some submenus are context-dependent. **Avatar** appears when the avatar feature
is installed; **Performance** comes from the performance UI package;
**Modelica** comes from the Modelica editor; **Collaboration** requires the
networking UI feature. **Sim Core** is contributed by the application's Rhai
policy through the same replaceable Settings-submenu contract; no Rust crate
registers it.

Settings submenus are content-sized in both axes, capped at 640 logical pixels
wide and 24 interaction rows high. A longer submenu scrolls; it does not reserve
empty popup space.

## User-global settings

`settings.json` is one JSON document with namespaced keys. Each feature owns a
typed section; it does not get its own file. The shape is deliberately close to
VS Code's settings model:

```json
{
  "theme": { "mode": "Dark" },
  "perf_hud": { "enabled": true },
  "input_overlay": { "enabled": false },
  "overlays": { "schema_version": 1, "sky_clock": false, "view_switcher": false },
  "input_bindings": { "bindings": {}, "command_bindings": {} }
}
```

Each key is flat and names the feature that owns the section. The Settings UI
groups rows by submenu rather than by JSON nesting.

| Key | Owner | Purpose |
|---|---|---|
| `theme` | `lunco-workbench` | Active theme mode |
| `workbench_appearance` | `lunco-workbench` | Translucent tab content; debug overlays |
| `window` | `lunco-workbench-window` | Restored window geometry |
| `overlays` | `lunco-luncosim-ui` | Sky clock and surface-view switcher |
| `perf_hud` | `lunco-workbench-perf-ui` | Status-bar performance HUD |
| `input_overlay` | `lunco-input-ui` | Input visualizer |
| `input_bindings` | `lunco-input-core` | Resolved keyboard and pointer bindings |
| `entity_list` | `lunco-luncosim-edit-ui` | System-managed entity rows |
| `diagram_presentation` | `lunco-theme` | Diagram controls, authored colors, hover values, semantic zoom |
| `modelica_code_editor` | `lunco-modelica-ui` | Word wrap, auto indent, text scale |
| `modelica_journal_panel` | `lunco-modelica-ui` | Journal panel display |
| `welcome_progress` | `lunco-modelica-ui` | Welcome learning-path progress |
| `library` | `lunco-modelica-library` | Modelica source-library settings |
| `experiments` | `lunco-experiments` | Experiment defaults |
| `download` | `lunco-settings` | Download concurrency, retry budget, backoff |
| `renderer` | `lunco-render` | Raster or path-traced backend |
| `rendering_quality` | `lunco-render` | Rendering budget and per-feature limits |
| `telemetry` | `lunco-telemetry` | Telemetry defaults |
| `telemetry_display` | `lunco-viz` | Telemetry browser display preferences |
| `scene` | `lunco-workspace` | Default-scene loading |
| `physics` | `lunco-workspace` | Finite-world escape guard |
| `updates` | `lunco-updater` | Update channel and actions |

A missing file, a missing section, or an unreadable section falls back to that
section's default. A file that is not valid JSON is preserved as
`settings.json.bad` and the app starts from defaults rather than silently
overwriting the user's preferences. Writes are atomic.

Settings are saved when their resource changes. There is no separate "apply"
step for user-global preferences.

## Project settings

**Settings → Project** edits the active project's local override. The file is
`<project>/.lunco/settings.json`, uses the same section format as the global
file, and is excluded from Twin distribution. It is the right place for a
preference that depends on this checkout, not on the project's shared behavior.

The Project submenu reports when a shared Twin value or a command-line flag
takes precedence. A plain folder has neither project nor Twin settings. Changes
to scene-loading and physics-containment choices apply when the Twin is next
opened.

For example, a local project can choose not to load the default scene:

```json
{ "scene": { "load_default": false } }
```

A malformed project file or a non-boolean Twin override rejects the candidate
open and preserves the current workspace instead of guessing.

## Twin settings

The generic `[settings]` table in `twin.toml` is the per-Twin extension seam.
Keys are dotted, namespaced scalars: booleans, integers, numbers, or strings.
Adding a project preference does not require a Rust field, a new settings
section, or a new command.

```toml
[settings]
"ui.camera_status" = true
"ui.vehicle_controls" = false
```

A surface that consumes a Twin setting declares its key and its omitted value:

```json
"setting": "ui.camera_status",
"setting_default": true
```

An omitted key uses the authored default. Rhai reads the same map with
`get_twin_setting(key)` and writes it with `set_twin_setting(key, value)`. Both
the runtime surface gate and the script API converge on the workspace's generic
`SetTwinSetting` command.

The **Twin settings** panel walks the active Twin's map as a change-driven view.
It groups keys by their namespace and renders the stored scalar type directly.
Edits dispatch `SetTwinSetting`; **Reset** dispatches `ResetTwinSetting`, which
removes the key so the consuming surface's declared default applies. The panel
is intentionally limited to the generic scalar map. Structured sections such as
`[usd]` and `[journal]` remain with their domain owners, and user-global
preferences remain in `settings.json`.

The panel excludes `scene.load_default` and
`physics.finite_world_escape_guard` because those have dedicated rows under
**General** and **Project**. It clears immediately when its Twin closes.

## Keybindings

**Settings → Keybindings** opens the application-owned `input_settings`
perspective. The binding document is the typed `input_bindings` section in
`settings.json`; there is no separate `keybinds.toml`.

Authored defaults are discovered as a runtime asset with kind
`lunco.input-bindings.v1`, not compiled into the input contract. The same
resolved resource feeds the live input map, help surfaces, input injection, and
Rhai lesson labels. A persisted override that omits the look button inherits the
authored value when that asset loads.

`command_bindings` maps an identity to a physical chord, a reflected command,
typed scalar arguments, and an explicit text-focus permission. Menu hints and
Rhai `input_hint(...)` read the effective map. `SetCommandKeyBinding` validates
the command name and arguments before persisting; `SetInputIntentBinding` edits
semantic alternatives through the same owner.

Twin composition removes conflicting lower-priority physical bindings from the
transient effective map. Global preferences stay stored and return when the
Twin closes. Conflicts publish warning telemetry and appear in Recent Events;
identical snapshots do not repeat the warning.

## Appearance and Graphics

**Appearance** owns workbench presentation rather than simulation behavior:

- **Translucent tab content** keeps the live scene visible behind tab bodies.
  Turning it off uses the same opaque background in every tab.
- **Diagram editing and navigation controls** hides Modelica toolbars, zoom
  buttons, and connection-view controls for presentation while leaving model
  geometry, wires, diagnostics, and live values visible.
- **Preserve authored diagram colors** stops the dark-theme icon remapping.
- **Diagram hover values** and **Modelica semantic zoom** control diagram
  interaction.
- **Egui debug overlays** is a debug-build diagnostic for widget alignment and
  changing widget IDs.

**Graphics** owns renderer and GPU budgets. It selects the raster or path-traced
backend, the samples per video frame, and the rendering-quality preset. A Twin
can override the renderer preference; when it does, the submenu says so. A
renderer error is reported in the submenu instead of being hidden.

Rendering quality is a budget, not a shader. It changes shadow resolution,
effect availability, and similar renderer-wide costs; it does not replace the
USD-authored sky, terrain, or material shaders. See
[Shaders → Quality](../shaders/quality.md).

## HUD and debug settings

**Settings → HUD** is the discoverable view over the HUD visibility owners. It
does not maintain a second visibility registry. The page
[HUD](hud.md) lists every shipped surface and its owner.

**Settings → Debug visualization** toggles temporary physics diagnostics:
joints, wheel forces, selected-body mass, selected-body forces, and selected-body
frames. These rows are not persisted; the lease store is cleared at scene
teardown. They are diagnostic overlays, not authored scene content.

**Settings → Debug** appears on Windows and controls whether the next launch
allocates a debug console. The preference is read before the app process starts,
so it cannot be changed by Rhai or by the running UI.

## Commands and automation

Settings changes are commands, not direct UI-only mutations. The important
generic commands are:

| Command | Effect |
|---|---|
| `SetTwinSetting` | Writes one key in the active Twin's `[settings]` map |
| `ResetTwinSetting` | Removes one key so its authored default applies |
| `SetTheme` | Sets `"dark"` or `"light"`; omit `mode` to toggle |
| `SetCommandKeyBinding` | Validates and persists a command chord |
| `SetInputIntentBinding` | Edits a semantic input alternative |
| `TogglePerfHud` | Shows or hides the status-bar performance HUD |
| `ToggleInputOverlay` | Shows or hides the input visualizer |

`SetTheme` accepts `persist: false` to apply a theme for the current session
without rewriting the user's preference. That is the seam for a scene-authored
appearance override. See [Theming](theming.md).

A script or external client should use the command API rather than editing
`settings.json` while the app is running. The settings owner keeps an in-memory
mirror and flushes atomically; an external write can be overwritten by the next
flush.

## Adding a setting

A feature adds a setting by owning a typed section:

```rust
#[derive(Resource, Serialize, Deserialize, Default, Clone, PartialEq)]
struct PerfHudSettings {
    enabled: bool,
}

impl SettingsSection for PerfHudSettings {
    const KEY: &'static str = "perf_hud";
}

app.register_settings_section::<PerfHudSettings>();
```

After registration the section is a normal Bevy resource. Mutating it marks the
section changed, and the central flush writes `settings.json`. A new setting
needs one struct and one registration call; there is no central allowlist.

Use a dotted key when several sections share a domain prefix. Keep one owner per
key. Do not create a per-feature JSON file for a new preference: the documented
exceptions are `recents.json` (high-churn list state),
`workspace-state/<hash>.json` (per-project, path-keyed workspace state), and the
layout store, which is structural rather than a preference.

## Troubleshooting

| Symptom | Likely cause | Check |
|---|---|---|
| A setting reverts after restart | The write did not reach `settings.json`, or another scope wins | Inspect the file, then check project and Twin scopes |
| A Twin setting has no effect | Key spelling differs, or the consumer declares a different default | Compare `twin.toml`, the manifest `setting`, and the producer |
| A shortcut does nothing | The chord is displaced by a Twin binding or focus permission denies it | Open Keybindings and inspect the effective map |
| Settings file is ignored | Invalid JSON | Look for `settings.json.bad` beside the original |
| HUD row is missing | Its feature or Twin context is absent | Check the feature build and the active Twin |

Continue with [HUD](hud.md) for the surfaces those settings control, or
[Runtime UI](runtime-ui.md) for the authored presentation layer.
