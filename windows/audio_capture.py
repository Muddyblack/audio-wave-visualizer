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
import soundcard

FFT_SIZE = 2048
MAX_RANGE = 1000.0
SAMPLERATE = 48000


def runtime_dir() -> Path:
    """Where frames are published. XDG_RUNTIME_DIR has no Windows equivalent."""
    base = os.environ.get("LOCALAPPDATA") or os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    path = Path(base) / "audio-visualizer"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _publish(path: Path, text: str) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(text, encoding="utf-8")
    os.replace(tmp, path)


def _write_status(run: Path, line: str) -> None:
    _publish(run / "status.ini", 'v="%s"\n' % line)
    _publish(run / "status", line + "\n")


def _loopback_microphone():
    """The default output device, opened for recording what it plays."""
    speaker = soundcard.default_speaker()
    try:
        return soundcard.get_microphone(str(speaker.name), include_loopback=True)
    except (IndexError, RuntimeError):
        # Linux: PulseAudio already exposes the monitor source as a microphone.
        return soundcard.default_microphone()


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
        self._stop = threading.Event()

    def stop(self) -> None:
        self._stop.set()

    def run(self) -> None:
        try:
            self._capture()
        except Exception as error:  # noqa: BLE001 — surfaced to the widget, not raised into Qt
            _write_status(self.run_dir, "error capture %s" % type(error).__name__)

    def _capture(self) -> None:
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
            while not self._stop.is_set():
                chunk = recorder.record(block)
                mono = chunk.mean(axis=1) if chunk.ndim > 1 else chunk
                ring = np.roll(ring, -len(mono))
                ring[-len(mono) :] = mono

                spectrum = np.abs(np.fft.rfft(ring * window))
                raw = np.array(
                    [spectrum[a:b].max() for a, b in zip(edges[:-1], edges[1:])],
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

        _write_status(self.run_dir, "ok stopped")

    def _publish_frame(self, values: np.ndarray) -> None:
        frame = ";".join(str(int(v)) for v in values)
        _publish(
            self.run_dir / "frame.ini",
            't=%.3f\nv="%s"\nprotocol=2\n' % (time.time(), frame),
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
