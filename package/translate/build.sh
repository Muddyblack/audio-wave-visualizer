#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PACKAGE_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
SOURCE="$SCRIPT_DIR/tr.po"
OUTPUT_DIR="$PACKAGE_DIR/contents/locale/tr/LC_MESSAGES"
CATALOG="plasma_applet_org.muddyblack.plasmaAudioVisualizer.mo"

if ! command -v msgfmt >/dev/null 2>&1; then
    echo "error: gettext (msgfmt) is required to build translations" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
msgfmt --check --check-header --output-file="$OUTPUT_DIR/$CATALOG" "$SOURCE"
echo "Built Turkish translation: $OUTPUT_DIR/$CATALOG"
