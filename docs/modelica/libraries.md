---
title: Libraries
chapter: 4
section: 4
---

# Libraries

A Modelica library is a package tree of reusable classes. LunCoSim admits
source roots, resolves qualified names through them, and compiles the reachable
closure. The Package Browser and the compiler read the same source-root
inventory.

Libraries are ordinary `.mo` files with `package.mo` and `package.order`
structure. There is no LunCoSim-specific package format.

## The standard library

The engine ships the Modelica Standard Library (MSL) and the DLR Thermofluid
Stream library as downloadable assets. Their manifest is
`assets/manifests/modelica.toml`:

```toml
[library]
name = "Modelica Standard Library"
version = "4.1.0"
url = "https://github.com/modelica/ModelicaStandardLibrary/archive/refs/tags/v4.1.0.tar.gz"
dest = "library"

[thermofluidstream]
name = "DLR Thermofluid Stream Library"
version = "1.3.0"
url = "https://github.com/DLR-SR/ThermofluidStream/archive/refs/tags/v1.3.0.tar.gz"
dest = "thermofluidstream"
```

The libraries are not downloaded in the background on launch. A missing
library is shown in **Settings → Data & libraries** and starts downloading only
after an explicit request.

A Twin can also use the application's packaged source bundle:

```toml
[modelica]
externals = [
  { name = "BundledModelicaLibraries", path = "@bundled:source-bundle" },
]
```

`@bundled:source-bundle` is owned by the bundled source-library inventory, not
by a Twin folder. It is always available and is admitted lazily on first
compile.

## Source roots

`[modelica].paths` lists Twin-relative search roots:

```toml
[modelica]
paths = ["models", "shared"]
```

A path may be `"."` to make the Twin root a search root. The default is `["."]`.

`[modelica].externals` adds libraries outside the Twin:

```toml
[modelica]
externals = [
  { name = "BundledModelicaLibraries", path = "@bundled:source-bundle" },
  { name = "MyPkg", path = "../shared_library/" },
]
```

Relative paths work for sibling-folder libraries in a monorepo. Absolute paths
are supported but break portability; the editor warns on save. A git URL form
is not part of the current contract.

The authored `twin.lifecycle` policy selects which roots to load. Rust
validates the Twin-scoped path, registers the generic source root, and sends it
through the worker. The worker recursively reads `package.mo` and
`package.order` trees and uses the same input-default normalization as other
disk roots.

## Package structure

A package is a directory with a `package.mo`:

```text
models/
  LunarBase/
    package.mo
    package.order
    Power/
      package.mo
      package.order
      Battery.mo
      SolarArray.mo
```

`package.mo` declares the package:

```modelica
within;
package LunarBase
  annotation(
    Documentation(info = "<html><p>Lunar base subsystems.</p></html>")
  );
end LunarBase;
```

`package.order` lists the classes in display order:

```text
Power
Thermal
Guidance
```

The compiler uses the package hierarchy for qualified lookup. It does not
require a particular folder name to match a class name, but keeping them
aligned makes the source tree readable and makes external tools happier.

## Qualified names and lookup

A class is identified by its qualified name:

```modelica
within LunarBase.Power;

model Battery
  // ...
end Battery;
```

The full name is `LunarBase.Power.Battery`. An import shortens the spelling:

```modelica
within LunarBase;

model Rover
  import Modelica.Blocks.Math;
  Math.Max maxBlock;
end Rover;
```

The compiler resolves the source's qualified roots and seats each known
structured package before the DAE call. Every bundled source library follows
the same admission contract. An unknown or unavailable root is a visible
compile error rather than an implicit retry.

The editor uses the same root-segment rule. A cold qualified class requests its
package root asynchronously; the canvas shows **Loading** and reprojects when
the root is ready.

## What gets compiled

Compilation is closure-based, not folder-based. The compiler parses each unique
URI once and installs the paired source and definition as one batch. The
closure includes:

- the selected class;
- every class it references;
- every package needed to resolve those names;
- the admitted source roots.

A sibling `.mo` file that the selected class does not reference is not part of
the closure. This is why two open documents can coexist without contaminating
each other's compile source set.

Generated network sources consume their complete synthesized document and the
admitted source roots, not other open Modelica documents. Their reserved
`generated/` filename namespace is classified by the runtime metadata owner and
used for structural hashing.

## Browsing and inserting classes

The **Package Browser** is a Dymola-style tree of every admitted library and
package. Clicking a class opens it in the Diagram and Code Editor, which share
one `ModelicaDocument`; an edit in either view updates the other on the next
frame.

The **Component Palette** is a search-first flat list of instantiable leaf
components drawn from the same admitted roots. It filters by display name, full
library path, category, and description. Dragging a row onto the Diagram
instantiates it; insertion is disabled when no writable Modelica document is
active.

A class that is present on disk but not admitted as a source root does not
appear in either browser. Adding the root to `[modelica].paths` or
`[modelica].externals` makes it visible after the Twin is reopened.

## Versioning and reproducibility

A library version is part of the build identity. The compiler's persistent
artifact cache includes the library generation and the exact source content
identity. A compiler upgrade or a changed library cannot admit an artifact from
another build.

For reproducible projects:

- pin downloaded library versions and hashes in the asset manifest or a Twin
  `Assets.toml`;
- keep `package.mo` and `package.order` in version control;
- avoid absolute external paths in a shared Twin;
- record the library version in the Twin's README or manifest description;
- re-run validation after a library upgrade.

A binary asset such as a downloaded library archive is content-hashed. A hash
mismatch rejects the download rather than installing unverified bytes.

## Common failures

| Symptom | Likely cause | Fix |
|---|---|---|
| `Class not found` | Source root not admitted | Add the path to `[modelica].paths` or `externals` |
| `Package not found` | Missing `package.mo` or wrong `within` | Fix the package structure or the `within` clause |
| Duplicate class | Two roots define the same qualified name | Remove one root or rename the package |
| Stale behavior after upgrade | Cached artifact from another build | Recompile; the cache key includes the library generation |
| Library missing at startup | Dataset not downloaded | Open **Settings → Data & libraries** and install it |

A missing library is not silently replaced by a built-in class. The compile
fails with the qualified name it could not resolve.

## Rules of thumb

- Treat `package.mo` and `package.order` as part of the source, not as metadata.
- Pin external libraries by version and hash.
- Keep project packages under the Twin; keep shared libraries outside it.
- Do not rely on an absolute path in a Twin you intend to share.
- Recompile after changing a library; the closure may have changed.
- Read the first compiler diagnostic; later errors are often consequences.

Continue with [Experiments](experiments.md), which run a compiled model many
times over swept parameters.
