#!/usr/bin/env bash
if ! command -v python3 >/dev/null 2>&1; then
    printf '%s\n' '{"warning":"Install Python 3 to load local lyrics and automatic pronunciation"}'
    exit 0
fi
if [[ $1 == --online ]]; then
    shift
    exec python3 "${BASH_SOURCE[0]%/*}/online_lyrics.py" "$@"
fi
exec python3 "${BASH_SOURCE[0]%/*}/local_lyrics.py" "$@"
