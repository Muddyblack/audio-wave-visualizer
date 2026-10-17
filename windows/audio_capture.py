"""WASAPI loopback capture -> the same frame.ini the Linux feeder writes.

cava is Linux-only, so this replaces it: capture whatever the default output
device is playing, band it with an FFT, and publish the bars in feeder.sh's
format (`t=`, quoted `v="b0;b1;..."`, `protocol=2`) so the QML reader in
VisualizerCore works unchanged. `soundcard` gives WASAPI loopback on Windows
and PulseAudio monitors on Linux, so this runs on both and can be developed
without a VM.
"""

import os
import threading
import time
from pathlib import Path

import numpy as np

FFT_SIZE = 2048
MAX_RANGE = 1000.0
SAMPLERATE = 48000
# How long to wait before reopening a device that failed or vanished (no
# speakers at login, a USB DAC unplugged), and how often to look for a new
# default output (headphones plugged in) while capturing.
RETRY_SECONDS = 2.0
DEVICE_CHECK_SECONDS = 2.0


def runtime_dir() -> Path:
    """Where frames are published. XDG_RUNTIME_DIR has no Windows equivalent."""
    base = os.environ.get("LOCALAPPDATA") or os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    path = Path(base) / "audio-visualizer"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _publish(path: Path, text: str) -> None:
    # Per writer, so two writers (a second copy started by autostart) never
    # rename each other's half-written file away.
    tmp = path.with_suffix(f"{path.suffix}.{os.getpid()}-{threading.get_ident()}.tmp")
    tmp.write_text(text, encoding="utf-8")
    # Windows refuses to replace a file another process has open without
    # FILE_SHARE_DELETE, which neither QSettings (the QML reader, polling at
    # the frame rate) nor Python's open() asks for. The reader holds it for
    # well under a millisecond; if it is still busy, drop this write — the
    # next frame follows within one frame interval.
    for attempt in range(5):
        try:
            os.replace(tmp, path)
            return
        except PermissionError:
            time.sleep(0.001 * (attempt + 1))
    tmp.unlink(missing_ok=True)


def _write_status(run: Path, line: str) -> None:
    _publish(run / "status.ini", 'v="%s"\n' % line)
    _publish(run / "status", line + "\n")


def _loopback_microphone():
    """The default output device, opened for recording what it plays."""
    import soundcard

    speaker = soundcard.default_speaker()
    try:
        return soundcard.get_microphone(str(speaker.name), include_loopback=True)
    except (IndexError, RuntimeError):
        # Linux: PulseAudio already exposes the monitor source as a microphone.
        return soundcard.default_microphone()


class NoOutputDevice(RuntimeError):
    """Windows has no output at all: nothing plays, so nothing can be captured.

    No speakers or headphones, or a remote desktop session whose client does
    not bring the sound back ("Remote Audio" only exists when it does).
    """


def _default_output_id() -> str | None:
    """The current default output device's id, or None when there is none."""
    try:
        import soundcard

        return str(soundcard.default_speaker().id)
    except Exception:  # noqa: BLE001 — WASAPI raises RuntimeError(0x80070490) with no device
        return None


def _band_edges(bars: int, low: int, high: int) -> np.ndarray:
    """Log-spaced FFT bin index per band edge, matching cava's band layout."""
    freqs = np.logspace(
        np.log10(max(20, low)), np.log10(min(high, SAMPLERATE // 2)), bars + 1
    )
    edges = np.round(freqs * FFT_SIZE / SAMPLERATE).astype(int)
    # Distinct bins per band, or low bands collapse onto the same index.
    for i in range(1, len(edges)):
        edges[i] = max(edges[i], edges[i - 1] + 1)
    return np.clip(edges, 0, FFT_SIZE // 2)


class _Feed(threading.Thread):
    def __init__(self, run: Path, config: dict):
        super().__init__(daemon=True, name="audio-capture")
        self.run_dir = run
        self.bars = int(config.get("numBars", 24))
        self.framerate = max(10, int(config.get("framerate", 60)))
        self.sensitivity = float(config.get("sensitivity", 100)) / 100.0
        self.noise_reduction = float(config.get("noiseReduction", 0.77))
        self.low = int(config.get("lowCutoff", 50))
        self.high = int(config.get("highCutoff", 10000))
        self._stop_event = threading.Event()
        self._last_frame = ""
        self._last_second = -1

    def stop(self) -> None:
        self._stop_event.set()

    def run(self) -> None:
        # Never give up: a machine with no output device at startup, or one
        # that loses it mid-playback, should start drawing again as soon as a
        # device is back, not stay blank until the app is restarted.
        while not self._stop_event.is_set():
            try:
                self._capture()
            except NoOutputDevice:
                _write_status(self.run_dir, "error no-output")
                self._idle()
            except Exception as error:  # noqa: BLE001 — surfaced to the widget, not raised into Qt
                _write_status(self.run_dir, "error capture %s" % type(error).__name__)
                self._idle()
        _write_status(self.run_dir, "ok stopped")

    def _idle(self) -> None:
        """Wait to retry, keeping silent frames fresh meanwhile.

        VisualizerCore only trusts status.ini while frame.ini is fresh, so
        without these the widget would never show why it is not moving.
        """
        deadline = time.monotonic() + RETRY_SECONDS
        while not self._stop_event.is_set() and time.monotonic() < deadline:
            self._publish_frame(np.zeros(self.bars))
            self._stop_event.wait(min(0.5, RETRY_SECONDS))

    def _capture(self) -> None:
        """Capture until stopped or the default output changes, then return."""
        device = _default_output_id()
        if device is None:
            raise NoOutputDevice
        next_check = time.monotonic() + DEVICE_CHECK_SECONDS
        window = np.hanning(FFT_SIZE).astype(np.float32)
        ring = np.zeros(FFT_SIZE, dtype=np.float32)
        edges = _band_edges(self.bars, self.low, self.high)
        smoothed = np.zeros(self.bars, dtype=np.float32)
        # cava's autosens: normalise against a decaying running peak so quiet
        # tracks still fill the bars and loud ones do not clip flat.
        peak = 1e-6
        block = max(64, SAMPLERATE // self.framerate)

        with _loopback_microphone().recorder(
            samplerate=SAMPLERATE, blocksize=block
        ) as recorder:
            _write_status(self.run_dir, "ok loopback")
            while not self._stop_event.is_set():
                chunk = recorder.record(block)
                mono = chunk.mean(axis=1) if chunk.ndim > 1 else chunk
                # A low framerate makes the block longer than the window; only
                # the newest FFT_SIZE samples can be held anyway.
                mono = mono[-FFT_SIZE:]
                shift = len(mono)
                ring[:-shift] = ring[shift:]
                ring[-shift:] = mono

                spectrum = np.abs(np.fft.rfft(ring * window))
                # initial= because clipping can leave a band with no bins of
                # its own, and max() of an empty slice raises.
                raw = np.array(
                    [
                        spectrum[a:b].max(initial=0.0)
                        for a, b in zip(edges[:-1], edges[1:])
                    ],
                    dtype=np.float32,
                )
                # Compensate the 1/f tilt of music so highs stay visible.
                raw *= np.sqrt(np.arange(1, self.bars + 1, dtype=np.float32))

                peak = max(raw.max(), peak * 0.999, 1e-6)
                scaled = np.clip(raw / peak * self.sensitivity, 0, 1) * MAX_RANGE
                # noise_reduction is cava's integral filter: a per-frame EMA.
                smoothed = smoothed * self.noise_reduction + scaled * (
                    1 - self.noise_reduction
                )
                self._publish_frame(smoothed)

                # Loopback is bound to one endpoint; WASAPI keeps it open
                # silently after the default moves elsewhere.
                if time.monotonic() >= next_check:
                    next_check = time.monotonic() + DEVICE_CHECK_SECONDS
                    if _default_output_id() != device:
                        _write_status(self.run_dir, "probing loopback")
                        return

    def _publish_frame(self, values: np.ndarray) -> None:
        frame = ";".join(str(int(v)) for v in values)
        now = time.time()
        # feeder.sh's write_frame rule: an unchanged frame is rewritten only
        # once a second, which is enough to keep the reader's two-second
        # freshness check passing. Without it silence still costs a write and a
        # rename per frame — 60/s of identical zeros.
        if frame == self._last_frame and int(now) == self._last_second:
            return
        self._last_frame = frame
        self._last_second = int(now)
        _publish(
            self.run_dir / "frame.ini",
            't=%.3f\nv="%s"\nprotocol=2\n' % (now, frame),
        )


_feed: _Feed | None = None


def start(config: dict, run: Path | None = None) -> Path:
    """Begin publishing frames; returns the directory they are published in."""
    global _feed
    stop()
    target = run or runtime_dir()
    _write_status(target, "probing loopback")
    _feed = _Feed(target, config)
    _feed.start()
    return target


def stop() -> None:
    global _feed
    if _feed is not None:
        _feed.stop()
        _feed.join(timeout=2)
        _feed = None
