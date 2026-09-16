#!/usr/bin/env python3
"""Source identity, channel routing and no-fallback capture contracts."""

import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "audio_sources",
    Path(__file__).resolve().parents[1] / "package/contents/code/audio_sources.py",
)
audio = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(audio)


class SourceTests(unittest.TestCase):
    def test_pipewire_serial_and_no_fallback(self):
        for kind, monitor in [
            ("Audio/Sink", True),
            ("Audio/Source", False),
            ("Stream/Output/Audio", True),
        ]:
            with (
                self.subTest(kind=kind),
                patch.object(
                    audio, "targets", return_value=[["pw:music", "Music", "987", kind]]
                ),
            ):
                command = audio.capture_command("pw:music")
                self.assertIn("--target=987", command)
                properties = audio.json.loads(
                    next(
                        c.split("=", 1)[1]
                        for c in command
                        if c.startswith("--properties=")
                    )
                )
                self.assertTrue(properties["node.dont-fallback"])
                self.assertEqual(properties["stream.capture.sink"], monitor)

    def test_pulse_application_uses_own_sink_monitor(self):
        with patch.object(
            audio, "targets", return_value=[["app:spotify", "Spotify", "42", "8"]]
        ):
            command = audio.capture_command("app:spotify", rate=8000)
        self.assertIn("--monitor-stream=42", command)
        self.assertIn("--device=8", command)
        self.assertIn("--rate=8000", command)

    def test_missing_source_never_captures_default(self):
        with patch.object(audio, "targets", return_value=[]):
            with self.assertRaises(RuntimeError):
                audio.capture_command("pw:disappeared")

    def test_discovery_survives_missing_servers(self):
        with patch.object(audio, "query", side_effect=FileNotFoundError):
            self.assertEqual(audio.targets(), [])

    def test_pulse_identity_survives_stream_restart(self):
        def query(command):
            if command == ["pw-dump"]:
                raise FileNotFoundError
            return {
                "sources": [],
                "sinks": [{"index": 2, "monitor_source": 7}],
                "sink-inputs": [
                    {
                        "index": 91,
                        "sink": 2,
                        "properties": {
                            "application.process.binary": "spotify",
                            "application.name": "Spotify",
                        },
                    }
                ],
            }[command[-1]]

        with patch.object(audio, "query", side_effect=query):
            self.assertEqual(
                audio.targets(),
                [["app:spotify", "Application (Pulse): Spotify", "91", "7"]],
            )


if __name__ == "__main__":
    unittest.main()
