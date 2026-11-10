---
title: UI & Settings
chapter: 8
---

# UI & Settings

The LunCoSim window is a workbench around a live 3D viewport. The workbench
owns the shell: menus, docks, panels, the status bar, and the task layouts. The
viewport owns the world. Twin-facing HUDs and cards are a separate,
runtime-authored layer that can be changed without recompiling Rust.

This chapter describes the interface as a system: where a control lives, which
owner decides whether it is visible, and which file or command changes it. It
does not repeat every keyboard shortcut; the complete binding reference is in
[Controls](../reference/controls.md).

## The shell

The standard layout has six regions:

| Region | Contents | Owner |
|---|---|---|
| Menu and title bar | File, Edit, View, domain menus, Settings, Help, Time, transport, perspective tabs, window controls | Workbench shell |
| Left dock | Twin browser; Entities, Telemetry, and task-specific panels | Workbench dock |
| Center | Live 3D viewport, document editor, or analysis surface | Perspective |
| Right dock | Inspector, Environment, Requirements, Change History | Workbench dock |
| Bottom dock | Console, Graphs, Timeline, task tools | Workbench dock |
| Status bar | Simulation time, speed, selection, body, FPS, latest status event | Status bus and HUD owners |

The 3D scene is rendered full-window by the scene camera. The egui host camera
paints the chrome into the same shared texture, with the scene pass clearing and
drawing first. That is why a panel can be translucent over the live scene
without the viewport being tiled or resized.

A perspective changes which panels are docked and what the center is for. It
does not reload the Twin, stop the simulation, or duplicate the project. The
five pinned tasks are **View**, **Analyze**, **Build**, **Editor**, and
**Lunica**; specialist tasks such as **Terrain** and **Keybindings** are
available under **View → Perspectives**. See
[Perspectives](../general/perspectives.md) for the task-by-task description.

## Presentation layers

LunCoSim does not have one undifferentiated UI layer. From front to back:

1. Menus and popups.
2. Floating windows, dialogs, guided cards, and notices.
3. The general HUD: clocks, toasts, and global notices.
4. The specific HUD: scene- and vehicle-owned readouts.
5. Docked workbench panels.
6. Runtime-authored HUI surfaces, which paint before the egui pass and
   therefore stay below every egui tier.

The ordering matters for both appearance and input. A menu always wins over a
HUD. A visible modal runtime surface can claim the scene-pick gate; an ordinary
full-window HUD does not, and scene clicks pass through everywhere except its
authored buttons.

## What is configurable

| You want to change | Surface | Where it is owned |
|---|---|---|
| Panel layout for a task | Perspective | Workbench layout, remembered per Twin |
| User preferences | Settings menu | `settings.json` |
| Project-wide behavior | Project settings | `<project>/.lunco/settings.json` |
| Behavior that travels with a Twin | Twin settings | `twin.toml` `[settings]` |
| HUD visibility | Settings → HUD, or a Twin setting | The HUD's owning resource |
| HUD content and placement | Runtime surface manifest, template, stylesheet | Twin or application `assets/ui/` |
| Colours and typography | Theme | `Theme` resource and `settings.json` |
| Key bindings | Keybindings perspective | `input_bindings` settings section |
| Telemetry readout | Analyze perspective or HTTP API | Live port registry |

## Reading this chapter

| Section | Question it answers |
|---|---|
| [Settings](settings.md) | Which settings exist, where are they stored, and which scope wins? |
| [HUD](hud.md) | Which heads-up surfaces ship, who controls their visibility, and how do they take input? |
| [Theming](theming.md) | How do Dark and Light mode, semantic tokens, fonts, and diagram colours work? |
| [Runtime UI](runtime-ui.md) | How does an authored HTML/CSS surface become a retained UI tree? |
| [Telemetry](telemetry.md) | How do I read live values and record evidence? |

For the authoring walkthrough, start with
[Compose a HUD](../tutorials/compose-ui.md). For the USD metadata that attaches
a surface to a subject, see
[USD → Programs](../usd/programs.md) and
[USD → Authoring](../usd/authoring.md).
