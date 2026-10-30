"""Catalog checks msgfmt cannot do: placeholders, marked labels, compiled name."""

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
TRANSLATE = REPO / "translate"
STRING = r'"((?:[^"\\\n]|\\.)*)"'


def unescape(text):
    return re.sub(
        r"\\(.)", lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), text
    )


def read_po(path):
    """msgid -> msgstr for every entry; continuation lines are joined."""
    entries = {}
    msgid = msgstr = field = None

    def flush():
        if msgid:
            entries[msgid] = msgstr or ""

    for line in path.read_text(encoding="utf-8").split("\n"):
        if line.startswith("msgid "):
            flush()
            msgid, msgstr, field = unescape(line[7:-1]), None, "id"
        elif line.startswith("msgstr "):
            msgstr, field = unescape(line[8:-1]), "str"
        elif line.startswith('"') and field == "id":
            msgid += unescape(line[1:-1])
        elif line.startswith('"') and field == "str":
            msgstr += unescape(line[1:-1])
        elif not line.strip():
            flush()
            msgid = field = None
    flush()
    return entries


failures = []

# 1. Every translation keeps its %N placeholders.
for po in sorted(TRANSLATE.glob("*.po")):
    for msgid, msgstr in read_po(po).items():
        if msgstr and set(re.findall(r"%\d", msgid)) != set(re.findall(r"%\d", msgstr)):
            failures.append(f"{po.name}: placeholder mismatch: {msgid!r} -> {msgstr!r}")

# 2. Studio data labels are marked, so they can be translated when drawn.
for name in ("Schema.js", "StudioCatalog.js"):
    text = (REPO / "package/contents/ui/studio" / name).read_text(encoding="utf-8")
    for match in re.finditer(
        r'"?\b(?:label|desc|title|kde|hypr)"?\s*:\s*' + STRING, text
    ):
        if match.group(1):
            failures.append(
                f"{name}: unmarked display text {unescape(match.group(1))!r}"
            )

if shutil.which("msgfmt"):
    # 3. Every catalog compiles; the listed languages are complete.
    result = subprocess.run(
        [str(TRANSLATE / "check.sh")], capture_output=True, text=True, check=False
    )
    if result.returncode:
        failures.append("check.sh failed: " + result.stderr.strip())

    # 4. The catalog is named after the package it is built for.
    with tempfile.TemporaryDirectory() as directory:
        package = Path(directory)
        (package / "metadata.json").write_text(
            '{"KPlugin": {"Id": "org.example.test"}}\n'
        )
        result = subprocess.run(
            [str(TRANSLATE / "build.sh"), str(package)],
            capture_output=True,
            text=True,
            check=False,
        )
        compiled = (
            package / "contents/locale/tr/LC_MESSAGES/plasma_applet_org.example.test.mo"
        )
        if result.returncode or not compiled.is_file():
            failures.append("build.sh failed: " + result.stderr.strip())
else:
    print("SKIP: msgfmt is not on PATH; catalog compilation not checked")

if failures:
    print("\n".join("FAIL: " + failure for failure in failures))
    sys.exit(1)
print("PASS: translation catalogs")
