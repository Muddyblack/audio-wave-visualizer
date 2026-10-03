#!/usr/bin/env bash
# Adjust the default output without requiring Python in Plasma's environment.
set -euo pipefail
export LC_ALL=C

step="${1:-}"
if [[ ! "$step" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
    echo "Expected a numeric volume adjustment" >&2
    exit 1
fi

target_volume() {
    awk -v current="$1" -v step="$step" 'BEGIN {
        if (step > 1) step = 1; if (step < -1) step = -1;
        value = current + step;
        if (value < 0) value = 0; if (value > 1) value = 1;
        printf "%.4f", value;
    }'
}

if current="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)"; then
    if [[ "$current" =~ Volume:[[:space:]]*([0-9]+([.][0-9]+)?) ]]; then
        target="$(target_volume "${BASH_REMATCH[1]}")"
        if wpctl set-volume --limit 1.0 @DEFAULT_AUDIO_SINK@ "$target" 2>/dev/null; then
            printf '%s\n' "$target"
            exit 0
        fi
    fi
fi

if current="$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null)"; then
    if [[ "$current" =~ ([0-9]+)% ]]; then
        current="$(awk -v percent="${BASH_REMATCH[1]}" 'BEGIN { print percent / 100 }')"
        target="$(target_volume "$current")"
        percent="$(awk -v target="$target" 'BEGIN { printf "%.0f", target * 100 }')"
        if pactl set-sink-volume @DEFAULT_SINK@ "${percent}%"; then
            awk -v percent="$percent" 'BEGIN { printf "%.4f\n", percent / 100 }'
            exit 0
        fi
    fi
fi

echo "Cannot adjust the default output: wpctl and pactl are unavailable or failed" >&2
exit 1
