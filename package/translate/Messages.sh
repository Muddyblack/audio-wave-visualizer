#!/bin/sh
# Extracts every i18n("…") and N_("…") literal from the QML and JavaScript
# sources into template.pot, then merges it into tr.po. Obsolete entries are
# dropped, and translations are kept. Run after changing any UI string.
set -eu

# Sorting and the #: location comments must not depend on the user's locale.
export LC_ALL=C

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
cd "$ROOT"

SOURCES=$(find package/contents hyprland \( -name '*.qml' -o -name '*.js' \) \
    -not -path '*/locale/*' -not -path '*/node_modules/*' | sort)

xgettext --language=JavaScript --from-code=UTF-8 -k \
    --keyword=i18n --keyword=N_ \
    --package-name="Plasma Audio Visualizer" --msgid-bugs-address=https://github.com/Muddyblack/audio-wave-visualizer/issues \
    --add-location=file --sort-output \
    --output="$HERE/template.pot" $SOURCES

sed -i '/^"POT-Creation-Date:/d' "$HERE/template.pot"
msgmerge --quiet --update --backup=none --no-fuzzy-matching \
    --add-location=file "$HERE/tr.po" "$HERE/template.pot"
msgattrib --no-obsolete --output="$HERE/tr.po" "$HERE/tr.po"
# The catalog the studio uses at run time, generated so that it is available as
# soon as the module is imported. Hosts never have to load a file first.
python3 "$HERE/catalog.py" "$HERE/tr.po" "$ROOT/package/contents/ui/studio/TranslationCatalog.js"
echo "Messages: $(grep -c '^msgid ' "$HERE/template.pot" | awk '{print $1-1}') strings in template.pot"
