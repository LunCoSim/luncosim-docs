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

Open **Settings → Input** and change the action, not the physical key in a
tutorial. The saved bindings are read from `assets/config/keybindings.json` in a
source checkout and from the user settings location in a packaged build.

A lesson that uses `input_hint("forward")` will display the new key. A lesson
that hardcodes a key name is not using the controller-owned binding contract.

## Gamepad and alternate input

The input layer maps semantic intents, so an alternate device or a remapped
keyboard supplies the same actions. The UI and lessons consume the intent, not
the raw key. If an added device does not respond, check that it is mapped to the
same intent in the input settings.
