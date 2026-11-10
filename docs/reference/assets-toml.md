---
title: Assets.toml
chapter: 8
section: 4
---

# Assets.toml

`Assets.toml` declares **external bytes** that a Twin or the engine needs but
does not store in the project: source libraries, terrain rasters, textures,
fonts, and downloadable models.

It is a manifest, not a scene file and not a cache. The actual files are
downloaded to a local cache and addressed from USD or Modelica through logical
asset URIs.

## Where it lives

- A Twin can have an `Assets.toml` at its root. Destinations resolve against the
  Twin.
- The engine ships manifests under `assets/manifests/*.toml` using the same
  entry format. Each file is a group such as `modelica`, `fonts`, `terrain`, or
  `celestial`.

## A basic entry

```toml
[modelica_standard_library]
name = "Modelica Standard Library"
version = "4.1.0"
url = "https://github.com/modelica/ModelicaStandardLibrary/archive/refs/tags/v4.1.0.tar.gz"
dest = "library"
sha256 = "<sha256 of the archive>"
```

A single-file dataset uses the same shape:

```toml
[site_dem]
name = "Site terrain DEM"
url = "https://example.org/site-dem.tif"
dest = "assets/terrain/site-dem.tif"
sha256 = "<sha256 of the file>"
```

The table key is the asset key. It is what `--asset` / `-a` uses on the assets
manager CLI.

## Fields

| Field | Meaning |
|---|---|
| `name` | Human-readable name used in progress and diagnostics |
| `url` | Download source |
| `dest` | Destination relative to the Twin root or engine cache |
| `version` | Version marker checked when validating an installed archive |
| `sha256` | Expected content hash; the download is rejected on mismatch |
| `extract` | Archive-internal path to extract into `dest` |
| `shared` | Put the download in the shared global cache instead of the Twin-local cache |
| `recommended` | Offer the dataset during onboarding when it is missing |
| `process` | Optional processing recipe for a downloaded source |
| `bundle` | Binary names whose package should contain this artifact |
| `package_only` | Build-time package input, excluded from the runtime download catalog |

`dest` is a portable relative path. Absolute paths, parent traversal, and
platform-specific path syntax are rejected.

## Processing

A download can be followed by a processing step. A compound recipe uses
`kind = "pipeline"` and must declare both the final artifacts and the ordered
steps that produce them:

```toml
[site_dem.process]
kind = "pipeline"
output_root = "cache"
output = "terrain/site"
center_lat = -85.0
center_lon = 30.0
window_m = 1024.0
target_resolution = [257, 257]
frame = "MOON_ME"

[site_dem.process.pipeline]
artifacts = [
  { from = "height",
    source = "materials/textures/heightmap.tif",
    path = "materials/textures/heightmap.tif",
    kind = "dem",
    dimensions = [257, 257] },
]

[[site_dem.process.pipeline.steps]]
id = "height"
input = "source"
kind = "dem"
output = "height"
```

The `artifacts` table is the final consumer contract; a planner cannot replace
it. A step input names `source`, another declared input, or an earlier step.
Scratch outputs must be distinct and may not overlap.

Processing is optional. If the downloaded bytes are already the artifact you
need, omit `process`.

## Runtime behavior

LunCoSim does **not** download in the background on launch. A missing declared
dataset is shown to the user, and the download starts only after an explicit
request. The same declarations are visible in **Settings → Data & libraries**
and in the Twin's assets view.

The shared cache is:

| Platform | Default cache |
|---|---|
| Linux | `~/.cache/lunco/` |
| macOS | `~/Library/Caches/lunco/` |
| Windows | `%LOCALAPPDATA%\lunco\` |

Set `LUNCOSIM_CACHE` to override the cache root. Twin-scoped declarations write
beside the Twin by default unless the entry is marked `shared = true`.

## CLI

The assets manager in the source checkout can inspect and fetch a Twin's
manifest:

```bash
cargo run -p lunco-assets -- list -t path/to/twin
cargo run -p lunco-assets -- download -t path/to/twin
cargo run -p lunco-assets -- process -t path/to/twin
```

Use `-a <key>` to target one entry, `--force` to replace an installed artifact,
and `--quality coarse|good` to choose a faster or full processing bake.

## Addressing the result

Authored files never address the physical cache path. Use:

- `lunco://...` for the installed engine asset library
- `twin://...` for a file inside the open Twin

The asset registry resolves the logical URI to the installed bytes. A USD layer
that hardcodes `~/.cache/lunco/...` is not portable and does not use this
contract.

## Related

- [USD](../usd/index.md) — how assets are referenced from a scene
- [Twin](../general/twins.md) — the project that can declare its own assets
- [Troubleshooting](troubleshooting.md) — missing or failed downloads
