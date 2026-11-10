---
title: Troubleshooting
chapter: 8
section: 9
---

# Troubleshooting

Start with the visible owner: the status bar, the lesson card, the readiness
endpoint, or the terminal that launched the app. A log line is evidence only
when it names the same failure.

## The app does not start

**`--api` port is already in use**

Choose a different free port:

```bash
luncosim --api 4102
```

Do not reuse a port owned by another LunCoSim session. Stop only your own
session through its API, then relaunch.

**The window does not appear**

Check that the machine has a working display and GPU driver. For a headless or
remote run, use the documented headless/recording options rather than expecting
a window.

**A source build fails on `libclang`**

Install LLVM. On Windows:

```powershell
winget install --exact --id LLVM.LLVM --architecture x64
```

On Debian/Ubuntu, install `libclang-dev` or the matching LLVM package. If
`libclang` is not in a default location, set `LIBCLANG_PATH` to the directory
that contains it.

**Linux build fails on a missing system library**

Install the windowing and audio development headers:

```bash
sudo apt-get install -y \
  libasound2-dev libudev-dev \
  libwayland-dev libxkbcommon-dev \
  libx11-dev xorg-dev
```

## The scene is empty or the Twin opens as files

A Twin only mounts a scene when `twin.toml` declares it:

```toml
[usd]
default_scene = "scene.usda"
```

The path is relative to the Twin root. If it is missing or wrong, the Twin opens
as a file browser. Check that the file exists and that the manifest has no
unknown-field typo; the parser rejects unknown fields.

If the scene loads but the ground is missing, a terrain asset is probably not
installed. See **Assets** below.

## The vehicle ignores input

1. Click **Take control** or use `possess`. Selection is not control.
2. Confirm the vehicle is not held by another session or producer.
3. Check that the input binding is actually mapped. The lesson hint resolves the
   current binding; a label of **unbound** means the action has no key.
4. If a script holds the vehicle, release that claim before taking manual
   control.

## An asset is missing

LunCoSim does not download external data silently at launch. When a declared
asset is missing:

1. Open **Settings → Data & libraries** or the Twin's assets view.
2. Confirm the entry exists in `Assets.toml` with a valid `url` and `dest`.
3. Start the download explicitly and watch its status.
4. If a hash is declared, a mismatch rejects the download. Remove the bad cache
   artifact only after confirming the source, then retry.

The cache lives at:

| Platform | Path |
|---|---|
| Linux | `~/.cache/lunco/` |
| macOS | `~/Library/Caches/lunco/` |
| Windows | `%LOCALAPPDATA%\lunco\` |

Set `LUNCOSIM_CACHE` to use a different root. Do not hardcode a cache path in a
USD file; use `lunco://` or `twin://` addresses instead.

## The rover does not move

Check the whole chain, not just the script:

1. Does the scenario attach to the entity that should act?
2. Does the drive model compile and report a running participant?
3. Does the component declare the `outputs:` port that the connection targets?
4. Is the target input actually wired to a source?
5. Is a higher-priority control hold keeping the input at another value?

A missing port is not a zero. Inspect it with `ListPorts` and the wiring
diagnostics rather than assuming a default.

## Modelica does not run

- Check that the `.mo` file parses and compiles in the **Lunica** perspective.
- Confirm the Twin's `[modelica].paths` includes the model's root.
- Confirm the USD program prim names the exact source asset.
- Check that required external libraries are installed and declared.
- Read the participant status and cosim diagnostics; a model that stopped is not
  a model that is still advancing.

## Telemetry shows no value

- Wait for readiness; a port can be absent while its model is compiling.
- Run `ListPorts` before `ReadPorts`; reads require explicit port names.
- For solver state, use `SnapshotVariables`, not only the port surface.
- If a value was valid earlier and then vanished, check whether the owning
  entity or scene was replaced.

## The API rejects a request

- Read the error. Unknown fields and malformed nested values are rejected, not
  ignored.
- Confirm the command name with `GET /api/commands/schema`.
- Confirm IDs are the stable `api_id`, not a display name or a local index.
- For a multi-target write, fix the whole batch; a rejection means no partial
  writes were admitted.
- Do not retry a rejected input with the same value and expect a different
  result.

## The updater says `NotInstalled`

Automatic updates only work from a supported installed package:

- the Windows Setup.exe installation
- the installed macOS app
- the same Linux AppImage you originally launched

A source build and an ordinary extracted archive correctly report
`NotInstalled`. Reinstall from the current release to restore update support.

## What to include in a report

Include:

- the LunCoSim version and platform
- whether it is a packaged build or a source build
- the exact scene or Twin path
- the exact command or input that failed
- the readiness/diagnostic response
- a screenshot when the failure is visual
- the first error, not only the last log line

Never include secrets, tokens, or private asset URLs in a public report.
