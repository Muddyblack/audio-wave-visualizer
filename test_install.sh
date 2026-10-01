#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# Use the desktop's Qt/KDE build on NixOS. The dev shell may have a different
# build that cannot load the running system's Plasma package plugins.
if [[ -z "${KPACKAGETOOL6:-}" ]]; then
    if [[ -x /run/current-system/sw/bin/kpackagetool6 ]]; then
        KPACKAGETOOL6=/run/current-system/sw/bin/kpackagetool6
    else
        KPACKAGETOOL6=kpackagetool6
    fi
fi

for tool in "$KPACKAGETOOL6" python3 timeout; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Required command not found: $tool" >&2
        exit 1
    fi
done

TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/audio-visualizer-test.XXXXXX")"
trap 'rm -rf -- "$TEMP_DIR"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
cp -r "$HERE/package/." "$TEMP_DIR/"

TEST_METADATA="$(python3 - "$TEMP_DIR/metadata.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
metadata = json.loads(path.read_text())
plugin = metadata["KPlugin"]
plugin["Id"] += "Test"
plugin["Name"] += " (Test)"
plugin["Icon"] = plugin["Id"]
path.write_text(json.dumps(metadata, indent=4) + "\n")
print(plugin["Id"])
print(plugin["Name"])
PY
)"
TEST_ID="${TEST_METADATA%%$'\n'*}"
NAME="${TEST_METADATA#*$'\n'}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
PACKAGE_ROOT="$DATA_DIR/plasma/plasmoids"

# Only the local test copy determines whether this is an install or update.
# Listing every package can stall if Plasma's package plugin fails to load.
if [[ -d "$PACKAGE_ROOT/$TEST_ID" ]]; then
    ACTION=-u
    echo "Updating $NAME..."
else
    ACTION=-i
    echo "Installing $NAME..."
fi
echo "Using $KPACKAGETOOL6 (30-second timeout)"
if timeout --kill-after=5s 30s "$KPACKAGETOOL6" -t Plasma/Applet \
    -p "$PACKAGE_ROOT" "$ACTION" "$TEMP_DIR"; then
    :
else
    result=$?
    if [[ "$result" == 124 || "$result" == 137 ]]; then
        echo "kpackagetool6 timed out. Check that it matches your desktop's Qt/KDE installation." >&2
    else
        echo "kpackagetool6 failed (exit $result); see its output above." >&2
    fi
    exit "$result"
fi

ICON_DIR="$DATA_DIR/icons/hicolor/256x256/apps"
mkdir -p "$ICON_DIR"
cp "$HERE/package/icon.png" "$ICON_DIR/$TEST_ID.png"

echo ""
echo "=== Test Widget Installed! ==="
echo "Add '$NAME' to your desktop or panel."
echo "To uninstall the test version later, run:"
printf '  %q -t Plasma/Applet -p %q -r %q\n' "$KPACKAGETOOL6" "$PACKAGE_ROOT" "$TEST_ID"
printf '  rm -f %q\n' "$ICON_DIR/$TEST_ID.png"
