<p align="center">
  <img src="./package/icon.png" width="180" alt="Plasma Audio Wave Visualizer Logo">
</p>

<h1 align="center">Plasma Audio Wave Visualizer</h1>

<p align="center">
  <a href="https://www.opendesktop.org/p/2359422/">
    <img src="https://img.shields.io/badge/KDE_Store-Download-1d99f3?style=for-the-badge&logo=kde&logoColor=white" alt="KDE Store Download" />
  </a>
  <img src="https://img.shields.io/badge/KDE_Plasma-6.0%2B-1d99f3?style=for-the-badge&logo=kde&logoColor=white" alt="KDE Plasma 6.0+" />
  <img src="https://img.shields.io/badge/License-GPL--3.0-blue?style=for-the-badge" alt="License: GPL-3.0" />
  <a href="https://www.opendesktop.org/p/2359422/">
    <img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.pling.com%2Focs%2Fv1%2Fcontent%2Fdata%3Fsearch%3Daudio%2Bwave%2Bvisualizer%26format%3Djson&query=%24.data%5B0%5D.downloads&label=Downloads&style=for-the-badge&color=1d99f3&logo=kde&logoColor=white" alt="KDE Store Downloads" />
  </a>
  <a href="https://github.com/Muddyblack/kde-audio-visualizer/releases">
    <img src="https://img.shields.io/github/downloads/Muddyblack/kde-audio-visualizer/total?style=for-the-badge&logo=github&logoColor=white&label=GitHub%20Downloads&color=blue" alt="GitHub Downloads" />
  </a>
</p>

<p align="center">
  <img src="./readme/demo.svg?v=1.1.3" alt="Widget demo" width="680"/>
</p>

<p align="center">
  <a href="#features">Features</a> ·
  <a href="#gallery">Gallery</a> ·
  <a href="#requirements">Requirements</a> ·
  <a href="#install">Install</a> ·
  <a href="#configuration">Configuration</a> ·
  <a href="#how-it-works">How it works</a>
</p>

---

A glassy audio visualizer plasmoid for KDE Plasma 6. Renders a mirrored waveform that reacts to whatever is playing system-wide (via [cava]), alongside MPRIS track metadata, album art, transport controls, and a seekable progress bar.

<p align="center">
  <img src="./readme/preview.png" alt="Preview" width="680"/>
</p>

## Features

- **6 visualizer styles** — Smooth Wave, Rounded Bars, Mirror Bars, Tech Line, Floating Dots, Floating Dots Bold
- **5 progress bar styles** — Glassy Sleek, Ultra Minimal, Glowing Pulse, Bold Pill, Waveform
- System-wide reactive waveform (PipeWire via cava — not tied to any single player)
- Smooth frame interpolation so the waveform glides instead of snapping
- MPRIS2 track info: title, artist, album art
- Transport controls (prev / play-pause / next) with customizable color
- Seekable progress bar with elapsed/total time
- Honors the active Plasma accent color (or set a custom color)
- Optional waveform fill + neon glow effect
- **Album art as background** — use the current cover as a blurred backdrop with independent Blur and Darkness sliders; the redundant thumbnail hides automatically
- Optional background card with configurable color, opacity (via alpha), and corner radius
- Custom text and controls colors
- Customizable dock background color (supports alpha via color picker)
- No panel background — sits cleanly on any panel

## Gallery

<details open>
  <summary><b>Smooth Wave / Lines</b></summary>
  <br/>
  <img src="./readme/lines.png" alt="Line-style visualizer" width="680"/>
</details>

<details>
  <summary><b>Bars</b></summary>
  <br/>
  <img src="./readme/bars.png" alt="Bar-style visualizer" width="680"/>
</details>

<details>
  <summary><b>Dotted</b></summary>
  <br/>
  <img src="./readme/dotted.png" alt="Floating-dots visualizer" width="680"/>
</details>

<details>
  <summary><b>Album art as background</b></summary>
  <br/>
  Turn the current track's cover into a blurred backdrop. The album-art thumbnail
  hides automatically (it'd be redundant), and the <b>Blur</b> and <b>Darkness</b>
  sliders dial the look from a crisp bold cover to a subtle frosted tint — all
  while keeping the waveform and text readable.
  <br/><br/>
  <img src="./readme/art_as_background.png" alt="Album art as background" width="680"/>
</details>

<details>
  <summary><b>Settings</b></summary>
  <br/>
  <img src="./readme/settings.png" alt="Configuration dialog" width="680"/>
</details>

## Requirements

- KDE Plasma **6.0+**
- [`cava`][cava] — the audio bar generator
- A running PipeWire or PulseAudio server (the widget auto-detects which one cava can capture from)
- `flock` (from `util-linux`) and `pkill` (from `procps`) — standard on virtually every Linux distro

[cava]: https://github.com/karlstav/cava

## Install

### Hyprland / Caelestia (Quickshell)

Run the standalone desktop widget alongside Caelestia. Both frontends render
the same `VisualizerView.qml`: the original Plasma layout, glass transport dock,
album-art background effects, six waveform styles, and five seekbar styles.
Requires `qs` (Quickshell), `cava`,
and the shell utilities listed above; KDE Plasma is not required.

From this repository, in your Hyprland session:

```bash
make view-hyprland
# equivalent:
bash hyprland/run.sh
```

On NixOS, if `qs` is not on PATH, the Make target uses `nix run .#view-hyprland`
to supply Quickshell, cava, and the helper utilities automatically.

Play audio and show your desktop: the transparent visualizer appears centered
60% down the first monitor, below application windows. Stop with **Ctrl+C**.
Caelestia can keep running. The launcher opens the root `shell.qml`, prevents
duplicate instances, and stops its audio helpers when you exit.
The launcher selects Qt's generic platform theme and Basic controls for this
process only. This prevents an inherited KDE/Breeze theme from loading Kirigami
through tooltips; the shared custom-drawn widget layout is unaffected.

**Right-click the visualizer to open Settings.** Choose a monitor or **All displays**,
adjust position, size, audio, colors and appearance, then click **Apply**.
All displays share one audio capture and processing backend; each draws its own view.
The Hyprland default is **15 Hz** to reduce GPU/compositor work across displays.
In Settings → Audio, lower **Framerate** to **5 Hz** for less power use, or raise
it for smoother motion. Explicit saved/declarative frame rates override this
default. The layout, colors and drawing code are shared with Plasma.
**Pause When Covered** is enabled by default: each fully covered view stops
rendering, and covering all views also stops audio capture. Uncovering a view
resumes it; window drags are checked once per second. Coverage uses window
bounds, so disable this option if you want the widget visible through translucent
windows. It applies only when the widget is below application windows.
Preferences are saved to `~/.config/audio-wave-visualizer/hyprland.json`
(or under `$XDG_CONFIG_HOME`). No Nix setup is needed.

If the widget is hidden, open Settings from a terminal with:

```bash
make settings-hyprland
```

You can also edit `shell.qml` to set defaults for width, vertical position, monitor name, color,
wave style, background, or media controls; Quickshell reloads automatically.
Set `desktopLayer: false` to show it above application windows while testing.
For audio tuning, add e.g. `audio.sensitivity: 150` or `audio.inputMethod: "pulse"`
inside `AudioVisualizerShell { ... }`. Appearance defaults come directly from
Plasma's `package/contents/config/main.xml`. Override any of them with `settings`,
using the same property names, for example:

```qml
settings: ({
    alwaysVisible: true,
    showBg: true,
    artBg: true,
    progressBarStyle: 4
})
```

The default size is Plasma's 360 × 104; change `widgetWidth` / `widgetHeight`
as needed. Matching size, settings, colors, font and icon theme gives the same
appearance. Plasma supplies its theme through Kirigami; Quickshell uses the
configured colors and the session's font/icon theme, without requiring Kirigami.
The Plasma configuration dialog remains specific to Plasma.

For declarative defaults, set `AUDIO_WAVE_DEFAULTS` to a JSON file with the same
keys as the settings above, plus `monitor` (`"all"`, `""`, or an output name),
`widgetWidth`, `widgetHeight`, `verticalPosition`, `desktopLayer`, `pauseWhenCovered`, `waveColor`,
and `textColor`. For example, in Home Manager:

```nix
home.sessionVariables.AUDIO_WAVE_DEFAULTS = toString (pkgs.writeText "audio-wave-defaults.json"
  (builtins.toJSON {
    monitor = "all";
    sensitivity = 150;
    progressBarStyle = 4;
  }));
```

The running widget must inherit that environment variable. GUI changes override
these defaults in the separate writable preferences file; they never rewrite
your Nix files. **Reset to defaults** removes local overrides and restores the
current declarative defaults (or `shell.qml`/Plasma defaults when none are supplied).

To start at login, add this to your Hyprland configuration (use your actual path):

```ini
exec-once = bash /absolute/path/to/plasma-audio-visualizer/hyprland/run.sh
```

The Quickshell backend keeps its status and `cava.log` under
`$XDG_RUNTIME_DIR/audio-wave-quickshell/`, separately from Plasma's backend.
Its process adapter uses [Quickshell Process](https://quickshell.org/docs/v0.2.0/types/Quickshell.Io/Process/)
and its controls use [Quickshell MPRIS](https://quickshell.org/docs/v0.2.0/types/Quickshell.Services.Mpris/MprisPlayer/).
Headless adapter regression test: `python3 tests/test_quickshell.py` with `qs` on PATH.
Settings UI/persistence test: `python3 tests/test_hyprland_settings.py`.
Ctrl+C/duplicate-launch test: `python3 tests/test_lifecycle_power.py`.

The shared waveform uses one GPU glow effect instead of blurring each bar on
the CPU. Progress decorations follow audio updates instead of running a separate
continuous animation. Software rendering omits the unsupported GPU glow.
For a repeatable CPU comparison against a saved older package, run
`python3 tests/benchmark_rendering.py --baseline /path/to/older/package`.
`python3 tests/benchmark_frames.py` measures the current view's frame submissions.
These offscreen benchmarks measure CPU drawing and frame submissions, not GPU
cost or system power; compare actual watts in your desktop session.
`python3 tests/measure_power.py` reads live package power, GPU clocks and capture
status without root. Compare the same music and visible displays, with other
work kept steady. Hardware domains overlap, so their watt readings must not be
added together. Turning off waveform glow alone does not necessarily reduce
compositor power; update rate and the number of visible displays matter too.
For a renderer investigation, stop the preview and start it with
`QSG_INFO=1 make view-hyprland`. Qt records its actual graphics backend and
render-loop startup details in that instance's Quickshell log.

### KDE Plasma

<details open>
  <summary><b>Manual (any distro)</b></summary>

```bash
git clone https://github.com/muddyblack/plasma-audio-visualizer.git
cd plasma-audio-visualizer
kpackagetool6 -t Plasma/Applet -i package
# or, to update an existing install:
kpackagetool6 -t Plasma/Applet -u package
```

Then add the widget from Plasma's **Add Widgets** panel.

To remove:

```bash
kpackagetool6 -t Plasma/Applet -r org.muddyblack.plasmaAudioVisualizer
```

</details>

<details>
  <summary><b>NixOS (flake)</b></summary>

```nix
# flake.nix
{
  inputs.audio-wave.url = "github:muddyblack/plasma-audio-visualizer";

  outputs = { self, nixpkgs, audio-wave, ... }: {
    nixosConfigurations.mybox = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            audio-wave.packages.${pkgs.system}.default
            pkgs.cava
          ];
        })
      ];
    };
  }
}
```

</details>

<details>
  <summary><b>Package as <code>.plasmoid</code> (for the KDE Store)</b></summary>

```bash
./pack.sh
# produces plasma-audio-visualizer-<version>.plasmoid
```

</details>

## Configuration

All settings are available via the widget's right-click → Configure menu:

| Setting | Description |
|---|---|
| **Visualizer Style** | Smooth Wave / Rounded Bars / Mirror Bars / Tech Line / Floating Dots / Floating Dots Bold |
| **Progress Bar Style** | Glassy Sleek / Ultra Minimal / Glowing Pulse / Bold Pill / Waveform |
| **Number of Bars** | How many frequency bars cava outputs (8–128) |
| **Framerate** | Target refresh rate in Hz |
| **Sensitivity** | Cava amplitude multiplier |
| **Smoothing** | Noise reduction factor (0–1) |
| **Audio Input** | Auto-detect, or pin cava to PipeWire / PulseAudio / ALSA |
| **Wave Color** | System accent or custom color |
| **Wave Glow** | Neon glow shadow on the waveform |
| **Fill Wave** | Transparent gradient fill under the waveform |
| **Line Width** | Stroke width for line-based visualizers |
| **Text / Controls / Dock Colors** | Each independently customizable |
| **Background Card** | Optional frosted card with custom color+alpha and corner radius |
| **Art Background** | Use the album cover as a blurred card background |
| **Art Blur / Art Darkness** | Independent sliders to tune how blurred and how dark the art background is |
| **Show MPRIS info** | Toggle album art, track title, artist, and controls |

## Troubleshooting

**The bars never move (track info and controls work fine).**

The waveform comes from `cava`, which is a separate process from the MPRIS metadata — so
playback info can be perfect while audio capture is dead. The widget tells you which it is:
if the backend is down it prints the reason where the wave would be, with the command to fix
it underneath (`sudo apt install cava`, `sudo pacman -S cava`, … depending on your distro).
Hover the message for the full explanation.

Run the built-in diagnostic and paste its output into an issue:

```bash
bash ~/.local/share/plasma/plasmoids/org.muddyblack.plasmaAudioVisualizer/contents/code/doctor.sh
```

It reports your cava version, which input backends your cava was *built* with (distros
differ — a cava without PipeWire support cannot capture on a PipeWire system), whether
PipeWire/PulseAudio are running, and a live 2-second capture test per backend.

Common causes:

| Symptom | Fix |
|---|---|
| `cava is not installed` | The widget prints the install command for your package manager underneath. It retries every 30s, so no Plasma restart is needed unless your package manager only updates `PATH` for new sessions |
| `No usable audio input` | Check the doctor output — usually no sound server is reachable, or cava was built without the backend you need |
| Bars only move for one app | Nothing to fix: cava captures the default sink's monitor, so it follows system output |
| Everything works but bars are flat and quiet | Raise **Sensitivity** or lower **Smoothing** in the widget settings |

The feeder keeps a log of cava's own messages at `$XDG_RUNTIME_DIR/audio-wave-widget/cava.log`
and its current state in `.../status`.

## How it works

For a detailed explanation of the architecture and data flow, see the [Architecture Documentation](docs/workflow.md).

In short: a small shell helper (`feeder.sh`) runs `cava` in the background and writes each changed frame to `$XDG_RUNTIME_DIR/audio-wave-widget/`. The QML side reads it in-process at the configured frame rate, drops to 2 FPS after a few seconds of silence, and stops polling while the widget is hidden.

The waveform is drawn by a single fragment shader (`package/contents/shaders/visualizer.frag`), so a frame costs no CPU rasterisation; software-rendered sessions fall back to the Canvas renderer. After editing the shader, run `make shaders`.

Regression tests (synthetic audio, no desktop or sound server needed): `nix develop --command python3 tests/run.py`.
