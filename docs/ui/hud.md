---
title: HUD
chapter: 9
section: 2
---

# HUD

A HUD is presentation drawn over the live scene. It is not a dock panel and it
is not a document. HUDs answer questions about the running world: which body is
in view, how fast the vessel is moving, whether a download is holding the
simulation, or which lesson step comes next.

LunCoSim has three HUD families:

| Family | Visibility owner | Examples |
|---|---|---|
| User-controlled | A persisted setting or a Twin setting | Time HUD, surface-view switcher, performance HUD, input HUD, camera/status HUD |
| Automatic | Scene, possession, or lifecycle state | Rover HUD, lander control cards, terrain and download progress, guided and notification cards |
| Twin-authored | A runtime surface manifest plus its exposure | Mission-status cards, vehicle controls, program browsers, custom Twin HUDs |

**Settings → HUD** is the discoverable view over the user-controlled family. It
does not become a second visibility registry: each row writes the same resource,
Twin setting, or typed command that the owning feature already reads.

## User-controlled HUDs

| Surface | Position | Default | Owner and switch |
|---|---|---|---|
| Time HUD | Top-left | Off | `OverlaySettings.sky_clock`; also in the **Time** menu |
| Surface view switcher | Top-centre | Off | `OverlaySettings.view_switcher`; also in the **Camera** menu |
| Performance HUD | Status bar | Off | `PerfHudSettings.enabled`; `TogglePerfHud` |
| Input HUD | Bottom-centre | Off | `InputOverlaySettings.enabled`; `ToggleInputOverlay` |
| Camera/status HUD | Top-right | On | Twin setting `ui.camera_status`, authored default `true` |
| Graphs HUDs | Measured view area | Per instance | `GraphHuds`; **+ Add** in Settings → HUD |
| Camera views | Measured view area | Per instance | `CameraFeeds`; **+ Add camera view**, limit eight |

The Time HUD shows the shared celestial epoch. The surface-view switcher is both
a control and a readout: it selects Surface, Moon, or Earth and shows which body
the camera is focused on. Both are opt-in; a fresh install shows the terrain and
nothing on top of it.

The performance HUD occupies the status bar and reports rendering FPS, frame
time, physics step time, and Modelica worker time per physics step. Its samples
come from the shared engine-health publication, so the graph remains live before
a Twin is active. When space is tight the metric text shortens and scales rather
than wrapping.

The input HUD visualizes live keyboard and mouse input. It is intended for
recording, teaching, and input debugging, not for normal operation.

The camera/status surface shows the active camera identity. It is a runtime
surface with a Twin-scoped boolean gate, so a Twin can hide it with
`"ui.camera_status" = false` without changing the user's global settings.

Graphs HUDs are independent native windows, each with its own grid, parameter
selection, visibility, and measured geometry. A card can plot up to four measured
channels; each quantity keeps its own unit and Y scale while the time axes stay
linked. The title-bar **×** removes the instance; the Settings row only toggles
visibility, so a hidden card keeps its selection. The picker closes on **Done**
or an outside click. Scene teardown releases every HUD-owned grid and plot,
including while hidden.

Camera views are independent render feeds. **+ Add camera view** creates the
first view without needing an existing camera window; the view's own toolbar
then selects a live camera. The limit is eight views.

## Automatic HUDs

These surfaces are listed in **Settings → HUD** under **Automatic HUDs** with
their owner, but they are not user-toggled. Their visibility is a consequence of
state:

| Surface | Owner |
|---|---|
| Rover HUD | Driven-vessel possession and capability state |
| Lander control cards | Authored USD control-HUD metadata on the active scene |
| Terrain and scenario-download progress | Transient terrain and network lifecycle state |
| Guided, notification, and blackout HUDs | Authored guidance and runtime session state |

The rover HUD appears only while a vessel is possessed, because it answers a
question the user just asked by taking control. The lander cards are authored on
the scene, not generated from a model class. Download and terrain progress are
transient: dismissing the preparation window keeps the required-data hold, and
the window reopens when a new runtime requirement appears.

Tutorial presentation is a separate guided layer. Its lesson HUD is a
specific-HUD readout; its ring, coach card, and completion prompt use the guided
overlay order. Menus and window controls remain in front of both.

## Runtime surfaces

The shipped application manifest registers these Twin-facing surfaces:

| Surface | Placement | Gate |
|---|---|---|
| `vessel-hud` | Full viewport | View perspective |
| `vehicle-control-left` | Bottom-left window | `ui.vehicle_controls`, default on |
| `vehicle-control-right` | Bottom-right window | `ui.vehicle_controls`, default on |
| `camera-status` | Top-right window | View perspective; `ui.camera_status`, default on |
| `celestial-view` | Top-centre window | View perspective; `view_switcher` gate |
| `program-browser` | Top-left window | Always registered; content decides visibility |
| `lunica-schema` | Top-centre window | Modelica schema presentation |
| `terrain-progress` | Top-centre window | Terrain lifecycle |
| `scenario-download` | Top-centre window | Download lifecycle |
| `asset-consent` | Full viewport | Required-data consent; non-modal |

A Twin can replace any of these by stable ID or add its own surfaces. Closing the
Twin restores the application surfaces. The full manifest contract is in
[Runtime UI](runtime-ui.md).

The `celestial-view` surface also carries the lunar map and the mission-site
card. The map is gated by the Twin setting `ui.lunar_map`; omission means hidden.
The map marker is projected from the canonical surface pose, not from a render
transform. The mission-site card appears only while the Moon orbital pin is
active and the scene has a valid lunar site anchor.

## Stacking and input

HUD layers are ordered. From front to back: menus and popups, floating windows
and dialogs, the general HUD, the specific HUD, docked panels, then authored
runtime HUI. A HUD area belongs inside the viewport rectangle. Docked panels are
not above a HUD that overlaps them.

Pointer ownership follows the same explicitness:

- A full-window runtime surface is transparent to scene clicks. Only visible
  controls that declare an HUI `on_press` callback enter the scene-pick gate.
- A `window` surface can be dragged only by a descendant tagged
  `tag:ui_drag_handle="true"`. Dragging a button never moves the panel.
- A `modal` surface must be interactive and use viewport placement. While
  visible, its root claims the full-window scene-pick gate. Escape emits its
  declared `dismiss_action`; Rhai owns what dismissal means.
- A non-modal data window such as asset consent consumes clicks only inside its
  own panel. The rest of the viewport stays interactive while its work
  continues.

Hiding a surface destroys its retained tree. When the exposure returns, the
runtime creates a fresh root from the manifest, so template-owned build state
cannot survive a hidden transition.

## Guided HUD cards

Rhai scripts can publish hint, objective, and action cards through
`lunco-workbench-guided-ui`. This is separate from the runtime surface manifest:
the cards are script-owned presentation, not HTML templates.

`hud_perspectives(ids)` sets a card-specific allowlist. The default is **View**
(`sandbox_view`); an empty list allows every perspective. Unknown perspective
ids reject before state changes. Hiding a card preserves its state; visible cards
stack by stable owner identity and measured height.

An implicit card belongs to the executing script's stable identity. Unscripted
API or REPL calls use a distinct command-context card. An explicit `hud` name
creates a scene-owned card that several producers can share:

```rhai
hint("mission", "Align with the landing site.");
objectives_hud("mission", [
    #{ id: "align", text: "Align with the site", done: false },
]);
guided_hud_actions("mission", "rover", "on_guided_action", [
    #{ id: "take_control", label: "Take control" },
]);
```

Action sets carry a `ToolHookBinding` lease. Replacing or clearing the actions
despawns the previous lease, so a queued click cannot bind to a new same-name
card or a different Twin.

## Layout persistence

A draggable `window` surface stores only a validated logical top-left override in
the active Twin's workspace state. The manifest remains the default geometry and
visibility authority. Overrides are pruned when the manifest no longer authors
their surface ID, clamped after a resize or DPI change, and cleared when the Twin
closes. A primary-button double click on the drag handle restores the authored
anchor.

**Settings → HUD → Surface view switcher position → Reset position** removes only
the `celestial-view` override. It does not reset other draggable surfaces or the
shared layout store.

## Common tasks

To reduce clutter while presenting:

1. Open **Settings → HUD**.
2. Turn off the performance HUD, input HUD, and any graph or camera view you do
   not need.
3. Leave automatic HUDs alone; they disappear with their scene state.
4. If a Twin hides the camera/status surface, check `ui.camera_status` in the
   Twin settings rather than looking for a global toggle.

To diagnose a missing HUD:

| Symptom | Check |
|---|---|
| Surface absent | Namespace, `visible`, perspective filter, gate, and placement rectangle |
| Surface visible but empty | Declared template properties and binding source names |
| Button ignores clicks | Callback spelling in the template and manifest, then the Rhai action handler |
| Surface moved and will not return | Double-click its drag handle, or reset its position in Settings → HUD |
| Text renders as boxes | The stylesheet must import `lunco://ui/runtime_fonts.css` |
| Surface remains after its state ended | Check the exposure's `visible` value and the surface lifecycle; hidden surfaces are destroyed |

For the full authoring contract, see [Runtime UI](runtime-ui.md). For the
walkthrough, see [Compose a HUD](../tutorials/compose-ui.md).
