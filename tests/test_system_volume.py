#!/usr/bin/env python3
"""Run the installed shell helper with a desktop PATH that has no Python."""

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

HELPER = Path(__file__).resolve().parents[1] / "package/contents/code/system_volume.sh"
BASH = shutil.which("bash")


class VolumeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.log = self.directory / "commands"
        (self.directory / "awk").symlink_to(shutil.which("awk"))
        self.env = os.environ | {
            "PATH": str(self.directory),
            "VOLUME_TEST_LOG": str(self.log),
        }

    def command(self, name, body):
        path = self.directory / name
        path.write_text(f'#!{BASH}\nprintf "%s\\n" "$*" >> "$VOLUME_TEST_LOG"\n' + body)
        path.chmod(0o755)

    def run_helper(self, step):
        return subprocess.run(
            [BASH, str(HELPER), str(step)],
            check=False,
            env=self.env,
            capture_output=True,
            text=True,
            timeout=3,
        )

    def test_wpctl_works_without_python_and_clamps(self):
        self.command(
            "wpctl", 'if [[ "$1" == get-volume ]]; then echo "Volume: 0.98"; fi\n'
        )
        result = self.run_helper(0.04)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "1.0000")
        self.assertIn(
            "set-volume --limit 1.0 @DEFAULT_AUDIO_SINK@ 1.0000", self.log.read_text()
        )
        self.assertIsNone(shutil.which("python3", path=self.env["PATH"]))

    def test_pactl_fallback(self):
        self.command(
            "pactl",
            'if [[ "$1" == get-sink-volume ]]; then echo "Volume: front-left: 32768 / 50% / -18.06 dB"; fi\n',
        )
        result = self.run_helper(-0.04)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "0.4600")
        self.assertIn("set-sink-volume @DEFAULT_SINK@ 46%", self.log.read_text())

    def test_failed_wpctl_falls_back(self):
        self.command("wpctl", "exit 1\n")
        self.command(
            "pactl", 'if [[ "$1" == get-sink-volume ]]; then echo "Volume: 3%"; fi\n'
        )
        result = self.run_helper(-0.04)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "0.0000")

    def test_missing_backends_report_failure(self):
        result = self.run_helper(0.04)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("Cannot adjust", result.stderr)

    def test_invalid_input_is_rejected(self):
        for value in ("nan", "", "1; echo bad"):
            self.assertNotEqual(self.run_helper(value).returncode, 0)


if __name__ == "__main__":
    unittest.main()
