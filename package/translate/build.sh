#!/usr/bin/env sh
# Compile the Turkish catalog into a Plasma package.
#
# Usage: build.sh [PACKAGE_DIR]
#
# Plasma loads bundled catalogs from
#   <package>/contents/locale/<lang>/LC_MESSAGES/plasma_applet_<plugin id>.mo
# so the catalog name is derived from the package's own metadata.json. This
# lets test_install.sh build a catalog for the renamed test copy.
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
PACKAGE_DIR="$(CDPATH= cd -- "${1:-$SCRIPT_DIR/..}" && pwd)"
SOURCE="$SCRIPT_DIR/tr.po"

if ! command -v msgfmt >/dev/null 2>&1; then
    echo "error: gettext (msgfmt) is required to build translations" >&2
    exit 1
fi

PLUGIN_ID="$(sed -n 's/.*"Id":[[:space:]]*"\([^"]*\)".*/\1/p' "$PACKAGE_DIR/metadata.json" | head -n 1)"
if [ -z "$PLUGIN_ID" ]; then
    echo "error: could not read KPlugin.Id from $PACKAGE_DIR/metadata.json" >&2
    exit 1
fi

OUTPUT_DIR="$PACKAGE_DIR/contents/locale/tr/LC_MESSAGES"
CATALOG="plasma_applet_$PLUGIN_ID.mo"

mkdir -p "$OUTPUT_DIR"
msgfmt --check --check-header --output-file="$OUTPUT_DIR/$CATALOG" "$SOURCE"
echo "Built Turkish translation: $OUTPUT_DIR/$CATALOG"
