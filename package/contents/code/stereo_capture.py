#!/usr/bin/env python3
"""Publish bounded signed stereo PCM frames while the QML owner's lease is live.

The default is the output monitor; explicit selections never fall back.
"""

import argparse
import configparser
import os
from pathlib import Path
import select
import shutil
import struct
import subprocess
import time


def samples(block, count=32):
    """Keep channels paired and signed; choose one contiguous triggered window."""
    frames = list(struct.iter_unpack("<hh", block[: len(block) // 4 * 4]))
    if len(frames) < count:
        return []
    # Start on a rising left-channel zero crossing, retaining stereo phase.
    start = next(
        (
            i
            for i in range(1, len(frames) - count + 1)
            if frames[i - 1][0] <= 0 < frames[i][0]
        ),
        0,
    )
    return [
        (left / 32768, right / 32768) for left, right in frames[start : start + count]
    ]


def lease_alive(path):
    try:
        parser = configparser.ConfigParser()
        parser.read(path)
        return abs(time.time() * 1000 - float(parser["General"]["t"])) < 3000
    except (OSError, ValueError, KeyError, configparser.Error):
        return False


def capture(lease, output, fps, source="auto"):
    if source == "auto" and not shutil.which("pw-cat"):
        raise RuntimeError("Stereo scope requires pw-cat (PipeWire)")
    command = [
        "pw-cat",
        "--record",
        "--raw",
        "--format=s16",
        "--rate=8000",
        "--channels=2",
        "--channel-map=FL,FR",
        "--latency=20ms",
        "--properties={ stream.capture.sink=true node.passive=true }",
        "-",
    ]
    if source != "auto":
        from audio_sources import capture_command

        command = capture_command(source, rate=8000)
    process = subprocess.Popen(
        command, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL
    )
    pending = bytearray()
    last = 0
    try:
        while lease_alive(lease) and process.poll() is None:
            if not select.select([process.stdout], [], [], 0.25)[0]:
                continue
            data = os.read(process.stdout.fileno(), 8192)
            if not data:
                break
            pending.extend(data)
            if len(pending) < 512 or time.monotonic() - last < 1 / fps:
                # Bound retained memory even if the producer outpaces polling.
                if len(pending) > 4096:
                    del pending[: len(pending) // 4 * 4 - 2048]
                continue
            complete = len(pending) // 4 * 4
            frame = samples(pending[complete - 512 : complete])
            del pending[:complete]
            value = ";".join(f"{left:.6f}:{right:.6f}" for left, right in frame)
            temporary = output.with_suffix(".tmp")
            temporary.write_text(f'[General]\nt={time.time():.6f}\nv="{value}"\n')
            temporary.replace(output)
            last = time.monotonic()
    finally:
        process.terminate()
        try:
            process.wait(timeout=1)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
        output.unlink(missing_ok=True)
        output.with_suffix(".tmp").unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("lease", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("fps", type=int)
    parser.add_argument("source", nargs="?", default="auto")
    args = parser.parse_args()
    try:
        capture(args.lease, args.output, max(1, min(60, args.fps)), args.source)
    except (OSError, RuntimeError) as error:
        print(error)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
