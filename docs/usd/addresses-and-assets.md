---
title: Addresses and assets
chapter: 3
section: 6
---

# Addresses and assets

Every reference in an authored file is an address. LunCoSim recognizes exactly
two scene schemes, and one rule decides which to use: **the root that owns the
file**.

| Scheme | Root | Use |
|---|---|---|
| `lunco://<path>` | The installed engine asset library | Shipped assets, engine libraries, bundled models and shaders |
| `twin://<authority>/<path>` | A registered Twin or folder root | Anything the user opened or authored in the project |

A bare relative path is an input to an open command only. It does not survive
past the command boundary as a scene address. An absolute filesystem path is
what a file picker produces; it is converted to a rooted address before the
scene lifecycle starts.

This is not ceremony. A bare relative path means "resolve against the default
source", but once a Twin is open the same string resolves against the Twin
instead. A miss then becomes a silent no-load: an empty scene with no error.
Two spellings of the same intent with different, context-dependent meanings is
a correctness hazard.

## The Twin authority

A Twin is mounted under a percent-encoded authority derived from its display
name. The authority is not necessarily the manifest name spelled literally:
spaces, Unicode, percent signs, and URI delimiters are encoded injectively.
Reopening the same folder assigns a fresh authority while keeping the authored
logical source identity.

Scripts should read the current authority with `twin_name()` rather than
reconstructing it from the manifest:

```rhai
let authority = twin_name();
let path = `twin://${authority}/models/Drive.mo`;
```

A retired origin fails before binding. A transport request without an origin
retains its exact authority and cannot revive a closed source.

## Relative references inside a layer

USD references are relative by design:

```usda
def Xform "Rover" (
    prepend references = @./assets/rovers/skid_rover.usda@
)
{
}
```

A relative reference resolves against the layer that authored it, not against
the process working directory. That is why a scene cannot be loaded in
isolation: it always resolves *through* a root.

The same rule applies to sublayers, payloads, and asset-typed shader inputs.
A layer that hardcodes `~/.cache/lunco/...` is not portable and bypasses the
asset registry.

## Do not escape the root

`..` traversal that leaves an asset root is rejected. A reference that needs a
sibling root should use the correct scheme, not a longer relative path.

This is a safety boundary, not a style preference. The loader validates every
authored composition arc before OpenUSD's identifier callback, and a rejected
identity is recorded as a diagnostic before the stage is published.

## Where the bytes come from

A `twin://` address names a logical file. The bytes may be:

- a file the author saved in the Twin;
- a file produced by a processing step;
- a file downloaded into the Twin-local cache;
- a shared artifact in the global cache.

`Assets.toml` declares the external ones. It is a manifest, not a cache and not
a scene file:

```toml
[modelica_standard_library]
name = "Modelica Standard Library"
version = "4.1.0"
url = "https://github.com/modelica/ModelicaStandardLibrary/archive/refs/tags/v4.1.0.tar.gz"
dest = "library"
sha256 = "<sha256 of the archive>"
```

`dest` is a portable relative path. Absolute paths, parent traversal, and
platform-specific syntax are rejected.

The runtime does not download in the background on launch. A missing declared
dataset is shown to the user, and the download starts only after an explicit
request. The same declarations are visible in **Settings → Data & libraries**.

A required dataset holds simulation until it is available. A recommended or
optional dataset remains available in the catalog and does not block an
unrelated scene. Dismissing the preparation window keeps the hold; a new scene
or runtime dependency reopens the window.

## The cache is not an address

| Platform | Default cache |
|---|---|
| Linux | `~/.cache/lunco/` |
| macOS | `~/Library/Caches/lunco/` |
| Windows | `%LOCALAPPDATA%\lunco\` |

Set `LUNCOSIM_CACHE` to override the cache root. Twin-scoped declarations write
beside the Twin by default unless the entry is marked `shared = true`.

Authored files never address these physical paths. They address the logical
URI; the asset registry resolves it to installed bytes. A physical path in a
scene breaks portability and bypasses hash validation, processing, and cache
lifecycle.

## Asset-typed inputs

Shader inputs, program sources, and texture roles are asset-typed:

```usda
# On a prim applying LunCoProgramAPI:
uniform token info:implementationSource = "sourceAsset"
uniform asset info:sourceAsset = @twin://rover/models/Drive.mo@

# On a shader prim:
asset inputs:albedo_map = @twin://terrain/site/albedo.png@
```

The asset owner resolves the path, checks the source scope, and publishes the
loaded asset. A missing source is an explicit error at that owner, not a
fallback to a similarly named file.

For a script that needs to resolve a document-relative path without reading
the filesystem, use the shared URI helper:

```rhai
let uri = asset_source_relative_uri(document, "textures/hull.png");
```

It preserves the document's registered source authority and performs URI
algebra only. It does not read the file or create an asset handle.

## glTF payloads

A `.gltf` or `.glb` file is an external mesh or scene asset, not a USD layer.
USD composition does not parse it. A prim points at the file with a standard
`payload` or `reference` arc, and the render adapter reads that arc from the
composed prim and imports the asset through the glTF loader:

```usda
def Xform "Lander" (
    prepend payload = @twin://rover/models/lander.glb@
)
{
    string lunco:assetMode = "scene"
}
```

The default `lunco:assetMode` is `"scene"`: the whole glTF scene is attached as a
child and keeps its hierarchy, materials, and lights. Set
`lunco:assetMode = "mesh"` to attach one mesh primitive as `Mesh3d`, which is the
form a mesh collider can consume. `lunco:assetLabel` selects the sub-asset label,
for example `"Mesh0/Primitive0"`; an empty label uses the loader's default.

The arc may live in a referenced USD wrapper. The adapter reads it from the
composed prim stack and anchors the URI to the layer that authored it, so
`scene → wrapper.usda → model.glb` renders on the composed prim. A `def Cube`
placeholder with `lunco:placeholder = true` gives external tools a stand-in that
hides once the glTF visual loads.

External USD tools need a glTF `SdfFileFormat` plugin to compose the same arc.
LunCoSim reads the authored arc itself and does not synthesize a USD layer.

## Composition and missing arcs

A missing sublayer, reference, or payload does not discard the siblings that
did resolve. The loader publishes the available stage and records a
scene-scoped warning naming both the referring layer and the dependency.

The `usd.scene_composition` policy decides whether to keep the partial stage or
reject it. The shipped policy allows partial composition. A Twin can require a
complete closure with `reject_scene`.

Other failures remain terminal at their owner: unsafe traversal, permission
errors, malformed required input, and exceeded closure limits are not treated
as missing files. The loader never rewrites a stale URI to a different asset.
Fixing an old reference is an authored migration, not a Windows-path fallback.

## Browser and native

Native readers use the filesystem and registered asset sources. Browser readers
use HTTP or mounted OPFS through the same logical paths. Filename components
are encoded once; `/` separators stay separators, and a literal `%20` is not
the same file as a space.

A browser build has no native file URI support. A `file:` URI is rejected
explicitly rather than being interpreted as a relative path.

## Rules of thumb

- Use `lunco://` for shipped assets and `twin://` for project files.
- Read the Twin authority with `twin_name()`; do not build it from a name.
- Keep relative references inside their root.
- Point at glTF with a payload or reference; USD composition does not parse the
  binary.
- Declare external bytes in `Assets.toml`; do not commit a cache path.
- Treat a missing arc as a visible fact, not as an empty scene.
- Fix a stale address by editing the authored file, not by adding a resolver
  fallback.

Continue with [Authoring](authoring.md), which covers the tools that write
these files.
