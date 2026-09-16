#!/usr/bin/env python3
"""Discover capture targets and construct isolated PCM capture commands."""

import json
import os
import subprocess
import sys


def query(command):
    result = subprocess.run(
        command, capture_output=True, text=True, timeout=3, check=True
    )
    return json.loads(result.stdout)


def targets():
    found = []
    try:
        for node in query(["pw-dump"]):
            props = node.get("info", {}).get("props", {})
            kind = props.get("media.class")
            if kind not in ("Audio/Sink", "Audio/Source", "Stream/Output/Audio"):
                continue
            name = props.get("node.name")
            if not name:
                continue
            label = (
                props.get("node.description") or props.get("application.name") or name
            )
            group = {
                "Audio/Sink": "Output",
                "Audio/Source": "Input",
                "Stream/Output/Audio": "Application",
            }[kind]
            found.append(
                [
                    "pw:" + name,
                    group + ": " + label,
                    str(props.get("object.serial", node["id"])),
                    kind,
                ]
            )
    except (OSError, ValueError, subprocess.SubprocessError):
        pass
    try:
        for source in query(["pactl", "--format=json", "list", "sources"]):
            found.append(
                [
                    "pulse:" + source["name"],
                    "Pulse: " + source.get("description", source["name"]),
                    source["name"],
                    "source",
                ]
            )
        sinks = {
            str(s["index"]): s["monitor_source"]
            for s in query(["pactl", "--format=json", "list", "sinks"])
        }
        for stream in query(["pactl", "--format=json", "list", "sink-inputs"]):
            props = stream.get("properties", {})
            identity = props.get("application.process.binary") or props.get(
                "application.name"
            )
            if identity and str(stream["sink"]) in sinks:
                found.append(
                    [
                        "app:" + identity,
                        "Application (Pulse): "
                        + props.get("application.name", identity),
                        str(stream["index"]),
                        str(sinks[str(stream["sink"])]),
                    ]
                )
    except (OSError, ValueError, KeyError, subprocess.SubprocessError):
        pass
    return found


def capture_command(selection, rate=44100):
    target = next((t for t in targets() if t[0] == selection), None)
    if target is None:
        raise RuntimeError("Selected audio source unavailable: " + selection)
    if selection.startswith("pw:"):
        properties = {
            "node.dont-fallback": True,
            "node.linger": False,
            "node.passive": True,
            "stream.capture.sink": target[3] != "Audio/Source",
        }
        return [
            "pw-cat",
            "--record",
            "--raw",
            "--format=s16",
            "--rate=" + str(rate),
            "--channels=2",
            "--target=" + target[2],
            "--properties=" + json.dumps(properties),
            "-",
        ]
    command = [
        "parec",
        "--raw",
        "--format=s16le",
        "--rate=" + str(rate),
        "--channels=2",
    ]
    if selection.startswith("app:"):
        command += ["--monitor-stream=" + target[2], "--device=" + target[3]]
    else:
        command += ["--device=" + target[2]]
    return command


def main():
    if len(sys.argv) == 1 or sys.argv[1] == "list":
        choices = [["auto", "Default output monitor"]]
        for value, label, *_ in targets():
            if not any(c[0] == value for c in choices):
                choices.append([value, label])
        print(json.dumps(choices))
        return
    try:
        command = capture_command(
            sys.argv[2] if sys.argv[1] == "check" else sys.argv[1]
        )
        if sys.argv[1] == "check":
            return
        os.execvp(command[0], command)
    except (OSError, RuntimeError) as error:
        print(error, file=sys.stderr)
        raise SystemExit(1) from error


if __name__ == "__main__":
    main()
