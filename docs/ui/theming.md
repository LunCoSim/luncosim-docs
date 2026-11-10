---
title: Theming
chapter: 8
section: 3
---

# Theming

LunCoSim ships two themes: **Dark** and **Light**. Dark is the default. The
themes are built from the Catppuccin Mocha and Latte palettes, then projected
through semantic design tokens so a panel, a plot, a Modelica diagram, and an
authored HUD do not each invent their own colours.

There is no High Contrast mode in the current build. A feature that needs a
higher-contrast presentation should use the existing semantic tokens rather than
adding a second theme enum.

## The theme model

`lunco-theme` owns one `Theme` resource:

| Part | What it provides |
|---|---|
| `ColorPalette` | The raw Catppuccin palette |
| `DesignTokens` | Semantic colours: accent, success, warning, error, text, subdued text, raised and sunken surfaces, borders, scrim, overlay backdrop |
| `TypographyScale` | Named roles from display and title down to dense data and code |
| `SpacingScale` | Shared spacing increments |
| `RoundingScale` | Shared corner radii |
| `SchematicTokens` | Wire and class-kind colours for block diagrams |
| `JournalTokens` | Edit-history row colours by category |
| `PlotTokens` | Signal-series colours for plots |
| `ModelicaIconPalette` | Anchor and inversion rules for authored Modelica icons |
| `overrides` | Code-registered per-domain token overrides |

Consumers read tokens; they do not read raw palette entries for functional UI.
That is what lets the same panel render correctly in both modes. A new UI
surface should choose a role such as `tokens.overlay_backdrop`, not a literal
`#181825`.

The typography roles are `display`, `title`, `section`, `body`, `button`,
`label`, `tree`, `caption`, `dense_data`, `dense_code`, and `code`. The
workbench applies them in `ThemeApplySet`; render systems that paint their own
egui must run after that boundary.

## Selecting a theme

The first row of the **Settings** menu shows the current mode. Selecting it
switches between Dark and Light. The choice is persisted in the `theme` section
of `settings.json`:

```json
{ "theme": { "mode": "Dark" } }
```

The same change is available as a command:

```json
{ "type": "ExecuteCommand", "command": "SetTheme", "params": { "mode": "light" } }
```

`SetTheme` accepts `"dark"` and `"light"` case-insensitively. Omitting `mode`
toggles. The command normally persists the new mode. Passing
`"persist": false` applies the theme for the current session only and leaves the
user's saved preference untouched.

That non-persisted path is the seam for scene-authored appearance. A film take
that records dark must not rewrite the operator's editor preference. While the
live theme equals the non-persisted override, the preference sync stands down;
the moment another action changes the theme, the override clears and normal
persistence resumes.

## What the theme reaches

| Surface | How it follows the theme |
|---|---|
| Workbench chrome and panels | Palette-derived egui `Visuals`, semantic tokens, typography roles |
| Docked panel bodies | `overlay_backdrop` by default; optional opaque mantle surface |
| Status bar and HUD tiers | Shared theme tokens |
| Plots and graphs | `PlotTokens` signal colours |
| Modelica diagrams | `SchematicTokens` for wires and class kinds; `ModelicaIconPalette` for authored icons |
| Change History | `JournalTokens` row colours |
| Runtime-authored HUDs | Semantic CSS custom properties written by the runtime bridge |
| Authored Modelica icon colours | Remapped in dark mode unless **Preserve authored diagram colors** is on |

The Modelica icon palette is not a simple invert. Canonical source-library
colours (black outlines, white fills, primary blue and red) are mapped through
an anchor table, and other colours have their lightness inverted within a
clamped range. Light mode uses the identity palette because the source library
was designed for a paper-white canvas. **Settings → Appearance → Preserve
authored diagram colors** disables the remapping when the authored diagram is
itself the presentation.

## Workbench appearance

**Settings → Appearance** exposes two workbench-level choices:

- **Translucent tab content** keeps the live scene visible behind every tab body
  and its standard panel surface. Turning it off uses the same opaque background
  in every tab.
- **Egui debug overlays** is available in debug builds and draws widget
  alignment and changing-widget-ID diagnostics. It is off by default and should
  stay off during ordinary interaction.

The same submenu owns Modelica diagram presentation: editing and navigation
controls, authored colours, hover values, and semantic zoom. These are
presentation settings, not model edits. Hiding controls does not reload or
change the model.

## Runtime UI colours and fonts

An authored stylesheet should import both shared runtime stylesheets:

```css
@import "runtime_fonts.css";
@import "runtime_theme.css";
```

`runtime_fonts.css` declares the bundled **LunCo UI** font. Bevy's minimal
default font is ASCII-only; relying on it turns telemetry and status glyphs into
boxes on some platforms. The runtime contract supports one explicit
`@font-face`, with no browser-like local or fallback chain. A surface that needs
another glyph set must bundle and author that font asset.

`runtime_theme.css` declares the semantic custom properties. The runtime bridge
rewrites the same properties from the active `Theme` whenever the theme changes:

| Property | Semantic source |
|---|---|
| `--panel-background` | Overlay backdrop |
| `--panel-border` | Overlay border |
| `--panel-inner` | Sunken surface |
| `--button-background` | Raised surface |
| `--button-border` | Raised-surface border |
| `--text-color` | Primary text |
| `--muted-color` | Subdued text |
| `--accent-color` | Accent |
| `--active-text-color` | Sunken surface |
| `--ok-color` | Success |
| `--caution-color` | Warning |
| `--warm-color` | Warning |
| `--danger-color` | Error |

The values in `runtime_theme.css` are dark defaults. They cover the stylesheet
before its retained root mounts; once the surface is live, the bridge supplies
the active theme's values. A light-mode surface therefore does not need a second
stylesheet.

Use semantic variables in authored CSS:

```css
#status-root {
  background-color: var(--panel-background);
  border: 1px solid var(--panel-border);
  color: var(--text-color);
}

#status-state {
  color: var(--ok-color);
}
```

A manifest binding with `"css": true` adds a per-property custom variable named
`--ui-<property-name>`, with underscores converted to hyphens. That is the
supported way to project a changing value into CSS. A text-only binding never
enters the CSS token stream.

Do not hardcode a dark palette into a Twin stylesheet if the surface should work
in both themes. If a surface is deliberately theme-independent, say so in its
own comments and keep the authored colours accessible against the scene.

## Theme extension

Domain code can register a token override:

```rust
theme.register_override("terrain", "contour", color);
```

The override is keyed by domain and token and bumps the theme revision. This is
a code-level extension point for a domain that needs a shared semantic colour;
it is not a user-facing theme editor. A per-surface colour that changes at
runtime belongs in the surface's exposure and a `css: true` binding.

## Troubleshooting

| Symptom | Check |
|---|---|
| HUD stays dark in Light mode | The stylesheet must import `runtime_theme.css`; literal colours do not follow the theme |
| Text is unreadable over the scene | Use `--panel-background` and `--text-color`, not a transparent background with a fixed text colour |
| Glyphs render as boxes | Import `runtime_fonts.css` and confirm the bundled font asset is available |
| Diagram colours look inverted | Turn on **Preserve authored diagram colors** or use theme-aware authored colours |
| Theme reverts on restart | The change was applied with `persist: false`, or another scope owns the preference |
| Theme changes but a custom panel does not | The panel is painting before `ThemeApplySet` or caching derived colours without the theme revision |

For the runtime surface contract, continue with [Runtime UI](runtime-ui.md). For
the settings that expose these choices, see [Settings](settings.md).
