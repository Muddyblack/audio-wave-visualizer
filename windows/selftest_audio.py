"""Device-free capture regression tests, also run inside the packaged .exe."""

import configparser
import io
import sys
import tempfile
import time
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

import numpy as np

import audio_capture as capture


class AudioTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="visualizer-audio-test-")
        self.addCleanup(self.directory.cleanup)
        self.addCleanup(capture.stop)
        self.run_dir = Path(self.directory.name)
        # A fixed default device, so no test touches the real audio stack.
        device = patch.object(capture, "_default_output_id", return_value="speaker")
        device.start()
        self.addCleanup(device.stop)
        retry = patch.object(capture, "RETRY_SECONDS", 0.01)
        retry.start()
        self.addCleanup(retry.stop)

    def wait_for_status(self, expected, timeout=5):
        deadline = time.monotonic() + timeout
        status = self.run_dir / "status"
        while time.monotonic() < deadline:
            if status.is_file() and status.read_text().strip() == expected:
                return
            time.sleep(0.01)
        self.fail(f"status never became {expected!r}")

    def read_frame(self, bars):
        parser = configparser.ConfigParser()
        parser.read_string("[frame]\n" + (self.run_dir / "frame.ini").read_text())
        frame = parser["frame"]
        self.assertEqual(frame["protocol"], "2")
        self.assertGreater(float(frame["t"]), 0)
        values = [int(value) for value in frame["v"].strip('"').split(";")]
        self.assertEqual(len(values), bars)
        self.assertTrue(all(0 <= value <= capture.MAX_RANGE for value in values))
        self.assertEqual(list(self.run_dir.glob("*.tmp")), [])
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
            self.wait_for_status("error capture RuntimeError")
            feed = capture._feed
            capture.stop()
            self.assertFalse(feed.is_alive(), "capture thread did not stop")
        self.assertEqual((self.run_dir / "status").read_text().strip(), "ok stopped")

    def test_no_output_device_is_reported_with_fresh_silent_frames(self):
        # Windows with no output (RDP without sound): say so, and keep a fresh
        # frame so the widget trusts status.ini and shows why.
        with patch.object(capture, "_default_output_id", return_value=None):
            capture.start({}, self.run_dir)
            self.wait_for_status("error no-output")
            self.wait_for_frame()
            capture.stop()
        self.assertEqual(self.read_frame(24), [0] * 24)

    def wait_for_frame(self, timeout=5):
        deadline = time.monotonic() + timeout
        while not (self.run_dir / "frame.ini").is_file():
            if time.monotonic() > deadline:
                self.fail("no frame published")
            time.sleep(0.01)

    def test_capture_recovers_once_a_device_appears(self):
        # No output device at startup (WASAPI's 0x80070490), then one shows up.
        class Recorder:
            def __enter__(self):
                return self

            def __exit__(self, *args):
                pass

            def record(self, block):
                capture._feed.stop()
                return np.ones((block, 2))

        microphone = Mock()
        microphone.recorder.return_value = Recorder()
        with patch.object(
            capture,
            "_loopback_microphone",
            side_effect=[RuntimeError, RuntimeError, microphone],
        ) as opened:
            capture.start({}, self.run_dir)
            capture._feed.join(timeout=5)
            self.assertEqual(opened.call_count, 3)
        self.read_frame(24)

    def test_default_output_change_reopens_capture(self):
        devices = iter(["speakers", "headphones", "headphones"])
        opened = []

        class Recorder:
            def __enter__(self):
                opened.append(True)
                return self

            def __exit__(self, *args):
                pass

            def record(self, block):
                if len(opened) == 2:
                    capture._feed.stop()
                return np.zeros((block, 2))

        with (
            patch.object(capture, "_default_output_id", lambda: next(devices)),
            patch.object(capture, "DEVICE_CHECK_SECONDS", 0),
            patch.object(capture, "_loopback_microphone") as microphone,
        ):
            microphone.return_value.recorder.side_effect = lambda **_: Recorder()
            capture.start({}, self.run_dir)
            capture._feed.join(timeout=5)
            self.assertFalse(capture._feed.is_alive())
        self.assertEqual(len(opened), 2)

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
