#!/usr/bin/env python3
"""Keep the Turkish catalog, its template and the QML fallback in step.

package/translate/tr.po is the single source of truth. This script rewrites
  * package/translate/template.pot  (same msgids, empty msgstr)
  * the MESSAGES table in package/contents/ui/studio/Translations.js, which
    hosts without KDE's i18n() (Quickshell/Hyprland) use as a fallback.

Run it after editing tr.po. `--check` exits non-zero when either file is stale.
"""

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PO = REPO / "package/translate/tr.po"
POT = REPO / "package/translate/template.pot"
JS = REPO / "package/contents/ui/studio/Translations.js"

POT_HEADER = """# Translation template for Plasma Audio Visualizer.
# Shared settings-schema strings are passed to KDE's i18n() function at render
# time. Generated from tr.po by tools/sync_translations.py; do not edit by hand.
msgid ""
msgstr ""
"Project-Id-Version: Plasma Audio Visualizer {version}\\n"
"Report-Msgid-Bugs-To: https://github.com/Muddyblack/audio-wave-visualizer/issues\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"
"""

_ESCAPES = {"n": "\n", "t": "\t", '"': '"', "\\": "\\"}


def _unquote(chunk):
    body = chunk.strip()[1:-1]
    return re.sub(r"\\(.)", lambda m: _ESCAPES.get(m.group(1), m.group(1)), body)


def _quote(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def read_po(path):
    """Return [(msgid, msgstr)] in file order, header excluded."""
    entries, key, values = [], None, {}

    def flush():
        if "msgid" in values and values["msgid"]:
            entries.append((values["msgid"], values.get("msgstr", "")))
        values.clear()

    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            if not stripped:
                flush()
                key = None
            continue
        match = re.match(r"(msgid|msgstr)\s+(\".*\")$", stripped)
        if match:
            if match.group(1) == "msgid" and "msgid" in values:
                flush()
            key = match.group(1)
            values[key] = _unquote(match.group(2))
        elif stripped.startswith('"') and key:
            values[key] += _unquote(stripped)
        else:
            raise SystemExit(f"{path}: unsupported line: {line}")
    flush()
    return entries


def render_pot(entries):
    version = json.loads((REPO / "package/metadata.json").read_text(encoding="utf-8"))["KPlugin"]["Version"]
    blocks = [POT_HEADER.replace("{version}", version)]
    for msgid, _ in entries:
        blocks.append(f"msgid {_quote(msgid)}\nmsgstr \"\"\n")
    return "\n".join(blocks)


def render_js(entries, current):
    start = current.index("var MESSAGES = {")
    end = current.index("\n};", start)
    lines = [
        f"    {json.dumps(msgid, ensure_ascii=False)}: {json.dumps(msgstr, ensure_ascii=False)}"
        for msgid, msgstr in entries
        if msgstr
    ]
    return current[:start] + "var MESSAGES = {\n" + ",\n".join(lines) + current[end:]


def main():
    check = "--check" in sys.argv[1:]
    entries = read_po(PO)
    seen = set()
    for msgid, _ in entries:
        if msgid in seen:
            raise SystemExit(f"duplicate msgid in {PO.name}: {msgid!r}")
        seen.add(msgid)
    outputs = {
        POT: render_pot(entries),
        JS: render_js(entries, JS.read_text(encoding="utf-8")),
    }
    stale = [path for path, text in outputs.items() if path.read_text(encoding="utf-8") != text]
    if check:
        for path in stale:
            print(f"stale: {path.relative_to(REPO)} (run tools/sync_translations.py)", file=sys.stderr)
        sys.exit(1 if stale else 0)
    for path in stale:
        path.write_text(outputs[path], encoding="utf-8")
        print(f"updated {path.relative_to(REPO)}")


if __name__ == "__main__":
    main()
