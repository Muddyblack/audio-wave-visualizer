#!/usr/bin/env python3
"""Stereo channel/phase integrity and monitor subprocess ownership."""

import importlib.util
import math
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "package/contents/code/stereo_capture.py"
spec = importlib.util.spec_from_file_location("stereo_capture", HELPER)
stereo = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stereo)


class StereoTests(unittest.TestCase):
    def test_signed_phase_and_bounds(self):
        block = b"".join(
            struct.pack("<hh", v, -v)
            for v in [round(math.sin(i * 0.2) * 30000) for i in range(128)]
        )
        frame = stereo.samples(block)
        self.assertEqual(len(frame), 32)
        self.assertTrue(any(left < 0 for left, _ in frame))
        self.assertTrue(any(left > 0 for left, _ in frame))
        for left, right in frame:
            self.assertAlmostEqual(left, -right)
            self.assertLessEqual(abs(left), 1)
        self.assertEqual(stereo.samples(b"\x00" * 4), [])

    def test_lease_stops_capture_and_removes_frame(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            lease, output = base / "lease", base / "frame.ini"
            lease.write_text(f"[General]\nt={time.time() * 1000}\n")
            fake = base / "pw-cat"
            fake.write_text(
                f"#!{sys.executable}\n"
                + """import os, sys, time
assert '--record' in sys.argv and '--raw' in sys.argv
assert '--channels=2' in sys.argv
assert any('stream.capture.sink=true' in a for a in sys.argv)
while True:
    os.write(1, b'\\x00\\x40\\x00\\xc0' * 128)
    time.sleep(.01)
"""
            )
            fake.chmod(0o755)
            proc = subprocess.Popen(
                [sys.executable, str(HELPER), str(lease), str(output), "30"],
                env=dict(os.environ, PATH=directory),
            )
            try:
                deadline = time.monotonic() + 2
                while not output.exists() and time.monotonic() < deadline:
                    time.sleep(0.02)
                self.assertTrue(output.exists(), "The helper must publish PCM")
                self.assertIn("0.500000:-0.500000", output.read_text())
                lease.write_text("[General]\nt=0\n")
                self.assertEqual(proc.wait(timeout=2), 0)
                self.assertFalse(output.exists(), "Expired PCM must be removed")
                self.assertFalse(stereo.lease_alive(lease))
            finally:
                if proc.poll() is None:
                    proc.terminate()
                    proc.wait(timeout=2)


if __name__ == "__main__":
    unittest.main()
