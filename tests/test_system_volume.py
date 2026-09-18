#!/usr/bin/env python3
"""Default output volume command selection and bounds."""

import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch


HELPER = Path(__file__).resolve().parents[1] / "package/contents/code/system_volume.py"
spec = importlib.util.spec_from_file_location("system_volume", HELPER)
volume = importlib.util.module_from_spec(spec)
spec.loader.exec_module(volume)


class VolumeTests(unittest.TestCase):
    def test_wpctl_changes_default_sink_and_clamps(self):
        calls = []

        def run(*args):
            calls.append(args)
            return "Volume: 0.98" if args[1] == "get-volume" else ""

        with patch.object(volume, "run", side_effect=run):
            self.assertEqual(volume.adjust(0.04), 1)
        self.assertEqual(
            calls[-1],
            ("wpctl", "set-volume", "--limit", "1.0", "@DEFAULT_AUDIO_SINK@", "1.0000"),
        )

    def test_pactl_fallback_changes_default_sink(self):
        calls = []

        def run(*args):
            calls.append(args)
            if args[0] == "wpctl":
                raise FileNotFoundError
            return (
                "Volume: front-left: 32768 /  50% / -18.06 dB"
                if args[1] == "get-sink-volume"
                else ""
            )

        with patch.object(volume, "run", side_effect=run):
            self.assertAlmostEqual(volume.adjust(-0.04), 0.46)
        self.assertEqual(
            calls[-1], ("pactl", "set-sink-volume", "@DEFAULT_SINK@", "46%")
        )


if __name__ == "__main__":
    unittest.main()
