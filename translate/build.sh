#!/usr/bin/env bash
#
# Compile translate/<lang>.po into the binary catalogs the plasmoid loads at
# runtime: <package>/contents/locale/<lang>/LC_MESSAGES/plasma_applet_<Id>.mo.
#
# Usage: translate/build.sh [PACKAGE_DIR]   (default: package)
#
# The widget reads <package>/contents/translate/<lang>.po for its own text, and
# Plasma reads the .mo for the store description. Both are build output, not
# committed. The catalog name comes from the package's own metadata.json, so
# test_install.sh can build one for its renamed test copy.
set -euo pipefail

if ! command -v msgfmt >/dev/null 2>&1; then
    echo "error: msgfmt not found — install gettext (or run inside 'nix develop')" >&2
    exit 1
fi

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(dirname "$dir")"
pkg="${1:-$root/package}"

id="$(grep -oE '"Id"[[:space:]]*:[[:space:]]*"[^"]+"' "$pkg/metadata.json" | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
if [ -z "$id" ]; then
    echo "error: could not read KPlugin.Id from $pkg/metadata.json" >&2
    exit 1
fi
domain="plasma_applet_$id"

# An unchanged .po does not need recompiling: the .mo is derived output, and
# `make view`/`pack` run this on every invocation. Set FORCE_TRANSLATIONS=1
# (or delete the .mo) to rebuild regardless. The .mo is ignored when its
# mtime is not strictly newer than the .po, so a checked-out pair still
# compiles once.
force="${FORCE_TRANSLATIONS:-0}"

shopt -s nullglob
for po in "$dir"/*.po; do
    lang="$(basename "$po" .po)"
    mkdir -p "$pkg/contents/translate"
    cp "$po" "$pkg/contents/translate/"
    outdir="$pkg/contents/locale/$lang/LC_MESSAGES"
    out="$outdir/$domain.mo"
    if [ "$force" != "1" ] && [ -e "$out" ] && [ "$out" -nt "$po" ]; then
        continue
    fi
    mkdir -p "$outdir"
    msgfmt --check-format --output-file="$out" "$po"
    echo "[i18n] $lang -> ${out#"$root"/}"
done
shopt -u nullglob
