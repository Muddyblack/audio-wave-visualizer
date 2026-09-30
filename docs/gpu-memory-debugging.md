# Debugging plasmashell memory growth

If `plasmashell` memory grows while the visualizer animates, find out which
GPU path it follows.

## Quick test

```sh
bash tools/awv-ab.sh
```

It restarts plasmashell (your windows stay open) once per run below. Each time,
open the widget's settings window, press Enter, wait 20 seconds, close it and
press Enter again. The results end up in `~/awv-ab.txt`, together with the
Plasma, Qt and NVIDIA driver versions. `AWV_AB_SECONDS=60 bash tools/awv-ab.sh`
measures longer.

| Run | Turns off | Instead you see |
| --- | --- | --- |
| `baseline` | nothing | |
| `all` | all three below | |
| `layers` | every `layer.effect` and visible `MultiEffect` | software fallbacks: no glow or shadows |
| `sources` | every `ShaderEffectSource` (glass blur, cover reflection) | no glass blur, no reflection |
| `shaders` | the WaveShader / OrbitShader `ShaderEffect`s | Canvas, as with *Simple render* |
| `vulkan` | nothing, but Qt renders with Vulkan instead of OpenGL | |

Reading it: if a run stays flat while `baseline` grows, that path is the cause.
If only `vulkan` is flat, suspect the OpenGL driver. If everything grows,
suspect something outside the widget's effects.

## The switches by hand

The runs set `AWV_GPU_DEBUG` (`layers`, `sources`, `shaders`, `all`, or a list
like `layers,sources`) in plasmashell's environment. Unset, it changes nothing.

```sh
systemctl --user set-environment AWV_GPU_DEBUG=shaders
systemctl --user restart plasma-plasmashell
journalctl --user -b | grep AWV_GPU_DEBUG | tail -1   # confirms it took effect
# undo:
systemctl --user unset-environment AWV_GPU_DEBUG
systemctl --user restart plasma-plasmashell
```

A longer memory log, every 5 s:

```sh
pid=$(pgrep -xo plasmashell); while sleep 5; do echo "$(date +%T) $(( $(awk '/VmRSS/{print $2}' /proc/$pid/status) / 1024 )) MB"; done
```

## Past case: issue #10

On NVIDIA, plasmashell grew about 6.5 GB in 20 s with `baseline`, but stayed
flat with `shaders` and with `vulkan`. The shader packages contained invalid
GLSL 120 / ES 100 code (integer `min()`/`max()`/`clamp()`); the driver rejected
it and Qt retried every frame. `build_shaders.py --check` (part of `make test`)
now compiles every GLSL variant with glslangValidator, so this should not come
back unnoticed.
