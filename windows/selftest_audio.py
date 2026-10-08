"""Device-free capture regression tests, also run inside the packaged .exe."""

import configparser
import io
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import numpy as np

import audio_capture as capture


class AudioTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="visualizer-audio-test-")
        self.addCleanup(self.directory.cleanup)
        self.addCleanup(capture.stop)
        self.run_dir = Path(self.directory.name)

    def read_frame(self, bars):
        parser = configparser.ConfigParser()
        parser.read_string("[frame]\n" + (self.run_dir / "frame.ini").read_text())
        frame = parser["frame"]
        self.assertEqual(frame["protocol"], "2")
        self.assertGreater(float(frame["t"]), 0)
        values = [int(value) for value in frame["v"].strip('"').split(";")]
        self.assertEqual(len(values), bars)
        self.assertTrue(all(0 <= value <= capture.MAX_RANGE for value in values))
        self.assertFalse((self.run_dir / "frame.ini.tmp").exists())
        return values

    def run_capture(self, signal, bars=24, framerate=60):
        class Recorder:
            calls = 0

            def __enter__(self):
                return self

            def __exit__(self, *args):
                pass

            def record(self, block):
                self.calls += 1
                samples = signal(block)
                if self.calls == 4:
                    capture._feed.stop()
                return samples

        recorder = Recorder()
        with patch.object(capture, "_loopback_microphone") as microphone:
            microphone.return_value.recorder.return_value = recorder
            capture.start({"numBars": bars, "framerate": framerate}, self.run_dir)
            feed = capture._feed
            feed.join(timeout=5)
            self.assertFalse(feed.is_alive(), "capture thread did not stop")
            capture.stop()  # Exercise the same cleanup as Quit in the app.
        self.assertEqual(recorder.calls, 4)
        self.assertEqual((self.run_dir / "status").read_text().strip(), "ok stopped")
        return self.read_frame(bars)

    def test_stereo_tone_publishes_nonzero_bars_and_stops(self):
        def tone(block):
            wave = np.sin(2 * np.pi * 1000 * np.arange(block) / capture.SAMPLERATE)
            return np.column_stack((wave, wave * 0.5))

        self.assertGreater(max(self.run_capture(tone)), 0)

    def test_silence_publishes_zero_bars(self):
        self.assertEqual(self.run_capture(lambda block: np.zeros((block, 2))), [0] * 24)

    def test_low_framerate_and_many_bands(self):
        values = self.run_capture(lambda block: np.ones(block), bars=128, framerate=10)
        self.assertGreater(max(values), 0)

    def test_capture_failure_is_reported_and_shutdown_is_safe(self):
        with patch.object(capture, "_loopback_microphone", side_effect=RuntimeError):
            capture.start({}, self.run_dir)
            capture._feed.join(timeout=5)
            self.assertFalse(capture._feed.is_alive())
            capture.stop()
        self.assertEqual(
            (self.run_dir / "status").read_text().strip(), "error capture RuntimeError"
        )

    def test_unchanged_frames_are_throttled_and_refreshed(self):
        feed = capture._Feed(self.run_dir, {})
        with patch.object(capture.time, "time", side_effect=[100.1, 100.2, 101.1]):
            feed._publish_frame(np.zeros(24))
            first = (self.run_dir / "frame.ini").read_bytes()
            feed._publish_frame(np.zeros(24))
            self.assertEqual((self.run_dir / "frame.ini").read_bytes(), first)
            feed._publish_frame(np.zeros(24))
            self.assertNotEqual((self.run_dir / "frame.ini").read_bytes(), first)

    @unittest.skipUnless(sys.platform == "win32", "WASAPI backend requires Windows")
    def test_wasapi_backend_imports(self):
        # Import without enumerating devices: checks CFFI and its bundled header.
        import soundcard

        self.assertTrue(callable(soundcard.default_speaker))


def main():
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(AudioTests)
    # PyInstaller's windowed bootloader has no stderr; exit status still reports
    # failure to the PowerShell runner.
    result = unittest.TextTestRunner(
        stream=sys.stderr or io.StringIO(), verbosity=2
    ).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    sys.exit(main())
