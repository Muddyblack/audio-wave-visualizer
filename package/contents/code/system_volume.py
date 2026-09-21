#!/usr/bin/env python3
"""Adjust the default system output and print its resulting 0..1 volume."""

import re
import subprocess
import sys


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


def adjust(delta):
    delta = max(-1.0, min(1.0, float(delta)))
    try:
        current = float(
            re.search(
                r"Volume:\s*([0-9.]+)",
                run("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"),
            ).group(1)
        )
        target = max(0.0, min(1.0, current + delta))
        run(
            "wpctl",
            "set-volume",
            "--limit",
            "1.0",
            "@DEFAULT_AUDIO_SINK@",
            f"{target:.4f}",
        )
        return target
    except (
        FileNotFoundError,
        subprocess.CalledProcessError,
        AttributeError,
        ValueError,
    ):
        current = (
            int(
                re.search(
                    r"(\d+)%", run("pactl", "get-sink-volume", "@DEFAULT_SINK@")
                ).group(1)
            )
            / 100
        )
        target = max(0.0, min(1.0, current + delta))
        run("pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{round(target * 100)}%")
        return target


if __name__ == "__main__":
    try:
        print(f"{adjust(sys.argv[1]):.4f}")
    except (
        IndexError,
        FileNotFoundError,
        subprocess.CalledProcessError,
        AttributeError,
        ValueError,
    ) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1)
