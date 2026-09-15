#!/usr/bin/env python3
"""Exercise the real Quickshell adapter with synthetic audio, without a desktop.

Run with `python3 tests/test_quickshell.py` and qs on PATH.
"""

import fcntl
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time

REPO = Path(__file__).resolve().parents[1]
qs = shutil.which("qs")
if not qs:
    raise SystemExit("Quickshell (qs) must be on PATH")


def wait_for(condition, message, timeout=5):
    deadline = time.monotonic() + timeout
    while not condition():
        assert time.monotonic() < deadline, message
        time.sleep(0.02)


with tempfile.TemporaryDirectory(prefix="audio-quickshell-test-") as directory:
    root = Path(directory)
    # Quickshell's config root must contain the shared imports.
    shutil.copytree(REPO / "package", root / "package")
    shutil.copytree(REPO / "hyprland", root / "hyprland")
    (root / "shell.qml").write_text(r"""import QtQuick
import Quickshell
import Quickshell.Io
import "hyprland"
import "hyprland/Configuration.js" as Configuration
import "package/contents/ui" as Shared

ShellRoot {
    // Load the real shared UI too: testing only the backend missed Breeze's
    // implicit Kirigami dependency in QtQuick.Controls.ToolTip.
    FileView {
        id: defaultsFile
        path: Qt.resolvedUrl("package/contents/config/main.xml").toString().replace(/^file:\/\//, "")
        blockLoading: true
    }
    Shared.VisualizerView {
        width: 360
        height: 104
        configuration: Configuration.defaults(defaultsFile.text())
        visualizer: vis
    }
    QtObject {
        id: config
        property int numBars: 4
        property int framerate: 60
        property int sensitivity: 100
        property real noiseReduction: 0.77
        property string inputMethod: "pipewire"
    }
    CommandProcess {
        id: command
        property bool roundTrip: false
        runtimeDirectory: vis.runtimeDirectory
        Component.onCompleted: {
            connectSource("printf adapter-ok");
            const startup = "exec sh -c 'sleep 0.2; touch \"$AUDIO_WAVE_RUNTIME_DIR/cancelled-start\"'";
            connectSource(startup, true);
            cancelSource(startup);
        }
        onNewData: (source, data) => roundTrip = data.stdout === "adapter-ok" && connectedSources.length === 0
    }
    Shared.VisualizerCore {
        id: vis
        configuration: config
        stopWhenInactive: true
        runtimeDirectory: Quickshell.env("XDG_RUNTIME_DIR") + "/audio-wave-quickshell"
        commandSourceComponent: Component {
            CommandProcess { runtimeDirectory: vis.runtimeDirectory }
        }
    }
    Timer {
        interval: 1200
        running: true
        onTriggered: config.numBars = 8
    }
    Timer {
        interval: 2500
        running: true
        onTriggered: {
            if (command.roundTrip && vis.backendState === "ok" && vis.hasAudio && vis.bars.length === 8 && vis.bars[0] === 800)
                console.log("PASS: Quickshell command output and live audio frames");
            else
                console.log("FAIL:", command.roundTrip, vis.backendState, vis.bars);
            vis.active = false;
            console.log("phase:inactive");
        }
    }
    Timer {
        interval: 3000
        running: true
        onTriggered: {
            config.numBars = 12;
            config.sensitivity = 120;
            console.log("phase:inactive-settings");
        }
    }
    Timer {
        interval: 3300
        running: true
        onTriggered: {
            vis.active = true;
            console.log("phase:restart-wait");
        }
    }
    Timer {
        interval: 3400
        running: true
        onTriggered: {
            vis.active = false;
            console.log("phase:restart-cancelled");
        }
    }
    Timer {
        interval: 4200
        running: true
        onTriggered: {
            vis.active = true;
            console.log("phase:resume");
        }
    }
    Timer {
        interval: 7200
        running: true
        onTriggered: {
            if (vis.backendState === "ok" && vis.hasAudio && vis.bars.length === 12 && vis.bars[0] === 800)
                console.log("PASS: resumed live audio with updated settings");
            else
                console.log("FAIL: resumed audio", vis.backendState, vis.bars);
            Qt.quit();
        }
    }
}
""")
    binaries = root / "bin"
    binaries.mkdir()
    cava = binaries / "cava"
    cava.write_text("""#!/usr/bin/env bash
while :; do
    printf '800;400;200;100;\n'
    sleep 0.02
done
""")
    cava.chmod(0o755)
    env = os.environ | {
        "PATH": str(binaries) + os.pathsep + os.environ["PATH"],
        "QT_QPA_PLATFORM": "offscreen",
        "QT_QPA_PLATFORMTHEME": "generic",
        "QT_QUICK_CONTROLS_STYLE": "Basic",
        "QT_QUICK_BACKEND": "software",
        "XDG_RUNTIME_DIR": directory,
    }
    run = root / "audio-wave-quickshell"
    pidfile = run / "feeder.pid"
    # Simulate a feeder left behind by the old launcher after Ctrl+C. A newly
    # loaded dedicated shell must replace it, rather than join its old lock.
    old_env = env | {"AUDIO_WAVE_RUNTIME_DIR": str(run)}
    old_env.pop("AUDIO_WAVE_OWNER", None)
    orphan = subprocess.Popen(
        [
            "bash",
            str(root / "package/contents/code/feeder.sh"),
            "6",
            "30",
            "66",
            "0.77",
            "pipewire",
        ],
        env=old_env,
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    wait_for(
        lambda: (
            (run / "status").exists()
            and (run / "status").read_text().strip() == "ok pipewire"
        ),
        "Could not start the simulated old feeder",
    )
    with (root / "log").open("w") as log:
        process = subprocess.Popen(
            [qs, "-p", directory],
            env=env,
            stdout=log,
            stderr=log,
            start_new_session=True,
        )
        try:
            wait_for(
                lambda: (
                    orphan.poll() is not None
                    and pidfile.exists()
                    and "bars = 4" in (run / "cava.conf").read_text()
                ),
                "New shell did not reclaim its ownerless feeder",
            )
            wait_for(
                lambda: "phase:inactive" in (root / "log").read_text(),
                "Shell did not enter the inactive phase",
            )
            wait_for(
                lambda: not pidfile.exists(), "Inactive shell kept capture running"
            )
            # Watch the entire inactive period, including a settings change.
            frame_stamp = (run / "frame.ini").stat().st_mtime_ns
            with (run / "lock").open("a") as restart_lock:
                # Force the brief reactivation's restart command to wait. It
                # must not start its feeder after the view becomes hidden again.
                fcntl.flock(restart_lock, fcntl.LOCK_EX)
                released = False
                while "phase:resume" not in (root / "log").read_text():
                    assert process.poll() is None, (root / "log").read_text()
                    assert not pidfile.exists(), (
                        "Inactive settings or a pending restart started capture"
                    )
                    assert (run / "frame.ini").stat().st_mtime_ns == frame_stamp, (
                        "Inactive capture kept publishing"
                    )
                    if (
                        not released
                        and "phase:restart-cancelled" in (root / "log").read_text()
                    ):
                        fcntl.flock(restart_lock, fcntl.LOCK_UN)
                        released = True
                    time.sleep(0.02)
                assert released, "Did not exercise a cancelled pending restart"
            assert "phase:inactive-settings" in (root / "log").read_text()
            wait_for(
                lambda: (
                    pidfile.exists()
                    and "bars = 12" in (run / "cava.conf").read_text()
                    and "sensitivity = 120" in (run / "cava.conf").read_text()
                ),
                "Reactivation did not start capture with the new settings",
            )
            process.wait(timeout=7)
            output = (root / "log").read_text()
            assert (
                process.returncode == 0
                and "PASS: Quickshell" in output
                and "FAIL:" not in output
            ), output
            assert "PASS: resumed live audio with updated settings" in output, output
            assert not (run / "cancelled-start").exists(), (
                "A cancelled owned command started before its PID was available"
            )
            assert not (root / "audio-wave-widget").exists(), "Touched Plasma runtime"
            assert "bars = 12" in (run / "cava.conf").read_text()
            # A clean shell exit must also stop its feeder.
            deadline = time.monotonic() + 3
            while pidfile.exists() and time.monotonic() < deadline:
                time.sleep(0.02)
            assert not pidfile.exists(), output
            print(
                "PASS: Quickshell frames, orphan recovery, idle shutdown, inactive settings, resume and cleanup"
            )
        except BaseException:
            print((root / "log").read_text())
            if pidfile.exists():
                print("Remaining feeder PID:", pidfile.read_text().strip())
            raise
        finally:
            pidfile = root / "audio-wave-quickshell/feeder.pid"
            if pidfile.exists():
                try:
                    os.kill(int(pidfile.read_text()), signal.SIGTERM)
                except (ProcessLookupError, FileNotFoundError):
                    pass
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            process.wait(timeout=3)
            try:
                os.killpg(orphan.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            orphan.wait(timeout=3)
