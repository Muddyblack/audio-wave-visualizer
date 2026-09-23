#!/usr/bin/env python3
"""Backend transport regressions; Python 3 only, no desktop or audio capture."""

import os
import shutil
import signal
import subprocess
import tempfile
import time
import unittest
from pathlib import Path


FEEDER = Path(__file__).resolve().parents[1] / "package/contents/code/feeder.sh"

# Each awk distros ship as `awk`, with the reader feeder.sh must pick for it.
# mawk (Debian/Ubuntu) buffers pipes unless run with -W interactive, and nawk
# (one-true-awk) lacks systime(), so it keeps the Bash reader. The dev shell
# provides mawk and nawk; gawk comes from stdenv.
AWKS = {}
for name, reader in (
    ("gawk", "awk"),
    ("mawk", "awk -W interactive"),
    ("busybox", "awk"),
    ("nawk", "bash"),
):
    path = shutil.which(name)
    if path:
        AWKS[name] = (path, reader)
AWKS["unusable"] = (None, "bash")


class FeederCases:
    awk = None
    reader = "bash"

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="audio-feeder-test-")
        self.addCleanup(self.directory.cleanup)
        self.runtime = Path(self.directory.name)
        self.run = self.runtime / "audio-wave-widget"
        binaries = self.runtime / "bin"
        binaries.mkdir()
        awk = binaries / "awk"
        if self.awk:
            awk.symlink_to(self.awk)
        else:
            awk.write_text("#!/bin/sh\nexit 2\n")
            awk.chmod(0o755)
        cava = binaries / "cava"
        # The control file changes a live frame without restarting the feeder.
        # Python's sleep avoids spawning a child for every synthetic frame.
        cava.write_text("""#!/usr/bin/env python3
import os
import sys
import time
from pathlib import Path
runtime = Path(os.environ['XDG_RUNTIME_DIR'])
control = runtime / 'control'
configuration = Path(sys.argv[2]).read_text()
if 'method = fifo' in configuration:
    source = next(line.split(' = ', 1)[1] for line in configuration.splitlines() if line.startswith('source = '))
    with open(source, 'rb') as pcm:
        (runtime / 'captured').write_bytes(pcm.read(4))
i = 0
while True:
    frame = control.read_text()
    if frame == 'exit':
        break
    if frame == 'pulse-only':
        if 'method = pipewire' in configuration:
            break
        frame = '200;300;400;500;'
    if frame == 'ramp':
        frame = (str(100 + i % 900) + ';') * 4
    print(frame, flush=True)
    i += 1
    time.sleep(1 / 144)
""")
        cava.chmod(0o755)
        self.control = self.runtime / "control"
        self.control.write_text("0;0;0;0;")
        self.env = os.environ | {
            "PATH": str(binaries) + os.pathsep + os.environ["PATH"],
            "XDG_RUNTIME_DIR": str(self.runtime),
        }
        self.command = ["bash", str(FEEDER), "4", "144", "100", "0.77", "pipewire"]
        self.process = subprocess.Popen(
            self.command, env=self.env, start_new_session=True
        )
        self.addCleanup(self.stop)
        self.wait_for(lambda: self.read("status").strip() == "ok pipewire")
        self.wait_for(lambda: self.read("status.ini").strip() == 'v="ok pipewire"')

    def stop(self):
        try:
            os.killpg(self.process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        self.process.wait(timeout=3)

    def read(self, name):
        try:
            return (self.run / name).read_text()
        except FileNotFoundError:
            return ""

    def frame(self):
        # A read during truncate/write may be empty; callers keep polling.
        return dict(
            line.split("=", 1)
            for line in self.read("frame.ini").splitlines()
            if "=" in line
        )

    def wait_for(self, condition, timeout=3):
        deadline = time.monotonic() + timeout
        while not condition():
            if time.monotonic() >= deadline or self.process.poll() is not None:
                self.fail(
                    "Feeder did not reach the expected state: " + self.read("status")
                )
            time.sleep(0.005)

    def restart_with(self, extra):
        self.stop()
        self.process = subprocess.Popen(
            self.command + extra, env=self.env, start_new_session=True
        )

    def test_frequency_cutoffs_reach_cava(self):
        self.restart_with(["auto", "80", "8000"])
        self.wait_for(lambda: "higher_cutoff_freq = 8000" in self.read("cava.conf"))
        self.assertIn("lower_cutoff_freq = 80", self.read("cava.conf"))

    def test_invalid_cutoffs_use_safe_defaults(self):
        self.restart_with(["auto", "9000", "100"])
        self.wait_for(lambda: self.read("status").strip() == "ok pipewire")
        self.assertIn("lower_cutoff_freq = 50", self.read("cava.conf"))
        self.assertIn("higher_cutoff_freq = 10000", self.read("cava.conf"))

    def test_explicit_pipewire_source_streams_pcm_through_fifo(self):
        scripts = {
            "pw-dump": '#!/bin/sh\nprintf \'%s\' \'[{"id":12,"info":{"props":{"node.name":"music","media.class":"Stream/Output/Audio","object.serial":123}}}]\'\n',
            "pactl": "#!/bin/sh\nexit 1\n",
            "pw-cat": "#!/usr/bin/env python3\nimport os, sys, time\nfrom pathlib import Path\np = Path(os.environ['XDG_RUNTIME_DIR'])\n(p / 'capture-args').write_text(' '.join(sys.argv))\nsys.stdout.buffer.write(b'PCM!')\nsys.stdout.buffer.flush()\ntime.sleep(60)\n",
        }
        for name, script in scripts.items():
            binary = self.runtime / "bin" / name
            binary.write_text(script)
            binary.chmod(0o755)
        self.restart_with(["pw:music", "80", "8000"])
        self.wait_for(lambda: (self.runtime / "captured").exists())
        self.assertEqual((self.runtime / "captured").read_bytes(), b"PCM!")
        self.wait_for(lambda: self.read("status").strip() == "ok fifo")
        args = (self.runtime / "capture-args").read_text()
        self.assertEqual(
            self.read("input-method"),
            "pipewire\n",
            "Explicit capture must not replace the remembered default backend",
        )
        self.assertIn("--target=123", args)
        self.assertIn('"node.dont-fallback": true', args)

    def test_missing_explicit_source_does_not_fallback(self):
        for name in ["pw-dump", "pactl"]:
            binary = self.runtime / "bin" / name
            binary.write_text("#!/bin/sh\nexit 1\n")
            binary.chmod(0o755)
        self.restart_with(["pw:missing"])
        self.process.wait(timeout=3)
        self.assertEqual(self.read("status").strip(), "error source-unavailable")
        self.assertIn("method = fifo", self.read("cava.conf"))
        self.assertEqual(self.read("bars"), "0;0;0;0;")

    def test_reader_matches_awk(self):
        self.assertEqual(self.read("publisher"), self.reader + "\n")

    def test_duplicate_frames_keep_fresh_ini_without_rewriting_bars(self):
        bars = self.run / "bars"
        initial_mtime = bars.stat().st_mtime_ns
        initial_sequence = int(self.frame()["seq"])
        self.assertEqual(self.read("bars"), "0;0;0;0;")
        self.assertEqual(self.read("status.ini"), 'v="ok pipewire"\n')
        frames = set()
        deadline = time.monotonic() + 2.3
        while time.monotonic() < deadline:
            frame = self.frame()
            if "t" in frame:
                self.assertLess(abs(time.time() - float(frame["t"])), 2)
                self.assertEqual(frame["protocol"], "2")
                frames.add(frame["t"])
            time.sleep(0.01)
        self.assertGreaterEqual(len(frames), 2, "Idle heartbeat stopped refreshing")
        self.assertGreater(
            int(self.frame()["seq"]),
            initial_sequence,
            "Idle heartbeat stopped advancing the frame sequence",
        )
        self.assertLessEqual(
            len(frames), 4, "Duplicate frames still rewrite INI at audio FPS"
        )
        self.assertEqual(bars.stat().st_mtime_ns, initial_mtime)

        # A new frame must reach both transports after a quiet heartbeat.
        # The changing-frame test separately checks that updates are not
        # limited to the heartbeat rate.
        stamp = self.frame().get("t")
        sequence = int(self.frame()["seq"])
        self.wait_for(lambda: self.frame().get("t") not in (None, stamp))
        self.control.write_text("900;100;500;250;")
        self.wait_for(lambda: self.read("bars") == "900;100;500;250;")
        self.wait_for(
            lambda: (
                self.frame().get("v", "").strip('"').replace(",", ";")
                == "900;100;500;250;"
            )
        )
        self.assertGreater(int(self.frame()["seq"]), sequence)

    def test_shared_startup_preserves_running_frame_and_status(self):
        status_mtime = (self.run / "status.ini").stat().st_mtime_ns
        subprocess.run(self.command, env=self.env, check=True, timeout=3)
        self.assertIsNone(self.process.poll())
        self.assertEqual((self.run / "status.ini").stat().st_mtime_ns, status_mtime)

    def test_changing_frames_are_not_limited_to_heartbeat_rate(self):
        self.assertIn("framerate = 144", self.read("cava.conf"))
        self.control.write_text("ramp")
        frames = set()
        # Count progress rather than benchmarking a shared CI runner over a
        # subsecond window. Even with a tick at each boundary, a publisher
        # limited to the one-second heartbeat cannot deliver 31 values here.
        deadline = time.monotonic() + 5
        while len(frames) < 31 and time.monotonic() < deadline:
            value = self.frame().get("v")
            if value and value != '"0;0;0;0;"':
                frames.add(value)
            time.sleep(0.002)
        self.assertGreater(
            len(frames),
            30,
            f"Only {len(frames)} changing frames observed in 5 seconds; "
            f"publisher={self.read('publisher').strip()}, "
            f"status={self.read('status').strip()}",
        )

    def test_backend_exit_updates_both_status_formats(self):
        self.control.write_text("exit")
        self.process.wait(timeout=3)
        self.assertEqual(self.read("status"), "error cava-exited pipewire\n")
        self.assertEqual(self.read("status.ini"), 'v="error cava-exited pipewire"\n')

    def test_failed_backend_still_falls_through_to_next_candidate(self):
        self.stop()
        self.control.write_text("pulse-only")
        self.process = subprocess.Popen(
            self.command[:-1] + ["auto"], env=self.env, start_new_session=True
        )
        self.wait_for(lambda: self.read("status.ini").strip() == 'v="ok pulse"')
        self.assertEqual(self.read("input-method"), "pulse\n")
        self.assertEqual(self.read("bars"), "200;300;400;500;")


for name, (path, reader) in AWKS.items():
    test_case = "FeederWith_" + name
    globals()[test_case] = type(
        test_case, (FeederCases, unittest.TestCase), {"awk": path, "reader": reader}
    )


if __name__ == "__main__":
    unittest.main()
