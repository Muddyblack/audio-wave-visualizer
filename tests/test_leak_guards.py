#!/usr/bin/env python3
"""Static guards for the patterns that made plasmashell grow (issue #10).

Source-level checks that need no Qt, so they run everywhere. They complement
test_command_sources.py (raw executable DataSource). Each rule has a documented
way out; add a justified entry to ALLOW rather than weakening the rule.

1. Dynamic objects: Qt.createQmlObject is banned (it leaks the parsed
   component per call) and every Component.createObject must have a destroy()
   in the same file.
2. Always-on clocks: a repeating Timer must not be `running: true` or have an
   `interval` below 16 ms; it must be gated on visibility / activity.
3. Unbounded caches: module-level JS maps that are only ever written to.
"""

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
FOLDERS = ("package", "hyprland")
ALLOW = {}  # "relative/path.qml:rule": "why it is safe"

problems = []


def report(path, rule, message):
    key = f"{path.relative_to(REPO)}:{rule}"
    if key not in ALLOW:
        problems.append(f"{key}  {message}")


def blocks(text, item):
    """Yield the body of every `Item { ... }` block (brace matched)."""
    for match in re.finditer(rf"\b{item}\s*\{{", text):
        depth, i = 1, match.end()
        while i < len(text) and depth:
            depth += {"{": 1, "}": -1}.get(text[i], 0)
            i += 1
        yield text[match.end() : i - 1]


for folder in FOLDERS:
    for path in sorted((REPO / folder).rglob("*.qml")):
        text = path.read_text()
        if "Qt.createQmlObject" in text:
            report(
                path, "createQmlObject", "leaks a component per call; use a Component"
            )
        if ".createObject(" in text and ".destroy(" not in text:
            report(path, "createObject", "created objects are never destroy()ed")
        for body in blocks(text, "Timer"):
            if not re.search(r"repeat:\s*true", body):
                continue
            if re.search(r"running:\s*true\s*(\n|$)", body):
                report(
                    path, "alwaysOnTimer", "repeating Timer is always running; gate it"
                )
            interval = re.search(r"interval:\s*(\d+)\s*(\n|$)", body)
            if interval and int(interval.group(1)) < 16:
                report(path, "fastTimer", f"{interval.group(1)} ms repeating Timer")

for path in sorted((REPO / "package/contents/code").glob("*.js")):
    text = path.read_text()
    for name in re.findall(
        r"^(?:var|let)\s+(\w+)\s*=\s*(?:\{\}|new Map\(\)|\[\])\s*;", text, re.M
    ):
        writes = re.search(rf"\b{name}\s*(\[[^\]]+\]\s*=|\.set\(|\.push\()", text)
        shrinks = re.search(
            rf"\b{name}\s*(\.delete\(|\.clear\(|\.length\s*=|\.shift\(|\.splice\(|\s*=\s*(\{{\}}|\[\]))",
            text.replace(f"var {name}", "", 1),
        )
        if writes and not shrinks:
            report(
                path,
                f"unboundedCache:{name}",
                "module-level collection only ever grows",
            )

if problems:
    sys.exit("Memory-growth guard failed:\n  " + "\n  ".join(problems))
print("leak guards: PASS")
