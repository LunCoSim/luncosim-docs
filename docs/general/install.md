---
title: Installation
chapter: 1
section: 4
---

# Installation

The supported way to use LunCoSim is the packaged desktop application. Build
from source only if you are developing the engine or need the newest
unreleased code. The packaged build includes the application, the installed
asset library, and the updater.

## Download

Get the current installer from the
[LunCoSim releases page](https://github.com/LunCoSim/lunco-sim/releases).

| Platform | Package | Launch |
|---|---|---|
| Windows x86_64 | `LunCoSim-Windows-x86_64-Setup.exe` | Start-menu or desktop shortcut |
| macOS Apple Silicon | `LunCoSim-macOS-Apple-Silicon.pkg` | Installed `LunCoSim.app` |
| macOS Intel | `LunCoSim-macOS-Intel.pkg` | Installed `LunCoSim.app` |
| Linux x86_64 | `LunCoSim-Linux-x86_64.AppImage` | The same AppImage from a writable location |

Do not launch `Setup.exe` again to use the app, and do not launch a copied
`.app` binary or a source-build executable if you want the updater to work. Use
the installed shortcut or the same AppImage you originally placed on disk.

## Windows

Run `LunCoSim-Windows-x86_64-Setup.exe` and follow the installer. Launch
LunCoSim from the Start menu or the desktop shortcut. The installer records the
installation so the built-in updater can replace it later.

If Windows SmartScreen shows a warning for an unsigned development build,
verify the download against the release notes before choosing to run it.

## macOS

Open the `.pkg` and install `LunCoSim.app` where the installer offers. Launch
the installed application from Finder or Launchpad. The installed app bundle is
the update target; running a copy from a disk image or a build directory is not
an installed build.

## Linux

The Linux package is an AppImage. Place it somewhere writable, make it
executable, and run it:

```bash
chmod +x LunCoSim-Linux-x86_64.AppImage
./LunCoSim-Linux-x86_64.AppImage
```

There is no system-wide installation step. Keep the AppImage in a location
where you can replace it, because the built-in updater replaces that file. If
the AppImage fails to start because of a missing FUSE library, install the
distribution's FUSE compatibility package or run the AppImage with the
documented extraction option for your distribution.

## First launch

LunCoSim may check the release feed once at startup. If an update is available,
the status bar shows a clickable notice. Choose **Download update**, then
**Install and restart** when the package is ready.

The application is ready when the main window shows the 3D viewport and the
perspective tabs. The first launch does not automatically load a sandbox; open
a scene or a lesson explicitly. Continue with [First run](first-run.md).

## Build from source

Source builds are for contributors and for running the newest unreleased code.
Packaged users do not need Rust or LLVM.

### Prerequisites

- The Rust toolchain selected by the repository (`rust-toolchain.toml`)
- LLVM/libclang for the FMI import dependency
- The native windowing and audio development libraries used by Bevy

On Debian/Ubuntu, the CI build installs:

```bash
sudo apt-get install -y \
  libasound2-dev libudev-dev \
  libwayland-dev libxkbcommon-dev \
  libx11-dev xorg-dev
```

On macOS, the Xcode Command Line Tools provide libclang. On Windows, install
the MSVC C++ Build Tools and Windows SDK, then install LLVM:

```powershell
winget install --exact --id LLVM.LLVM --architecture x64
```

### Build and run

```bash
git clone https://github.com/LunCoSim/lunco-sim.git
cd lunco-sim
cargo build -p lunco-luncosim --bin luncosim -j 4
target/debug/luncosim --api 4101
```

Run from the repository root so the application can find its bundled assets.
The `--api` flag is optional, but an explicit free port is useful for scripts,
screenshots, and inspection. Do not reuse a port that another LunCoSim session
is already using.

If the build reports `Unable to find libclang`, verify that LLVM contains
`libclang` and that `LIBCLANG_PATH` points to its containing directory if it is
not in the default location.

### Build profiles

A debug build is the normal development build. It keeps development checks and
is slower than a release build. Use a release build when measuring frame time
or running a long experiment; do not compare a debug frame rate with a release
frame rate.

## The updater

Automatic updates only work from a supported installed package:

- the Windows `Setup.exe` installation;
- the installed macOS app;
- the same Linux AppImage you originally launched.

A source build and an ordinary extracted archive correctly report
`NotInstalled`. Reinstall from the current release to restore update support.
Do not move an installed application after the updater has recorded its
location unless you reinstall it.

## Uninstalling

Use the platform's normal uninstall flow for the installed package. Project
folders are not removed by uninstalling the application. User settings and the
asset cache live outside the application directory; remove them separately only
if you intend to reset the application state.

## Related sections

- [First run](first-run.md) — the window, perspectives, and tutorials
- [First mission](../tutorials/first-mission.md) — a five-minute rover exercise
- [Troubleshooting](../reference/troubleshooting.md) — startup and build failures
- [Command line](../reference/cli.md) — startup flags and headless runs
