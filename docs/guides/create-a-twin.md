# Create a Twin

There are two practical ways to start a project:

- **Promote a working scene.** Open a lesson or example, then save it as a new
  Twin. This is the fastest way to get a real scene with physics, models, and
  scripts.
- **Start empty.** Create a new Twin and add your own scene and sources.

## Promote a scene into a Twin

1. Launch LunCoSim.
2. Open **Tutorials → Sandbox → First Drive** so a working scene is mounted.
3. Choose **File → Save as Twin…**.
4. Select or create an empty folder for the project.
5. Confirm. LunCoSim writes `twin.toml` and opens the new Twin.

The new folder contains the scene document and the manifest. The scene keeps
its normal `lunco://` references to the installed library; it is a project that
uses the shared asset bundle, not a self-contained copy of every referenced
asset.

<figure class="shot">
<a href="../../assets/images/screenshots/perspective-build.webp"><img src="../../assets/images/screenshots/perspective-build.webp" alt="The Build perspective with the Entities panel, the Twin file list, the 3D viewport, the Inspector, and the Spawn palette."></a>
<figcaption>The Build perspective keeps the scene tree, the Twin's files, the Inspector, and the Spawn palette together while the simulation keeps running.</figcaption>
</figure>

## Start from a new Twin

Choose **File → New Twin…**, select a folder, and provide a name. LunCoSim
creates the manifest and opens the project. You can add a scene later.

A minimal manifest looks like this:

```toml
name = "my-rover-twin"
version = "0.1.0"
description = "My first LunCoSim project"

[usd]
default_scene = "scene.usda"
```

The folder should look like:

```text
my-rover-twin/
├── twin.toml
├── scene.usda
├── models/
│   └── Drive.mo
├── scenarios/
│   └── drive.rhai
└── .lunco/
```

`default_scene` is the important line. It tells LunCoSim which USD stage becomes
the active world when the Twin opens. Without it, the Twin opens as a file
browser and does not mount a scene.

## Add behavior

- **Modelica** goes in `.mo` files under the Twin, then a USD
  `LunCoProgramAPI` prim points at it with `info:sourceAsset`.
- **Rhai** goes in `.rhai` files under the Twin, then a `LunCoProgramAPI` prim
  points at the scenario.
- **External assets** go in `Assets.toml`, never as hardcoded cache paths.

The next guide builds a scenario:

[Write a Rhai scenario](write-a-scenario.md)

## Run it

Open the Twin and choose its default scene, or load the scene directly:

```bash
luncosim --api 4101 --scene /path/to/my-rover-twin/scene.usda
```

Use an explicit free API port. Run from the folder containing the Twin if you
are using a source build and relative asset paths.

## Check the manifest

If the Twin does not open the scene you expect:

1. Confirm `default_scene` is a path relative to the Twin root.
2. Confirm the file exists and is a valid `.usda`.
3. Reopen the Twin after editing the manifest; the manifest is read at open.
4. Check that unknown fields are not present — the manifest parser rejects typos.

See [twin.toml](../concepts/twin-toml.md) for the field reference.
