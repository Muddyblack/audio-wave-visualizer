# Windows support

Status: **working, but never run on real Windows.** `windows/app.py` hosts the
same render tree the Plasma widget and Hyprland panel draw, and
`windows/audio_capture.py` replaces cava with WASAPI loopback capture, so the
bars react to whatever is playing. Building, packaging and CI (PyInstaller,
the Inno installer, `windows.yml`/`release.yml`, Scoop/WinGet manifests) were
wired up first and are unchanged.

What has actually been verified, and where:

| | verified | how |
|---|---|---|
| render tree loads outside Quickshell/Plasma | yes | `--selftest`, zero QML warnings, Linux + Windows in CI |
| capture → `frame.ini` → bars move | yes, **on Linux** | `soundcard` against a PulseAudio monitor |
| bottom-of-Z-order pin, tray, DPI scaling | **no** | needs a real machine — CI runners have no desktop |
| WASAPI loopback specifically | **no** | CI runners have no audio device |

So the remaining risk is concentrated in Windows-only behaviour, not in the
visualizer or the capture maths. See "Testing on real Windows" below.

## What "Windows support" means here

Three separable pieces, roughly in build order:

1. **The overlay app** — a desktop-wide, audio-reactive background window
   that sits behind every other window (not just "always on top" — the
   opposite: always on *bottom*, like Wallpaper Engine/Lively Wallpaper),
   plus a system tray icon for show/hide/settings/quit. This is the actual
   feature; everything else is distribution.
2. **Package-manager listings** — Scoop and WinGet manifests, generated from
   a built release the same way `ai-usage-widget/windows/package-manifests.py`
   does. Mechanical once (1) produces a signed-or-not installer and a portable
   ZIP.
3. **Microsoft Store** — needs MSIX packaging and a Partner Center publisher
   identity; see the dedicated section below. Treat as a follow-up, not part
   of the initial port.

## 1. The overlay app

### How it is hosted

`VisualizerCore` and `VisualizerView` already take everything host-specific as
properties, so neither needed changing: `windows/qml/Overlay.qml` supplies a
`configuration`, a `runtimeDirectory` and a `commandSourceComponent`, exactly
as `hyprland/AudioVisualizerShell.qml` does. Only three things differ from the
Hyprland host:

- **Configuration** is parsed by the same `hyprland/Configuration.js` from the
  same `package/contents/config/main.xml`; `app.py` reads both files and
  passes the text in, because Quickshell's `FileView` does not exist here and
  QML's synchronous `XMLHttpRequest` throws `Invalid state` on local files.
  Defaults are the `HostDefaults.hyprland` set — they assume a desktop-wide
  overlay, where the Plasma ones assume a panel applet.
- **`commandSourceComponent` is a no-op.** On Linux it launches `feeder.sh`;
  here `audio_capture.py` is already running, so nothing needs spawning and
  only `frame.ini` matters. It also writes `status.ini`, so the widget's
  backend-health display keeps working.
- **A `QtObject` mirrors the audio settings** (`audioConfig`), because
  `VisualizerCore` watches them with `Connections`, which needs a real QObject
  rather than the merged plain JS configuration object. Same reason the
  Hyprland shell has one.

There is **no settings UI yet** — the tray's *Settings…* is still disabled.
Settings are read from `%APPDATA%\audio-visualizer\settings.json` if it
exists, using the same key names as everywhere else; porting
`studio/Studio.qml` is the next task.

### Why this was harder than the ai-usage-widget Windows port

ai-usage-widget's Windows port reuses the Hyprland panel's QML almost as-is
(`PopupContent.qml`, `SettingsPage.qml`) because that app's Quickshell layer
is thin — a popup shown on click, backed by a stdlib Python provider package.
This project's Hyprland integration (`hyprland/AudioVisualizerShell.qml` and
everything under `package/contents/ui`) is a full always-visible render tree
(shaders, `WaveCanvas`, orbit/backdrop effects, cover art compositing — see
the audio-visualizer-artbg background-compositing notes) driven continuously
by live audio, and it currently assumes Quickshell (`qs`) as its host.
Quickshell does not run on Windows. Both problems this raised are now solved:

- **Hosting** turned out not to need the render tree factored at all. Only
  `main.qml`, `Visualizer.qml` and `configStudio.qml` import `org.kde.*`, and
  none of those are on the overlay's path — everything under
  `package/contents/ui` that the view actually loads is plain QtQuick. A
  `QQuickView` mounts `VisualizerCore` + `VisualizerView` directly.
- **Audio input**: `feeder.sh` shells out to `cava`, which is Linux-only
  (fixed-in input backends, no Windows build). `windows/audio_capture.py`
  replaces it with `soundcard` + numpy: WASAPI loopback of the default output
  device, Hann-windowed rFFT, log-spaced bands between the configured
  cutoffs, cava's autosens (a decaying running peak) and its `noise_reduction`
  integral filter as a per-frame EMA. `soundcard` was picked over
  `pyaudiowpatch` because it also captures PulseAudio monitors on Linux, so
  the same code path is developed and tested without a VM.

### Reader protocol (already fixed by the Linux side, reuse it)

Per the audio-visualizer-perf project memory: the QML side reads
`$RUN/frame.ini` in-process via `Qt.labs.settings`/`QSettings` — a `t=`
timestamp and a quoted `v="b0;b1;...;bN"` line, `protocol=2`. There is no
`XDG_RUNTIME_DIR` on Windows, so `audio_capture.runtime_dir()` publishes into
`%LOCALAPPDATA%\audio-visualizer\` instead. The wire format is unchanged, so
the existing QML reader works as-is; frames are written to a `.tmp` and
`os.replace`d, so a poll can never land on a half-written file.

### Staying behind every window ("always on bottom")

`windows/app.py::_pin_to_bottom` does the simple version: Qt's
`FramelessWindowHint | Tool | WindowStaysOnBottomHint |
WindowDoesNotAcceptFocus` (no taskbar or alt-tab entry, never takes focus),
plus a `SetWindowPos(HWND_BOTTOM)` reasserted on a 2s timer via
`ctypes.windll.user32`, because Windows restacks HWND_BOTTOM windows above
newly created ones.

**This is the least-tested part of the port.** Two things to check first on a
real machine, both of which may force the Wallpaper Engine/Rainmeter/Lively
route instead (reparenting into Progman's hidden `WorkerW`, created by sending
`0x052C` to Progman, which sits behind desktop icons and survives restacking
without polling):

- whether the 2s re-assert is visible as flicker, or loses races against
  newly opened windows;
- whether the overlay swallows clicks meant for the desktop and its icons.
  The widget is interactive on Linux (seek, volume scroll), so it is *not*
  click-through here; if that turns out to be wrong on Windows, add
  `WS_EX_TRANSPARENT` and accept losing those interactions.

### Running it

```powershell
pip install -r windows\requirements.txt
python windows\app.py
```

On Linux, which is where it is developed — `soundcard` captures the
PulseAudio monitor there, so the bars react exactly as they do on Windows:

```bash
nix develop .#windows
python windows/app.py
```

`python windows/app.py --selftest` loads `Overlay.qml` headless and exits 1 on
any QML warning. It deliberately does not import `audio_capture`, so it opens
no audio device and needs neither numpy nor soundcard; CI checks that module
imports separately, on Windows only (importing `soundcard` on Linux needs a
running PulseAudio). The selftest needs `QT_QPA_PLATFORM=offscreen`, which the
script sets itself unless something (a real desktop session, including `nix develop` run
from one — verified while wiring this up: it inherited `QT_QPA_PLATFORM=wayland`
from the host session and the app then aborted with no message trying to use
it headless) has already set the variable. Unset it first if testing locally
from a live Wayland/X11 session and the selftest aborts with no output.

### Building the .exe

On Windows (PyInstaller does not cross-compile):

```powershell
pip install -r windows\build-requirements.txt
pyinstaller --noconfirm windows\audio-visualizer.spec
"dist\Audio Visualizer\Audio Visualizer.exe" --selftest
```

The installer wraps that folder (Inno Setup, `windows/installer.iss`):

```powershell
windows\build-installer.ps1 -Version 0.1.0     # → Audio-Visualizer-Setup-0.1.0.exe
```

Per-user install (no admin rights) to `%LOCALAPPDATA%\Programs\Audio
Visualizer`, Start menu entry, optional desktop shortcut and *Start when I
sign in*, stops a running copy before replacing it, registers an uninstaller.
Keep the installer's `AppId` (`808901FC-...`) as it is — that GUID is also
`PRODUCT_CODE` in `windows/package-manifests.py`; changing one without the
other breaks WinGet's upgrade detection.

CI does all of this on every push and pull request
(`.github/workflows/windows.yml`), and on demand from any branch (*Actions →
Windows → Run workflow*). A tag runs the same workflow from `release.yml`,
which attaches the installer and the zip to the release once they pass —
after the `.plasmoid`, which a failing Windows build does not hold back.

## 2. Package managers (Scoop, WinGet)

`windows/package-manifests.py` is adapted from ai-usage-widget's script of
the same name and generates a Scoop manifest and the three WinGet manifest
files (version/locale/installer) from a built release's ZIP + Inno installer.
It runs automatically for stable (non-prerelease) tags in
`.github/workflows/windows.yml`'s `build` job. To reproduce locally against a
downloaded release's assets:

```powershell
python windows/package-manifests.py --version 0.1.0 --assets . --output dist/package-manifests
```

- **Scoop**: users install via
  `scoop install https://github.com/Muddyblack/audio-wave-visualizer/releases/latest/download/audio-visualizer.json`.
  No bucket published initially — same posture as ai-usage-widget.
- **WinGet**: the generated ZIP contains
  `manifests/m/Muddyblack/AudioVisualizer/<version>/`, testable locally with
  `winget validate`/`winget install --manifest` before ever submitting to
  [microsoft/winget-pkgs](https://github.com/microsoft/winget-pkgs). Generating
  the manifest does not register the app in the public catalog — submitting
  that version folder there is a separate, manual step per release, and
  should wait until the overlay has actually been run on Windows.

## 3. Microsoft Store

Same tradeoff ai-usage-widget documented and deferred, which applies here
too:

- **EXE/installer submission** needs trusted code signing for the installer
  and every bundled PE binary (PyInstaller's Python DLL, Qt DLLs, …), plus
  versioned URLs through Partner Center. No code signing exists for this
  project yet.
- **MSIX** gives Store-managed signing and updates but needs its own
  packaging and Windows testing — particularly here, since the "run behind
  every window" overlay behavior is the kind of thing MSIX's app-container
  sandboxing can interfere with (WorkerW reparenting, global window-position
  hooks) in ways a plain Win32 install doesn't hit. Confirm the overlay still
  achieves bottom-of-Z-order placement under an MSIX package *before*
  committing to Store distribution — this is the biggest unknown in the whole
  Windows plan, more than the audio capture backend.

Treat Store distribution as a separate task once (1) and (2) work and a
Partner Center publisher identity exists. Nothing in this repo depends on it.

## Testing on real Windows

Same constraints as ai-usage-widget: no Docker/distrobox route (Windows
containers need a Windows host; Wine isn't trustworthy for window/tray
behavior). Use a KVM VM — `quickemu`/`quickget windows 11`,
[`dockur/windows`](https://github.com/dockur/windows), or virt-manager if
already set up — and share the checkout in via virtiofs/SMB so editing stays
on Linux. The user has a VM available for this; nothing here has been run on
real Windows yet.

Things that specifically need a real machine, not CI, because no test covers
them yet:

- whether the `HWND_BOTTOM` re-assert keeps the overlay behind the desktop
  *and* behind newly opened windows without visible flicker, and whether it
  swallows desktop clicks (see "Staying behind every window" above);
- whether `soundcard` picks the right WASAPI loopback device when the default
  output changes (headphones plugged in mid-playback), and whether capture
  latency leaves the visualizer feeling responsive — a "does it look right"
  check, not a unit test;
- whether PyInstaller bundles `soundcard`'s cffi backend correctly; the spec
  lists `audio_capture` as a hidden import because `app.py` only imports it
  outside `--selftest`, but the cffi side is untested in a frozen build;
- tray icon behavior at 100/125/150% display scaling, light/dark taskbar;
- multi-monitor: does the overlay span all monitors, one, or need to be
  per-monitor — undecided, needs a call once there's something to look at.
