"""Validate native blur geometry and bounded runtime files without a desktop."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

SCRIPT = (
    Path(__file__).resolve().parents[1] / "package/contents/code/popup_blur_mask.sh"
)


class PopupMaskTests(unittest.TestCase):
    def test_geometry_and_bounded_replacements(self):
        with tempfile.TemporaryDirectory() as runtime:
            env = os.environ | {"XDG_RUNTIME_DIR": runtime}
            for width, height, radius in [
                (360, 104, 14),
                (250, 332, 30),
                (380, 320, 0),
                (360, 104, 14),
            ]:
                result = subprocess.run(
                    [
                        "bash",
                        str(SCRIPT),
                        "42",
                        str(width),
                        str(height),
                        str(radius),
                        "12",
                    ],
                    env=env,
                    check=True,
                    capture_output=True,
                    text=True,
                )
                path = Path(result.stdout.strip())
                self.assertEqual(len(list(path.parent.glob("*.svg"))), 1)
                svg = ET.parse(path).getroot()
                self.assertEqual(int(svg.attrib["width"]), width + 24)
                self.assertEqual(int(svg.attrib["height"]), height + 24)
                card = list(list(svg)[0])[1]
                self.assertEqual(
                    [int(card.attrib[k]) for k in ("x", "y", "width", "height", "rx")],
                    [12, 12, width, height, radius],
                )
                self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            # A second widget cannot remove the first widget's current mask.
            subprocess.run(
                ["bash", str(SCRIPT), "43", "340", "138", "14", "12"],
                env=env,
                check=True,
                capture_output=True,
            )
            self.assertTrue(path.exists())

    def test_invalid_arguments_cannot_write_files(self):
        with tempfile.TemporaryDirectory() as runtime:
            for args in [
                ("1", "0", "104", "14", "12"),
                ("../escape", "360", "104", "14", "12"),
                ("1", "360", "104", "x;touch bad", "12"),
            ]:
                result = subprocess.run(
                    ["bash", str(SCRIPT), *args],
                    env=os.environ | {"XDG_RUNTIME_DIR": runtime},
                    capture_output=True,
                )
                self.assertNotEqual(result.returncode, 0)
            self.assertEqual(list(Path(runtime).iterdir()), [])


if __name__ == "__main__":
    unittest.main()
