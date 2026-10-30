#!/usr/bin/env bash
#
# Extract every translatable string from the widget and merge it into the
# per-language catalogs under translate/.
#
# The widget ships its own translations inside the .plasmoid archive, in
# package/contents/locale/<lang>/LC_MESSAGES/plasma_applet_<Id>.mo. This script
# only updates the sources of truth, translate/*.po, through template.pot. The
# template, and the .mo files build.sh compiles, are git-ignored build output.
#
# Requires gettext (xgettext, msgmerge).
set -euo pipefail

if ! command -v xgettext >/dev/null 2>&1; then
    echo "error: xgettext not found — install gettext (or run inside 'nix develop')" >&2
    exit 1
fi

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(dirname "$dir")"
pkg="$root/package"

bug_url="$(grep -oE '"Website"[[:space:]]*:[[:space:]]*"[^"]+"' "$pkg/metadata.json" | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"

pot="$dir/template.pot"

# QML is not a language xgettext knows, but every translatable call sits inside
# a JavaScript expression, so the JavaScript backend finds them all. noop marks
# text stored as data and translated when it is drawn. Windows's tray words pass
# through QML too (windows/qml/Overlay.qml), so Python needs no pass of its own.
#
# Paths are relative to the repo root so template.pot does not embed the build
# machine's home directory (which would make every diff machine-specific).
cd "$root"
mapfile -t sources < <(
    find package/contents hyprland windows/qml \
        -type f \( -name '*.qml' -o -name '*.js' \) -not -path '*/locale/*' | LC_ALL=C sort
)
# The KPlugin description is read from metadata.json by KJsonUtils. It never
# appears in code, so it is declared in this tiny shim.
sources+=("translate/metadata-i18n.js")

xgettext \
    --from-code=UTF-8 \
    --language=JavaScript \
    --add-comments=TRANSLATORS \
    --no-location \
    --keyword=i18n --keyword=i18nc:1c,2 --keyword=i18np:1,2 --keyword=i18ncp:1c,2,3 \
    --keyword=noop \
    --package-name="Plasma Audio Visualizer" \
    --msgid-bugs-address="$bug_url/issues" \
    --output="$pot" \
    "${sources[@]}"

# xgettext keys the catalog header on the charmap; normalise it so the .pot is
# stable and the merge in a fresh checkout is a no-op.
sed -i 's/^"Content-Type: text\/plain; charset=CHARSET\\n"$/"Content-Type: text\/plain; charset=UTF-8\\n"/' "$pot"

# The creation date changes on every run. Drop it from the .pot and the .po so
# a regenerated catalog is byte-identical to the committed one — the CI sync
# check compares them with `git diff --exit-code`.
sed -i '/^"POT-Creation-Date:/d' "$pot"

shopt -s nullglob
for po in "$dir"/*.po; do
    echo "[i18n] merge $(basename "$po")"
    # No locations: moving a string between files should not rewrite catalogs.
    msgmerge --quiet --update --backup=none --no-fuzzy-matching --no-location "$po" "$pot"
    sed -i '/^"POT-Creation-Date:/d' "$po"
    # Drop entries that are no longer in the sources, so the catalog only ever
    # holds live strings.
    msgattrib --no-obsolete --no-location "$po" -o "$po"
done
shopt -u nullglob

echo "[i18n] wrote $pot"
