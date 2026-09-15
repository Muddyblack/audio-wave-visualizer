#!/usr/bin/env python3
"""Check repeated preview launches and Ctrl+C leave one shell and no audio jobs.

Run with python3 tests/test_lifecycle_power.py and qs on PATH.
Uses synthetic audio and a private runtime directory; no desktop is required.
"""

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


def running(pid):
    try:
        return Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()[0] != "Z"
    except FileNotFoundError:
        return False


def descendants(pid):
    children = set()
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            stat = (entry / "stat").read_text().rsplit(")", 1)[1].split()
        except FileNotFoundError:
            continue
        if int(stat[1]) == pid:
            children.add(int(entry.name))
    for child in tuple(children):
        children.update(descendants(child))
    return children


def wait_for(condition, message, timeout=5):
    deadline = time.monotonic() + timeout
    while not condition():
        assert time.monotonic() < deadline, message
        time.sleep(0.02)


with tempfile.TemporaryDirectory(prefix="audio-lifecycle-test-") as directory:
    root = Path(directory)
    shutil.copytree(REPO / "package", root / "package")
    shutil.copytree(REPO / "hyprland", root / "hyprland")
    shutil.copyfile(REPO / "Makefile", root / "Makefile")
    (root / "shell.qml").write_text("""import QtQuick
import Quickshell
import Quickshell.Io
import "hyprland"
import "package/contents/ui" as Shared

ShellRoot {
    QtObject {
        id: config
        property int numBars: 4
        property int framerate: 30
        property int sensitivity: 100
        property real noiseReduction: 0.77
        property string inputMethod: "pipewire"
    }
    Shared.VisualizerCore {
        id: vis
        configuration: config
        stopWhenInactive: true
        runtimeDirectory: Quickshell.env("XDG_RUNTIME_DIR") + "/audio-wave-quickshell"
        commandSourceComponent: Component {
            CommandProcess { runtimeDirectory: vis.runtimeDirectory }
        }
        onHasAudioChanged: if (hasAudio) console.log("audio-ready")
    }
}
""")
    binaries = root / "bin"
    binaries.mkdir()
    cava = binaries / "cava"
    cava.write_text("""#!/usr/bin/env bash
while :; do
    printf '800;400;200;100;\\n'
    sleep 0.033
done
""")
    cava.chmod(0o755)
    env = os.environ | {
        "PATH": str(binaries) + os.pathsep + os.environ["PATH"],
        "QT_QPA_PLATFORM": "offscreen",
        "QT_QUICK_BACKEND": "software",
        "XDG_RUNTIME_DIR": directory,
    }
    pidfile = root / "audio-wave-quickshell/feeder.pid"
    tracked = set()
    direct = None
    unrelated = subprocess.Popen(
        ["sleep", "30"],
        env=env | {"AUDIO_WAVE_OWNER": "another-widget"},
        start_new_session=True,
    )
    with (root / "log").open("w") as log:
        process = subprocess.Popen(
            ["make", "view-hyprland"],
            cwd=root,
            env=env,
            stdout=log,
            stderr=log,
            start_new_session=True,
        )
        try:
            wait_for(
                lambda: pidfile.exists() and pidfile.read_text().strip(),
                "Preview did not start its feeder: " + str(root / "log"),
            )
            feeder_pid = int(pidfile.read_text())

            def ready():
                return "audio-ready" in (root / "log").read_text()

            wait_for(ready, "Preview failed to receive audio")
            tracked = {feeder_pid} | descendants(feeder_pid)
            assert len(tracked) >= 3, "Expected feeder, cava, and publisher processes"
            repeated = subprocess.run(
                ["make", "view-hyprland"],
                cwd=root,
                env=env,
                capture_output=True,
                text=True,
                timeout=3,
            )
            assert repeated.returncode == 0, repeated.stdout + repeated.stderr
            assert "already running" in repeated.stdout + repeated.stderr, (
                repeated.stdout + repeated.stderr
            )
            assert process.poll() is None and int(pidfile.read_text()) == feeder_pid
            assert ready(), "Duplicate launch interrupted the existing widget"

            # Terminal Ctrl+C signals the foreground group, including make.
            os.killpg(process.pid, signal.SIGINT)
            process.wait(timeout=5)
            assert "Error 130" not in (root / "log").read_text(), (
                "Normal Ctrl+C reported a launcher failure"
            )
            wait_for(
                lambda: not pidfile.exists() and not any(map(running, tracked)),
                "Ctrl+C left an audio process running: " + (root / "log").read_text(),
            )
            subprocess.run(
                ["flock", "-n", str(root / "audio-wave-quickshell/lock"), "true"],
                check=True,
                timeout=2,
            )
            assert unrelated.poll() is None, "Stopped another owner's process"
            print(
                "PASS: repeated launch reuses shell; Ctrl+C stops owned audio jobs and preserves other processes"
            )

            # A shell started directly has no launcher lock or ownership token.
            # qs -n must leave it running when the make target is then invoked.
            direct = subprocess.Popen(
                [qs, "-p", str(root / "shell.qml")],
                env=env,
                stdout=log,
                stderr=log,
                start_new_session=True,
            )
            wait_for(
                lambda: pidfile.exists() and pidfile.read_text().strip(),
                "Direct shell failed to start",
            )
            direct_feeder = int(pidfile.read_text())
            tracked |= {direct_feeder} | descendants(direct_feeder)
            repeated = subprocess.run(
                ["make", "view-hyprland"],
                cwd=root,
                env=env,
                capture_output=True,
                text=True,
                timeout=3,
            )
            assert repeated.returncode == 0, repeated.stdout + repeated.stderr
            assert "already running" in repeated.stdout + repeated.stderr
            assert direct.poll() is None and running(direct_feeder)
            assert int(pidfile.read_text()) == direct_feeder
            print("PASS: launcher preserves an existing shell started directly")
        except BaseException:
            print((root / "log").read_text())
            print("Feeder PID file remains:", pidfile.exists())
            for pid in tracked:
                if running(pid):
                    print(
                        "Still running:",
                        pid,
                        Path(f"/proc/{pid}/cmdline").read_text().replace("\0", " "),
                    )
            raise
        finally:
            unrelated.terminate()
            unrelated.wait(timeout=3)
            if direct is not None:
                direct.terminate()
                direct.wait(timeout=3)
            if pidfile.exists() and pidfile.read_text().strip():
                tracked.add(int(pidfile.read_text()))
            for pid in tracked:
                try:
                    os.kill(pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            process.wait(timeout=3)
