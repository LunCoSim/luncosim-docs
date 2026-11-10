---
title: Command line
chapter: 8
section: 1
---

# Command line

The `luncosim` binary can open the desktop app, serve the API headlessly, run a
scene test, validate assets, or connect the Rhai REPL to a running session.

```text
luncosim [FLAGS]
luncosim rhai [--api PORT] [-e SNIPPET | -f FILE]
luncosim test --scene PATH
luncosim --validate PATH…
```

Run `luncosim --help` for the help text of the installed version.

## Startup

| Flag | Meaning |
|---|---|
| `--scene PATH` | Load this USD scene at startup. The path may be relative to `assets/`, to the current directory, or absolute |
| `--api [PORT]` | Serve the HTTP command API on the given port |
| `--no-ui` | Run headless, without a window. Also `LUNCO_NO_UI=1` |
| `--window-pos SPEC` | Place the window: `left`, `right`, `top-left`, `top-right`, `bottom-left`, or `bottom-right`. X11/XWayland only; native Wayland ignores it |
| `--validate PATH…` | Parse-check asset files and exit without opening a window or GPU |

`--no-ui` does **not** imply `--api`. Pass both when a headless run needs the
API:

```bash
luncosim --no-ui --api 4101 --scene scenes/tests/rover.usda
```

Without `--scene`, the app starts with an empty persistent world shell. The
sandbox is an explicit scene or lesson, not an implicit startup default.

## Recording and capture

| Flag | Meaning |
|---|---|
| `--record-offline <dir|out.mp4>` | Record deterministic frames. A directory receives a PNG sequence; a video path streams to ffmpeg |
| `--record-fps N` | Output frame rate; default 60 |
| `--record-preset MODE` | H.264 preset; default `ultrafast` |
| `--record-frames N` | Stop after N frames |
| `--offscreen` | Render windowlessly into an offscreen target and exit when the take drains |
| `--record-size WxH` | Offscreen target resolution; default `1280x720` |

A one-command windowless take:

```bash
luncosim --offscreen --scene scenes/demo.usda \
  --record-offline /tmp/demo.mp4 --record-frames 300
```

Recording is deterministic once the scene is ready. Do not judge render cost
from a recording run; use a separate profiling session.

## Networking

| Flag | Meaning |
|---|---|
| `--host [PORT]` | Host a WebTransport session; default port 5888 |
| `--connect ADDR` | Join a hosted session; a missing port implies port 5888 |
| `--cert PATH` | TLS certificate: a certbot live directory or a certificate file |
| `--key PATH` | TLS private key when `--cert` names a file |

Omit `--cert` and `--key` for a development self-signed certificate. A bare IP
address for `--connect` skips TLS validation for a LAN/development run.

Networking is opt-in at build time. A default local build does not start a
multiplayer host.

## Rendering and performance

| Flag | Meaning |
|---|---|
| `--render-profile MODE` | `standard` preserves authored PBR; `fast` uses unlit, texture-free materials and disables HDR, bloom, and MSAA |
| `--render-quality MODE` | `low`, `balanced`, or `high` graphics budgets |
| `--no-vsync` | Uncap the frame rate |
| `--no-throttle` | Keep running at full rate while unfocused |
| `--headless-max-speed` | With `--no-ui`, advance the fixed simulation lattice as fast as the CPU and causal participants allow |
| `--log-diag` | Log FPS, frame-time, and physics diagnostics |
| `--console` | Windows: enable the debug console for this launch |

`--render-quality` changes GPU budgets; it does not replace the shaders authored
by the scene. When measuring FPS, use `--no-vsync --no-throttle` so you are not
timing the compositor or the unfocused power-save throttle.

## Rhai REPL

Connect to a running instance's API port:

```bash
luncosim rhai --api 4101
luncosim rhai --api 4101 -e 'print(find("Rover"))'
luncosim rhai --api 4101 -f scripts/check.rhai
```

The REPL evaluates against the live app. It is useful for inspection and small
commands; authored tests belong in a scene test.

## Scene tests

```bash
luncosim test --scene assets/scenes/tests/rover_drive.usda
luncosim test --list
```

A scene test runs the authored Rhai test headlessly and deterministically. The
exit code is the verdict:

| Exit | Meaning |
|---|---|
| `0` | PASS |
| `1` | FAIL |
| `2` | No verdict was produced |

| Option | Meaning |
|---|---|
| `--list` | List discovered test scenes and their execution kind |
| `--verdict-channel NAME` | Accept the verdict only from this channel |
| `--verification QUALIFIED_NAME` | Require a Twin manifest SysML verification mapping |
| `--max-ticks N` | Bound cumulative fixed steps; default 20000 |
| `--tick-hz HZ` | Manual update rate; default 60 |
| `--readiness-timeout SECS` | Bound scene and participant preparation; default 420 |
| `--determinism-reference PATH` | Load a typed JSON state reference for Rhai comparisons |
| `--threads N` | Compute-pool width; `1` is the gate profile |
| `--jitter FRAC` / `--seed U64` | Exercise seeded fractional-`dt` pacing |

A component-level suite selects its own scene from the Twin manifest:

```bash
luncosim test-component --twin path/to/twin --component rover.wheels
```

Run the production binary for these checks; do not substitute a private test
harness or `--validate`. `--validate` only proves that the files parse and their
declarations are structurally valid. See
[Validation](validation.md) for the evidence layers.

## Asset validation

```bash
luncosim --validate path/to/model.mo path/to/scene.usda
```

Supported inputs include `.mo`, `.usda`, `.sysml`, `.kerml`, `.wesl`, and
`.rhai`. The command is parse-only: no window, GPU, or app launch. It exits `0`
when every input is valid and `1` when any input fails.

## Related

- [Controls](controls.md) — default input bindings
- [HTTP API](http-api.md) — command and query envelope
- [Install](../general/install.md) — packaged and source builds
