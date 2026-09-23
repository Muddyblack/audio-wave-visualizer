# Install and use the visualizer

Choose the host you use: [KDE Plasma](#kde-plasma) or [Hyprland / Quickshell](#hyprland--quickshell). Both use the same widget layouts and settings studio.

## Requirements

- `cava` and a running PipeWire or PulseAudio server for audio-reactive visuals.
- Python 3 and `busctl` on Plasma's session `PATH` for browser site names, queue details, and other MPRIS metadata. The Nix flake package supplies these for its metadata helper; manual NixOS installs need `pkgs.python3` and `pkgs.systemd` in `environment.systemPackages`.
- `flock` from util-linux and `pkill` from procps.
- KDE Plasma 6 with `kpackagetool6`, or Quickshell (`qs`) for the Hyprland host.

MPRIS playback information comes from your media player. Audio bars can work even when no player publishes track metadata.

## KDE Plasma

Install from the [KDE Store](https://www.opendesktop.org/p/2359422/) or use this checkout:

```bash
git clone https://github.com/Muddyblack/audio-wave-visualizer.git
cd audio-wave-visualizer
kpackagetool6 -t Plasma/Applet -i package
```

Add **Plasma Audio Visualizer** from Plasma's **Add Widgets** panel. To update or remove a manual install:

```bash
kpackagetool6 -t Plasma/Applet -u package
kpackagetool6 -t Plasma/Applet -r org.muddyblack.plasmaAudioVisualizer
```

Run only the command you need. For a packaged `.plasmoid`, use `make pack`. It writes the archive in the repository root.

### NixOS flake

Add the package and `cava` to your system packages:

```nix
{
  inputs.audio-wave.url = "github:Muddyblack/audio-wave-visualizer";

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
  };
}
```

## Hyprland / Quickshell

Run the desktop widget from this checkout in your Hyprland session:

```bash
make view-hyprland
```

This uses `hyprland/run.sh` when `qs` is on your PATH. Otherwise the Make target uses the Nix flake to supply Quickshell and its dependencies. KDE Plasma is not required. The widget starts below application windows on the first monitor; press **Ctrl+C** in that terminal to stop it.

Right-click the widget to open **Settings**. If the widget is hidden, run:

```bash
make settings-hyprland
```

Choose one monitor or **All displays**, position the widget, then click **Apply**. Preferences are saved in `~/.config/audio-wave-visualizer/hyprland.json` (or under `$XDG_CONFIG_HOME`). All displays share one audio backend. **Pause When Covered** stops rendering a fully covered view and stops capture when all views are covered.

To launch at login, add this to your Hyprland configuration with your checkout's actual path:

```ini
exec-once = bash /absolute/path/to/audio-wave-visualizer/hyprland/run.sh
```

The Hyprland default is 15 Hz. In **Settings → Audio**, choose a lower frame rate for less work or a higher one for smoother motion. The default widget size is 360 × 104; placement and size can also be set in `shell.qml`.

### Declarative defaults

Set `AUDIO_WAVE_DEFAULTS` to a JSON file to provide defaults without changing your Nix files from the GUI. It accepts widget settings plus `monitor`, `widgetWidth`, `widgetHeight`, `verticalPosition`, `desktopLayer`, `pauseWhenCovered`, `waveColor`, and `textColor`.

```nix
home.sessionVariables.AUDIO_WAVE_DEFAULTS = toString (pkgs.writeText "audio-wave-defaults.json"
  (builtins.toJSON {
    monitor = "all";
    sensitivity = 150;
    progressBarStyle = 4;
  }));
```

The widget must inherit that environment variable. GUI changes are stored separately and override those defaults. **Reset to defaults** removes the local overrides.

## Settings and presets

The built-in studio previews changes while you edit. **Apply** or **OK** saves them; **Cancel** discards them. In Quickshell, right-click the widget to open it. In Plasma, open the widget's configuration.

To share a look, choose **Copy as JSON** in **My presets** (or **Copy current as JSON** in the [browser studio](https://muddyblack.github.io/audio-wave-visualizer/)), then use **Import JSON** in the other interface. [Preset sharing](sharing-presets.md) explains the details. See [lyrics setup](lyrics.md) for local files, LRCLIB, translations, and timing.

## Troubleshooting

If track information works but the bars never move, check `cava`: MPRIS metadata and audio capture are separate. Run the diagnostic:

```bash
make doctor
```

For an installed Plasma widget, you can run `bash ~/.local/share/plasma/plasmoids/org.muddyblack.plasmaAudioVisualizer/contents/code/doctor.sh`. It reports your `cava` version, available input backends, sound server status, and a short capture test. Include its output when filing an issue.

| Symptom | Check |
| --- | --- |
| `cava is not installed` | Install `cava` with your distro's package manager. The widget retries automatically. |
| `No usable audio input` | Check whether PipeWire or PulseAudio is running and whether your `cava` build supports it. |
| Bars are flat or quiet | Raise **Sensitivity** or lower **Smoothing** in **Settings → Audio**. |
| Widget is hidden in Hyprland | Run `make settings-hyprland` and check monitor and position settings. |

The Plasma feeder writes `cava.log` under `$XDG_RUNTIME_DIR/audio-wave-widget/`. Quickshell keeps its status and log under `$XDG_RUNTIME_DIR/audio-wave-quickshell/`.
