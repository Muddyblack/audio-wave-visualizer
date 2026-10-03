#!/usr/bin/env bash
# A bounded, per-widget SVG for Plasma's native blur mask. No screen capture.
set -euo pipefail
[[ $# == 5 ]] || exit 2
for value in "$@"; do
    [[ $value =~ ^[0-9]{1,6}$ ]] || exit 2
done
instance=$((10#$1)); width=$((10#$2)); height=$((10#$3)); radius=$((10#$4)); padding=$((10#$5))
((width >= 30 && width <= 2000 && height >= 30 && height <= 2000 && radius <= 100 && padding <= 64)) || exit 2
[[ -n ${XDG_RUNTIME_DIR:-} && -d $XDG_RUNTIME_DIR && -O $XDG_RUNTIME_DIR ]] || exit 3
umask 077
directory="$XDG_RUNTIME_DIR/plasma-audio-visualizer-blur/$instance"
mkdir -p -- "$directory"
file="$directory/$width-$height-$radius-$padding.svg"
if [[ ! -f $file ]]; then
    temporary=$(mktemp "$directory/.mask.XXXXXX")
    trap 'rm -f -- "$temporary"' EXIT
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d"><g id="center"><rect width="%d" height="%d" fill="none"/><rect x="%d" y="%d" width="%d" height="%d" rx="%d" fill="white"/></g></svg>\n' \
        "$((width + padding * 2))" "$((height + padding * 2))" \
        "$((width + padding * 2))" "$((height + padding * 2))" \
        "$padding" "$padding" "$width" "$height" "$radius" > "$temporary"
    mv -f -- "$temporary" "$file"
fi
# Requests are serialized by the QML owner, which disables blur during replacement.
# Keep only the current immutable shape; names prevent stale SVG cache hits.
for previous in "$directory"/*.svg; do
    [[ $previous == "$file" ]] || rm -f -- "$previous"
done
printf '%s\n' "$file"
