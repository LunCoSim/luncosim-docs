# LunCoSim documentation

Public documentation site for LunCoSim. The site is built with
[MkDocs Material](https://squidfunk.github.io/mkdocs-material/) and published
with GitHub Pages from the `gh-pages` branch. No GitHub Actions or connection to
the engine repository is required.

## Write

Content lives under `docs/`:

- `getting-started/` — install, first launch, first lesson
- `concepts/` — Twin, `twin.toml`, USD, Modelica, Rhai, `Assets.toml`
- `guides/` — hands-on workflows
- `reference/` — CLI flags and controls

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
