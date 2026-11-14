---
title: Controls
chapter: 10
section: 2
---

# Controls

These are the shipped default bindings. Tutorials and lessons show the current
binding through `input_hint(...)`, so rebinding an action updates both the
control and the on-screen hint.

## Movement

| Action | Default |
|---|---|
| Forward | <kbd>W</kbd> |
| Backward | <kbd>S</kbd> |
| Left | <kbd>A</kbd> |
| Right | <kbd>D</kbd> |
| Yaw left | <kbd>Q</kbd> |
| Yaw right | <kbd>E</kbd> |
| Speed boost | <kbd>Shift</kbd> |

The same movement set applies to walking and to driving. A vehicle first needs
to be possessed; selection alone does not send input to it.

## Actions

| Action | Default |
|---|---|
| Context action | <kbd>F</kbd> |
| Thrust / brake | <kbd>Space</kbd> |
| Release | <kbd>G</kbd> |
| Switch mode | <kbd>V</kbd> |
| Pause | <kbd>P</kbd> |
| Cancel | <kbd>Backspace</kbd> or <kbd>Escape</kbd> |
| Delete selection | <kbd>Delete</kbd> |

`Space` is both thrust and brake depending on the controlled vehicle and mode.
The active control mode decides which effect applies.

## Camera and selection

| Action | Default |
|---|---|
| Look / orbit | Hold right mouse button and move |
| Select | Left click |
| Extend selection | <kbd>Shift</kbd> + left click |
| Remove from selection | <kbd>Ctrl</kbd> + left click |
| Drill into an assembly | <kbd>Alt</kbd> + <kbd>Shift</kbd> + left click |
| Add route point | <kbd>Alt</kbd> + left click |
| Route context menu | Right click |

Middle-button look is available when configured. The default look button is the
right mouse button.

## Workbench shortcuts

| Action | Default |
|---|---|
| Find navigation target | <kbd>Ctrl</kbd> + <kbd>P</kbd> |
| Find action | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> |
| Navigate back | <kbd>Alt</kbd> + <kbd>←</kbd> |
| Navigate forward | <kbd>Alt</kbd> + <kbd>→</kbd> |
| Save document | <kbd>Ctrl</kbd> + <kbd>S</kbd> |
| Save as | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> |
| Close document | <kbd>Ctrl</kbd> + <kbd>W</kbd> |
| New document | <kbd>Ctrl</kbd> + <kbd>N</kbd> |
| Open file | <kbd>Ctrl</kbd> + <kbd>O</kbd> |
| Compile | <kbd>F5</kbd> |
| Undo | <kbd>Ctrl</kbd> + <kbd>Z</kbd> |
| Redo | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Z</kbd> or <kbd>Ctrl</kbd> + <kbd>Y</kbd> |

## Rebinding

Open **Settings → Keybindings** and change the action, not the physical key in a
tutorial. The authored defaults are the input-bindings document discovered by
kind `lunco.input-bindings.v1`; in a source checkout that document is
`assets/config/keybindings.json`. Your edits persist in the `input_bindings`
section of `settings.json`, not in the authored asset.

A lesson that uses `input_hint("forward")` displays the effective binding. A
lesson that hardcodes a key name is not using the controller-owned binding
contract.

A Twin can displace a conflicting lower-priority physical binding while it is
active. The displaced action and the winning action are reported in Recent
Events; your global preference stays stored and returns when the Twin closes.

## Gamepad and alternate input

The input layer maps semantic intents, so an alternate device or a remapped
keyboard supplies the same actions. The UI and lessons consume the intent, not
the raw key. If an added device does not respond, check that it is mapped to the
same intent in the input settings.
