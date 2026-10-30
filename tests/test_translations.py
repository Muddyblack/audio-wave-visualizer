"""Turkish catalog checks: template freshness, coverage, placeholders and compilation."""

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
TRANSLATE = REPO / "package/translate"
SOURCES = [
    path
    for root in (REPO / "package/contents", REPO / "hyprland")
    for path in sorted(root.rglob("*"))
    if path.suffix in (".qml", ".js") and "locale" not in path.parts
]
STRING = r'"((?:[^"\\\n]|\\.)*)"'


def unescape(text):
    return re.sub(
        r"\\(.)", lambda m: {"n": "\n", "t": "\t"}.get(m.group(1), m.group(1)), text
    )


def read_po(path):
    """msgid -> msgstr for every entry; continuation lines are joined."""
    entries = {}
    msgid = msgstr = None
    field = None

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
            msgid = None
            field = None
    flush()
    return {key: value for key, value in entries.items() if key}


def literals(pattern, text):
    return [
        unescape(match.group(1))
        for match in re.finditer(pattern + r"\(\s*" + STRING, text)
    ]


sys.path.insert(0, str(TRANSLATE))
import catalog as generated  # noqa: E402

catalog = read_po(TRANSLATE / "tr.po")
failures = []

# 0. The run-time catalog matches tr.po.
runtime = REPO / "package/contents/ui/studio/TranslationCatalog.js"
if runtime.read_text(encoding="utf-8") != generated.render(
    generated.read_entries(TRANSLATE / "tr.po")
):
    failures.append("TranslationCatalog.js is stale; run package/translate/Messages.sh")

# 1. template.pot is what Messages.sh extracts from the current sources.
if shutil.which("xgettext"):
    with tempfile.TemporaryDirectory() as directory:
        fresh = Path(directory) / "template.pot"
        subprocess.run(
            [
                "xgettext",
                "--language=JavaScript",
                "--from-code=UTF-8",
                "-k",
                "--keyword=i18n",
                "--keyword=N_",
                "--output=" + str(fresh),
                *map(str, SOURCES),
            ],
            check=True,
        )
        expected = set(read_po(fresh))
        current = set(read_po(TRANSLATE / "template.pot"))
        if expected != current:
            failures.append(
                "template.pot is stale; run package/translate/Messages.sh "
                f"(missing {len(expected - current)}, extra {len(current - expected)})"
            )
else:
    print("SKIP: xgettext is not on PATH; template freshness not checked")

# 2. Every entry is translated and keeps its %N placeholders.
for msgid, msgstr in catalog.items():
    if not msgstr:
        failures.append(f"untranslated: {msgid!r}")
    elif sorted(set(re.findall(r"%\d", msgid))) != sorted(
        set(re.findall(r"%\d", msgstr))
    ):
        failures.append(f"placeholder mismatch: {msgid!r} -> {msgstr!r}")

# 3. Every string the code marks for translation is in the catalog.
for path in SOURCES:
    text = path.read_text(encoding="utf-8")
    for msgid in literals(r"(?:\bi18n|\bN_)", text):
        if msgid and msgid not in catalog:
            line = text.count("\n", 0, text.find(msgid)) + 1
            failures.append(
                f"{path.relative_to(REPO)}: not in tr.po: {msgid!r} (line ~{line})"
            )

# 4. Studio data labels are marked, so they can be translated when drawn.
for name in ("Schema.js", "StudioCatalog.js"):
    text = (REPO / "package/contents/ui/studio" / name).read_text(encoding="utf-8")
    for match in re.finditer(r"\b(?:label|desc|title|kde|hypr)\s*:\s*" + STRING, text):
        if match.group(1):
            failures.append(
                f"{name}: unmarked display text {unescape(match.group(1))!r}"
            )

# 4b. Catalog labels are marked where they are defined, not copied into a list.
catalog_text = (REPO / "package/contents/ui/studio/StudioCatalog.js").read_text(
    encoding="utf-8"
)
for match in re.finditer(r'"label":\s*"', catalog_text):
    failures.append(
        "StudioCatalog.js: label is not marked with N_(): "
        + catalog_text[match.start() : match.start() + 60].split("\n")[0]
    )
# 5. The old translation layer is gone.
for path in [*SOURCES, REPO / "tests/run.py", REPO / "test_install.sh"]:
    text = path.read_text(encoding="utf-8")
    if re.search(
        r"Translations\.js|isTurkish|sync_translations|Translations\.translate", text
    ):
        failures.append(
            f"{path.relative_to(REPO)}: refers to the removed translation layer"
        )

# 6. The catalog compiles under the name Plasma looks for.
if shutil.which("msgfmt"):
    with tempfile.TemporaryDirectory() as directory:
        package = Path(directory)
        (package / "metadata.json").write_text(
            '{"KPlugin": {"Id": "org.example.test"}}\n'
        )
        result = subprocess.run(
            ["sh", str(TRANSLATE / "build.sh"), str(package)],
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
print(f"PASS: Turkish catalog ({len(catalog)} messages) covers the widget and compiles")
