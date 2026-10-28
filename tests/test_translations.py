#!/usr/bin/env python3
"""Turkish catalog checks: syntax, coverage of UI strings and the QML fallback."""

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
import sync_translations  # noqa: E402

UI = REPO / "package/contents/ui"
STUDIO = UI / "studio"
LITERAL = r'"((?:[^"\\]|\\.)*)"'


def unescape(text):
    return re.sub(r"\\(.)", lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), text)


catalog = dict(sync_translations.read_po(sync_translations.PO))
failures = []

# 1. template.pot and Translations.js are generated from tr.po.
if subprocess.run([sys.executable, str(REPO / "tools/sync_translations.py"), "--check"]).returncode:
    failures.append("template.pot or Translations.js is stale; run tools/sync_translations.py")

# 2. Every entry is translated and keeps its %N placeholders.
for msgid, msgstr in catalog.items():
    if not msgstr:
        failures.append(f"untranslated: {msgid!r}")
    elif sorted(set(re.findall(r"%\d", msgid))) != sorted(set(re.findall(r"%\d", msgstr))):
        failures.append(f"placeholder mismatch: {msgid!r} -> {msgstr!r}")

# 3. Every literal passed to i18n() or Translations.translate() is in the catalog.
for path in sorted(UI.rglob("*.qml")) + sorted(UI.rglob("*.js")):
    text = path.read_text(encoding="utf-8")
    for match in re.finditer(r"(?:\bi18n|Translations\.translate)\(\s*" + LITERAL, text):
        msgid = unescape(match.group(1))
        if msgid and msgid not in catalog:
            line = text.count("\n", 0, match.start()) + 1
            failures.append(f"{path.relative_to(REPO)}:{line}: not in tr.po: {msgid!r}")

# 4. Schema data that the studio passes to i18n() at render time: labels,
#    descriptions, section titles, option labels and style names.
schema = (STUDIO / "Schema.js").read_text(encoding="utf-8") + (STUDIO / "StudioCatalog.js").read_text(encoding="utf-8")
data = set()
for match in re.finditer(r'\b"?(?:label|desc|title)"?\s*:\s*' + LITERAL, schema):
    data.add(unescape(match.group(1)))
for match in re.finditer(r'\[\s*(?:"[^"]*"|-?[\d.]+|true|false)\s*,\s*' + LITERAL + r"\s*\]", schema):
    data.add(unescape(match.group(1)))
for name in ("VIZ", "PBS", "ORBITS", "STATES", "FILTERS"):
    block = re.search(r"var " + name + r" = \[(.*?)\];", schema, re.S)
    if not block:
        failures.append(f"Schema.js: {name} not found")
        continue
    data.update(unescape(s) for s in re.findall(LITERAL, block.group(1)) if re.search(r"[A-Z]", s[:1]) or " " in s)
for msgid in sorted(data):
    if msgid and msgid not in catalog:
        failures.append(f"Schema data not in tr.po: {msgid!r}")

# 5. The catalog compiles, under the name Plasma looks for.
if shutil.which("msgfmt"):
    with tempfile.TemporaryDirectory() as directory:
        package = Path(directory)
        (package / "metadata.json").write_text('{"KPlugin": {"Id": "org.example.test"}}\n')
        result = subprocess.run(
            ["sh", str(REPO / "package/translate/build.sh"), str(package)],
            capture_output=True,
            text=True,
        )
        catalog_file = package / "contents/locale/tr/LC_MESSAGES/plasma_applet_org.example.test.mo"
        if result.returncode or not catalog_file.is_file():
            failures.append("build.sh failed: " + result.stderr.strip())
else:
    print("SKIP: msgfmt is not on PATH; catalog compilation not checked")

if failures:
    print("\n".join("FAIL: " + failure for failure in failures))
    sys.exit(1)
print(f"PASS: Turkish catalog ({len(catalog)} messages) covers the studio and compiles")
