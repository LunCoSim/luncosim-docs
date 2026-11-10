# LunCoSim documentation

Public documentation site for LunCoSim. The site is built with
[MkDocs Material](https://squidfunk.github.io/mkdocs-material/) and published
with GitHub Pages from the `gh-pages` branch. No GitHub Actions or connection to
the engine repository is required.

## Write

Content lives under `docs/` and is organized into numbered chapters:

- `general/` — introduction, formats, installation, perspectives, Twins
- `tutorials/` — guided end-to-end lessons
- `usd/` — scene composition, physics, ports, programs, materials
- `modelica/` — language, cosimulation, Lunica, libraries, experiments
- `rhai/` — lifecycle, tasks, commands, events, testing, patterns
- `shaders/` — parameters, texture layers, USD materials, terrain, quality
- `ui/` — settings, HUD, theming, runtime UI, telemetry
- `reference/` — CLI, controls, manifests, file formats, API, validation

Pages use frontmatter to place themselves in the chapter sequence:

```yaml
---
title: Settings
chapter: 7
section: 1
---
```

`chapter` renders the page as **7**, and `section` renders it as **7.1**.
Headings below the page title are numbered automatically by the theme override
in `overrides/main.html`; do not type the numbers into the heading text.

Add new pages to `nav` in `mkdocs.yml`.

## Preview locally

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/mkdocs serve
```

Open <http://127.0.0.1:8000/>.

## Publish

```bash
.venv/bin/mkdocs gh-deploy --force
```

That builds the site into a temporary directory and pushes it to `gh-pages`.
GitHub Pages serves the root of that branch at
<https://luncosim.github.io/luncosim-docs/>.

Images live in `docs/assets/images/` and are copied into the published site.
Keep source images reasonably sized; prefer SVG diagrams and optimized
screenshots.
