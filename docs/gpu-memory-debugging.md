# Narrowing down plasmashell memory growth (issue #10)

Use this when `plasmashell` memory keeps growing while the visualizer animates
(media playing, or the settings window open). The widget can switch off each of
its GPU paths on its own, so a few short runs show which one the growth follows.

The switches do nothing unless `AWV_GPU_DEBUG` is set in plasmashell's
environment. They have no settings UI and change nothing in your configuration.

| `AWV_GPU_DEBUG` | What it turns off | What you see instead |
| --- | --- | --- |
| `layers` | every `layer.effect` and visible `MultiEffect` (waveform glow, card background blur, cover masking, dock and progress shadows, karaoke fill, title fade, settings wallpaper cache) | the software-renderer fallbacks: no glow or shadows, the cover painted on the CPU |
| `sources` | every `ShaderEffectSource` (glass/liquid card backdrop blur, cover reflection) | no glass blur, no reflection |
| `shaders` | the WaveShader and OrbitShader `ShaderEffect`s | the Canvas renderer (the same one *Simple render* uses) |
| `all` | all three of the above | |

Values can be combined, e.g. `AWV_GPU_DEBUG=layers,sources`.

## 1. A memory logger

Run this in a terminal. It prints plasmashell's resident memory (in MB) every 5 s
for 3 minutes:

```sh
awv_rss() { pid=$(pgrep -xo plasmashell); for i in $(seq 36); do echo "$(date +%T) $(( $(awk '/VmRSS/{print $2}' /proc/$pid/status) / 1024 )) MB"; sleep 5; done; }
```

## 2. Start plasmashell with a switch

Plasma 6 runs plasmashell as a systemd user service, so set the variable there
and restart the shell (your windows stay open):

```sh
systemctl --user set-environment AWV_GPU_DEBUG=all
systemctl --user restart plasma-plasmashell
journalctl --user -b | grep AWV_GPU_DEBUG | tail -2   # confirms the switch took effect
```

The journal line reads
`audio-wave-visualizer: AWV_GPU_DEBUG layers=true sources=true shaders=true`.
It shows up once for the widget and again when the settings window opens. If it
is missing, the variable did not reach plasmashell.

Then reproduce the growth exactly as before (play media, or open the settings
window) and run `awv_rss`.

To go back to normal:

```sh
systemctl --user unset-environment AWV_GPU_DEBUG
systemctl --user restart plasma-plasmashell
```

## 3. Runs to do (about 3 minutes each)

1. No switch: confirm the growth still happens.
2. `AWV_GPU_DEBUG=all`
3. `AWV_GPU_DEBUG=layers`
4. `AWV_GPU_DEBUG=sources`
5. `AWV_GPU_DEBUG=shaders`
6. No `AWV_GPU_DEBUG`, but Qt's Vulkan renderer:
   `systemctl --user set-environment QSG_RHI_BACKEND=vulkan`, restart as above,
   and `systemctl --user unset-environment QSG_RHI_BACKEND` afterwards.

## 4. Reading the results

- **Still grows with `all`.** The widget's own GPU effects are not what is
  growing. Suspect the driver's per-frame presentation path, or a Plasma/Qt
  issue that any animating widget would trigger. Run 6 helps tell those apart.
- **Flat with `all`, and exactly one of `layers` / `sources` / `shaders` also
  flat.** That path is the cause. Report which one.
- **Flat with `all`, but still grows with each single switch.** Two paths leak
  on their own. Try pairs (`layers,sources`, `layers,shaders`,
  `sources,shaders`) and report which pair stays flat.
- **Run 6 flat while run 1 grows.** The growth is in the OpenGL driver path.
  That is worth reporting to the driver vendor, and `QSG_RHI_BACKEND=vulkan`
  works around it in the meantime.

Please include your GPU, driver version, Plasma and Qt versions, and the six
`awv_rss` outputs in the issue.
