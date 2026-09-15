# Widget Workflow & Architecture

## Component Overview

The widget is split into three main layers: the **QML Frontend**, the **IPC Layer**, and the **Audio Backend**.

```mermaid
graph TD
    subgraph "Frontend (QML)"
        main[main.qml - UI & Logic]
        vis[Visualizer.qml - Data Handler]
        canvas[Waveform.qml - GPU shader, Canvas fallback]
        clock[PlaybackClock.qml - Progress Prediction]
    end

    subgraph "IPC (Filesystem)"
        bars_file["$RUN/bars and $RUN/frame.ini"]
    end

    subgraph "Backend (Bash + CAVA)"
        feeder[feeder.sh]
        cava[CAVA - Audio Processor]
        publisher[publish.awk - Frame Publisher]
    end

    main --> vis
    main --> clock
    vis --> canvas
    vis -- spawns --> feeder
    feeder --> cava
    cava --> publisher
    publisher -- writes to --> bars_file
    vis -- reads from --> bars_file
```

## Data Flow

The following sequence diagram shows how audio data moves from the system to your screen in real-time.

```mermaid
sequenceDiagram
    participant OS as System Audio (Pulse/Pipewire)
    participant CAVA as CAVA (via feeder.sh)
    participant FS as Runtime Directory
    participant QML as Visualizer.qml
    participant Canvas as Waveform.qml

    Note over QML, CAVA: 1. Initialization
    QML->>CAVA: Spawns feeder.sh (30s heartbeat, flock prevents duplicates)
    CAVA->>CAVA: Opens lock file & starts CAVA

    Note over OS, Canvas: 2. Real-time Processing Loop
    loop Continuous
        OS->>CAVA: Raw Audio Stream
        CAVA->>CAVA: FFT & Bar calculation
        CAVA->>FS: Writes changed frames to $RUN/bars and $RUN/frame.ini; unchanged frames refresh the timestamp once per second
    end

    loop Configured frame rate while visible, 2 FPS after 3s of silence
        QML->>FS: Reads $RUN/frame.ini in-process (QSettings, no process per frame)
        FS-->>QML: Quoted string of bar values
        QML->>QML: Parses and smooths toward the new frame
        QML->>Canvas: Triggers onBarsChanged only when bar values change
        Canvas->>Canvas: Uploads levels to the shader (Canvas fallback repaints)
    end
```

## Detailed Process breakdown

### 1. The Feeder (`feeder.sh`)
The feeder script acts as a bridge. It uses `cava` to process system audio and outputs raw data. It ensures only one instance of CAVA is running by using `flock`. `$RUN` is `${XDG_RUNTIME_DIR:-/tmp}/audio-wave-widget`.

`bars` keeps its original semicolon format for installed widgets. `frame.ini` holds
`t=<Unix time in seconds>`, `v="<semicolon-separated bars>"` and `protocol=2` for
in-process QSettings reads; quoting keeps the payload a single string. Older
comma-separated INI frames are still accepted. Changed frames are written
immediately; identical frames leave `bars` untouched and refresh `frame.ini` once per
second, so the reader can tell a quiet feeder from a dead one. If the INI file is
missing or its timestamp is at least two seconds old, the reader falls back to the
original `bars` file. This lets old and new widgets share a feeder without forcing a
restart on startup.

Bash handles the first frame (probing and status), then hands the rest of cava's
stream to `publish.awk`: Bash's `read` costs a syscall per byte on a pipe, awk reads
in blocks. Only an awk with `systime()` is used, and mawk, the default on
Debian/Ubuntu, runs with `-W interactive`, because otherwise it waits for a full read
buffer before handling a line. Without a usable awk (e.g. one-true-awk) the Bash loop
keeps publishing.

It also **probes input backends**. cava is compiled with a fixed set of them and distros do
not agree on which ones, so a hardcoded `method = pipewire` silently produces nothing on a
build without PipeWire support, or on a machine where the sound server is not reachable.
With the input method left on `auto` the feeder tries `pipewire`, `pulse`, then `alsa`, and
keeps the first one that emits a frame within `PROBE_TIMEOUT` seconds (cava emits frames
continuously even in silence, so "no output at all" is a reliable failure signal). The
winner is cached in `$RUN/input-method` so restarts skip the probe.

Status and diagnostics files make failures visible:

| File | Contents |
|---|---|
| `$RUN/status` | `ok <method>`, `probing <method>`, or `error <code> [detail]` |
| `$RUN/status.ini` | The same line as a quoted `v` value, for in-process reads |
| `$RUN/publisher` | Which reader publishes frames: `awk`, `awk -W interactive`, or `bash` |
| `$RUN/cava.log` | stderr of cava and the publisher, for when capture fails |

Error codes: `no-cava` (binary missing), `no-backend` (every candidate failed),
`cava-exited` (a working backend died — usually transient).

`no-cava` carries a third token naming the detected package manager (`apt-get`, `pacman`,
`nix-env`, …) so the widget can print the exact install command rather than "install cava".
Detection is by binary presence, not the `/etc/os-release` ID: derivatives keep their
parent's package manager but change the ID.

### 2. The Data Handler (`Visualizer.qml`)
This component is responsible for:
- Starting the feeder script.
- Reading frames while the widget is shown; `main.qml` deactivates it while the widget
  is hidden (no player and "always visible" off).
- Following actual audio independently of MPRIS playback state. Capture stays
  available so audio from apps without media controls can wake the wave.
- Polling at 2 FPS after sustained silence or missing data, and snapping settled
  values to their target; repeated settled frames do not emit `barsChanged` or repaint
  the canvas.
- Reading status every 4s and exposing `backendFailed` / `backendMessage` /
  `backendHint`, which `main.qml` renders in place of the waveform. A `cava-exited` state
  triggers an immediate respawn (the `flock` makes a redundant spawn a no-op) and is only
  reported to the user if it persists for ~12s. While protocol-2 frames are fresh, status
  comes from `status.ini` in-process; otherwise from `status` via `cat`. Frame polling
  pauses while the backend has failed, and the status checks keep running to recover.
- Respawning the feeder every 30s unless fresh frames show it is alive.
- Restarting the feeder when settings change, once per burst of changes (100ms): it
  stops the feeder by the PID in `$RUN/feeder.pid` (and cava, for older feeders), waits
  for the `flock` to be released, then spawns the new one. Stopping only cava is not
  enough: during a backend probe the feeder would move on to the next backend with the
  old settings.
- Cleaning up the feeder process when the widget is destroyed.

### 3. The Renderer (`Waveform.qml`)
`Waveform.qml` draws the selected style with `WaveShader.qml` wherever Qt Quick runs
shaders, and with `WaveCanvas.qml` on the software scene graph, which ignores
`ShaderEffect`.

`WaveShader` is one fragment shader, `contents/shaders/visualizer.frag`, that follows
WaveCanvas' paths shape by shape, including its glow. An audio frame costs a few
uniform writes: the tapered levels travel four per `vec4`, since `ShaderEffect` has
no array uniforms. There is no CPU rasterisation, texture upload or blur pass per
frame. The glow is two Gaussians fitted to the `MultiEffect` shadow WaveCanvas uses.
`tests/tst_rendererparity.qml` compares both renderers pixel by pixel on a desktop,
so keep them in step, and run `make shaders` after editing the shader: the widget
loads the compiled `visualizer.frag.qsb`.

Commit both `package/contents/shaders/visualizer.frag` and its generated
`visualizer.frag.qsb`: edit the `.frag`, run `make shaders`, then commit both files.
The compiled file is required at runtime and ships in the repository so users
do not need `qsb`. Packaging does not rebuild it, and a missing `.qsb` does not
trigger the software Canvas fallback.

When `qsb` is on `PATH`, `tests/run.py` rebuilds the shader in a temporary directory
and compares its bytes with the checked-in `.qsb`; a mismatch fails the test.
Without `qsb`, this check is skipped. Use `nix develop --command python3 tests/run.py`
to run with the development tools. After a nixpkgs update changes the `qsb`
version, the compiled bytes may change: run `make shaders` and commit the updated
`.qsb` if the check reports it as out of date.

`WaveCanvas` uses the HTML5-like `Canvas` API. The idle line follows `vis.hasAudio`;
MPRIS only controls track information and media controls. Colors, edge tapers and
fill gradients are recomputed only when their inputs change, and both renderers skip
work while hidden, idle, or showing a backend error.

`PlaybackClock.qml` predicts the playback position between MPRIS updates, since MPRIS
does not signal position during normal playback. Its 50ms tick only runs while the
progress bar is visible and playing, and a bar that becomes visible catches up at
once. The waveform seekbar repaints when its playhead crosses a pixel or
appears/disappears at an endpoint.

## Regression checks

Run `nix develop --command python3 tests/run.py`, or `python3 tests/run.py` with Qt 6
`qmltestrunner` on `PATH`. The tests run the real feeder with a synthetic cava in an
isolated runtime directory, once for each awk found on `PATH` (gawk, mawk, busybox,
nawk) plus an unusable one, and the actual QML components with a stub executable
engine. They cover changing and repeated frames, the heartbeat, legacy compatibility
and the stale-file fallback, silence settling and wakeup, joining an existing feeder,
backend fallthrough and failure recovery, coalesced settings, a restart during a
backend probe, all six canvas styles, what the shader receives, and playback
prediction. They do not access the desktop or sound server. CI runs them in
`.github/workflows/tests.yml`. The renderer parity check needs a GPU scene graph and
skips itself there; on a desktop run `qmltestrunner -input tests/tst_rendererparity.qml`.

CI also runs the Quickshell audio, settings persistence and launcher lifecycle
integration tests. Run the same checks locally with:

```sh
nix develop --command dbus-run-session -- python3 tests/test_quickshell.py
nix develop --command dbus-run-session -- python3 tests/test_hyprland_settings.py
nix develop --command dbus-run-session -- python3 tests/test_lifecycle_power.py
```

These use offscreen rendering, synthetic audio and private runtime directories
and session buses; no running desktop or sound server is required.
