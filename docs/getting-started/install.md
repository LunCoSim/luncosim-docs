# Install LunCoSim

The supported way to use LunCoSim is the packaged desktop application. Build
from source only if you are developing the engine.

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
`.app` binary or a source-build executable if you want the updater to work.
Use the installed shortcut or the same AppImage you originally placed on disk.

### Windows

Run `LunCoSim-Windows-x86_64-Setup.exe` and follow the installer. Launch
LunCoSim from the Start menu or the desktop shortcut.

### macOS

Open the `.pkg` and install `LunCoSim.app` where the installer offers. Launch
the installed application from Finder or Launchpad.

### Linux

The Linux package is an AppImage. Place it somewhere writable, make it
executable, and run it:

```bash
chmod +x LunCoSim-Linux-x86_64.AppImage
./LunCoSim-Linux-x86_64.AppImage
```

There is no system-wide installation step. Keep the AppImage in a location
where you can replace it, because the built-in updater replaces that file.

## First launch

LunCoSim may check the release feed once at startup. If an update is available,
the status bar shows a clickable notice. Choose **Download update**, then
**Install and restart** when the package is ready.

The application is ready when the main window shows the 3D viewport and the
perspective tabs. Continue with [First run](first-run.md).

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

## Next

- [First run](first-run.md) — the window, perspectives, and where to click
- [First lesson](first-lesson.md) — a five-minute rover exercise
